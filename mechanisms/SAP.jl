using Statistics

# Select at Percentile mechanism based on the SAPTool by Steve Vitka:
# https://docs.google.com/spreadsheets/d/1y8q7zSCY75UFN-2J_b8ODvUYlfM3AjhyrP19xZjgGow/edit?gid=0#gid=0
#
# Sort each column, select the highest row where the sum is less than the
# budget. Total will not necessarily add up to budget. For monotonically
# increasing preferences or preferences where the peak is greater than the
# budget, this results in pareto-inefficient allocations. The SAPScaled
# mechanism is the same but scales the results so they sum to the budget.
function SAP(reports)
     n, m = size(reports)

    # sort each column ascending
    sorted_votes = hcat([sort(reports[:, j]; rev=false) for j in 1:m]...)

    # find the selection point: the last row with a sum less than the budget of 1.0
    row_sums = sum.(eachrow(sorted_votes))
    sp = findlast(≤(1.0), row_sums)

    # if no row qualifies, return zeros
    if isnothing(sp)
        return zeros(m)
    end

    return sorted_votes[sp, :]
end

return SAP


