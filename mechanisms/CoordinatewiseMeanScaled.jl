using Statistics

return reports -> begin
    n, m = size(reports)

    total_spend = median(min.(sum(reports, dims=2), 1))

    mean(reports ./ sum(reports, dims=2), dims=1)[1,:] .* total_spend
end

