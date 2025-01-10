# Mechanism described in "Truthful Aggregation of Budget Proposals" by Freeman et. al 
# https://arxiv.org/abs/1905.00457
function independent_markets_mechanism(reports::Matrix{Float64})
    n, m = size(reports)  # n voters, m alternatives
    
    # Normalize each voter's reports to sum to 1
    reports = reports ./ sum(reports, dims=2)
    
    # Binary search for the correct t* value that gives normalized output
    t_min, t_max = 0.0, 1.0
    max_iterations = 100
    tolerance = 1e-10
    
    function calculate_allocation(t::Float64)
        # For each k, phantom k is placed at min(t*(n-k), 1)
        phantom_values = [min(t*(n-k), 1.0) for k in 0:n]
        
        # Calculate allocation for each alternative using medians
        allocation = [median(vcat(reports[:,j], phantom_values)) for j in 1:m]
        
        return allocation
    end
    
    # Binary search for t* that gives normalized allocation
    t_star = nothing
    for _ in 1:max_iterations
        t = (t_min + t_max) / 2
        allocation = calculate_allocation(t)
        sum_allocation = sum(allocation)
        
        if abs(sum_allocation - 1.0) < tolerance
            t_star = t
            break
        elseif sum_allocation < 1.0
            t_min = t
        else
            t_max = t
        end
    end
    
    # If binary search didn't converge, use the midpoint
    if isnothing(t_star)
        t_star = (t_min + t_max) / 2
    end
    
    # Calculate final allocation
    final_allocation = calculate_allocation(t_star)
    
    return final_allocation
end