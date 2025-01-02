using Optim, Plots

include("SqrtPreferences.jl")
include("QuadraticPreferences.jl")


function constrainBudget(x)
    sum(x) > 1.0 ? x/sum(x) : x
end

"""
    optimalPoint(utilityFunction::Function, m::Int)

Find the maximum point of a utility function within bounds: each xᵢ value of
the input is between 1 and 0 and the total sums to 1.
"""
function optimalPoint(utilityFunction::Function, m::Int)

    objective = (x) -> (maximum(x) > 1.0 || minimum(x) < 0.0 || sum(x) > 1.0) ? 999999999.99 : -utilityFunction(x)

    x0 = fill(1/m, m)

    res1 = optimize(objective, x0, NelderMead())
    res = optimize(objective, res1.minimizer, BFGS(), autodiff = :forward)

    # res = optimize(objective, x0, LBFGS(), autodiff = :forward)

    res.minimizer
end

# We'll scale each user's utility so its optimum is 1.
function normalizedUtilityFunction(utilities::Vector{Function}, optimalPoints=nothing)
    n = length(utilities)
    optimalUtilities = [utilities[i](optimalPoints[i,:]) for i in 1:n]
    return (user::Int, allocation) -> utilities[user](allocation) ./ optimalUtilities[user]
end

"""
    makePreferenceProfile(utilities::Vector{Function}, m::Int)

Returns a preference profile given a vector of preference functions, plus the 
cardinality (number of xᵢ arguments).
"""
function makePreferenceProfile(utilities::Vector{Function}, m::Int; optimalPoints=nothing, overallOptimalPoint=nothing)
    n = length(utilities)
    # utilities::Vector{Function} = [ x -> utilities[i](x) for i in 1:n]
    if isnothing(optimalPoints)
        optimalPoints = vcat(
            [optimalPoint(utilities[i], m)' for i in 1:n]...
        )
    end

    normalizedUtility = normalizedUtilityFunction(utilities, optimalPoints)

    if isnothing(overallOptimalPoint)
        totalUtility = x -> sum(normalizedUtility(i, x) for i in 1:n)
        overallOptimalPoint = optimalPoint(totalUtility, m)
    end

    return normalizedUtility, optimalPoints, overallOptimalPoint
end

"""
    plotPreferenceProfile(Utility, n, m, prefName)

Plots the utility function for each user i=1..n, with lines for each item j=1..m.
- Each user i is a subplot.
- Item j uses the same color across subplots.
- Only one legend is shown, listing "Item 1, Item 2, ..." etc.
- Saved in 'plots/prefName/Utility.png'.
"""
function plotPreferenceProfile(Utility, n::Int, m::Int, prefName::String)
    # Ensure output directory exists
    outDir = "output/plots/preferences"
    if !isdir(outDir)
        mkpath(outDir)
    end
    outFile = joinpath(outDir, "$(prefName).png")

    # Determine a grid layout so it forms a roughly square shape
    rows = cols = ceil(Int, sqrt(n))

    # Create a single plot with that layout; place a combined legend to the right
    p = plot(
        layout=(rows, cols),
        legend=:outerright,
        title="Utility Profiles",
        size=(600*cols, 450*rows)
    )

    # Define a color palette with at least m distinct colors
    # (change :Dark2 to your preferred palette)
    palette_colors = palette(:Dark2, m)

    # Range of x values
    xs = 0:0.1:1

    # For each user i => subplot i
    for i in 1:n
        # For each item j, we plot a line in the same color across subplots
        for j in 1:m
            # Utility for user i, item j
            u(x) = Utility(i, [k == j ? x : 0 for k in 1:m])

            # We only want a legend entry for item j in the first row (or first subplot).
            # Otherwise, we set the label to "" so it doesn't repeat in the legend.
            the_label = (i == 1) ? "Item $j" : ""

            # Plot in subplot i, with color based on item j
            plot!(
                p,
                xs,
                u.(xs),
                subplot = i,
                color   = palette_colors[j],
                label   = the_label,
                ylim    = (-Inf, 1)  # allow negative utilities but cap at y=1
            )
        end

        # Add title and axes labels for user i
        plot!(p,
            title  = "User $i",
            xlabel = "x",
            ylabel = "Utility",
            subplot = i
        )
    end

    # Display interactively (optional)
    display(p)

    # Finally, save everything in one file
    savefig(p, outFile)
    println("Saved combined plot to $outFile")
end

