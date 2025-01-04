using Statistics

SAPTool = include("SAP.jl")

# Modified SAP that scales results to sum exactly to budget when possible
return reports -> begin
    A = SAPTool(reports)
    return sum(A) > 0 ? A/sum(A) : A
end
