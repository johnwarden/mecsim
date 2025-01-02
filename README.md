# Budget Allocation Mechanism Simulator

This repository contains a simulator for comparing budget allocation mechanisms. It simulates strategic users who modify their reported preferred allocations in an attempt to maximize their individual utility.

The most surprising result of the simulation is that, for a wide variety of preference profiles, the final results are close to the optimal.

## Motivation

### Incentive Compatible Budget Allocation

The theoretical problem of allocation a limited budget among multiple competing projects (or public goods or policies or whatever) has been extensively studied. It first it looks like it should be simple: just ask everybody what they think the allocation should be, and take some sort of average. But when the early social choice theorists such as Condorcet and Arrow tried this, they ran into difficulties. Never mind that there are many different ways you could define the "average"; the big problem is that people will do whatever produces the best outcome for themselves. And no matter what aggregation function you use, self-interested people can get better results for themselves by proposing something *different from what they really want the allocation to be*. 

This may seem counter-intuitive. Normally when you vote, if you vote for the person you want to win, that person is more likely to win! So there is no incentive to lie. We say that majority voting (between two candidates) is [**strategyproof**](https://en.wikipedia.org/wiki/Strategyproofness), in that there is no voting strategy better than just voting for exactly what you want.

But budget allocation voting mechanisms are generally not strategyproof. For example, suppose you think 80% of the budget should go to your favorite project, but the average for the group was 40%; your favorite project is under-funded while other projects are over-funded. So you would be better off *saying* you think 100% should go to your favorite project and 0% to the others, thereby raising the final average of your favorite project and lowering the average for the others. If there are only two projects, there *is* a [strategyproof mechanism that uses the median](https://en.wikipedia.org/wiki/Median_voter_theorem) instead of the mean, but with three or more projects, you will be better off exaggerating your preference for your favorite project, no matter what the mechanism.

Try as they might, the great social-choice theorists of yore could not get around this. They couldn't come up with any *strategyproof* mechanism that wasn't limited in some way. Many theorems proved the impossibility of a mechanism that had certain combination of desired properties. 


In fact eventually [Allan Gibbard](https://en.wikipedia.org/wiki/Allan_Gibbard) proved that it [just wasn't possible](https://en.wikipedia.org/wiki/Gibbard%27s_theorem) to design a mechanism that was fair in any reasonable sense of the word, and that was also strategyproof.


### Alternatives

So what do we do? It doesn't seem acceptable that one person can impose their will on others by lying. Nevertheless, budgets must be allocated! So let's get realistic. What if *everybody lies*? Or at least we don't even pretend that people's proposed budget is their *preferred* budget. Rather we recognize it as a kind of game, where people make a proposal they think will produce the best results for themselves, given the current set of proposals and the mechanism for aggregating them. And then other people respond, trying to maximize their results given what everyone else is doing. Maybe things balance out?

Here is the point where we move from theory to experiment. 

## Goals of the Simulation

Using a variety of profiles of user preferences, the simulation tells us if:

- if an equilibrium is reached
- if the final allocations are close to the overall optimal
- if results disproportionately benefit some individuals at the expense of others
- how incentive-aligned the mechanism is (how close individuals reports are to their "true optimal" allocations)

## Setup

`n` users need to allocate a budget of 1.0 across `m` items. Each user has a utility functions that returns their total utility given their allocation vector.

User submits their proposed allocation vectors and the mechanism outputs a final allocation.

Users then take turns updating their reports by best-responding: maximizing their own utility given the reports of other users.

The simulation terminates if no user is able to improve their utility more than some threshhold. 

## Results

The following is the output of the simulation for all combinations of mechanisms and preferences currently implemented. Since these are averages across preference profiles, the averages aren't really that useful for comparing mechanisms -- different mechanisms work better for certain types of preference profiles. The averages are just averages across the preference profiles I happen to have implemented.

But since I have implemented a variety of preference profiles, it is interesting to note how close to optimality many mechanisms are overall.

Another striking result is that most simulations reach an equilibrium for most preference profiles.

    ┌────────────────────────┬─────────────┬─────────────────┬──────────────┬─────────────────────┬─────────────────────────┐
    │ Mechanism              │ Mean Rounds │ Equilibrium (%) │ Mean Utility │ Mean Optimality (%) │ Mean Incent. Align. (%) │
    ├────────────────────────┼─────────────┼─────────────────┼──────────────┼─────────────────────┼─────────────────────────┤
    │ Mean                   │         3.3 │           100.0 │        0.821 │                89.6 │                    79.9 │
    │ Median                 │         1.8 │           100.0 │        0.883 │                96.9 │                    91.8 │
    │ PairwiseMeanTradeoff   │         2.4 │           100.0 │        0.806 │                88.0 │                    73.4 │
    │ PairwiseMedianTradeoff │         1.7 │           100.0 │        0.816 │                89.1 │                    95.5 │
    │ PairwiseProbability    │         1.3 │           100.0 │        0.774 │                84.7 │                    96.0 │
    │ QuadraticFunding       │         4.0 │            90.0 │        0.817 │                89.2 │                    73.0 │
    │ SAP                    │         1.7 │           100.0 │        0.854 │                92.9 │                    80.6 │
    │ SAPScaled              │         6.5 │            50.0 │          0.8 │                87.0 │                    79.0 │
    └────────────────────────┴─────────────┴─────────────────┴──────────────┴─────────────────────┴─────────────────────────┘

### Description of Output Columns 

- Equilibrium is the % of profiles for which equilibrium is reached
- Utility is the mean utility-per-user
- Optimality is the difference between this and the maximum possible normalized utility. Each user's utility function is normalized so their maximum utility = 1.0.
- Incentive Alignment is a mean Euclidian distance between users' "honest" reports and final reports.

## Defining Optimality

The optimality definition is based on an estimate of total utility. But Kenneth Arrow famously argued that individual subjective utilities can't be added togeter: “it seems to make no sense to add the utility of one individual, a psychic magnitude in his mind, with the utility of another individual”.

So instead of considering user's subjective utility as an absolute quantity, we consider each user's utility as a percentage of their maximum possibility utility.

This is consistent with many intuitive notions of what is fair. For example, if each user gets 99% of their optimal utility, overall optimality is 99%. If we did not normalize utility, the optimal solution would be weighted towards users with higher absolute values of subjective utility.


### Output Files

The simulation also outputs:

- output/plots/preferences: Plot of each preference profile
- output/plots/sims: For 3-D preferences, plot how the allocation changes over the course of the simulation for each mechanism
- output/log: detailed log of simulation for each simulation/mechanism combination



## Limitations

This simulations aren't a substitute for a more formal equilibrium analysis. It assumes players behave in a certain way:

- Users always start by reporting their ideal point and only change their reports in response to other users.
- Users play in a fixed order and always play the current "best response", defined as the response that maximizes utility *given the other players' current responses*. This may not be how a rational user can maximizes expected utility in real life. Specifically, "best-responding" may be a *bad* move for some mechanisms. For example skipping a turn, and allowing the next user to best-respond, could produce better outcomes in some cases.
- There are no attempts by groups to collude

A rational agent trying to optimize their results might behave differently.


# Development 

## Dependencies

- just
- julia

## Running Locally

Once Julia is installed, you can install all the needed packages by running:

    just instantiate

Then to run the simulation for all mechanisms, run

    just sim

To simulate a single mechanism or mechanisms, pass the mechanism file names:

    just sim mechanisms/SAP.jl

Likewise to simulate a single preference profile:

    just sim preferences/CondorcetCycle.jl

## Defining Mechanisms and Preferences

To implement a new mechanism or preference profile, add a .jl file under the `mechanisms/` or `preferences/` folders directory.

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

A preference profile is 1) a function that outputs the utility for a given user allocation vector and 2) a set of optimal points. Helper function will create a square-root or quadratic preference profile from a matrix of coefficients.

#### Example: `preferences/CondorcetCycle.jl`

```julia

return sqrtPreferences([
    5.0  2.0  1.0
    1.0  5.0  2.0
    2.0  1.0  5.0
])

```

