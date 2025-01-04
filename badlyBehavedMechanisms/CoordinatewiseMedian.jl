using Statistics


# Builds a "median tradeoff" matrix from user reports, then iteratively
# adjusts the allocation in pairs. Finally returns the average allocation
# across iterations.

return (reports) -> begin
    n, m = size(reports)

    # Build a list of tradeoff matrices T[user].
    T = [tradeoff_matrix_from_report(reports[i, :]) for i in 1:n]
    # T = [relativeValueMatrixFromReport(reports[i, :]) for i in 1:n]

    # Build a matrix of median tradeoffs across users:
    median_tradeoffs = [ 
        i == j ? 0.0 : median(T[u][i, j] for u in 1:n)
        for i in 1:m, j in 1:m 
    ]

    # Start A as the median of the raw reports (coordinatewise).
    A = [median(reports[:, i]) for i in 1:m]
    A ./= sum(A)

    # We'll keep a history of allocations across rounds.
    rounds = 10  # fixed here; could parameterize
    history = Vector{Vector{Float64}}()

    if m < 3        
        a1 = median_tradeoffs[1,2]
        return [a1, 1-a1]
    end


    # Now do a coordinate-wise ascent algorithm. For each pair of items, use the median
    # of ideal tradeoff between those two items.
    for _ in 1:rounds
        for j in 1:(m - 1)
            for k in (j + 1):m
                fixedSum = sum(A[l] for l in 1:m if l != j && l != k)
                remainder = 1.0 - fixedSum
                A[j] = median_tradeoffs[j, k] * remainder
                A[k] = remainder - A[j]
                push!(history, copy(A))
            end
        end
    end

    # Take the mean across the saved history as the final outcome.
    s = length(history)
    meanAlloc = [mean(history[i][j] for i in 1:s) for j in 1:m]
    return meanAlloc
end

