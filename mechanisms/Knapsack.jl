function knapsack_mechanism(reports::Matrix{Float64})
    n, m = size(reports)

    # Not scaling inputs seems to get better results. But scaling is described in the paper
    # https://dl.acm.org/doi/pdf/10.1145/3340230
    reports = reports ./ sum(reports, dims=2)

    # Initialize results vector
    results = zeros(m)
    
    # Process each alternative separately
    for j in 1:m
        # Sort reports for current alternative
        sorted_reports = sort(reports[:,j])
        
        # Initialize phantom values array
        phantom_values = zeros(n+1)
        
        # Calculate phantom values using knapsack approach
        for i in 1:n+1
            if i == 1
                phantom_values[i] = 0.0
            else
                # Calculate the maximum possible value that maintains strategy-proofness
                max_value = min(1.0, 2 * sorted_reports[i-1] - phantom_values[i-1])
                phantom_values[i] = max_value
            end
        end
        
        # Result is the median of combined real and phantom values
        results[j] = median(vcat(reports[:,j], phantom_values))
    end
    
    return results

end