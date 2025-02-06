using Statistics

quadratic_funding = include("QuadraticFunding.jl")

return reports -> begin
    n, m = size(reports)

    total_spend = mean(min.(sum(reports, dims=2), 1))
    # total_spend = mean(sum(reports, dims=2))

    # With square root preference profiles of the form Vᵢ(y) = ∑ⱼ bᵢⱼ√yⱼ, and
    # an *uncapped* quadratic funding mechanism (where the sum can exceed the
    # budget) then there is an equilibrium where user i always maximizes utility by 
    # reporting the vector { bᵢⱼ² / 2 }, no matter what other voters report. 
    # 
    # However, this is not the case when we add a cap and scale down the final allocations
    # if the total exceeds the budget of 1.0.
    #  
    # But we can avoid this cap by scaling by a constant factor. It doesn't change the equilibrium
    # So we divide each user's reports by n before feeding into the quadratic funding formula, then divide
    # the results by n. The result is that the maximum will be 1.0. So most of the budget is "used up" but
    # we don't have any discontinuity so the equilibrium doesn't change.


    # X = sqrt_preference_matrix_from_reports(reports) .^ 2

    X = ( sqrt.(reports) ./ sum(sqrt.(reports), dims=2) ) .^ 2
    X = X ./ sum(X, dims=2)


    X = vcat([ X[i,:]' ./ n for i in 1:n ]...)

    r = quadratic_funding( X ) ./ n
    r = r  .* total_spend

    r
    # sum(r) > 1.0 ? zeros(m) : r

end
