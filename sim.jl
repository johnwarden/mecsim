#!/usr/bin/env julia

using LinearAlgebra, Random, Optim, Statistics, Plots, PrettyTables
using Printf  # for @printf

################################################################################
#                          Preference Utility Helpers                          #
################################################################################

function optimalPoint(prefs::Vector{Float64})
    m = length(prefs)
    function idealTradeoff(firstItem::Int, secondItem::Int)
        c1 = prefs[firstItem]
        c2 = prefs[secondItem]
        return c1^2 / (c1^2 + c2^2)
    end

    i = findfirst(prefs .> 0)
    x = zeros(m)
    x[i] = 1.0
    for j in 2:m
        t = idealTradeoff(i, j)
        x[j] = (1 - t) / t
    end
    return x / sum(x)
end

function quadraticPreferenceProfile(prefMatrix)
    n, m = size(prefMatrix)

    Utility = (user::Int, allocation::Vector{Float64}) -> begin
        dot(prefMatrix[user, :], sqrt.(allocation))
    end

    optimalPoints = vcat([optimalPoint(prefMatrix[i, :])' for i in 1:n]...)
    overallOptimalPoint = optimalPoint(sum(prefMatrix, dims=1)[1, :])

    return Utility, optimalPoints, overallOptimalPoint
end

################################################################################
#                          Mechanism Helpers                                   #
################################################################################

function tradeoffMatrixFromReport(report::Vector{Float64})
    n = length(report)
    return [
        report[i] + report[j] == 0 ? 0.5 : report[i] / (report[i] + report[j])
        for i in 1:n, j in 1:n
    ]
end

################################################################################
#                               Parsing arguments                               #
################################################################################

function expand_path(path::String)
    if isdir(path)
        results = String[]
        for filename in readdir(path)
            expanded = expand_path(joinpath(path, filename))
            append!(results, expanded)
        end
        return results
    else
        endswith(path, ".jl") ? [path] : String[]
    end
end

const DEFAULT_MECHANISMS_DIR = abspath(joinpath(@__DIR__, "mechanisms"))
const DEFAULT_PREFERENCES_DIR = abspath(joinpath(@__DIR__, "preferences"))

arg_mechanism_files = String[]
arg_preference_files = String[]

for arg in ARGS
    fullpath = abspath(arg)
    if occursin("mechanisms/", fullpath)
        push!(arg_mechanism_files, fullpath)
    elseif occursin("preferences/", fullpath)
        push!(arg_preference_files, fullpath)
    else
        @warn "Ignoring argument ‘$(arg)’: it does not contain ‘mechanisms/’ or ‘preferences/’ in its path."
    end
end

if isempty(arg_mechanism_files)
    @info "No mechanism files specified. Using all .jl in $DEFAULT_MECHANISMS_DIR"
    arg_mechanism_files = expand_path(DEFAULT_MECHANISMS_DIR)
end

if isempty(arg_preference_files)
    @info "No preference files specified. Using all .jl in $DEFAULT_PREFERENCES_DIR"
    arg_preference_files = expand_path(DEFAULT_PREFERENCES_DIR)
end

mechanism_files = unique(vcat(map(expand_path, arg_mechanism_files)...))
preference_files = unique(vcat(map(expand_path, arg_preference_files)...))

if isempty(mechanism_files)
    throw("No mechanism files found in mechanisms/ directory.")
end
if isempty(preference_files)
    throw("No preference files found in preferences/ directory.")
end

################################################################################
#                               Helper Functions                               #
################################################################################

function updateResponse(reports::Matrix{Float64}, user::Int, newReport::Vector{Float64})
    newReports = copy(reports)
    newReports[user, :] = newReport
    return newReports
end

function findBestResponse(
    mechanismFunc::Function,
    reports::Matrix{Float64},
    user::Int;
    Utility::Function
)
    m = size(reports, 2)

    function objective(x::Vector{Float64})
        newReports = updateResponse(reports, user, x)
        alloc = mechanismFunc(newReports)
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

    Random.seed!(1234)
    res = optimize(objectiveWithBoundary, lower, upper, x0, NelderMead())
    return res.minimizer
end

################################################################################
#                             Mechanism Helpers                                #
################################################################################
# (Keep any sample or default mechanism code here.)

################################################################################
#                            Progress + Logging                                #
################################################################################

"""
    logln(io, msg)

Write a line `msg` to `io`. 
"""
function logln(io::IO, msg::AbstractString)
    println(io, msg)
end

"""
    progressUpdate(mechanismName, prefName, roundNum, currentAlloc, totalUtility)

Print a single-line progress message to the console (stdout), overwriting itself.
This does not know the total number of rounds, so it's an "indefinite" progress line.
"""
function progressUpdate(
    mechanismName::String,
    prefName::String,
    roundNum::Int,
    currentAlloc::Vector{Float64},
    totalUtility::Float64,
    incentiveAlignment::Float64
)
    # Overwrite the same line using \r
    @printf("\r[Running] Pref=%s | Mechanism=%s | Round=%d | Alloc=%.2f,%.2f,... | Utility=%.2f | Incent. Align=%.2f",
        prefName,
        mechanismName,
        roundNum,
        currentAlloc[1],
        currentAlloc[min(end, 2)],  # show at most 2 coords to avoid clutter
        totalUtility,
        incentiveAlignment*100
    )
    flush(stdout)
end

################################################################################
#                                 Simulation                                   #
################################################################################

function simulate(
    mechanismName::String,
    mechanismFunc::Function;
    maxRounds::Int=10,
    Utility::Function,
    initialReports::Matrix{Float64},
    optimalPoints::Matrix{Float64},
    logIO::IO,
    prefName::String
)
    n, m = size(initialReports)
    reportsCurrent = copy(initialReports)
    alloc = mechanismFunc(reportsCurrent)
    incentiveAlignment = 1.0

    allocHistory = Vector{Vector{Float64}}()
    converged = false

    # Write an initial log line instead of @info
    logln(logIO, "Starting simulation for mechanism=$mechanismName, preference=$prefName")

    totalUtility = (alloc) -> sum(Utility(i, alloc) for i in 1:n)

    for roundIdx in 1:maxRounds
        # Log output to file:
        logln(logIO, "\n=== Round $roundIdx ===")
        logln(logIO, "Current report matrix:")
        show(IOContext(logIO), "text/plain", reportsCurrent)
        logln(logIO, "")  # newline

        convergedInRound = true

        # Update progress on console
        progressUpdate(mechanismName, prefName, roundIdx, alloc, totalUtility(alloc), incentiveAlignment)

        for u in 1:n
            logln(logIO, "User $u's turn. (Current allocation: $alloc)")
            oldUtility = Utility(u, alloc)

            bestResp = findBestResponse(
                mechanismFunc,
                reportsCurrent,
                u;
                Utility=Utility
            )
            updated  = updateResponse(reportsCurrent, u, bestResp)
            newAlloc = mechanismFunc(updated)
            newUtility = Utility(u, newAlloc)

            honestRep   = optimalPoints[u, :]
            honestUpdt  = updateResponse(reportsCurrent, u, honestRep)
            honestAlloc = mechanismFunc(honestUpdt)
            honestUtility = Utility(u, honestAlloc)

            incentiveAlignment = 1 - mean(norm(reportsCurrent[i, :] - optimalPoints[i, :]) for i in 1:n)

            logln(logIO, "  Old utility = $oldUtility")
            logln(logIO, "  New utility = $newUtility")
            logln(logIO, "  Honest utility = $honestUtility")
            logln(logIO, "  Incentive Alignment = $incentiveAlignment")

            if newUtility > oldUtility
                logln(logIO, "  => User $u improves by switching to best response.")
                convergedInRound = false
                reportsCurrent = updated
                alloc = newAlloc
            else
                if honestUtility > oldUtility
                    logln(logIO, "  => Reverting user $u to honest report (better than old).")
                    convergedInRound = false
                    reportsCurrent = honestUpdt
                    alloc = honestAlloc
                    logln(logIO, "  => User $u's new report: $(reportsCurrent[u, :])")
                else
                    logln(logIO, "  => No improvement found; user $u stays with old report.")
                end
            end

            logln(logIO, "  Allocation after user $u: $alloc")
            push!(allocHistory, alloc)
        end

        if convergedInRound
            converged = true
            logln(logIO, "Converged! No user benefited from changing their response in this round.")
            break
        end
    end

    logln(logIO, "Final reports:")
    show(IOContext(logIO), "text/plain", reportsCurrent)
    logln(logIO, "") # newline

    ah = transpose(hcat(allocHistory...))

    # 3D scatter to file (unchanged logic, logs not needed on console)
    if m == 3
        plot3d = plot()
        n_rows = size(ah, 1)
        for i in 1:n_rows
            user = mod(i-1, n) + 1
            plot!(
                plot3d,
                [ah[i, 1]],
                [ah[i, 2]],
                [ah[i, 3]],
                seriestype = :scatter,
                title = "Mechanism: $(mechanismName), Preference Profile: ($prefName)",
                xlabel = "A1", ylabel = "A2", zlabel = "A3",
                xlim = (0, 1), ylim = (0, 1), zlim = (0, 1),
                label = i == user ? "User $user" : nothing
            )
        end

        if !isdir("plots")
            mkdir("plots")
        end
        outDir = joinpath("plots", prefName)
        if !isdir(outDir)
            mkpath(outDir)
        end
        outFile = joinpath(outDir, mechanismName * ".png")
        savefig(plot3d, outFile)
    end

    return (reportsCurrent, ah, converged, incentiveAlignment)
end

################################################################################
#                           Main Program Execution                             #
################################################################################

preference_summaries = Dict{String, Dict{Symbol, Any}}()
overall_results = Dict{String, Vector{Tuple{Int,Bool,Float64,Float64,Float64}}}()

for prefFile in preference_files
    prefName = endswith(prefFile, ".jl") ?
        String(chop(basename(prefFile), tail=3)) :
        basename(prefFile)
    # Instead of printing @info to console, we do a short message:
    # println("Loading preference $(prefName)...")

    prefProfile = include(prefFile)
    Utility, optimalPoints, overallOptimalPoint = prefProfile

    n, m = size(optimalPoints)
    function totalUtility(allocation::Vector{Float64})
        s = 0.0
        for i in 1:n
            s += Utility(i, allocation)
        end
        return s
    end

    maxUtility = totalUtility(overallOptimalPoint)

    user_opt_utilities = Float64[]
    for i in 1:n
        push!(user_opt_utilities, Utility(i, optimalPoints[i, :]))
    end

    rows_data = []
    initialReports = copy(optimalPoints)

    for mechFile in mechanism_files
        mechanismName = endswith(mechFile, ".jl") ?
            String(chop(basename(mechFile), tail=3)) :
            basename(mechFile)

        # Print short message for user feedback
        # println("  Running mechanism $(mechanismName) on $(prefName)...")
        progressUpdate(mechanismName, prefName, 0, Vector{Float64}(zeros(m)), 0.0, 1.0)
        mechanismFunc = include(mechFile)

        # Prepare output directory & file
        outDir = joinpath("output", prefName)
        if !isdir(outDir)
            mkpath(outDir)
        end
        outFile = joinpath(outDir, mechanismName * ".txt")



        # Open the log file and run the simulation
        open(outFile, "w") do logFile
            reports, allocHistory, converged, incentiveAlignment = simulate(
                mechanismName,
                mechanismFunc;
                maxRounds=10,
                Utility=Utility,
                initialReports=initialReports,
                optimalPoints=optimalPoints,
                logIO=logFile,        # <--- pass file handle
                prefName=prefName     # <--- pass pref name for progress line
            )

            finalAlloc = allocHistory[end, :]
            numRounds  = Int(size(allocHistory, 1) ÷ n)
            meanUtility = totalUtility(finalAlloc) / n
            optPercent  = (totalUtility(finalAlloc) / maxUtility) * 100

            push!(rows_data, [
                mechanismName,
                numRounds,
                converged,
                round.(finalAlloc, digits=3),
                round(meanUtility, digits=2),
                round(optPercent, digits=1),
                round(incentiveAlignment*100, digits=1)
            ])

            # Also store in overall_results
            if !haskey(overall_results, mechanismName)
                overall_results[mechanismName] = Vector{Tuple{Int,Bool,Float64,Float64,Float64}}()
            end
            push!(
                overall_results[mechanismName],
                (numRounds, converged, meanUtility, optPercent, incentiveAlignment)
            )

            # After finishing, print a newline on console so the progress line doesn't linger
            println()
        end
    end

    preference_summaries[prefName] = Dict(
        :optimal => (
            user_opt_allocations = optimalPoints,
            user_opt_utilities   = user_opt_utilities,
            overall_opt_allocation = overallOptimalPoint,
            overall_max_utility    = maxUtility
        ),
        :mechanisms => rows_data
    )
end

################################################################################
#                    PRINTING ALL PREFERENCE RESULTS AT THE END               #
################################################################################

for (prefName, infoDict) in preference_summaries
    println("\nPreference: $prefName")

    optData = infoDict[:optimal]
    mechData = infoDict[:mechanisms]

    println("\nOptimal Points and Utilities:")
    optimal_table_data = []

    user_opt_allocs = optData.user_opt_allocations
    user_opt_utils  = optData.user_opt_utilities

    n = length(user_opt_utils)
    for i in 1:n
        push!(optimal_table_data, [
            i,
            round.(user_opt_allocs[i, :], digits=3),
            round(user_opt_utils[i], digits=3)
        ])
    end
    push!(optimal_table_data, [
        "ALL",
        round.(optData.overall_opt_allocation, digits=2),
        round(optData.overall_max_utility/n, digits=2)
    ])

    opt_header = ["User", "Optimal Allocation", "Optimal Utility"]
    r_opt = vcat([reshape(optimal_table_data[i], 1, :) for i in 1:length(optimal_table_data)]...)
    pretty_table(
        r_opt,
        header=opt_header,
        alignment=[:r, :c, :r],
        backend=Val(:text)
    )

    println("\nMechanism Outcomes:")
    mech_header = [
        "Mechanism",
        "Rounds",
        "Equilibrium",
        "Final Allocation",
        "Mean Utility",
        "Optimality (%)",
        "Incent. Align. (%)"
    ]
    r_mech = vcat([reshape(mechData[i], 1, :) for i in 1:length(mechData)]...)
    pretty_table(
        r_mech,
        header=mech_header,
        alignment=[:l, :r, :r, :c, :r, :r, :r],
        backend=Val(:text)
    )
end

################################################################################
#               OVERALL SUMMARY ACROSS ALL PREFERENCES (AVERAGE)              #
################################################################################

println("\n" * "="^80)
println("OVERALL SUMMARY ACROSS ALL PREFERENCES")
println("="^80)

mechanism_summary_rows = []

for (mechName, data) in sort!(collect(overall_results); by=x->x[1])
    rounds_vals = Int[]
    eq_vals     = Bool[]
    util_vals   = Float64[]
    opt_vals    = Float64[]
    align_vals  = Float64[]

    for (rnd, eq, mu, optpct, align) in data
        push!(rounds_vals, rnd)
        push!(eq_vals, eq)
        push!(util_vals, mu)
        push!(opt_vals, optpct)
        push!(align_vals, align)
    end

    mean_rounds = mean(rounds_vals)
    frac_eq     = mean(eq_vals) * 100.0
    mean_util   = mean(util_vals)
    mean_opt    = mean(opt_vals)
    mean_align  = mean(align_vals)

    push!(mechanism_summary_rows, [
        mechName,
        round(mean_rounds, digits=2),
        round(frac_eq, digits=1),
        round(mean_util, digits=3),
        round(mean_opt, digits=1),
        round(mean_align*100, digits=1)
    ])
end

summary_header = [
    "Mechanism",
    "Mean Rounds",
    "Equilibrium (%)",
    "Mean Utility",
    "Mean Optimality (%)",
    "Mean Incent. Align. (%)"
]
rsum = vcat([reshape(mechanism_summary_rows[i], 1, :) for i in 1:length(mechanism_summary_rows)]...)
pretty_table(
    rsum,
    header=summary_header,
    alignment=[:l, :r, :r, :r, :r, :r],
    backend=Val(:text)
)

println("\nDone.")
