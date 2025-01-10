using Statistics

# Take the mean of user reports, constrained to positive values summing to ≤ 1.0
return reports -> vec(mean(reports, dims=1))
