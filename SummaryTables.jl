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

"""
Print summary tables for a single preference, appending them to `final_table_texts`.
Uses a named tuple for `preference_info`.
"""
function print_preference_summary!(
    final_table_texts::Vector{String},
    pref_name::String,
    preference_info::NamedTuple
)
    push!(final_table_texts, "\n#####################################")
    push!(final_table_texts, "# Preference Profile: $pref_name")
    push!(final_table_texts, "#####################################")
    push!(final_table_texts, "\nOptimal Points and Utilities:")


    opt_data = preference_info.optimal
    mech_data = preference_info.mechanisms

    user_opt_allocs = opt_data.user_opt_allocations
    user_opt_utils  = opt_data.user_opt_utilities
    n = length(user_opt_utils)

    # Build rows for user-optimal allocations
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
        round.(opt_data.overall_opt_allocation, digits=3),
        round(opt_data.overall_max_utility / n, digits=3)
    ])

    opt_header = ["User", "Optimal Allocation", "Optimal Utility"]
    r_opt = vcat([reshape(optimal_table_data[i], 1, :) for i in eachindex(optimal_table_data)]...)
    optimal_points_table_text = table_as_string(r_opt, opt_header, alignment = [:r, :c, :r])
    push!(final_table_texts, optimal_points_table_text)

    # Mechanism outcomes
    push!(final_table_texts, "\nMechanism Outcomes for $pref_name:")

    mech_header = [
        "Mechanism",
        "Rounds",
        "Eq",
        "Final Reports",
        "Alloc",
        "Opt%",
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
        fixed_width = length(row.mechanism_name) + 
                     length(string(row.num_rounds)) +
                     1 + # Eq column (✓ or ×)
                     length(alloc_str) +
                     4 + # Opt% (xx.x)
                     4 + # Envy (x.xx)
                     4 + # Align% (xx.x)
                     16  # Column separators and padding

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
            @sprintf("%.1f", row.envy),
            @sprintf("%.1f", row.incentive_alignment)
        ])
    end

    r_mech = vcat([reshape(row_list[i], 1, :) for i in 1:length(row_list)]...)
    mechanism_outcomes_table_text = table_as_string(
        r_mech,
        mech_header,
        alignment = [:l, :r, :c, :l, :l, :r, :r, :r]
    )
    push!(final_table_texts, mechanism_outcomes_table_text)
end


"""
Print the overall summary across all preferences at the end.
"""
function print_overall_summary!(
    output,
    overall_results::Dict{String, Vector{Tuple{Int,Bool,Float64,Float64,Float64,Float64}}}
)
    println(output,"\n", "="^80)
    println(output,"OVERALL SUMMARY ACROSS ALL PREFERENCES")
    println(output,"="^80)

    mechanism_summary_rows = []

    # Sort by mechanism name for consistent display
    for (mech_name, data) in sort!(collect(overall_results); by = x->x[1])
        rounds_vals = Int[]
        eq_vals     = Bool[]
        opt_vals    = Float64[]
        align_vals  = Float64[]
        envy_vals   = Float64[]

        for (rnd, eq, _, optpct, align, envy) in data  # Skip utility in destructuring
            push!(rounds_vals, rnd)
            push!(eq_vals, eq)
            push!(opt_vals, optpct)
            push!(align_vals, align)
            push!(envy_vals, envy)
        end

        push!(mechanism_summary_rows, [
            mech_name,
            round(mean(rounds_vals), digits=2),
            round(mean(eq_vals) * 100, digits=1),
            round(mean(opt_vals), digits=1),
            round(mean(envy_vals), digits=1),
            round(mean(align_vals) * 100, digits=1)
        ])
    end

    summary_header = [
        "Mechanism",
        "Mean Rounds",
        "Equilibrium (%)",
        "Mean Optimality (%)",
        "Mean Envy (%)",
        "Mean Alignment (%)"
    ]
    rsum = vcat([reshape(mechanism_summary_rows[i], 1, :) for i in eachindex(mechanism_summary_rows)]...)
    overall_summary_table_text = table_as_string(
        rsum,
        summary_header,
        alignment = [:l, :r, :r, :r, :r, :r]
    )
    print(output, overall_summary_table_text)
end

