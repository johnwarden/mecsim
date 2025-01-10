using Statistics

# Piecewise Uniform Mechanism Described in
# https://arxiv.org/abs/2203.09971


function calculate_phantoms(k::Int, n::Int, t::Float64)
    # Calculate phantom value for index k at position t
    if t < 0.5
        if k/n < 0.5
            return 0.0
        else
            return 4*t*k/n - 2*t
        end
    else # t >= 0.5
        if k/n < 0.5
            return k*(2*t-1)/n
        else
            return k*(3-2*t)/n - 2 + 2*t
        end
    end
end

function find_optimal_t(reports::Matrix{Float64})
    n, m = size(reports)
    
    # Binary search to find t* that makes medians sum to 1
    left, right = 0.0, 1.0
    max_iter = 100
    tolerance = 1e-10
    
    for _ in 1:max_iter
        t = (left + right) / 2
        
        # Calculate phantom values for this t
        phantom_values = [calculate_phantoms(k, n, t) for k in 0:n]
        
        # Calculate medians for each project
        sum_medians = 0.0
        for j in 1:m
            project_values = vcat(reports[:,j], phantom_values)
            sum_medians += median(project_values)
        end
        
        # Update binary search bounds
        if abs(sum_medians - 1.0) < tolerance
            break
        elseif sum_medians < 1.0
            left = t
        else
            right = t
        end
    end
    
    return (left + right) / 2
end

function piecewise_uniform_mechanism(reports::Matrix{Float64})
    n, m = size(reports)

    # portion_of_budget = median(min.(sum(reports, dims=2), 1))

    norm_reports = reports ./ sum(reports, dims=2)

    
    # Find t* that makes medians sum to 1
    t_star = find_optimal_t(norm_reports)
    
    # Calculate final phantom values using t*
    phantom_values = [calculate_phantoms(k, n, t_star) for k in 0:n]
    
    # Calculate final allocation
    allocation = zeros(m)
    for j in 1:m
        project_values = vcat(norm_reports[:,j], phantom_values)
        allocation[j] = median(project_values)
    end
    
    return allocation
end

# Example usage:
# reports = [0.8 0.2 0.0; 0.4 0.3 0.3]  # 2 voters, 3 projects
# allocation = piecewise_uniform_mechanism(reports)