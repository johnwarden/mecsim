using LinearAlgebra

# -----------------------------------------------------------------------------
#                         Single-user Quadratic Solver
# -----------------------------------------------------------------------------
"""
    optimal_point_quadratic(b::Vector{Float64}, c::Float64)

Given the utility function

  U(x) = ∑ᵢ (2*bᵢ*xᵢ - c*xᵢ²)

subject to xᵢ ≥ 0,  ∑ᵢ xᵢ = 1,

returns the allocation `x` (a vector) that maximizes U(x).
"""
function optimal_point_quadratic(b::Vector{Float64}, c::Float64)
    m = length(b)

    # Unconstrained maximum for each coordinate: x_j = b_j / c
    # Check whether the unconstrained solution is feasible (∑ x_j ≤ 1 and x_j >= 0).
    x_uncon = b ./ c
    if all(x_uncon .>= 0) && sum(x_uncon) <= 1.0
        return x_uncon
    end

    # Otherwise, solve the KKT system with the constraint ∑ x_j = 1, x_j ≥ 0.
    # The stationarity condition is: derivative wrt x_j = (2*b_j - 2*c*x_j) - λ = 0
    # => x_j = (b_j - λ/2)/c, plus the budget ∑ x_j = 1, and x_j ≥ 0.

    function solve_kkt(fixedAtZero::Set{Int})
        active = setdiff(1:m, fixedAtZero)
        mA = length(active)

        # sum_{j in active} x_j = 1 => sum_{j in active} (b_j - λ/2)/c = 1
        # => (1/c) [∑(b_j) - mA*(λ/2)] = 1
        # => ∑(b_j) - mA*λ/2 = c
        # => λ/2 = (∑(b_j) - c)/mA
        # => λ = 2*(∑(b_j) - c)/mA
        sumB = sum(b[j] for j in active)
        λ = 2 * (sumB - c) / mA
        λdiv2 = λ / 2

        # Build the candidate solution
        x_sol = zeros(m)
        for j in 1:m
            if j in fixedAtZero
                x_sol[j] = 0
            else
                x_sol[j] = (b[j] - λdiv2)/c
            end
        end
        return x_sol
    end

    fixedAtZero = Set{Int}()
    while true
        x_sol = solve_kkt(fixedAtZero)
        # If all coordinates are nonnegative, we have our solution.
        neg_inds = findall(x -> x < 0, x_sol)
        if isempty(neg_inds)
            return x_sol
        else
            # Fix those negative ones to zero and re-solve
            foreach(i -> push!(fixedAtZero, i), neg_inds)
        end
    end

    @show x_sol
    return x_sol
end


# -----------------------------------------------------------------------------
#                     Total Quadratic Utility (All Users)
# -----------------------------------------------------------------------------
"""
    overall_optimal_point_quadratic(pref_matrix::Matrix{Float64}, optimal_utilities::Vector{Float64})

Given:
- `pref_matrix[i,j]` for user i's linear coefficient on x_j in the unscaled utility,
- `optimal_utilities[i]` = user i's maximum utility (for normalization),

computes the aggregate objective

  T(x) = ∑ᵢ [1/optimal_utilities[i]] * ∑ⱼ (2*pref_matrix[i,j]*xⱼ - xⱼ²)

and returns the `x` that maximizes T(x) subject to xⱼ ≥ 0, ∑ⱼ xⱼ = 1.

Refactored to use `optimal_point_quadratic(b, c)` internally.
"""
function overall_optimal_point_quadratic(pref_matrix::Matrix{Float64},
                                          optimal_utilities::Vector{Float64})
    n, m = size(pref_matrix)

    # C[i] = 1 / (optimal utility of user i)
    C = 1.0 ./ optimal_utilities

    # We want to maximize ∑ⱼ (2*b_j*x_j - c*x_j²),
    # with b_j = ∑ᵢ C[i]*pref_matrix[i,j], and c = ∑ᵢ C[i].
    b = [sum(C .* pref_matrix[:, j]) for j in 1:m]
    c = sum(C)

    # Call our unified quadratic solver with these b, c
    return optimal_point_quadratic(b, c)
end


# -----------------------------------------------------------------------------
#            Example: Using the above in quadratic_preferences(...)
# -----------------------------------------------------------------------------
"""
    quadratic_preferences(pref_matrix::Matrix{Float64})

High-level function that:
1) Creates each user's single-user utility (and their "optimal" point),
2) Normalizes those utilities,
3) Finds the overall optimum by calling `overall_optimal_point_quadratic`.

Returns a dummy example of how you'd integrate all pieces in your code.
"""
function quadratic_preferences(pref_matrix::Matrix{Float64})
    n, m = size(pref_matrix)

    # Single-user utilities: uᵢ(x) = ∑ⱼ (2 * pref_matrix[i,j] * x[j] - x[j]^2).
    utilities::Vector{Function} = [
        x -> sum( (2*pref_matrix[i,j] * x[j] - x[j]^2 ) for j in 1:m )
        for i in 1:n
    ]

    # Single-user optimum for each user i, ignoring sum(x)=1? Or with sum(x)=1?
    # If you previously used your single-user code `optimal_point_quadratic(...)`,
    # we can just call it with b = pref_matrix[i,:], c=1.0, etc.
    optimal_points = [
        optimal_point_quadratic(pref_matrix[i,:], 1.0)'
        for i in 1:n
    ]
    optimal_points = vcat(optimal_points...)  # put them in one matrix

    # Each user's maximum utility
    optimal_utilities = [
        utilities[i](optimal_points[i,:]) for i in 1:n
    ]

    # The total utility function is sum( uᵢ(x) / optimal_utilities[i] ).
    # We find the point that maximizes it using overall_optimal_point_quadratic.
    overall_optimal_point = overall_optimal_point_quadratic(pref_matrix, optimal_utilities)

    # Return something that packages everything up

    @show optimal_point
    @show overall_optimal_point
    return make_preference_profile(
        utilities,
        m;
        optimal_points=optimal_points,
        overall_optimal_point=overall_optimal_point
    )
end
