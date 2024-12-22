using Random
using Statistics
using Plots

allocations = zeros(rounds,3)

for t in 1:rounds

    # Compute final allocation after updates
    (A, SV, S) = allocation(V, B)
    allocations[t,:] = A
end

# Now we plot the allocations over time in a 3D chart
# We'll plot t on one axis, and A1, A2, A3 on the other two.
t_vals = 1:rounds
x = allocations[:,1]
y = allocations[:,2]
z = allocations[:,3]

avg_allocations = vec(mean(allocations, dims=1))
 
println("Average allocation over $rounds steps: ", avg_allocations)

# Plot points before index 100
plot3d = plot(x, y, z, seriestype=:scatter, 
    title="Allocation Trajectory",
    xlabel="A1", ylabel="A2", zlabel="A3",
    xlim=(0, B), ylim=(0, B), zlim=(0, B), label="Allocations")

# # Add points from index 100 onward with a different color
# plot!(x[100:end], y[100:end], z[100:end], seriestype=:scatter, 
#     label="100 and After")

