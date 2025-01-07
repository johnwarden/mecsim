using Optim, Plots

include("QuasilinearSqrtPreferences.jl")
include("SqrtPreferences.jl")
include("QuadraticPreferences.jl")

# -----------------------------------------------------------------------------
#                              Budget Constraints
# -----------------------------------------------------------------------------

"""
    cap(x::Vector{Float64})

Normalize a vector so its sum is at most 1.0. If sum is already <= 1.0, return
the original vector.
"""
function cap(x::Vector{Float64})
    sum(x) > 1.0 ? x/sum(x) : x
end

# -----------------------------------------------------------------------------
#                            Preference Optimization
# -----------------------------------------------------------------------------

"""
    optimal_point(utility_function::Function, m::Int)

Find the maximum point of a utility function within bounds:
- Each xᵢ value must be between 0 and 1
- The sum of all xᵢ must be at most 1
"""
function optimal_point(utility_function::Function, m::Int)
    result = optimize(
        x -> -utility_function(x),
        zeros(m),
        ones(m),
        ones(m)/m,
        Fminbox(LBFGS()),
        Optim.Options(show_trace=false)
    )
    return cap(result.minimizer)
end

"""
    normalized_utility_function(utilities::Vector{Function}, optimal_points::Matrix{Float64})

Create a normalized utility function that returns 1.0 at a user's optimal point.
"""
function normalized_utility_function(utilities::Vector{Function}, optimal_points::Matrix{Float64})
    n = length(utilities)
    optimal_utilities = [utilities[i](optimal_points[i,:]) for i in 1:n]
    
    return (i::Int, x::Vector{Float64}) -> begin
        utilities[i](x) / optimal_utilities[i]
    end
end

"""
    make_preference_profile(utilities::Vector{Function}, m::Int; kwargs...)

Create a preference profile from a list of utility functions.

Returns:
- normalized_utility::Function - Scaled utility function for each user
- optimal_points::Matrix{Float64} - Matrix of each user's optimal allocation
- overall_optimal_point::Vector{Float64} - Allocation maximizing total utility

Optional kwargs:
- optimal_points: Pre-computed optimal points for each user
- overall_optimal_point: Pre-computed overall optimal allocation
"""
function make_preference_profile(
    utilities::Vector{Function}, 
    m::Int;
    optimal_points=nothing,
    overall_optimal_point=nothing
)
    n = length(utilities)

    # Compute optimal points if not provided
    if isnothing(optimal_points)
        optimal_points = vcat([optimal_point(utilities[i], m)' for i in 1:n]...)
    end

    normalized_utility = normalized_utility_function(utilities, optimal_points)

    # Compute overall optimal point if not provided
    if isnothing(overall_optimal_point)
        total_utility = x -> sum(normalized_utility(i, x) for i in 1:n)
        overall_optimal_point = optimal_point(total_utility, m)
    end

    return normalized_utility, optimal_points, overall_optimal_point
end
