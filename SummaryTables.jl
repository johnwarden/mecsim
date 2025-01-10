# -----------------------------------------------------------------------------
#                            PrettyTables Helpers
# -----------------------------------------------------------------------------

"""
Helper to build a PrettyTables-based text representation of `data` with `header`.
Returns the table as a string.
"""
function table_as_string(data, header; alignment = Symbol[])
    io_buf = IOBuffer()
    pretty_table(
        io_buf,
        data,
        header = header,
        alignment = alignment,
        backend = Val(:text)
    )
    return String(take!(io_buf))
end


# -----------------------------------------------------------------------------
#                             Summary Tables
# -----------------------------------------------------------------------------

using DataFrames
using Statistics
using Printf

function create_summary_dataframe(overall_results)
    # Create DataFrame from results
    df = DataFrame(
        mechanism = String[],
        preference = String[],
        preference_domain = String[],
        rounds = Int[],
        converged = Bool[],
        mean_utility = Float64[],
        optimality = Float64[],
        honest_optimality = Float64[],
        incentive_alignment = Float64[],
        envy = Float64[]
    )

    for (mech_name, results) in overall_results
        for result in results
            # Extract preference domain from path (first component of relative path)
            path_parts = split(result.preference, "/")
            pref_domain = length(path_parts) > 1 ? path_parts[1] : "Other"
            
            push!(df, (
                mech_name,
                result.preference,
                pref_domain,
                result.rounds,
                result.converged,
                result.mean_utility,
                result.optimality,
                result.honest_optimality,
                result.incentive_alignment,
                result.envy
            ))
        end
    end
    return df
end

function print_overall_summary!(output, overall_results)
    println(output,"\n", "="^80)
    println(output,"SUMMARY BY PREFERENCE DOMAIN")
    println(output,"="^80)

    df = create_summary_dataframe(overall_results)
    
    # Group by mechanism and preference domain
    gdf = groupby(df, [:mechanism, :preference_domain])
    
    # Create summary by mechanism and preference domain
    summary_df = combine(gdf,
        :rounds => mean => :mean_rounds,
        :converged => mean => :eq_percent,
        :optimality => mean => :mean_opt,
        :honest_optimality => mean => :mean_honest_opt,
        :envy => mean => :mean_envy,
        :incentive_alignment => mean => :mean_align
    )
    
    # Sort by mechanism and preference domain
    sort!(summary_df, [:mechanism, :preference_domain])
    
    # Print detailed table
    table_data = Matrix{Any}(undef, nrow(summary_df), 8)
    for (i, row) in enumerate(eachrow(summary_df))
        table_data[i,:] = [
            row.mechanism,
            row.preference_domain,
            round(row.mean_rounds, digits=1),
            round(row.eq_percent * 100, digits=1),
            round(row.mean_opt, digits=1),
            @sprintf("%+.1f", row.mean_opt - row.mean_honest_opt),
            round(row.mean_envy, digits=1),
            round(row.mean_align * 100, digits=1)
        ]
    end

    header = [
        "Mechanism",
        "Preference Domain",
        "Mean Rounds",
        "Equilibrium (%)",
        "Mean Optimality (%)",
        "vs. Honest",
        "Mean Envy (%)",
        "Mean Alignment (%)"
    ]

    table_text = table_as_string(
        table_data,
        header,
        alignment = [:l, :l, :r, :r, :r, :r, :r, :r]
    )
    print(output, table_text, "\n")

    # Print overall summary table
    println(output,"\n", "="^80)
    println(output,"OVERALL SUMMARY")
    println(output,"="^80)

    # Create overall summary by mechanism
    overall_df = combine(groupby(df, :mechanism),
        :rounds => mean => :mean_rounds,
        :converged => mean => :eq_percent,
        :optimality => mean => :mean_opt,
        :honest_optimality => mean => :mean_honest_opt,
        :envy => mean => :mean_envy,
        :incentive_alignment => mean => :mean_align
    )
    
    # Sort by mechanism name
    sort!(overall_df, :mechanism)
    
    # Format overall table
    overall_data = Matrix{Any}(undef, nrow(overall_df), 7)
    for (i, row) in enumerate(eachrow(overall_df))
        overall_data[i,:] = [
            row.mechanism,
            round(row.mean_rounds, digits=1),
            round(row.eq_percent * 100, digits=1),
            round(row.mean_opt, digits=1),
            @sprintf("%+.1f", row.mean_opt - row.mean_honest_opt),
            round(row.mean_envy, digits=1),
            round(row.mean_align * 100, digits=1)
        ]
    end

    overall_header = [
        "Mechanism",
        "Mean Rounds",
        "Equilibrium (%)",
        "Mean Optimality (%)",
        "vs. Honest",
        "Mean Envy (%)",
        "Mean Alignment (%)"
    ]

    overall_text = table_as_string(
        overall_data,
        overall_header,
        alignment = [:l, :r, :r, :r, :r, :r, :r]
    )
    print(output, overall_text, "\n")
end


"""
Print the preference profile summary table, including optimal points and honest reporting baseline.
"""
function preference_profile_summary!(
    final_table_texts::Vector{String},
    pref_name::String,
    user_opt_allocations::Matrix{Float64},
    user_opt_utilities::Vector{Float64},
    overall_opt_allocation::Vector{Float64},
    overall_max_utility::Float64
)
    # Extract just the relative path after "preferences/"
    display_name = split(pref_name, "preferences/")[end]
    
    push!(final_table_texts, "\n#####################################")
    push!(final_table_texts, "# Preference Profile: $display_name")
    push!(final_table_texts, "#####################################")
    push!(final_table_texts, "\nPreference Profile Summary:")

    n = length(user_opt_utilities)

    # Build rows for user-optimal allocations
    optimal_table_data = []
    for i in 1:n
        push!(optimal_table_data, [
            i,
            round.(user_opt_allocations[i, :], digits=3),
            round(user_opt_utilities[i], digits=3)
        ])
    end
    
    # Add overall optimal row
    push!(optimal_table_data, [
        "OVERALL",
        round.(overall_opt_allocation, digits=3),
        round(overall_max_utility / n, digits=3)
    ])

    opt_header = ["User", "Optimal Allocation", "Optimal Utility"]
    r_opt = vcat([reshape(optimal_table_data[i], 1, :) for i in eachindex(optimal_table_data)]...)
    optimal_points_table_text = table_as_string(r_opt, opt_header, alignment = [:r, :c, :r])
    push!(final_table_texts, optimal_points_table_text)
end


"""
Print the mechanism outcomes table for a given preference profile.
"""
function print_mechanism_outcomes!(
    final_table_texts::Vector{String},
    pref_name::String,
    mech_data::Vector{NamedTuple}
    
)
    push!(final_table_texts, "\nMechanism Outcomes for $pref_name:")

    mech_header = [
        "Mechanism",
        "Rounds",
        "Eq",
        "Final Reports",
        "Final Allocation",
        "Opt%",
        "vs. Honest",
        "Envy%",
        "Align%"
    ]

    row_list = []
    for row in mech_data
        # Format reports and allocation strings
        reports_str = join([
            "[" * join([@sprintf("%.2f", x) for x in row.final_reports[i,:]], ",") * "]"
            for i in 1:size(row.final_reports,1)
        ], ";")
        alloc_str = join([@sprintf("%.2f", x) for x in row.final_alloc], ",")

        # Calculate width of other columns (fixed width components)
        fixed_width = sum([
            length(row.mechanism_name),      # Mechanism name
            5,                               # Rounds (usually 2-3 digits + padding)
            3,                               # Eq column (✓/× + padding)
            length(alloc_str) + 2,           # Final allocation + brackets
            6,                               # Opt% (xx.x + padding)
            6,                               # vs. Honest (+x.x + padding)
            5,                               # Envy% (x.x + padding)
            6,                               # Align% (xx.x + padding)
            16                               # Column separators and padding
        ])

        # If total width would be <= maximum, show full reports
        max_reports_width = 120 - fixed_width
        reports_display = if length(reports_str) <= max_reports_width
            reports_str
        else
            reports_str[1:max(15, max_reports_width-3)] * "..."
        end

        push!(row_list, [
            row.mechanism_name,
            row.num_rounds,
            row.converged ? "✓" : "×",
            reports_display,
            alloc_str,
            @sprintf("%.1f", row.optimality_percent),
            @sprintf("%+.1f", row.optimality_percent - row.honest_optimality_percent),
            @sprintf("%.1f", row.envy),
            @sprintf("%.1f", row.incentive_alignment)
        ])
    end

    r_mech = vcat([reshape(row_list[i], 1, :) for i in 1:length(row_list)]...)
    mechanism_outcomes_table_text = table_as_string(
        r_mech,
        mech_header,
        alignment = [:l, :r, :c, :l, :l, :r, :r, :r, :r]
    )
    push!(final_table_texts, mechanism_outcomes_table_text)
end

