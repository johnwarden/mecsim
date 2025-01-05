using Statistics

using LinearAlgebra

"""
    geometric_median(reports; tol=1e-7, maxiter=1000)

Compute the geometric median of the rows in `reports` using Weiszfeld’s algorithm
(minimizing sum of Euclidean distances).

- `reports` is an `n x m` matrix, where each of the `n` rows is an `m`-dimensional point.
- `tol` is the stopping tolerance for the iterative method.
- `maxiter` is the maximum number of iterations.

Returns a 1D vector of length `m`.
"""
function geometric_median(reports; tol=1e-7, maxiter=1000)
    n, m = size(reports)

    # A common initialization is just the arithmetic mean:
    x = vec(mean(reports, dims=1))

    for _ in 1:maxiter
        numerator   = zeros(m)
        denominator = 0.0
        for i in 1:n
            dist = norm(x .- reports[i, :])    # Euclidean distance
            # If the current guess is extremely close to one of the points,
            # returning that point avoids division by very small dist.
            if dist < tol
                return reports[i, :]
            end
            w = 1.0 / dist
            numerator   .+= w * reports[i, :]
            denominator += w
        end
        x_new = numerator ./ denominator

        # Check for convergence
        if norm(x_new .- x) < tol
            return x_new
        end

        x = x_new
    end

    return x
end

return geometric_median