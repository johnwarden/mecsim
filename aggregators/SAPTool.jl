using Statistics

function SAPTool(reports::Matrix{Float64}, prefMatrix::Matrix{Float64}; scale::Bool=false)::Vector{Float64}
    # sort each column ascending
    sorted_votes = hcat([sort(reports[:, j]) for j in 1:m]...)

    # find the selection point: the last row with a sum less than the budget of 1.0
    row_sums = sum.(eachrow(sorted_votes))
    sp = findlast(≤(1.0), row_sums)

    # if no row qualifies, return zeros, or the  *first* row scaled down
    if sp == 0
        return scale ? sorted_votes[1, :] / sorted_votes[1, :] : zeros(m)
    end

    selection = sorted_votes[sp, :]
    return scale ? selection/sum(selection) : selection
end
