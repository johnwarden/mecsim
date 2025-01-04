using LinearAlgebra, Statistics

# Pairwise preferences somewhat similar to the method described in (https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3317445 and https://blog.zaratan.world/p/quadratic-v-pairwise)
# Convert each user's report into a matrix of binary pairwise preferences. 
# Then calculates an overall percentage for each pair.
# Final allocations proportional to eigenvector of the overall matrix.

function pairwise_matrix_from_reports(report)
    n = length(report)

    return [
        report[i] > report[j]
        for i in 1:n, j in 1:n
    ]
end

return (reports) -> begin
    n, m = size(reports)

    # Build a list of 1 matrix per user
    # The cells in the matrix are 1 if the user prefers item 1 or item j, otherwise 0
    T = [pairwise_matrix_from_reports(reports[i, :]) for i in 1:n]

    # For each pair, calculate the probability of a user preferring i over j, with laplace smoothing using Jeffrey's prior Beta(0.5,0.5)
    pairwise_percentages = [ 
        i == j ? 0.5 : (sum(T[u][i, j] for u in 1:n) + 0.5)/(n + 1)
        for i in 1:m, j in 1:m 
    ]

    # Pick the last eigenvector, which seems to be real-valued
    E = eigen(pairwise_percentages)
    vec = real(E.vectors[:, m])

    if minimum(vec) < 0
        vec = vec * -1 
    end

    return constrain_budget(vec)
end

