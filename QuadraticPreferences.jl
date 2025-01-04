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
        [optimal_point_quadratic_profile(pref_matrix[i,:])' for i in 1:n]...
    )

    return make_preference_profile(
        utilities, 
        m; 
        optimal_points=optimal_points
    )
end

"""
    optimal_point_quadratic_profile(prefs::Vector{Float64})

Calculate the optimal point for a quadratic preference profile.
"""
function optimal_point_quadratic_profile(prefs::Vector{Float64})
    return constrain_budget(prefs)
end 