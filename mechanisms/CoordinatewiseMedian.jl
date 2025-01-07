using Statistics

# Simply take the median of user reports for each item
# Simulator will scale to 1.0 if sum is greater than 1.0
return reports -> begin
    return median(reports, dims=1)[1,:]
end
