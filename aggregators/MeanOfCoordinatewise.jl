using Statistics

"""
    buildTradeoffMatrix(report)

Utility function repeated for convenience or distinct import.
"""
function buildTradeoffMatrix(report::Vector{Float64})
    m = length(report)
    T = Matrix{Float64}(undef, m, m)
    for i in 1:m
        for j in 1:m
            if i == j
                T[i, j] = 0.0
            else
                T[i, j] = report[i] / (report[i] + report[j])
            end
        end
    end
    return T
end


"""
    meanOfCoordinatewise(reports, prefMatrix)

Builds a "median tradeoff" matrix from user reports, then iteratively
adjusts the allocation in pairs. Finally returns the average allocation
across iterations.

`prefMatrix` is unused here but included for a consistent function signature.
"""
function meanOfCoordinatewise(reports::Matrix{Float64}, prefMatrix::Matrix{Float64})
    n, m = size(reports)

    # Build a list of tradeoff matrices T[user].
    T = [buildTradeoffMatrix(reports[i, :]) for i in 1:n]

    # Build a matrix of median tradeoffs across users:
    medianTradeoffs = [ 
        i == j ? 0.0 : median(T[u][i, j] for u in 1:n)
        for i in 1:m, j in 1:m 
    ]


    # Start A as the median of the raw reports (coordinatewise).
    A = [median(reports[:, i]) for i in 1:m]
    A ./= sum(A)

    # We'll keep a history of allocations across rounds.
    rounds = 10  # fixed here; could parameterize
    history = Vector{Vector{Float64}}()

    for _ in 1:rounds
        for j in 1:(m - 1)
            for k in (j + 1):m
                fixedSum = sum(A[l] for l in 1:m if l != j && l != k)
                remainder = 1.0 - fixedSum
                A[j] = medianTradeoffs[j, k] * remainder
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

return meanOfCoordinatewise
