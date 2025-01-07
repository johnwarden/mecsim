using LinearAlgebra

# -----------------------------------------------------------------------------
#                    Single-user quasilinear sqrt optimum
# -----------------------------------------------------------------------------

"""
    optimal_point_quasilinear_sqrt(prefs::Vector{Float64})

Solves the single-user problem:

Maximize:  (1 - sum(x_j)) + sum_j [ prefs[j] * sqrt(x_j) ]
subject to: x_j ≥ 0,  sum_j x_j ≤ 1.

Returns a vector x that maximizes that objective.
Uses a simple two-case closed-form approach:
1) Check the "unconstrained interior" solution x_j = (prefs[j]^2 / 4).
2) If sum_j x_j ≤ 1, we are done. Otherwise, we scale so that sum_j x_j = 1.
"""
function optimal_point_quasilinear_sqrt(prefs::Vector{Float64})
    # Filter out any non-positive prefs for safety
    # (Though if prefs[j] <= 0, the user wouldn't want to allocate x_j>0 anyway.)
    # We'll just treat them as zero in the formula. But watch out for negative values.
    c = max.(prefs, 0.0)  # negative or zero => no incentive to spend on that coordinate

    sum_c2 = sum(c.^2)
    if iszero(sum_c2)
        # No positive prefs => best is to allocate x=0 entirely => utility = 1
        return zeros(length(c))
    end

    # 1) "Unconstrained interior" guess: x_j = c_j^2 / 4
    x_unscaled = c.^2 ./ 4
    total_x = sum(x_unscaled)

    if total_x <= 1.0
        # feasible interior
        return x_unscaled
    else
        # 2) must saturate the sum_x = 1 constraint
        #    => scale so that sum_j x_j = 1
        #    => x_j = c_j^2 / sum_k c_k^2
        return c.^2 ./ sum_c2
    end
end


# -----------------------------------------------------------------------------
#           Aggregator optimum for multiple quasilinear sqrt users
# -----------------------------------------------------------------------------

"""
    overall_optimal_point_quasilinear_sqrt(pref_matrix, optimal_utilities)

Given:
- `pref_matrix[i,j]` for user i's coefficient on sqrt(x_j),
- `optimal_utilities[i]` = user i's maximum utility (for normalization),

we form the aggregate objective:

  T(x) = ∑ᵢ [1/optimal_utilities[i]] * ( (1 - sum_j x_j) + ∑ⱼ pref_matrix[i,j]*√(x_j) )
       = A * (1 - sum_j x_j) + ∑ⱼ B_j * √(x_j)

where
  A = ∑ᵢ [1 / optimal_utilities[i]],
  B_j = ∑ᵢ [ (pref_matrix[i,j]) / (optimal_utilities[i]) ].

We again solve via the same two-case formula.
"""
function overall_optimal_point_quasilinear_sqrt(pref_matrix::Matrix{Float64},
                                                optimal_utilities::Vector{Float64})
    n, m = size(pref_matrix)

    # A = sum of 1/opt_utility
    inv_utils = 1.0 ./ optimal_utilities
    A = sum(inv_utils)

    # B_j = sum_i inv_utils[i] * pref_matrix[i,j]
    B = [sum(inv_utils .* pref_matrix[:,j]) for j in 1:m]

    # Solve:
    #   max_{x >= 0, sum x <= 1} A*(1 - sum_j x_j) + sum_j B_j sqrt(x_j).
    #
    # derivative wrt x_j => -A + B_j/(2 sqrt(x_j)) = 0 => sqrt(x_j) = B_j/(2A).
    # same two-case check.

    c = max.(B, 0.0)
    sum_c2 = sum(c.^2)

    # 1) x_j = (B_j^2) / (4 A^2) if sum_j x_j <= 1
    x_unscaled = c.^2 ./ (4A^2)
    total_x = sum(x_unscaled)

    if total_x <= 1.0
        return x_unscaled
    else
        # 2) saturate: x_j = c_j^2 / sum_k c_k^2
        return c.^2 ./ sum_c2
    end
end


# -----------------------------------------------------------------------------
#           Putting it all together: quasilinear_sqrt_preferences
# -----------------------------------------------------------------------------

"""
    quasilinear_sqrt_preferences(pref_matrix::Matrix{Float64})

Build a preference profile for `n` users each with `m` "items," where user i's 
utility is:

  uᵢ(x) = (1 - sum_j x_j) + ∑ⱼ pref_matrix[i,j] * √(x_j),

subject to x ≥ 0, sum_j x_j ≤ 1.

Returns an object with:
- `utilities`: a vector of n functions  `x -> uᵢ(x)`
- `optimal_points`: each user's single-user optimum (in an n×m Matrix),
- `overall_optimal_point`: the allocation that maximizes total (scaled) utility.
"""
function quasilinear_sqrt_preferences(pref_matrix::Matrix{Float64})
    n, m = size(pref_matrix)

    # 1) Build each user's utility function.
    #    We'll treat x as an m-vector, so u_i(x) = (1 - sum(x)) + sum_j c_i_j * sqrt(x_j).
    utilities::Vector{Function} = [
        (x -> (1.0 - sum(x)) + dot(pref_matrix[i,:], sqrt.(x))) 
        for i in 1:n
    ]

    # 2) Single-user optima
    #    For user i, solve max (1 - sum(x)) + sum_j c_ij * sqrt(x_j).
    #    We'll collect them in an n×m matrix.
    optimal_points = [
        optimal_point_quasilinear_sqrt(pref_matrix[i,:])'
        for i in 1:n
    ]
    optimal_points = vcat(optimal_points...)  # shape: n × m

    # 3) Each user's maximum utility
    optimal_utilities = [
        utilities[i](optimal_points[i,:])
        for i in 1:n
    ]

    # 4) "Overall" optimum:
    #    We want to maximize   sum_i [ u_i(x) / optimal_utilities[i] ]
    #      = sum_i [ (1 / opt_i) * (1 - sum_j x_j) ] + sum_i [ (1 / opt_i)* sum_j c_ij sqrt(x_j) ]
    #      => let A = sum_i 1/opt_i, B_j = sum_i [ (1/opt_i)*c_ij ] => same 2-case solution
    overall_optimal_point = overall_optimal_point_quasilinear_sqrt(pref_matrix, optimal_utilities)

    # 5) Return a profile object. For symmetry with your code, we assume there's a
    #    function `make_preference_profile(...)` that collects everything.
    return make_preference_profile(
        utilities,
        m;
        optimal_points = optimal_points,
        overall_optimal_point = overall_optimal_point
    )
end

