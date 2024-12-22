using LinearAlgebra, Statistics



"""
    eigenOfMedians(reports, prefMatrix)

Build a single tradeoff matrix by taking the medians across all users, then take
the real-valued eigenvector and normalize
"""

function eigenvectorOfMedians(reports::Matrix{Float64}, prefMatrix::Matrix{Float64})::Vector{Float64}
    n, m = size(reports)

    # Build a list of tradeoff matrices
    T = [buildTradeoffMatrix(reports[i, :]) for i in 1:n]

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

return eigenvectorOfMedians
