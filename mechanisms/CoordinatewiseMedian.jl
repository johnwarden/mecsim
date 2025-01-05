using Statistics

# Take the median of user reports, constrained to positive values summing to ≤ 1.0
return reports -> begin
    n, m = size(reports)

    
    return median(reports, dims=1)[1,:]

    sorted = sort(reports, dims=1)
    # A = if n%2 == 1
    #     sorted[Int((n-1)/2)+1,:]
    # else
    #    (sorted[Int(n/2),:] + sorted[Int(n/2)+1,:])/2
    # end
end
