using LinearAlgebra, Statistics

# Simply take the mean of users reports. Note that reports are constrained so that they are positive and the total is <= 1.0
return (reports) -> begin
    n, m = size(reports)

    reports = hcat([reports[i,:] / sum(reports[i,:]) for i in 1:n]...)'

    A = median(reports, dims=1)[1,:]
    return constrainBudget(A)
end
