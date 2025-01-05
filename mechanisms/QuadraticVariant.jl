using Statistics

quadratic = include("QuadraticFunding.jl")

return reports -> begin
    n, m = size(reports)

    # Assuming sqrt preferences, the un-scaled quadratic funding formula has a
    # equilibrium where user reports the square of the coefficients of their
    # preference function
    b = sqrt_preference_matrix_from_reports(reports)

    return quadratic(b .^ 2)
end
