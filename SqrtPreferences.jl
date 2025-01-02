
"""
    sqrtPreferences(prefMatrix::Matrix{Float64})

Create a preference profile from a preference matrix `uᵢ(x) = ∑ⱼ prefMatrix[i,j] * √(xⱼ)`. 
"""
function sqrtPreferences(prefMatrix::Matrix{Float64})
    n, m = size(prefMatrix)
    utilities::Vector{Function} = [ x -> dot(prefMatrix[i, :], sqrt.(x)) for i in 1:n]

    optimalPoints = vcat(
        [optimalPointSqrtProfile(prefMatrix[i,:])' for i in 1:n]...
    )

    optimalUtilities = [utilities[i](optimalPoints[i,:]) for i in 1:n]

    scaledPrefMatrix = prefMatrix ./ optimalUtilities

    overallOptimalPoint = optimalPointSqrtProfile(sum(scaledPrefMatrix, dims=1)[1,:] / n)

    return makePreferenceProfile(utilities, m; optimalPoints = optimalPoints, overallOptimalPoint=overallOptimalPoint)

end

function sqrtPreferenceMatrixFromReports(reports)

    function coefficientsFromReport(r)
        r = r / sum(r)
        n = length(r)
        c = zeros(n)

        i = findfirst(r .> 0.0)
        c = [ sqrt(r[j] / r[i]) for j in 1:length(r) ]


        # Scale so that total utility at the ideal point is 10
        c / dot(c, sqrt.(optimalPointSqrtProfile(c)))
    end


    vcat([coefficientsFromReport(reports[i,:])' for i in 1:size(reports)[1]]...)
end

# For square root profiles of the form c₁√x₁ + c₂√x₂, the optimal point is given by the following formula (I found this using Lagrange multipliers)
function optimalPointSqrtProfile(prefs)
    # Local helper to compute the tradeoff between two items
    idealTradeoff(i, j) = let c1 = prefs[i], c2 = prefs[j]
        c1^2 / (c1^2 + c2^2)
    end

    # Find the first index with a positive preference
    i = findfirst(prefs .> 0)

    # Build the unnormalized vector x purely by comprehension
    x_unscaled = [
        j == i ? 1.0 : let t = idealTradeoff(i, j)
            (1 - t) / t
        end
        for j in 1:length(prefs)
    ]

    # Normalize so that sum(x) = 1
    s = sum(x_unscaled)
    return x_unscaled ./ s
end
