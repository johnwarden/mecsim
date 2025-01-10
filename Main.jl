#!/usr/bin/env julia

using LinearAlgebra
using Random
using Optim
using Statistics
using Plots
using PrettyTables
using Printf

include("Preferences.jl")
include("Plots.jl")
include("Simulation.jl")
include("SummaryTables.jl")



# -----------------------------------------------------------------------------
#                                 Argument Parsing
# -----------------------------------------------------------------------------

const DEFAULT_MECHANISMS_DIR = abspath(joinpath(@__DIR__, "mechanisms"))
const DEFAULT_PREFERENCES_DIR = abspath(joinpath(@__DIR__, "preferences"))

"""
Return all `.jl` files found in `path`.  
If `path` is a directory, recursively expand.  
If `path` is a file not ending in `.jl`, return empty.  
"""
function expand_path(path::String)
    if isdir(path)
        results = String[]
        for filename in readdir(path)
            expanded = expand_path(joinpath(path, filename))
            append!(results, expanded)
        end
        return results
    else
        return endswith(path, ".jl") ? [path] : String[]
    end
end

arg_mechanism_files = String[]
arg_preference_files = String[]

for arg in ARGS
    fullpath = abspath(arg)
    if occursin("mechanisms/", fullpath)
        push!(arg_mechanism_files, fullpath)
    elseif occursin("preferences/", fullpath)
        push!(arg_preference_files, fullpath)
    else
        @warn "Ignoring argument ‘$(arg)’: it does not contain ‘mechanisms/’ or ‘preferences/’ in its path."
    end
end

if isempty(arg_mechanism_files)
    @info "No mechanism files specified. Using all .jl in $DEFAULT_MECHANISMS_DIR"
    arg_mechanism_files = expand_path(DEFAULT_MECHANISMS_DIR)
end

if isempty(arg_preference_files)
    @info "No preference files specified. Using all .jl in $DEFAULT_PREFERENCES_DIR"
    arg_preference_files = expand_path(DEFAULT_PREFERENCES_DIR)
end

mechanism_files = unique(vcat(map(expand_path, arg_mechanism_files)...))
preference_files = unique(vcat(map(expand_path, arg_preference_files)...))

isempty(mechanism_files) && throw("No mechanism files loaded.")
isempty(preference_files) && throw("No preference files loaded.")


# -----------------------------------------------------------------------------
#                             Logging Utilities
# -----------------------------------------------------------------------------

"""
Show a real-time progress line in the console, using a carriage return.
"""
function progress_update(
    mechanism_name::String,
    pref_name::String,
    round_num::Int,
    current_alloc::Vector{Float64},
    optimality::Float64,
    incentive_alignment::Float64
)
    @printf(
        "\r[Running] Pref=%s | Mech=%s | Round=%d | Alloc=%.2f,%.2f,... | Optim=%.1f | Align=%.1f",
        pref_name,
        mechanism_name,
        round_num,
        current_alloc[1],
        current_alloc[min(end, 2)],
        optimality * 100,
        incentive_alignment * 100
    )
    flush(stdout)
end

# -----------------------------------------------------------------------------
#                                 Main Program
# -----------------------------------------------------------------------------

final_table_texts = String[]
overall_results = Dict{String, Vector{NamedTuple}}()

# Create output directories
const OUTPUT_DIR = joinpath("output", "local")
mkpath(OUTPUT_DIR)

# Create output directories for each preference class
for pref_file in preference_files
    pref_parts = split(pref_file, "preferences/")
    if length(pref_parts) > 1
        path_parts = split(pref_parts[2], "/")
        pref_class = lowercase(path_parts[1])
        mkpath(joinpath(OUTPUT_DIR, "log", pref_class))
        mkpath(joinpath(OUTPUT_DIR, "plots", "preferences", pref_class))
    end
end

# Update the summary output file path
summary_output_file = joinpath(OUTPUT_DIR, "summary.txt")

for pref_file in preference_files
    pref_name = endswith(pref_file, ".jl") ?
        String(chop(pref_file, tail=3)) :
        pref_file
    
    # Extract relative path from "preferences" directory
    pref_parts = split(pref_name, "preferences/")
    pref_name = length(pref_parts) > 1 ? string(pref_parts[end]) : pref_name

    println("Loading preferences $pref_file")
    pref_profile = include(pref_file)
    Utility, optimal_points, overall_optimal_point = pref_profile

    (n, m) = size(optimal_points)
    plot_preference_profile(Utility, n, m, String(pref_name))

    println("optimalPoints = ")
    display(optimal_points)

    @show overall_optimal_point

    total_utility(alloc) = sum(Utility(i, alloc) for i in 1:n)
    max_utility = total_utility(overall_optimal_point)

    user_opt_utilities = [ Utility(i, optimal_points[i, :]) for i in 1:n ]


    rows_data = NamedTuple[]
    initial_reports = copy(optimal_points)

    for mech_file in mechanism_files
        mechanism_name = endswith(mech_file, ".jl") ?
            String(chop(basename(mech_file), tail=3)) :
            basename(mech_file)

        progress_update(mechanism_name, pref_name, 0, zeros(m), 0.0, 1.0)
        mechanism_func = include(mech_file)

        # Extract preference class from path
        path_parts = split(pref_name, "/")
        pref_class = lowercase(path_parts[1])
        pref_basename = path_parts[end]
        
        # Create log directory with preference class subdirectory
        out_dir = joinpath(OUTPUT_DIR, "log", mechanism_name, pref_class)
        if !isdir(out_dir)
            mkpath(out_dir)
        end
        out_file = joinpath(out_dir, pref_basename * ".txt")

        open(out_file, "w") do log_file
            final_reports, alloc_history, converged, incentive_alignment, envy, honest_alloc = simulate(
                mechanism_name,
                mechanism_func;
                Utility = Utility,
                initial_reports = initial_reports,
                optimal_points = optimal_points,
                overall_optimal_point = overall_optimal_point,
                logIO = log_file,
                pref_name = pref_name
            )

            final_alloc = alloc_history[end, :]
            num_rounds = Int(size(alloc_history, 1) ÷ n)
            mean_utility = total_utility(final_alloc) / n
            opt_percent = (total_utility(final_alloc) / max_utility) * 100
            honest_opt_percent = (total_utility(honest_alloc) / max_utility) * 100

            push!(rows_data, (
                mechanism_name = mechanism_name,
                num_rounds = num_rounds,
                converged = converged,
                final_reports = round.(final_reports, digits=3),
                final_alloc = round.(final_alloc, digits=3),
                mean_utility = round(mean_utility, digits=3),
                optimality_percent = round(opt_percent, digits=1),
                honest_optimality_percent = round(honest_opt_percent, digits=1),
                envy = round(envy, digits=3),
                incentive_alignment = round(incentive_alignment * 100, digits=1)
            ))

            if !haskey(overall_results, mechanism_name)
                overall_results[mechanism_name] = Vector{NamedTuple}()
            end
            push!(
                overall_results[mechanism_name],
                (
                    rounds=num_rounds, 
                    converged=converged,
                    mean_utility=mean_utility,
                    optimality=opt_percent,
                    honest_optimality=honest_opt_percent,
                    incentive_alignment=incentive_alignment,
                    envy=envy,
                    preference=pref_name
                )
            )
            println()  # end progress line
        end
    end


    # Print preference-level summaries
    preference_profile_summary!(
        final_table_texts,
        pref_name,
        optimal_points,
        user_opt_utilities,
        overall_optimal_point,
        max_utility
    )
    print_mechanism_outcomes!(
        final_table_texts,
        pref_name,
        rows_data
    )
end

open(summary_output_file, "w") do summary_output

    # Finally, print all preference-level summaries:
    for table_str in final_table_texts
        println(table_str)
        println(summary_output, table_str)
    end

    # Print overall summary:
    print_overall_summary!(stdout, overall_results)
    print_overall_summary!(summary_output, overall_results)
    println("\nDone.")

end