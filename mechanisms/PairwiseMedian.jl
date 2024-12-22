using LinearAlgebra, Statistics

# Similar to pairwise percentage, but uses the medians of the users' tradeoff matrices.
# The tradeoff between i and j is the percentage of a fixed budget that a user prefers to
# allocate i if the remainder were to go to j. The assumption is that this ratio is the same
# no matter what the budget is (which is indeed the case given the preference profiles we are using).

return (reports::Matrix{Float64}) -> begin
    n, m = size(reports)

    # Build a list of tradeoff matrices
    T = [tradeoffMatrixFromReport(reports[i, :]) for i in 1:n]

    # medianTradeoffMatrix
    medianTradeoffs = [ 
        i == j ? 0.0 : median(T[u][i, j] for u in 1:n)
        for i in 1:m, j in 1:m 
    ]

    # Pick the last eigenvector, which seems to be real-valued
    E = eigen(medianTradeoffs)
    vec = real(E.vectors[:, m])
    return vec ./ sum(vec)
end
