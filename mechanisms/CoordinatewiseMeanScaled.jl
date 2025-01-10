using Statistics

return reports -> begin
    n, m = size(reports)

    portion_of_budget = median(min.(sum(reports, dims=2), 1))

    mean(reports ./ sum(reports, dims=2), dims=1)[1,:] .* portion_of_budget
end

