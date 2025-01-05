using LinearAlgebra

# -----------------------------------------------------------------------------
#                           Preference Creation
# -----------------------------------------------------------------------------

"""
    quadratic_preferences(pref_matrix::Matrix{Float64})

Create a preference profile from a preference matrix where utility functions are of the form:
`uᵢ(x) = ∑ⱼ (2*pref_matrix[i,j]x[j] - x[j]^2)`

Returns:
- normalized_utility::Function - Scaled utility function for each user
- optimal_points::Matrix{Float64} - Matrix of each user's optimal allocation
- overall_optimal_point::Vector{Float64} - Allocation maximizing total utility
"""
function quadratic_preferences(pref_matrix::Matrix{Float64})
    n, m = size(pref_matrix)
    utilities::Vector{Function} = [
        x -> sum((2*pref_matrix[i,j]*x[j] - x[j]^2) for j in 1:m)
        for i in 1:n
    ]

    optimal_points = vcat(
        [optimal_point_quadratic(pref_matrix[i,:])' for i in 1:n]...
    )

    total_utility(alloc) = sum(Utility(i, alloc) for i in 1:n)


    overall_optimal_point = overall_optimal_point_quadratic(pref_matrix)


    return make_preference_profile(
        utilities, 
        m; 
        optimal_points=optimal_points,
        overall_optimal_point=overall_optimal_point
    )
end

function optimal_point_quadratic(c)
    m = length(c)

    # The quadratic preference formula is Utility(x) = ∑ⱼ -xⱼ^2 + 2cⱼx. The max for each xⱼ is at xⱼ = cⱼ. If the optimal point for all xⱼ falls within the budget, return that.
    if sum(c) <= 1.0
           return c
    end

    # Otherwise, find the optimal point subject to constraint that ∑ⱼxⱼ = 1. The derivatives will all be equal at the maximum point.
    # So solve system of equations  { -2xⱼ + 2cⱼ = λ  for each i , ∑ⱼ xⱼ = 1 } and {xⱼ = 0 for i ∈ fixedAtZero}.
    function solve(fixedAtZero)
           # Create a matrix to representing the left-hand side of these equations
           A = hcat([
                       [
                           [j == i for j in 1:m]; (i in fixedAtZero) ? 0 : 1  # x_i + lambda or x_i
                       ]
                       for i in 1:m
                   ]...,
                   [[1 for j in 1:m]; 0]            # x₁ + x₂ ... xₙ
               )'

           # And a vector containing the right-hand side
           rhs = vcat([(i in fixedAtZero) ? 0 : c[i] for i in 1:m], 1)
           solution = A \ rhs
           solution[1:m]
    end

    fixedAtZero = []

    done = false
    result = zeros(m)
    while(true)
           result = solve(fixedAtZero)
           # index of smallest element in result that is less than 0
           if minimum(result)  >= 0
                   break
           end
           minimumIndex = argmin(result)
           push!(fixedAtZero, minimumIndex)
    end

    result
end

function overall_optimal_point_quadratic(pref_matrix::Matrix{Float64})
    n, m = size(pref_matrix)

    # c_j = sum of pref_matrix[i,j] over i
    c = [sum(pref_matrix[:, j]) for j in 1:m]

    # Unconstrained optimum => x_j = c_j / n
    x_unconstrained = c ./ n

    # Check if feasible: sum(x_j) ≤ 1 and all(x_j >= 0)
    if sum(x_unconstrained) <= 1.0 && all(x_unconstrained .>= 0)
        return x_unconstrained
    end

    # Otherwise, solve subject to ∑ x_j = 1 and x_j >= 0
    function solve_overall(fixedAtZero)
        # We want to solve { -2 n x_j + 2 c_j = λ  for j ∉ fixedAtZero
        #                    x_j = 0             for j ∈ fixedAtZero
        #                    ∑ x_j = 1 }.
        #
        # Re-arrange: -2 n x_j - λ = -2 c_j  =>  -2 n x_j = -2 c_j + λ
        # We do an analogous approach to "solve", but scaled by n.

        A = zeros(m+1, m+1)
        b = zeros(m+1)

        for j in 1:m
            if j in fixedAtZero
                # x_j = 0
                A[j,j] = 1
                b[j]   = 0
            else
                # -2 n x_j + 2 c_j = λ  =>  -2n x_j - λ = -2 c_j
                A[j,j]   = -2n   # coefficient for x_j
                A[j,m+1] = -1    # coefficient for λ
                b[j]     = -2c[j]
            end
        end

        # sum_j x_j = 1
        for j in 1:m
            A[m+1,j] = 1
        end
        b[m+1] = 1

        sol = A \ b
        return sol[1:m]
    end

    fixedAtZero = []
    while true
        x_candidate = solve_overall(fixedAtZero)
        if all(x_candidate .>= 0)
            return x_candidate
        end
        # Otherwise, fix the most negative coordinate at zero and re-solve
        idx = argmin(x_candidate)
        push!(fixedAtZero, idx)
    end
end
