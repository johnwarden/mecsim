# -----------------------------------------------------------------------------
#                                 Simulation
# -----------------------------------------------------------------------------

"""
Returns a copy of `reports` with row `user` replaced by `report`.
"""
function update_response(
    reports::Matrix{Float64},
    user::Int,
    report::Vector{Float64}
)
    n, m = size(reports)
    [
        (i == user) ? report[j] : reports[i, j]
        for i in 1:n, j in 1:m
    ]
end


"""
Given a mechanism, the current matrix of reports, and a user index,
return that user's best response (as a vector) by local optimization.
"""
function find_best_response(
    mechanism_func::Function,
    reports::Matrix{Float64},
    user::Int;
    Utility::Function
)
    m = size(reports, 2)
    x0 = reports[user, :]
    lower_bounds = fill(0.0, m)
    upper_bounds = fill(1.0, m)

    function objective(x)
        new_reports = update_response(reports, user, x)
        new_alloc = mechanism_func(new_reports)
        # Negative for maximization:
        return -Utility(user, new_alloc)
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
- `Utility`: user utility function (user i, allocation).
- `initial_reports`: starting user reports matrix.
- `optimal_points`: matrix of each user's "honest" optimum.
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
    # (You appear to use `constrain_budget` from Preferences.jl or something similar.)
    constrained_mechanism_func = x -> constrain_budget(mechanism_func(x))

    alloc = constrained_mechanism_func(current_reports)
    incentive_alignment = 1.0

    initial_allocation = alloc
    alloc_history = Vector{Vector{Float64}}()
    converged = false

    total_utility(alloc) = sum(Utility(i, alloc) for i in 1:n)

    logln(logIO, "Optional points: $optimal_points")
    logln(logIO, "Starting allocation: $alloc")

    for round_idx in 1:max_rounds
        logln(logIO, "\n=== Round $round_idx ===")
        logln(logIO, "Current report matrix:")
        show(IOContext(logIO), "text/plain", current_reports)
        logln(logIO, "")

        round_converged = true

        for u in 1:n
            logln(logIO, "User $u's turn.")
            old_utility = Utility(u, alloc)

            best_resp = find_best_response(
                constrained_mechanism_func, current_reports, u;
                Utility = Utility
            )
            updated_reports = update_response(current_reports, u, best_resp)
            new_alloc = constrained_mechanism_func(updated_reports)
            new_utility = Utility(u, new_alloc)

            # Evaluate honest reporting:
            honest_reports = update_response(current_reports, u, optimal_points[u, :])
            honest_alloc = constrained_mechanism_func(honest_reports)
            honest_utility = Utility(u, honest_alloc)

            if (new_utility > old_utility) && (abs(new_utility - old_utility) > termination_threshold)
                if honest_utility > new_utility
                    @warn "This shouldn't happen: honest_utility=$honest_utility, new_utility=$new_utility"
                    logln(logIO, "  => Reverting user $u to honest report (better than old).")
                    current_reports = honest_reports
                    alloc = honest_alloc
                else
                    logln(logIO, "  Best response = $best_resp")
                    logln(logIO, "  => User $u improves by switching to best response")
                    current_reports = updated_reports
                    alloc = new_alloc
                end
                round_converged = false
                logln(logIO, "  => User $u's new report: $(current_reports[u, :])")
            else
                logln(logIO, "  => No improvement found; user $u stays with old report.")
            end

            # Naive measure of "incentive alignment":
            incentive_alignment = mean(
                1 - norm(current_reports[i, :] - optimal_points[i, :])
                for i in 1:n
            )

            logln(logIO, "  Old utility = $old_utility")
            logln(logIO, "  New utility = $new_utility")
            logln(logIO, "  Honest utility = $honest_utility")
            logln(logIO, "  Incentive Alignment = $incentive_alignment")
            logln(logIO, "  Allocation after user $u: $alloc")
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
            logln(logIO, "Converged! Maximum improvement in utility < $termination_threshold.")
            break
        end
    end

    final_reports = current_reports
    print(" ✅")

    logln(logIO, "Final reports:")
    show(IOContext(logIO), "text/plain", current_reports)
    logln(logIO, "")
    logln(logIO, "Final Allocation: $alloc")
    logln(logIO, "Overall Utility: $(total_utility(alloc))")

    # 3D Plot if dimension == 3
    ah = Matrix(transpose(hcat(alloc_history...)))

    # Calculate envy as percentage difference between max and min normalized utility
    final_utilities = [Utility(i, alloc) for i in 1:n]
    max_possible_utilities = [Utility(i, optimal_points[i,:]) for i in 1:n]
    normalized_utilities = final_utilities ./ max_possible_utilities
    envy = (maximum(normalized_utilities) - minimum(normalized_utilities)) * 100

    return (final_reports, ah, converged, incentive_alignment, envy)
end

# -----------------------------------------------------------------------------
#                         Mechanism Helper Functions
# -----------------------------------------------------------------------------

"""
Construct a matrix of pairwise tradeoff proportions from a user's report.
Each entry is the fraction of total "budget" for `i` out of `i + j`.
"""
function tradeoff_matrix_from_report(report::AbstractVector{T}) where {T<:Real}
    n = length(report)
    [ (report[i] + report[j] == 0) ? 0.5 : report[i] / (report[i] + report[j])
      for i in 1:n, j in 1:n ]
end

