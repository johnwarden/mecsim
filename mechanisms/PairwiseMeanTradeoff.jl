using LinearAlgebra, Statistics

# Calculate allocation based on mean pairwise tradeoff preferences:
# 1. Convert each user's report to a tradeoff matrix
# 2. Take mean across users for each pairwise comparison
# 3. Return eigenvector of resulting matrix
return reports -> begin
    n, m = size(reports)
    T = [tradeoff_matrix_from_report(reports[i, :]) for i in 1:n]
    
    mean_tradeoffs = [
        i == j ? 0.0 : mean(T[u][i, j] for u in 1:n)
        for i in 1:m, j in 1:m
    ]
    
    vec = real(eigen(mean_tradeoffs).vectors[:, m])
    return minimum(vec) < 0 ? -vec : vec
end
