using Plots

function plot_preference_profile(
    utility::Function,
    n::Int,
    m::Int,
    pref_name::String
)
    # Extract preference class from path
    path_parts = split(pref_name, "/")
    pref_class = lowercase(path_parts[1])
    
    # Create output directory with preference class subdirectory
    out_dir = joinpath("output", "plots", "preferences", pref_class)
    mkpath(out_dir)

    # Get just the preference name without the class directory
    plot_name = path_parts[end]

    # Determine a grid layout so it forms a roughly square shape
    rows = cols = ceil(Int, sqrt(n))

    if n == 2
        rows = 1
        cols = 2
    end


    # Create a single plot with that layout; place a combined legend to the right
    plot_obj = plot(
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
            util(x::Float64) = utility(i, [k == j ? x : 0.0 for k in 1:m])

            # We only want a legend entry for item j in the first row (or first subplot).
            # Otherwise, we set the label to "" so it doesn't repeat in the legend.
            the_label = (i == 1) ? "Item $j" : ""


            # Plot in subplot i, with color based on item j
            plot!(
                plot_obj,
                xs,
                util.(xs),
                subplot = i,
                color   = palette_colors[j],
                label   = the_label,
                ylim    = (-Inf, 1)  # allow negative utilities but cap at y=1
            )
        end

        # Add title and axes labels for user i
        plot!(plot_obj,
            title  = "User $i",
            xlabel = "x",
            ylabel = "Utility",
            subplot = i
        )
    end

    # Finally, save everything in one file
    savefig(plot_obj, joinpath(out_dir, plot_name * ".png"))
end
