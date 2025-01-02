


# Utility functions of the form ∑ᵢ 1 - (xᵢ - cᵢ)^2. cᵢ is the point that maximizes the utility derived from the ith item 
function quadraticPreferences(prefMatrix)
    n, m = size(prefMatrix)

    utilities::Vector{Function} = [ x -> sum((2*prefMatrix[i,j]x[j] - x[j]^2) for j in 1:m ) for i in 1:n ]

    optimalPoints = vcat(
    	[optimalPointQuadraticProfile(prefMatrix[i,:])' for i in 1:n]...
    )

    optimalUtilities = [utilities[i](optimalPoints[i,:]) for i in 1:n]

    # overall utility for component after scaling each utility function by 1/optimalUtility
    # scalei(x^2 + 2cix) + scalej(x2 + 2cjx) = (scalei+scalej)x^2 + 2*scalei*cix + 2scalej*cjx) = (scalei+scalej)x^2 + 2(scalei*cix + scalej*cjx)x
	# (scalei+scalej)x^2 + 2(scalei*cix + scalej*cjx)x

	scale = 1 ./ optimalUtilities

	aggregatePrefMatrix = [ dot(scale, prefMatrix[:,j]) / sum(scale) for j in 1:m]

	overallOptimalPoint = optimalPointQuadraticProfile(aggregatePrefMatrix)

    # return makePreferenceProfile(utilities, m)
    return makePreferenceProfile(utilities, m; optimalPoints = optimalPoints, overallOptimalPoint=overallOptimalPoint)
end

function optimalPointQuadraticProfile(c)
	m = length(c)

	# The quadratic preference formula is Utility(x) = ∑ⱼ -xⱼ^2 + 2cⱼx. The max for each xⱼ is at xⱼ = cⱼ. If the optimal point for all xⱼ falls within the budget, return that.
	if sum(c) <= 1.0
		return c
	end

	# Otherwise, find the optimal point subject to constraint that ∑ⱼxⱼ = 1. The derivatives will all be equal at the maximum point.
	# So solve system of equations  { -2xⱼ + 2cⱼ = λ  for each i , ∑ⱼ xⱼ = 1 } and {xⱼ = 0 for i ∈ fixedAtZero}. 
	function solve(fixedAtZero)
		# Create a matrix to representing the left-hand side of these equations
		A = hcat([
		            [
		                [j == i for j in 1:m]; (i in fixedAtZero) ? 0 : 1  # x_i + lambda or x_i
		            ]
		            for i in 1:m		       
		        ]..., 
		        [[1 for j in 1:m]; 0]            # x₁ + x₂ ... xₙ
		    )'

		# And a vector containing the right-hand side
		b = vcat([(i in fixedAtZero) ? 0 : c[i] for i in 1:m], 1)
		solution = A \ b
		solution[1:m]
	end

	fixedAtZero = []

	done = false
	result = zeros(m)
	while(true)
		result = solve(fixedAtZero)
		# index of smallest element in result that is less than 0
		if minimum(result)  >= 0
			break
		end
		minimumIndex = argmin(result)
		push!(fixedAtZero, minimumIndex)
	end

	result
end

