using LinearAlgebra
using StatsBase: normalize

###############################################################################
# 1) Weiszfeld’s algorithm for geometric median
###############################################################################
function weiszfeld(points; tol=1e-9, maxiter=1000)
    # `points` is an Array{Float64,2} of size (m, n) with n = # of points, m = dimension.
    m, n = size(points)
    # Initial guess: average of points
    F = sum(points, dims=2) / n
    for iter in 1:maxiter
        numerator   = zeros(m)
        denominator = 0.0
        for k in 1:n
            distk = norm(F .- points[:, k])
            if distk < tol
                # If we land on top of a point, just return that point
                return copy(points[:, k])
            end
            w = 1.0 / distk
            numerator   .+= w .* points[:, k]
            denominator += w
        end
        newF = numerator ./ denominator
        if norm(newF - F) < tol
            return newF
        end
        F = newF
    end
    return F
end

###############################################################################
# 2) Best-response computation for one player i
#    given x_others (shape (m, n-1)) and preference vector b_i (length m).
###############################################################################
function best_response(x_others, b_i; tol=1e-6, maxiter=100)
    # x_others has shape (m, n-1), columns are other players' reports
    # b_i is a vector of length m (b_i[j] is that player's coefficient for project j).
    m = length(b_i)

    # Initialize x_i uniformly on the simplex
    x_i = fill(1.0/m, m)

    for iter in 1:maxiter
        # (1) Compute geometric median of all points (the others + current guess)
        all_points = hcat(x_others, x_i)
        F = weiszfeld(all_points)

        # (2) Current objective
        obj_current = sum(b_i[j] * sqrt(F[j]) for j in 1:m)

        # (3) Approx. gradient w.r.t. x_i (finite differences)
        g = zeros(m)
        eps = 1e-6
        for j in 1:m
            if x_i[j] > eps
                x_i_perturbed = copy(x_i)
                x_i_perturbed[j] += eps
                # Project to simplex (simple approach)
                x_i_perturbed = normalize(x_i_perturbed .* (x_i_perturbed .> 0), 1)

                # Recompute F
                F_pert = weiszfeld(hcat(x_others, x_i_perturbed))
                obj_pert = sum(b_i[k] * sqrt(F_pert[k]) for k in 1:m)
                g[j] = (obj_pert - obj_current) / eps
            else
                g[j] = 0.0
            end
        end

        # (4) Gradient ascent step
        alpha = 0.1
        x_i_new = x_i .+ alpha .* g

        # (5) Project to simplex (clip & renormalize)
        for j in 1:m
            x_i_new[j] = max(x_i_new[j], 0.0)
        end
        x_i_new = normalize(x_i_new, 1)

        # (6) Check for small change
        if norm(x_i_new - x_i) < tol
            return x_i_new
        end
        x_i = x_i_new
    end

    return x_i
end

###############################################################################
# 3) Find an approximate equilibrium by iterative best responses
#
#    b is an n×m matrix (n players, m projects),
#    so b[i,:] is the preference vector of player i.
###############################################################################
function find_equilibrium(b::Matrix{Float64}; tol=1e-5, maxiter=100, silent=false)
    # b has size (n, m)
    n, m = size(b)

    # We'll store the reports in x, of size (m, n), 
    # so that x[:,i] is the i-th user's report in R^m.
    x = fill(1.0/m, m, n)  # start uniformly for each user

    for iter = 1:maxiter
        old_x = copy(x)

        # For each player i, best-respond to others
        for i in 1:n
            x_others = x[:, [j for j in 1:n if j != i]]
            b_i = b[i, :]          # preference vector for player i
            x_i = best_response(x_others, b_i; tol=tol, maxiter=50)
            x[:, i] = x_i
        end

        # Check how much x changed overall
        diff = norm(x - old_x)
        if !silent
            println("Iteration $iter, delta_x = $diff")
        end

        if diff < tol
            break
        end
    end

    return x
end


using Statistics

return reports -> begin
    n, m = size(reports)

    # Assuming sqrt preferences, the un-scaled quadratic funding formula has a
    # equilibrium where user reports the square of the coefficients of their
    # preference function
    b = sqrt_preference_matrix_from_reports(reports)

    equilibriumReports = find_equilibrium(b; silent=true)

    return weiszfeld(equilibriumReports)

end
