using Plots

"""
Plot the history of allocations 
Only works for m=2 or m=3 dimensional allocations.
"""

function plot_allocation_history(
    allocation_history::Matrix{Float64},
    n::Int,
    mechanism_name::String,
    pref_name::String,
    initial_allocation::Vector{Float64}
)
    m = size(allocation_history, 2)
    if m != 2 && m != 3
        return nothing  # Only plot for 2D or 3D allocations
    end

    n_rows = size(allocation_history, 1)
    n_rounds = ceil(Int, n_rows/n) - 1
    
    # Exclude the last round's points by adjusting n_rows
    n_rows = n_rows - n
    
    # Define different markers for each user
    markers = [:circle, :square, :diamond, :utriangle, :dtriangle, :cross]
    user_markers = markers[1:min(n, length(markers))]
    
    # Create color gradient
    # Handle edge case where there's only one round
    colors = if n_rounds == 1
        [colorant"purple"]
    else
        range(colorant"purple", colorant"orange", length=n_rounds)  # One less round
    end
    
    # Add initial allocation color at the start
    colors = vcat([colorant"blue"], colors)
    
    # Create base plot with two legends
    if m == 2
        plot_obj = plot(
            title = "$mechanism_name, $pref_name",
            xlabel = "A1", ylabel = "A2",
            xlim = (0, 1), ylim = (0, 1),
            aspect_ratio = :equal,
            right_margin = 20Plots.mm
        )
    else
        plot_obj = plot(
            title = "$mechanism_name, $pref_name",
            xlabel = "A1", ylabel = "A2", zlabel = "A3",
            xlim = (0, 1), ylim = (0, 1), zlim = (0, 1),
            right_margin = 20Plots.mm
        )
    end

    # Create a subplot layout with the main plot and two legend boxes
    l = @layout [grid(1,1) a{0.2w}]
    
    # Create legend plot for users (no title)
    user_legend = plot(
        showaxis = false,
        grid = false,
        legend = :top
    )
    
    # Add user markers to user legend
    for u in 1:n
        plot!(
            user_legend,
            [NaN], [NaN],
            seriestype = :scatter,
            marker = user_markers[u],
            color = :black,
            markerstrokecolor = :black,
            markercolor = :white,
            label = "User $u",
            markersize = 4,
            markerstrokewidth = 1
        )
    end

    # Add initial allocation marker to user legend
    plot!(
        user_legend,
        [NaN], [NaN],
        seriestype = :scatter,
        marker = :star5,
        color = :black,
        markerstrokecolor = :black,
        markercolor = :white,
        label = "Initial",
        markersize = 6,
        markerstrokewidth = 1
    )
    
    # Create legend plot for rounds (no title)
    round_legend = plot(
        showaxis = false,
        grid = false,
        legend = :bottom
    )
    
    # Add initial allocation to round legend
    plot!(
        round_legend,
        [NaN], [NaN],
        seriestype = :path,
        color = colors[1],
        label = "Initial",
        linewidth = 3
    )

    # Add round colors to round legend
    for r in 1:n_rounds
        plot!(
            round_legend,
            [NaN], [NaN],
            seriestype = :path,
            color = colors[r+1],
            label = "Round $r",
            linewidth = 3
        )
    end

    # Plot initial allocation
    if m == 2
        plot!(
            plot_obj,
            [initial_allocation[1]],
            [initial_allocation[2]],
            seriestype = :scatter,
            marker = :star5,
            markerstrokecolor = colors[1],
            markercolor = :white,
            label = nothing,
            markersize = 6,
            markerstrokewidth = 1
        )
    else
        plot!(
            plot_obj,
            [initial_allocation[1]],
            [initial_allocation[2]],
            [initial_allocation[3]],
            seriestype = :scatter,
            marker = :star5,
            markerstrokecolor = colors[1],
            markercolor = :white,
            label = nothing,
            markersize = 6,
            markerstrokewidth = 1
        )
    end

    # Plot actual data points
    for i in 1:n_rows
        user = mod(i-1, n) + 1
        round_num = ceil(Int, i/n)
        
        if m == 2
            plot!(
                plot_obj,
                [allocation_history[i, 1]],
                [allocation_history[i, 2]],
                seriestype = :scatter,
                marker = user_markers[user],
                markerstrokecolor = colors[round_num + 1],
                markercolor = :white,
                label = nothing,
                markersize = 4,
                markerstrokewidth = 1
            )
            
            # Draw lines connecting consecutive points
            if i > 1 && mod(i-1, n) == mod(i-2, n)
                plot!(
                    plot_obj,
                    [allocation_history[i-1, 1], allocation_history[i, 1]],
                    [allocation_history[i-1, 2], allocation_history[i, 2]],
                    color = colors[round_num + 1],
                    label = nothing,
                    linestyle = :dash,
                    linewidth = 1
                )
            end
        else
            # 3D case
            plot!(
                plot_obj,
                [allocation_history[i, 1]],
                [allocation_history[i, 2]],
                [allocation_history[i, 3]],
                seriestype = :scatter,
                marker = user_markers[user],
                markerstrokecolor = colors[round_num + 1],
                markercolor = :white,
                label = nothing,
                markersize = 4,
                markerstrokewidth = 1
            )
            
            if i > 1 && mod(i-1, n) == mod(i-2, n)
                plot!(
                    plot_obj,
                    [allocation_history[i-1:i, 1]],
                    [allocation_history[i-1:i, 2]],
                    [allocation_history[i-1:i, 3]],
                    color = colors[round_num + 1],
                    label = nothing,
                    linestyle = :dash,
                    linewidth = 1
                )
            end
        end
    end

    # Combine main plot with legends
    legends = plot(
        user_legend,
        round_legend,
        layout = grid(2,1, heights=[0.5,0.5]),
        size = (200, 400)
    )
    
    # Create final combined plot
    final_plot = plot(plot_obj, legends, layout=l, size=(800,600))

    # Create output directory and save
    out_dir = joinpath("output/plots", mechanism_name)
    mkpath(out_dir)
    out_file = joinpath(out_dir, pref_name * ".png")
    savefig(final_plot, out_file)
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
