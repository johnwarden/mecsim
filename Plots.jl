using Plots

"""
Plot the history of allocations in 3D space.
Only works for m=3 dimensional allocations.
"""
function plot_allocation_history(
    allocation_history::Matrix{Float64},
    n::Int,
    mechanism_name::String,
    pref_name::String
)
    m = size(allocation_history, 2)
    if m != 2 && m != 3
        return nothing  # Only plot for 2D or 3D allocations
    end

    n_rows = size(allocation_history, 1)
    
    if m == 2
        # 2D scatter plot
        plot_obj = plot(
            title = "$mechanism_name, $pref_name",
            xlabel = "A1", ylabel = "A2",
            xlim = (0, 1), ylim = (0, 1),
            aspect_ratio = :equal,
            legend = :outerright
        )

        for i in 1:n_rows
            user = mod(i-1, n) + 1
            plot!(
                plot_obj,
                [allocation_history[i, 1]],
                [allocation_history[i, 2]],
                seriestype = :scatter,
                label = (i == user) ? "User $user" : nothing,
                markersize = 4
            )
            
            # Draw lines connecting consecutive points for the same user
            if i > 1 && mod(i-1, n) == mod(i-2, n)
                plot!(
                    plot_obj,
                    [allocation_history[i-1, 1], allocation_history[i, 1]],
                    [allocation_history[i-1, 2], allocation_history[i, 2]],
                    linecolor = plot_obj[end][:markercolor],
                    label = nothing,
                    linestyle = :dash,
                    linewidth = 1
                )
            end
        end
    else  # m == 3
        plot_obj = plot(
            title = "$mechanism_name, $pref_name",
            xlabel = "A1", ylabel = "A2", zlabel = "A3",
            xlim = (0, 1), ylim = (0, 1), zlim = (0, 1),
            legend = :outerright
        )

        for i in 1:n_rows
            user = mod(i-1, n) + 1
            plot!(
                plot_obj,
                [allocation_history[i, 1]],
                [allocation_history[i, 2]],
                [allocation_history[i, 3]],
                seriestype = :scatter,
                label = (i == user) ? "User $user" : nothing,
                markersize = 4
            )
            
            # Draw lines connecting consecutive points for the same user
            if i > 1 && mod(i-1, n) == mod(i-2, n)
                plot!(
                    plot_obj,
                    [allocation_history[i-1:i, 1]],
                    [allocation_history[i-1:i, 2]],
                    [allocation_history[i-1:i, 3]],
                    linecolor = plot_obj[end][:markercolor],
                    label = nothing,
                    linestyle = :dash,
                    linewidth = 1
                )
            end
        end
    end

    # Create output directory by mechanism
    out_dir = joinpath("output/plots", mechanism_name)
    mkpath(out_dir)
    
    # Save the plot
    out_file = joinpath(out_dir, pref_name * ".png")
    savefig(plot_obj, out_file)
end

function plot_preference_profile(
    utility::Function,
    n::Int,
    m::Int,
    pref_name::String
)

    # Create output directory
    out_dir = "output/plots/preferences"
    mkpath(out_dir)

    # Determine a grid layout so it forms a roughly square shape
    rows = cols = ceil(Int, sqrt(n))

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
    savefig(plot_obj, joinpath(out_dir, pref_name * ".png"))
end
