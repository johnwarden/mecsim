using Statistics


# Using the quadratic funding formula for this simulator doesn't make too much
# sense. Quadratic funding assumes a different setting, where users are
# actually making contributions and somebody is funding a deficit. It is not
# a social choice function. But still curious how the formula performs
return (reports) -> begin n, m = size(reports)

    # Fᵖ = (∑ⱼ √cⱼᵖ)²
    A = [sum(sqrt.(reports[:,j]))^2 for j in 1:m]

    return constrainBudget(A)
end
