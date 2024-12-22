using LinearAlgebra, Statistics

# Similar to pairwise percentage, but uses the medians of the users' tradeoff matrices.
# The tradeoff between i and j is the percentage of a fixed budget that a user prefers to
# allocate i if the remainder were to go to j. The assumption is that this ratio is the same
# no matter what the budget is (which is indeed the case given the preference profiles we are using).

return (reports::Matrix{Float64}) -> begin
    n, m = size(reports)

    reports = hcat([reports[i,:] / sum(reports[i,:]) for i in 1:n]...)'

    A = mean(reports, dims=1)[1,:]
    return A / sum(A)
end
