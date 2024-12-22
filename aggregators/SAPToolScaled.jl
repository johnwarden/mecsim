using Statistics

SAPTool = include("SAPTool.jl")

function SAPToolScaled(reports::Matrix{Float64}, prefMatrix::Matrix{Float64})::Vector{Float64}
    A = SAPTool(reports, prefMatrix; scaled=true)
    A/sum(A)
end
