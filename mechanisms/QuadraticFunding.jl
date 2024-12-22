using Statistics


# this doesn't really make sense. Quadratic funding assumes a different setting, where users are
# actually making contributions and somebody is funding a deficit. It is not a social choice function.
# But still curious how the formula performs
return (reports::Matrix{Float64}; scale::Bool=false) -> begin
    n, m = size(reports)

    # Fᵖ = (∑ⱼ √cⱼᵖ)²
    A = [sum(sqrt.(reports[:,j]))^2 for j in 1:m]

    return A / sum(A)
end
