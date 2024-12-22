using Statistics

SAPTool = include("SAP.jl")

return (reports::Matrix{Float64}) -> begin
    A = SAPTool(reports)
    A/sum(A)
end
