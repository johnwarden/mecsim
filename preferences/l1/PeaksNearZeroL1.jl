# Preference profile where peaks are close to zero. The optimal allocation for
# most users does not use up the total budget. And before the budget is
# reached, utility turns negative. This results in low optimality for a lot
# of mechanisms, where users tend to arrive at an equilibrium that users most
# of the budget.
return l1_preferences([
    0.3  0.15  0.12
    0.1  0.12  0.21
    0.2  0.3   0.2
])
