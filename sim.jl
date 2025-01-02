#!/usr/bin/env julia

using LinearAlgebra, Random, Optim, ForwardDiff, Statistics, Plots, PrettyTables, Printf

################################################################################
#                          Preference Utility Helpers                          #
################################################################################

include("Preferences.jl")

################################################################################
#                          Mechanism Helpers                                   #
################################################################################

function tradeoffMatrixFromReport(report)
    n = length(report)
    return[
        # Infer the relative preference between two items from a report.
        # The tradeoff is the percentage of a budget that the user prefers to allocate to item i
        # if those were the only two items.
        report[i] + report[j] == 0 ? 0.5 : report[i] / (report[i] + report[j])
        for i in 1:n, j in 1:n
    ]
end

################################################################################
#                               Parsing arguments                               #
################################################################################

function expand_path(path::String)
    if isdir(path)
        results = String[]
        for filename in readdir(path)
            expanded = expand_path(joinpath(path, filename))
            append!(results, expanded)
        end
        return results
    else
        endswith(path, ".jl") ? [path] : String[]
    end
end

const DEFAULT_MECHANISMS_DIR = abspath(joinpath(@__DIR__, "mechanisms"))
const DEFAULT_PREFERENCES_DIR = abspath(joinpath(@__DIR__, "preferences"))

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

if isempty(mechanism_files)
    throw("No mechanism files loaded.")
end
if isempty(preference_files)
    throw("No preference files loaded.")
end

################################################################################
#                            Progress + Logging                                #
################################################################################

function logln(io::IO, msg::AbstractString)
    println(io, msg)
end

function progressUpdate(
    mechanismName::String,
    prefName::String,
    roundNum::Int,
    currentAlloc::Vector{Float64},
    optimality::Float64,
    incentiveAlignment::Float64
)
    # Overwrite the same line using \r
    @printf("\r[Running] Pref=%s | Mech=%s | Round=%d | Alloc=%.2f,%.2f,... | Optimality=%.1f | Align=%.1f",
        prefName,
        mechanismName,
        roundNum,
        currentAlloc[1],
        currentAlloc[min(end, 2)],  # show at most 2 coords
        optimality*100,
        incentiveAlignment*100
    )
    flush(stdout)
end




################################################################################
#                                 Simulation                                   #
################################################################################

function updateResponse(reports, user, report)
    n, m = size(reports)
    return [
        i == user ? report[j] : reports[i, j]
        for i in 1:n, j in 1:m
    ]
end

function findBestResponse(
    mechanismFunc::Function,
    reports::Matrix{Float64},
    user::Int;
    Utility::Function
)
    m = size(reports, 2)

    x0 = copy(reports[user, :])
    lower = fill(0.0, m)
    upper = fill(1.0, m)


    function objective(x)
        newReports = updateResponse(reports, user, x)
        newAlloc = mechanismFunc(newReports)
        return -Utility(user, newAlloc)  # negative for maximization
    end

    function objectiveWithBoundary(x)
        if any(x .< 0.0) || any(x .> 1.0)
            return 9999.99
        end
        return objective(x)
    end

    function grad!(G, x)
        # Zero out G (just good practice).
        # fill!(G, 0.0)

        ForwardDiff.gradient!(G, objectiveWithBoundary, x)
        return G

        # ForwardDiff.gradient(simpleObjective, optimalPoints[1,:])
    end


    res = optimize(objectiveWithBoundary, x0, BFGS())

    # res = optimize(objectiveWithBoundary, grad!, x0, BFGS())
    return res.minimizer
end

function simulate(
    mechanismName::String,
    mechanismFunc::Function;
    maxRounds::Int=10,
    Utility::Function,
    initialReports::Matrix{Float64},
    optimalPoints::Matrix{Float64},
    overallOptimalPoint,
    logIO::IO,
    prefName::String
)
    Random.seed!(92834)
    terminationThreshold = .0001

    n, m = size(initialReports)

    reportsCurrent = copy(initialReports)

    constrainedMechanismFunc = x -> constrainBudget(mechanismFunc(x))

    alloc = constrainedMechanismFunc(reportsCurrent)
    incentiveAlignment = 1.0

    allocHistory = Vector{Vector{Float64}}()
    converged = false

    totalUtility = (alloc) -> sum(Utility(i, alloc) for i in 1:n)

    for roundIdx in 1:maxRounds
        logln(logIO, "\n=== Round $roundIdx ===")
        logln(logIO, "Current report matrix:")
        show(IOContext(logIO), "text/plain", reportsCurrent)
        logln(logIO, "")  # newline

        convergedInRound = true
        progressUpdate(mechanismName, prefName, roundIdx, alloc, totalUtility(alloc)/totalUtility(overallOptimalPoint), incentiveAlignment)
        reportsBeforeRound = reportsCurrent

        for u in 1:n
            logln(logIO, "User $u's turn. (Current allocation: $alloc)")
            oldUtility = Utility(u, alloc)

            bestResp   = findBestResponse(mechanismFunc, reportsCurrent, u; Utility=Utility)
            updated    = updateResponse(reportsCurrent, u, bestResp)
            newAlloc   = constrainedMechanismFunc(updated)
            newUtility = Utility(u, newAlloc)

            # Check honest
            honestRep   = optimalPoints[u, :]
            honestUpdt  = updateResponse(reportsCurrent, u, honestRep)
            honestAlloc = constrainedMechanismFunc(honestUpdt)
            honestUtility = Utility(u, honestAlloc)

            # Very naive measure of "incentive alignment":
            incentiveAlignment = mean(1 - norm(reportsCurrent[i, :] - optimalPoints[i, :]) for i in 1:n)

            logln(logIO, "  Old utility = $oldUtility")
            logln(logIO, "  New utility = $newUtility")
            logln(logIO, "  Honest utility = $honestUtility")
            logln(logIO, "  Incentive Alignment = $incentiveAlignment")

            if newUtility > oldUtility && abs(newUtility - oldUtility) > terminationThreshold
                logln(logIO, "  Best response = $bestResp")
                logln(logIO, "  => User $u improves by switching to best response")
                reportsCurrent = updated
                convergedInRound = false
                alloc = newAlloc
            else
                if honestUtility > oldUtility
                    logln(logIO, "  => Reverting user $u to honest report (better than old).")
                    reportsCurrent = honestUpdt
                    alloc = honestAlloc
                    convergedInRound = false
                    logln(logIO, "  => User $u's new report: $(reportsCurrent[u, :])")
                else
                    logln(logIO, "  => No improvement found; user $u stays with old report.")
                end
            end

            logln(logIO, "  Allocation after user $u: $alloc")
            push!(allocHistory, alloc)
        end

        if convergedInRound
            converged = true
            logln(logIO, "Converged! Maximum improvement in utility < $terminationThreshold.")
            break
        end
    end

    logln(logIO, "Final reports:")
    show(IOContext(logIO), "text/plain", reportsCurrent)
    logln(logIO, "") # newline

    ah = transpose(hcat(allocHistory...))

    if m == 3
        plot3d = plot()
        n_rows = size(ah, 1)

        for i in 1:n_rows
            user = mod(i-1, n) + 1
            plot!(
                plot3d,
                [ah[i, 1]],
                [ah[i, 2]],
                [ah[i, 3]],
                seriestype = :scatter,
                title = "$mechanismName, $prefName",
                xlabel = "A1", ylabel = "A2", zlabel = "A3",
                xlim = (0, 1), ylim = (0, 1), zlim = (0, 1),
                label = i == user ? "User $user" : nothing
            )
        end

        if !isdir("output/plots/sims")
            mkdir("output/plots/sims")
        end
        outDir = joinpath("output/plots/sims", prefName)
        if !isdir(outDir)
            mkpath(outDir)
        end
        outFile = joinpath(outDir, mechanismName * ".png")
        savefig(plot3d, outFile)
    end

    return (reportsCurrent, ah, converged, incentiveAlignment)
end

################################################################################
#                           Main Program                                       #
################################################################################

# Helper to build pretty-table strings without printing them immediately
function table_as_string(data, header; alignment=Symbol[])

    io_buf = IOBuffer()
    pretty_table(
        io_buf,
        data,
        header=header,
        alignment=alignment,
        backend=Val(:text)
    )
    # Convert IOBuffer to String
    return String(take!(io_buf))
end

preference_summaries = Dict{String, Dict{Symbol, Any}}()
overall_results = Dict{String, Vector{Tuple{Int,Bool,Float64,Float64,Float64}}}()

for prefFile in preference_files
    prefName = endswith(prefFile, ".jl") ?
        String(chop(basename(prefFile), tail=3)) :
        basename(prefFile)

    println("Loading preferences $prefFile")
    prefProfile = include(prefFile)
    Utility, optimalPoints, overallOptimalPoint = prefProfile


    (n, m) = size(optimalPoints)
    plotPreferenceProfile(Utility, n, m, prefName)


    println("optimalPoints = ")
    display(optimalPoints)

    @show overallOptimalPoint

    function totalUtility(allocation::Vector{Float64})
        sum(Utility(i, allocation) for i in 1:n)
    end

    maxUtility = totalUtility(overallOptimalPoint)

    user_opt_utilities = Float64[]
    for i in 1:n
        push!(user_opt_utilities, Utility(i, optimalPoints[i, :]))
    end

    rows_data = []
    initialReports = copy(optimalPoints)

    for mechFile in mechanism_files
        mechanismName = endswith(mechFile, ".jl") ?
            String(chop(basename(mechFile), tail=3)) :
            basename(mechFile)

        progressUpdate(mechanismName, prefName, 0, Vector{Float64}(zeros(m)), 0.0, 1.0)
        mechanismFunc = include(mechFile)

        outDir = joinpath("output/log", prefName)
        if !isdir(outDir)
            mkpath(outDir)
        end
        outFile = joinpath(outDir, mechanismName * ".txt")

        open(outFile, "w") do logFile
            reports, allocHistory, converged, incentiveAlignment = simulate(
                mechanismName,
                mechanismFunc;
                maxRounds=10,
                Utility=Utility,
                initialReports=initialReports,
                optimalPoints=optimalPoints,
                overallOptimalPoint=overallOptimalPoint,
                logIO=logFile,
                prefName=prefName
            )

            finalAlloc = allocHistory[end, :]
            numRounds  = Int(size(allocHistory, 1) ÷ n)
            meanUtility = totalUtility(finalAlloc) / n
            optPercent  = (totalUtility(finalAlloc) / maxUtility) * 100

            push!(rows_data, [
                mechanismName,
                numRounds,
                converged,
                round.(finalAlloc, digits=3),
                round(meanUtility, digits=3),
                round(optPercent, digits=1),
                round(incentiveAlignment*100, digits=1)
            ])

            # Also store in overall_results
            if !haskey(overall_results, mechanismName)
                overall_results[mechanismName] = Vector{Tuple{Int,Bool,Float64,Float64,Float64}}()
            end
            push!(
                overall_results[mechanismName],
                (numRounds, converged, meanUtility, optPercent, incentiveAlignment)
            )

            println()  # Let the progress line end
        end
    end

    preference_summaries[prefName] = Dict(
        :optimal => (
            user_opt_allocations = optimalPoints,
            user_opt_utilities   = user_opt_utilities,
            overall_opt_allocation = overallOptimalPoint,
            overall_max_utility    = maxUtility
        ),
        :mechanisms => rows_data
    )
end

################################################################################
#                    OUTPUT FOR EACH PREFERENCE PROFILE                        #
################################################################################

# We will collect the final “table text” in a vector or dictionary.
final_table_texts = String[]

for (prefName, infoDict) in preference_summaries
    # 1) Title for this preference
    push!(final_table_texts, "\nPreference: $prefName")

    # 2) Optimal Points and Utilities
    push!(final_table_texts, "\nOptimal Points and Utilities:")
    optData  = infoDict[:optimal]
    mechData = infoDict[:mechanisms]

    user_opt_allocs = optData.user_opt_allocations
    user_opt_utils  = optData.user_opt_utilities
    n = length(user_opt_utils)

    # Build the rows for optimal allocations
    optimal_table_data = []
    for i in 1:n
        push!(optimal_table_data, [
            i,
            round.(user_opt_allocs[i, :], digits=3),
            round(user_opt_utils[i], digits=3)
        ])
    end
    push!(optimal_table_data, [
        "ALL",
        round.(optData.overall_opt_allocation, digits=2),
        round(optData.overall_max_utility/n, digits=3)
    ])

    opt_header = ["User", "Optimal Allocation", "Optimal Utility"]
    # Turn them into a suitable matrix for pretty_table
    r_opt = vcat([reshape(optimal_table_data[i], 1, :) for i in eachindex(optimal_table_data)]...)

    # Generate text for the “optimal points” table
    optimal_points_table_text = table_as_string(
        r_opt,
        opt_header,
        alignment=[:r, :c, :r]
    )
    push!(final_table_texts, optimal_points_table_text)

    # 3) Mechanism outcomes
    push!(final_table_texts, "\nMechanism Outcomes:")

    mech_header = [
        "Mechanism",
        "Rounds",
        "Equilibrium",
        "Final Allocation",
        "Mean Utility",
        "Optimality (%)",
        "Incent. Align. (%)"
    ]
    r_mech = vcat([reshape(mechData[i], 1, :) for i in eachindex(mechData)]...)

    # Generate text for the “mechanism outcomes” table
    mechanism_outcomes_table_text = table_as_string(
        r_mech,
        mech_header,
        alignment=[:l, :r, :r, :c, :r, :r, :r]
    )
    push!(final_table_texts, mechanism_outcomes_table_text)
end

################################################################################
#               OVERALL SUMMARY (across all preferences)                       #
################################################################################

push!(final_table_texts, "\n" * "="^80)
push!(final_table_texts, "OVERALL SUMMARY ACROSS ALL PREFERENCES")
push!(final_table_texts, "="^80)

mechanism_summary_rows = []

for (mechName, data) in sort!(collect(overall_results); by=x->x[1])
    rounds_vals = Int[]
    eq_vals     = Bool[]
    util_vals   = Float64[]
    opt_vals    = Float64[]
    align_vals  = Float64[]

    for (rnd, eq, mu, optpct, align) in data
        push!(rounds_vals, rnd)
        push!(eq_vals, eq)
        push!(util_vals, mu)
        push!(opt_vals, optpct)
        push!(align_vals, align)
    end

    mean_rounds = mean(rounds_vals)
    frac_eq     = mean(eq_vals) * 100.0
    mean_util   = mean(util_vals)
    mean_opt    = mean(opt_vals)
    mean_align  = mean(align_vals)

    push!(mechanism_summary_rows, [
        mechName,
        round(mean_rounds, digits=2),
        round(frac_eq, digits=1),
        round(mean_util, digits=3),
        round(mean_opt, digits=1),
        round(mean_align*100, digits=1)
    ])
end

summary_header = [
    "Mechanism",
    "Mean Rounds",
    "Equilibrium (%)",
    "Mean Utility",
    "Mean Optimality (%)",
    "Mean Incent. Align. (%)"
]
rsum = vcat([reshape(mechanism_summary_rows[i], 1, :) for i in eachindex(mechanism_summary_rows)]...)

overall_summary_table_text = table_as_string(
    rsum,
    summary_header,
    alignment=[:l, :r, :r, :r, :r, :r]
)
push!(final_table_texts, overall_summary_table_text)

push!(final_table_texts, "\nDone.")

################################################################################
#           Finally, print out all the tables (in one place at the end).       #
################################################################################

for table_str in final_table_texts
    println(table_str)
end


