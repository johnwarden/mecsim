


function l1_preferences(pref_matrix::Matrix{Float64})
    n, m = size(pref_matrix)

    utilities::Vector{Function} = [x -> 1 - l1_norm(x, pref_matrix[i,:]) for i in 1:n]

    optimal_points = pref_matrix
    overall_optimal_point = vec(median(optimal_points, dims=1))

    return make_preference_profile(
        utilities, 
        m; 
        optimal_points=optimal_points, 
        overall_optimal_point=overall_optimal_point
    )
end