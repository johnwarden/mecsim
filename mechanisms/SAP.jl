using Statistics

# SAP (based on the SAPTool by Steve Vitka: https://docs.google.com/spreadsheets/d/1y8q7zSCY75UFN-2J_b8ODvUYlfM3AjhyrP19xZjgGow/edit?gid=0#gid=0) 
# Uses a "Select at Percentage" mechanism. Sort each column, select the highest row where the sum is <= 1.
# Optionally, scale so sum equals 1.
return (reports::Matrix{Float64}) -> begin
    n, m = size(reports)

    # sort each column ascending
    sorted_votes = hcat([sort(reports[:, j]) for j in 1:m]...)

    # find the selection point: the last row with a sum less than the budget of 1.0
    row_sums = sum.(eachrow(sorted_votes))
    sp = findlast(≤(1.0), row_sums)

    # if no row qualifies, return zeros, or the *first* row scaled down
    if sp == 0
        return zeros(m)
    end

    return sorted_votes[sp, :]
end


