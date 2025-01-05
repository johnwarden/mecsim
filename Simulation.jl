# -----------------------------------------------------------------------------
#                                 Simulation
# -----------------------------------------------------------------------------

"""
Returns a copy of `reports` with row `voter` replaced by `report`.
"""
function update_response(
    reports::Matrix{Float64},
    voter::Int,
    report::Vector{Float64}
)
    n, m = size(reports)
    [
        (i == voter) ? report[j] : reports[i, j]
        for i in 1:n, j in 1:m
    ]
end


"""
Given a mechanism, the current matrix of reports, and a voter index,
return that voter's best response (as a vector) by local optimization.
"""
function find_best_response(
    mechanism_func::Function,
    reports::Matrix{Float64},
    i::Int;
    Utility::Function
)
    m = size(reports, 2)
    x0 = reports[i, :]
    lower_bounds = fill(0.0, m)
    upper_bounds = fill(1.0, m)

    function objective(x)
        new_reports = update_response(reports, i, x)
        new_alloc = mechanism_func(new_reports)
        # Negative for maximization:
        return -Utility(i, new_alloc)
    end

    function objective_with_boundary(x)
        if any(x .< 0.0) || any(x .> 1.0)
            return 9.9e9
        end
        return objective(x)
    end

    # 1) NelderMead:
    res = optimize(objective_with_boundary, x0, NelderMead())

    # 2) BFGS starting from NelderMead's result:
    res_bfgs = optimize(objective_with_boundary, res.minimizer, BFGS())
    return res_bfgs.minimizer
end


"""
Run a multi-round simulation for a given mechanism and preference setting.

- `mechanism_name`: name of the mechanism (for logging).
- `mechanism_func`: the mechanism function itself.
- `max_rounds`: maximum number of best-response cycles.
- `Utility`: voter utility function (voter i, allocation).
- `initial_reports`: starting voter reports matrix.
- `optimal_points`: matrix of each voter's "honest" optimum.
- `overall_optimal_point`: the overall system optimum allocation.
- `logIO`: an IO stream to log textual output to.
- `pref_name`: name of the preference setting (for logging).

Returns `(final_reports, allocation_history, converged, incentive_alignment)`.
"""
function simulate(
    mechanism_name::String,
    mechanism_func::Function;
    max_rounds::Int = 10,
    Utility::Function,
    initial_reports::Matrix{Float64},
    optimal_points::Matrix{Float64},
    overall_optimal_point::Vector{Float64},
    logIO::IO,
    pref_name::String
)

    Random.seed!(92834)
    termination_threshold = 1e-4
    n, m = size(initial_reports)

    current_reports = copy(initial_reports)

    # Constrain final allocation to remain in [0,1] and sum to 1 if that's required.
    # (You appear to use `cap` from Preferences.jl or something similar.)
    capped_mechanism_func = x -> cap(mechanism_func(x))

    alloc = capped_mechanism_func(current_reports)
    incentive_alignment = 1.0

    initial_allocation = alloc
    alloc_history = Vector{Vector{Float64}}()
    converged = false

    total_utility(alloc) = sum(Utility(i, alloc) for i in 1:n)

    println(logIO, "Optimal points: $optimal_points")
    println(logIO, "Starting allocation: $alloc")

    for round_idx in 1:max_rounds
        println(logIO, "\n=== Round $round_idx ===")
        println(logIO, "Current report matrix:")
        show(IOContext(logIO), "text/plain", current_reports)
        println(logIO, "")
        println(logIO, "Current allocation: $alloc")

        round_converged = true

        for u in 1:n
            println(logIO, "Voter $u's turn.")
            old_utility = Utility(u, alloc)

            # Evaluate honest reporting:
            honest_reports = update_response(current_reports, u, optimal_points[u, :])
            honest_alloc = capped_mechanism_func(honest_reports)
            honest_utility = Utility(u, honest_alloc)

            # Find best response, starting search at voters current report
            best_resp = find_best_response(
                capped_mechanism_func, current_reports, u;
                Utility = Utility
            )
            updated_reports = update_response(current_reports, u, best_resp)
            new_alloc = capped_mechanism_func(updated_reports)
            new_utility = Utility(u, new_alloc)


            # find the best response again starting with the voters's honest honest report
            begin
                best_resp2 = find_best_response(
                    capped_mechanism_func, honest_reports, u;
                    Utility = Utility
                )
                updated_reports2 = update_response(current_reports, u, best_resp)
                new_alloc2 = capped_mechanism_func(updated_reports)
                new_utility2 = Utility(u, new_alloc2)

                if new_utility2 > new_utility
                    updated_reports = udpated_reports2
                    new_alloc = new_ALLOC2
                    new_utility = new_utility2
                end
            end




            if (new_utility > old_utility) && (abs(new_utility - old_utility) > termination_threshold)
                println(logIO, "  Best response = $best_resp")
                println(logIO, "  New allocation: $new_alloc")
                println(logIO, "  => Voter $u improves by switching to best response")
                current_reports = updated_reports
                alloc = new_alloc
                round_converged = false
            else
                println(logIO, "  => No improvement found; voter $u stays with old report.")
            end

            # Naive measure of "incentive alignment":
            incentive_alignment = mean(
                1 - norm(current_reports[i, :] - optimal_points[i, :])
                for i in 1:n
            )

            println(logIO, "  Old utility = $old_utility")
            println(logIO, "  New utility = $new_utility")
            println(logIO, "  Honest utility = $honest_utility")
            println(logIO, "  Incentive Alignment = $incentive_alignment")
            push!(alloc_history, alloc)
        end

        progress_update(
            mechanism_name,
            pref_name,
            round_idx,
            alloc,
            total_utility(alloc)/total_utility(overall_optimal_point),
            incentive_alignment
        )

        if round_converged
            converged = true
            println(logIO, "Converged! Maximum improvement in utility < $termination_threshold.")
            break
        end
    end

    final_reports = current_reports
    print(" ✅")

    println(logIO, "Final reports:")
    show(IOContext(logIO), "text/plain", current_reports)
    println(logIO, "")
    println(logIO, "Final Allocation: $alloc")
    println(logIO, "Mean Utility: $(total_utility(alloc)/n)")

    # Calculate optimality (1.0 would be the maximum possible normalized utility)
    optimality = total_utility(alloc)/n  # Since utilities are already normalized

    # Calculate envy as difference between max and min utilities
    final_utilities = [Utility(i, alloc) for i in 1:n]
    envy = (maximum(final_utilities) - minimum(final_utilities))*100

    # Incentive alignment was already being tracked throughout the simulation
    # It's the mean Euclidean distance between honest and final reports

    println(logIO, "Optimality: $optimality")
    println(logIO, "Envy: $envy") 
    println(logIO, "Incentive Alignment: $incentive_alignment")

    # 3D Plot if dimension == 3
    ah = Matrix(transpose(hcat(alloc_history...)))

    return (final_reports, ah, converged, incentive_alignment, envy)
end

# -----------------------------------------------------------------------------
#                         Mechanism Helper Functions
# -----------------------------------------------------------------------------

"""
Construct a matrix of pairwise tradeoff proportions from a voter's report.
Each entry is the fraction of total "budget" for `i` out of `i + j`.
"""
function tradeoff_matrix_from_report(report::AbstractVector{T}) where {T<:Real}
    n = length(report)
    [ (report[i] + report[j] == 0) ? 0.5 : report[i] / (report[i] + report[j])
      for i in 1:n, j in 1:n ]
end

