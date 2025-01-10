function uniform_phantom_mechanism(reports::Matrix{Float64})
    n, m = size(reports)
  
    # portion_of_budget = median(min.(sum(reports, dims=2), 1))
    reports = reports ./ sum(reports, dims=2)
 

    # Calculate uniform phantom values [0, 1/n, 2/n, ..., 1]
    phantom_values = [k/n for k in 0:n]
    
    # Calculate allocation for each project
    allocation = [median(vcat(reports[:,j], phantom_values)) for j in 1:m]
    
    return allocation
    # return allocation .* portion_of_budget
end