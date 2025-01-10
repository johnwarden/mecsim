using LinearAlgebra

# -----------------------------------------------------------------------------
#                           Preference Creation
# -----------------------------------------------------------------------------

"""
    sqrt_preferences(pref_matrix::Matrix{Float64})

Create a preference profile from a preference matrix where utility functions are of the form:
`uᵢ(x) = ∑ⱼ pref_matrix[i,j] * √(xⱼ)`

Returns:
- normalized_utility::Function - Scaled utility function for each user
- optimal_points::Matrix{Float64} - Matrix of each user's optimal allocation
- overall_optimal_point::Vector{Float64} - Allocation maximizing total utility
"""
function sqrt_preferences(pref_matrix::Matrix{Float64})
    n, m = size(pref_matrix)
    utilities::Vector{Function} = [x -> dot(pref_matrix[i, :], sqrt.(x)) for i in 1:n]

    optimal_points = vcat(
        [optimal_point_sqrt_profile(pref_matrix[i,:])' for i in 1:n]...
    )

    optimal_utilities = [utilities[i](optimal_points[i,:]) for i in 1:n]
    scaled_pref_matrix = pref_matrix ./ optimal_utilities
    overall_optimal_point = optimal_point_sqrt_profile(sum(scaled_pref_matrix, dims=1)[1,:] / n)

    return make_preference_profile(
        utilities, 
        m; 
        optimal_points=optimal_points, 
        overall_optimal_point=overall_optimal_point
    )
end

# -----------------------------------------------------------------------------
#                        Preference Matrix Generation
# -----------------------------------------------------------------------------

"""
    sqrt_preference_matrix_from_reports(reports::Matrix{Float64})

Generate a preference matrix from user reports by inferring coefficients that would
produce those reports as optimal points.

Returns a matrix where each row represents a user's preference coefficients.
"""
function sqrt_preference_matrix_from_reports(reports::Matrix{Float64})
    function coefficients_from_report(r::Vector{Float64})
        c = sqrt.(r) / sum(sqrt.(r))
        # Scale so total utility at ideal point is 1
        return c / dot(c, sqrt.(optimal_point_sqrt_profile(c)))
    end

    return vcat([coefficients_from_report(reports[i,:])' for i in 1:size(reports)[1]]...)
end

# -----------------------------------------------------------------------------
#                          Optimal Point Calculation
# -----------------------------------------------------------------------------

"""
    optimal_point_sqrt_profile(prefs::Vector{Float64})

Calculate the optimal point for a square root preference profile of the form:
∑ᵢ cᵢ√xᵢ subject to ∑ᵢ xᵢ = 1

Uses closed-form solution derived from Lagrange multipliers.
"""
function optimal_point_sqrt_profile(prefs::Vector{Float64})
    # Calculate tradeoff between two items using closed-form solution
    ideal_tradeoff(i, j) = let c1 = prefs[i], c2 = prefs[j]
        c1^2 / (c1^2 + c2^2)
    end

    # Find first non-zero preference as reference point
    i = findfirst(prefs .> 0)

    # Build unnormalized vector using tradeoffs
    x_unscaled = [
        j == i ? 1.0 : let t = ideal_tradeoff(i, j)
            (1 - t) / t
        end
        for j in 1:length(prefs)
    ]

    # Normalize to sum to 1
    return x_unscaled ./ sum(x_unscaled)
end 