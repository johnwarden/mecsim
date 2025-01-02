# Can't just use a step function cause optimizers assume these are curves.
return makePreferenceProfile([
    x -> x[1] >= .99 ? 100*x[1] : .01*x[1],
    x -> x[2] >= .99 ? 100*x[2] : .02*x[2],
], 2)

