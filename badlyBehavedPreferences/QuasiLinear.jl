return makePreferenceProfile([
    x -> x[1] + .5√x[2] + .45√x[3],
    x -> x[1] + 1√x[2] + .2√x[3],
    x -> x[1] + .2√x[2] + .5√x[3]
], 3)



