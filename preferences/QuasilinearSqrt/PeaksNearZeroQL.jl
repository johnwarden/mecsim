# Preference profile where peaks are close to zero. The optimal allocation for
# most users does not use up the total budget. And before the budget is
# reached, utility turns negative. This results in low optimality for a lot
# of mechanisms, where users tend to arrive at an equilibrium that users most
# of the budget.
return quasilinear_sqrt_preferences([
    .6  .3  .24
    .20  .24  .22
    .4  .6  .20
])
