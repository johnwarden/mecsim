using LinearAlgebra, Statistics

# Similar to pairwise probability, but uses the mean of the users' tradeoff matrices.
# The tradeoff between i and j is the percentage of a fixed budget that a user prefers to
# allocate i if the remainder were to go to j. The assumption is that this ratio is the same
# no matter what the budget is (which is indeed the case given the preference profiles we are using).


return (reports) -> begin
    n, m = size(reports)

    # Build a list of tradeoff matrices
    T = [tradeoffMatrixFromReport(reports[i, :]) for i in 1:n]

    # medianTradeoffMatrix
    meanTradeoffs::Matrix{Float64} = [ 
        i == j ? 0.0 : mean(T[u][i, j] for u in 1:n)
        for i in 1:m, j in 1:m 
    ]

    # Pick the last eigenvector, which seems to be real-valued
    E = eigen(meanTradeoffs)

    vec = real(E.vectors[:, m])

    if minimum(vec) < 0
        vec = vec * -1 
    end

    return vec
end
