using LinearAlgebra
using Statistics
using Optim
using FixedPointAcceleration

# -------------------------------------------------------------------
# 1) Anderson Acceleration Implementation
# -------------------------------------------------------------------

"""
    anderson_acceleration(T, x0; m=5, maxiter=100, tol=1e-7, project=nothing)

Applies Anderson acceleration to the fixed-point map `T(x)` starting from `x0`.

- `T`        : A function that takes a Matrix `x` and returns `T(x)`.
- `x0`       : Initial guess (Matrix or Vector).
- `m`        : Memory (number of previous iterates to use).
- `maxiter`  : Maximum number of iterations.
- `tol`      : Convergence tolerance, measured by `norm(x_{k+1} - x_k)`.
- `project`  : Optional function `project!(x)` that projects `x` back to the feasible set
               (e.g., the probability simplex). If `nothing`, no projection is done.

Returns `(x_star, converged, history)`, where:
- `x_star`   : The final iterate.
- `converged`: Boolean indicating whether the iteration reached the tolerance.
- `history`  : Vector of residuals ‖x_{k+1} - x_k‖ at each iteration.
"""
function anderson_acceleration(
    T,
    x0;
    m=5,
    maxiter=100,
    tol=1e-7,
    project=nothing
)
    x_k = copy(x0)
    f_k = T(x_k)

    # We'll store flattened differences
    sBuf = Vector{Vector{Float64}}(undef, m)
    yBuf = Vector{Vector{Float64}}(undef, m)

    history = Float64[]

    for k in 1:maxiter
        x_kp1_naive = f_k
        if project !== nothing
            project(x_kp1_naive)
        end

        push!(history, norm(x_kp1_naive .- x_k))
        if history[end] < tol
            return (x_kp1_naive, true, history)
        end

        # Flatten the differences:
        sBuf[(k-1) % m + 1] = vec(x_kp1_naive .- x_k)
        yBuf[(k-1) % m + 1] = vec(T(x_kp1_naive) .- f_k)

        # Build S, Y in ℝ^{(n*m) × t}
        t = min(k, m)
        S = hcat(sBuf[1:t]...)
        Y = hcat(yBuf[1:t]...)

        # Solve  min_{α}  (1/2) ‖Y α‖^2  subject to sum(α)=1
        λ = 1e-8
        I_t = Matrix{Float64}(I, t, t)
        M = [Y'Y + λ*I_t   -ones(t);
             ones(t)'       0.0    ]

        rhs = vcat(zeros(t), 1.0)
        sol = M \ rhs
        α   = sol[1:t]

        # Anderson update:  Δx_aa = S * α
        Δx_aa = S * α
        # Reshape back into n×m if needed:
        x_kp1 = x_k .+ reshape(Δx_aa, size(x_k))

        if project !== nothing
            project(x_kp1)
        end

        f_k = T(x_kp1)
        x_k = x_kp1
    end

    return (x_k, false, history)
end

# -------------------------------------------------------------------
# 2) Fixed-Point Map T(x)
# -------------------------------------------------------------------

"""
    T(x)

Given a current profile of reports `x` (size n×m),
returns a new matrix of reports `x_new` where each row `x_new[i, :]`
is user i's best response to the other users' reports.
Requires that `find_best_response` is defined somewhere in scope.

**Note**: We assume you've already defined:
  find_best_response(X, i)::Vector{Float64}

This function just loops over all users i = 1..n and calls `find_best_response(x, i)`.
"""
function T(x::Matrix{Float64})::Matrix{Float64}
    n, m = size(x)
    x_new = similar(x)
    # For each user, get the best response
    for i in 1:n
        # We assume find_best_response(x, i) is a function the user already has.
        # Must return an m-element vector that sums to 1 if it’s a probability vector.
        x_new[i, :] = find_best_response(x, i)
    end
    return x_new
end


# -------------------------------------------------------------------
# 3) (Optional) Projection onto Simplex
# -------------------------------------------------------------------
# If your best-response is guaranteed to be in the simplex, or if
# find_best_response already enforces that, you can skip this.
# Otherwise, define a small helper:

"""
    project_simplex!(row)

Projects a 1D vector `row` onto the probability simplex.
In-place implementation (there are many approaches).
"""
function project_simplex!(row::AbstractVector{Float64})
    u = copy(row)
    sort!(u, rev=true)

    sv = 0.0
    ρ = 0
    for i in 1:length(u)
        sv += u[i]
        t = (sv - 1) / i
        if u[i] - t > 0
            ρ = i
        end
    end

    θ = (sum(u[1:ρ]) - 1) / ρ
    for i in 1:length(row)
        row[i] = max(row[i] - θ, 0)
    end

    return row
end


"""
    project_all_rows!(X)

Projects each row of `X` onto the simplex in-place.
"""
function project_all_rows!(X::Matrix{Float64})
    n, m = size(X)
    for i in 1:n
        project_simplex!(view(X, i, :))
    end
    return X
end



# -------------------------------------------------------------------
# 4) High-Level Function to Compute Equilibrium
# -------------------------------------------------------------------

"""
    compute_equilibrium(b; m=5, maxiter=100, tol=1e-7)

Given a matrix of preference coefficients `b::Matrix{Float64}` (size n×m),
computes an approximate equilibrium using Anderson acceleration on the
fixed-point map `T(x)`.

- If you already store `b` somewhere or use it inside `find_best_response`, you
  can pass it in here or define it globally—adapt as needed.
- `m`, `maxiter`, `tol` control the Anderson acceleration.

Returns `x_star`, the approximate equilibrium matrix (n×m).
"""
function compute_equilibrium(
    mechanism,
    b::Matrix{Float64}
    ;
    memory=5,
    maxiter=100,
    tol=1e-7
)


    n, m = size(b)

    Utility, idealPoints = sqrt_preferences(b)

    find_best_response_i = (X::Matrix{Float64}, i::Int) -> begin
        br = find_best_response(
            mechanism,
            X,
            i;
            Utility = Utility
        )
        br / sum(br)
    end

    T = (X::Matrix{Float64}) -> begin
        n, m = size(X)
        x_new = copy(idealPoints)
        for i in 1:n
            x_new[i, :] = find_best_response_i(X, i)
        end
        return x_new
    end
    
    # Example: initial guess x0 = uniform distribution in the simplex
    x0 = idealPoints
    # fill(1.0/m, n, m)


    # Optionally, define a projection if you want to ensure x stays in the simplex:
    # project_fun!(X) = project_all_rows!(X)

    # x_star = fixed_point(T, x0; Algorithm = :Anderson)

    # Run Anderson acceleration
    return anderson_acceleration(
                                    T,
                                    x0;
                                    project=project_all_rows!  # uncomment if needed
                                )

end

geometric_median = include("GeometricMedian.jl")

return reports -> begin
    n, m = size(reports)

    mechanism = geometric_median
    capped_mechanism = x -> cap(mechanism(x))

    b = sqrt_preference_matrix_from_reports(reports)

    # Run Anderson acceleration
    x_star, converged, history = compute_equilibrium(capped_mechanism, b; memory=5, maxiter=50, tol=1e-8)
    println("Equilibrium:\n", x_star)

    F = capped_mechanism(x_star)
    println("Allocation from x_star = ", F)
    # println("Convergence history = $history")

    return F
end
