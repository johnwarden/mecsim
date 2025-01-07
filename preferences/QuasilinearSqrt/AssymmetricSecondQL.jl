# Profile where all users have similar preference ordering, but there is a big difference in the magnitude of preferences of the second-most-preferred item
# Designed to create sub-optimal results for the pairwise probability mechanism, which only considers preference orderings and not relative magnitude
return quasilinear_sqrt_preferences([
    .50  .02  .01
    .49  .48  .01
    .50  .02  .01
])

