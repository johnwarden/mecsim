#!/usr/bin/env julia

using LinearAlgebra, Random, Optim, Statistics, Plots

# -----------------------------------------------------------------------------
# Command-line usage:
#   julia main.jl <aggregatorName>
# e.g.:
#   julia main.jl aggregators/SAPToolBlend.jl
# -----------------------------------------------------------------------------

# Example preference matrix
const prefMatrix = [
    5.0  2.0  1.0
    1.0  5.0  2.0
    2.0  1.0  5.0
]

# Derive n, m from prefMatrix
const n, m = size(prefMatrix)


# -------------------------------------------------------------------------
# Utility for user i
function Utility(user::Int, allocation::Vector{Float64})
    dot(prefMatrix[user, :], sqrt.(allocation))
end

# Sum of all users' utilities
function totalUtility(allocation::Vector{Float64})
    sum(Utility(i, allocation) for i in 1:n)
end

function tradeoff(user::Int, firstItem::Int, secondItem::Int)
    if firstItem == secondItem
        return 0
    end
    c1 = prefMatrix[user, firstItem]
    c2 = prefMatrix[user, secondItem]
    return c1^2 / (c1^2 + c2^2)
end

function idealPoint(user::Int)
    t12 = tradeoff(user, 1, 2)
    t13 = tradeoff(user, 1, 3)

    # Denominator might be interpreted as t12/(1 - t12),
    # but here we do a ratio approach: 
    # y2 = (1 - t12)/t12, etc.
    # See original code for details on the rationale.
    y1 = 1
    y2 = (1 - t12) / t12
    y3 = (1 - t13) / t13

    r = [y1, y2, y3]
    return r / sum(r)
end

const initialReports = vcat([idealPoint(i)' for i in 1:n]...)

function buildTradeoffMatrix(report::Vector{Float64})
    m = length(report)
    T = Matrix{Float64}(undef, m, m)
    for i in 1:m
        for j in 1:m
            if i == j
                T[i, j] = 0.0
            else
                T[i, j] = report[i] / (report[i] + report[j])
            end
        end
    end
    return T
end

"""
    updateResponse(reports, user, newReport)

Returns a copy of `reports` where row `user` is replaced by `newReport`.
"""
function updateResponse(reports::Matrix{Float64}, user::Int, newReport::Vector{Float64})
    newReports = copy(reports)
    newReports[user, :] = newReport
    return newReports
end

"""
    findBestResponse(allocFunc, reports, user)

Find the best response for `user` to aggregator `allocFunc` given
the other users' reports. We do this by direct optimization in [0, 1]^m,
minimizing negative utility of user.

`allocFunc(reports, prefMatrix) -> allocation`
"""
function findBestResponse(allocFunc::Function, reports::Matrix{Float64}, user::Int)
    # Objective: negative utility
    function objective(x::Vector{Float64})
        newReports = updateResponse(reports, user, x)
        alloc = allocFunc(newReports, prefMatrix)
        return -Utility(user, alloc)
    end

    x0 = copy(reports[user, :])
    lower = fill(0.0, m)
    upper = fill(1.0, m)

    function objectiveWithBoundary(x)
        if any(x .< 0) || any(x .> 1)
            return 1e6
        end
        return objective(x)
    end

    Random.seed!(1234)  # for reproducibility
    res = optimize(objectiveWithBoundary, lower, upper, x0, NelderMead())
    return res.minimizer
end

"""
    simulate(allocFunc; maxRounds=20)

Multi-round simulation with aggregator `allocFunc`. 
- Start from `initialReports`.
- Each round, show the current report matrix, then let each user in turn
  compute a best response. 
- Update if it improves their utility. If not, check if honest is better, etc.
- Print each user's new report and the final allocation right after they act.
- Stop if we converge (no improvement).

Returns (finalReports, finalAllocation).
"""
function simulate(allocFunc::Function; maxRounds::Int=20)
    # 1) Start from initial (honest) reports
    reportsCurrent = copy(initialReports)
    # Initial aggregator call
    alloc = allocFunc(reportsCurrent, prefMatrix)

    allocHistory = []

    for roundIdx in 1:maxRounds
        println("\n=== Round $roundIdx ===")
        println("Current report matrix:")
        display(reportsCurrent)

        converged = true

        for u in 1:n
            println("User $u's turn. (Current allocation: $alloc)")

            oldUtility = Utility(u, alloc)
            bestResp   = findBestResponse(allocFunc, reportsCurrent, u)
            updated    = updateResponse(reportsCurrent, u, bestResp)
            newAlloc   = allocFunc(updated, prefMatrix)
            newUtility = Utility(u, newAlloc)

            # Also check "honest" (ideal) utility for user
            honestRep   = idealPoint(u)
            honestUpdt  = updateResponse(reportsCurrent, u, honestRep)
            honestAlloc = allocFunc(honestUpdt, prefMatrix)
            honestUtility = Utility(u, honestAlloc)

            println("  Old utility = $oldUtility")
            println("  New utility = $newUtility")
            println("  Honest utility = $honestUtility")

            if newUtility > oldUtility
                println("  => User $u improves by switching to best response.")
                converged = false
                reportsCurrent = updated
                alloc = newAlloc
            else
                # maybe honest is better than oldUtility
                if honestUtility > oldUtility
                    println("  => Reverting user $u to honest report (better than old).")
                    converged = false
                    reportsCurrent = honestUpdt
                    alloc = honestAlloc
                else
                    println("  => No improvement found; user $u stays with old report.")
                end
            end

            println("  User $u's new report: ", reportsCurrent[u, :])
            println("  Allocation after user $u: ", alloc)
        end

        if converged
            println("Converged! No user benefited from changing their response in this round.")
            break
        end

        push!(allocHistory, alloc)
    end

    allocHistory = transpose(hcat(allocHistory...))

    println("\nFinal allocation = $alloc")
    finalUtility = totalUtility(alloc)
    println("Final total utility = $finalUtility")
    println("Final mean utility  = $(finalUtility / n)")

  # Plot points with different colors for each user
    n_rows = size(allocHistory, 1)
    colors = [:red, :blue, :green, :orange, :purple, :cyan] # Add more colors if needed
    plot3d = plot()
    for i in 1:n_rows
        user = mod(i-1, n) + 1 # Get user number (1-based indexing)
        plot!(plot3d, [allocHistory[i,1]], [allocHistory[i,2]], [allocHistory[i,3]], 
            seriestype=:scatter,
            color=colors[user],
            label=i == user ? "User $user" : nothing) # Only show label once per user
    end
    plot!(plot3d,
        title="Allocation Trajectory",
        xlabel="A1", ylabel="A2", zlabel="A3",
        xlim=(0, 1), ylim=(0, 1), zlim=(0, 1))
    # make allocations directory
    if !isdir("plots")
        mkdir("plots")
    end

    # save plot to file
    savefig(plot3d, "plots/$(allocFunc)_allocations.png")
    

    return (reportsCurrent, alloc)
end


function expand_path(path::String)
    Vector{String}
    if isdir(path)
        return collect(
            Iterators.flatten([
                expand_path(joinpath(path, filename)) for filename in readdir(path)
            ]),
        )
    end
    return [path]
end

default_aggregators_path = joinpath(@__DIR__, "aggregators")

if length(ARGS) > 1
    throw("Too many arguments. Usage: julia run.jl [path]")
end

path_argument = length(ARGS) == 1 ? ARGS[1] : nothing

path =
    isnothing(path_argument) ?
    begin
        @info "Running all aggregators under $default_aggregators_path"
        default_aggregators_path
    end : joinpath(pwd(), path_argument)

filenames = expand_path(path)

if length(filenames) == 0
    throw("No files found in $path")
end

for file in filenames
    aggregator = include(file)
    aggregator_name =
        endswith(file, ".jl") ? String(chop(basename(file), tail = 3)) : basename(file)
    @info "Running simulation with aggregator $(aggregator_name)..."

    @show aggregator


    begin
        simulate(aggregator)
    end
end
