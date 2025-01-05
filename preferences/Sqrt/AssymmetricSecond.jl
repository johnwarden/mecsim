# Profile where all users have similar preference ordering, but there is a big difference in the magnitude of preferences of the second-most-preferred item
# Designed to create sub-optimal results for the pairwise probability mechanism, which only considers preference orderings and not relative magnitude
return sqrt_preferences([
    5.0  0.2  0.1
    4.9  4.8  0.1
    5.0  0.2  0.1
])

