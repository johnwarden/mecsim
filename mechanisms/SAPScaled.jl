using Statistics

SAPTool = include("SAP.jl")

# same as SAP tool but results are scaled so total equals budget
return (reports) -> begin
    A = SAPTool(reports)
    return sum(A) > 0 ? A/sum(A) : A
end
