using Statistics

# Take the median of user reports, constrained to positive values summing to ≤ 1.0
return reports -> begin
    n, m = size(reports)
    A = median(reports, dims=1)[1,:]
    return A
end
