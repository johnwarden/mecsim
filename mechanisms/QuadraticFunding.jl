using Statistics

# Apply quadratic funding formula: Fᵖ = (∑ⱼ √cⱼᵖ)²
# Note: This is an experimental adaptation of QF for budget allocation
return reports -> begin
    n, m = size(reports)
    A = [sum(sqrt.(reports[:,j]))^2 for j in 1:m]
    return A
end
