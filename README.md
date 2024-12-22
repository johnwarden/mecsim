# Budget Allocation Mechanism Simulator

This repository contains a simulator for comparing budget allocation mechanisms. It simulates strategic users who modify their reported preferred allocations in an attempt to maximize their individual utility.

## Overview

`n` users need to allocate a budget across `m` items. Each user has a utility functions that returns their total utility given an allocation vector.

Each user submits a report indicating proposing allocation for each item. A *mechanism* takes the set of users reports and returns a final allocations.

Users then strategically update their reports to maximize their own utility given the reports of other users and the mechanism.

## Motivation

It can be hard or impossible to prove certain aspects of mechanisms. But simulation can give us an idea of how a mechanism plays out as users try to maximize their utility. It can show us, for a variety of preference profiles:

- if an equilibrium is reached (though not that no other equilibriums are possible)
- if users fall into a stable cycle
- how close the final allocations are to optimal
- how incentive-aligned the mechanism is (how close users reports are to their "true optimal" allocation)

# Development 

## Dependencies

- just
- julia

## Running Locally

Once Julia is installed, you can install all the needed packages by running:

    just instantiate

Then to run the simulation for all mechanisms, run

    just sim

Or to simulate a single mechanism

    just sim mechanisms/mechanism.jl

## Files

*   **`justfile`**: Contains commands for running the simulations.
*   **`sim.jl`**: The main simulation script.
*   **`mechanisms/`**: A directory containing implementations of different allocation mechanisms (e.g., `SAPTool.jl`).
*   **`preferences/`**: A directory containing implementations of different preference profiles.
*   **`output/`**: Detailed output of each simulation -- one for each mechanism and preference profile combination.
*   **`plots/`**: Plots of the allocation history for each simulation -- one for each mechanism and preference profile combination.


## Defining Mechanisms and Preferences

To implement a new mechanism or preference profile, add a .jl file under the `mechanisms/` or `profile/` folders directory.

The mechanism is simply a function that inputs an allocation matrix and outputs a vector. 


#### Example: `SAPTool.jl`

```julia

using Statistics

# SAP (based on the SAPTool by Steve Vitka: https://docs.google.com/spreadsheets/d/1y8q7zSCY75UFN-2J_b8ODvUYlfM3AjhyrP19xZjgGow/edit?gid=0#gid=0) 
# Uses a "Select at Percentage" mechanism. Sort each column, select the highest row where the sum is <= 1.
# Optionally, scale so sum equals 1.
return (reports::Matrix{Float64}) -> begin
    n, m = size(reports)

    # sort each column ascending
    sorted_votes = hcat([sort(reports[:, j]) for j in 1:m]...)

    # find the selection point: the last row with a sum less than the budget of 1.0
    row_sums = sum.(eachrow(sorted_votes))
    sp = findlast(≤(1.0), row_sums)

    # if no row qualifies, return zeros, or the *first* row scaled down
    if sp == 0
        return zeros(m)
    end

    return sorted_votes[sp, :]
end

```

A preference profile is 1) a function that outputs the utility for a given user allocation vector and 2) a set of optimal points. Helper function will create a quadratic preference profile from a matrix of coefficients.

#### Example: `preferences/CondorcetCycle.jl`

```julia

return quadraticPreferenceProfile([
    5.0  2.0  1.0
    1.0  5.0  2.0
    2.0  1.0  5.0
])

```


## Results and Observations

The following is the output of the simulation for all combinations of mechanisms and preferences currently implemented.

    ┌──────────────────────┬─────────────┬─────────────────┬──────────────┬─────────────────────┬─────────────────────────┐
    │ Mechanism            │ Mean Rounds │ Equilibrium (%) │ Mean Utility │ Mean Optimality (%) │ Mean Incent. Align. (%) │
    ├──────────────────────┼─────────────┼─────────────────┼──────────────┼─────────────────────┼─────────────────────────┤
    │ CoordinatewiseMedian │         7.0 │            50.0 │        5.126 │                99.0 │                    61.4 │
    │ Mean                 │        4.67 │            83.3 │        5.097 │                99.0 │                    66.6 │
    │ PairwiseMean         │         6.0 │            83.3 │        5.103 │                99.1 │                    67.9 │
    │ PairwiseMedian       │        7.17 │            33.3 │        5.128 │                99.4 │                    62.4 │
    │ PairwisePercentage   │        1.67 │           100.0 │        5.064 │                98.4 │                    97.8 │
    │ QuadraticFunding     │        6.33 │            83.3 │        5.125 │                99.3 │                    42.4 │
    │ SAP                  │        3.33 │            83.3 │        4.991 │                95.6 │                    86.0 │
    │ SAPScaled            │         8.5 │            16.7 │         4.96 │                95.1 │                    69.1 │
    └──────────────────────┴─────────────┴─────────────────┴──────────────┴─────────────────────┴─────────────────────────┘

### Description of Output Columns 

- Optimality is the difference between the allocation that maximizes overall utility and the final allocation
- Equilibrium is the % of profiles for which equilibrium is reached
- Utility is the mean utility-per-user
- Optimality is the difference between this and the maximum possible utility
- Incentive Alignment is a mean Euclidian distance between users' "honest" reports and final reports.



## Limitations

- I have so far only implemented quadratic preferences of the form `c1*√(allocation1) + c2*√(allocation2) ...` These have "nice" properties like monotonicity, concavity, and additivity, and are probably not bad approximations of real-world preferences. However, different kinds of preference profiles might produce very different results.

- This simulations aren't a substitute for a more formal equilibrium analysis. A rational agent trying to optimize their results might play differently:
    - Users always start by reporting their ideal point and only change their reports in response to other users.
    - Users play in a fixed order and always play the current "best response", defined as the response that maximizes utility *given the other players' current responses*. This may not be how a rational user can maximizes expected utility in real life. Specifically, "best-responding" may be a *bad* move for some mechanisms. For example skipping a turn, and allowing the next user to best-respond, could produce better outcomes in some cases.
    - There are no attempts for groups to collude

## Observations

- The quadratic funding formula is included here even though this settings is *not* what QF was designed for. Specifically, quadratic funding is a *funding mechanism*: users actually contribute their own money. The optimality of quadratic funding is based on the assumption that the amount users choose to contribute to a project is proportional to the *utility* they receive from the project. But this simulator simulates social choice mechanisms, where users don't contribute money.

- The PairwiseMedian preference profile is highly incentive aligned: users rarely gain anything from falsifying preference. This profile ignores the strength of preferences and only considers preference ordering. By ignoring preference strength the mechanism removes much opportunity for users to improve their by lying about preferences, but the tradeoff seems to be less optimality. 

- All of these mechanisms could be implemented with a incentive-aligned mechanism per the revelation principle. Using these simple quadratic preference profiles, we can actually reconstruct a users preference profile from their (honest) reported preferences. Thus we can create a mechanism that "plays" on the users behalf. 
