# Can't just use a step function cause optimizers assume these are curves.
return make_preference_profile([
    x -> x[1] >= .99 ? 100*x[1] : .01*x[1],
    x -> x[2] >= .99 ? 100*x[2] : .02*x[2],
], 2)

