# Preference profile where peaks are close to zero. The optimal allocation for
# most users does not use up the total budget. And before the budget is
# reached, utility turns negative. This results in low optimality for a lot
# of mechanisms, where users tend to arrive at an equilibrium that users most
# of the budget.
return quadraticPreferences([
    .3  .15  .12
    .10  .12  .21
    .2  .3  .2
])
