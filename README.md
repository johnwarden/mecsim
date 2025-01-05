# Budget Allocation Mechanism Simulator

This repository contains a simulator for comparing budget allocation mechanisms. It simulates an iterative process where users strategically modify their reported preferred allocations in an attempt to maximize their individual utility.

Interestingly, for a wide variety of preference profiles and mechanisms, users arrive at an equilibrium that is close to the overall-utility-maximizing optimal allocation -- even though users individual reports different significantly from their individual optimal allocations.

## Motivation

### Incentive Compatible Budget Allocation

The problem of allocation a limited budget among multiple competing projects (or public goods or policies or whatever) has been studied for over a century. It first it looks like it should be simple: just ask everybody what they think the allocation should be, and take some sort of average. But when the pioneering social choice theorists  tried this, they ran into difficulties. Never mind that there are many different ways you can define the "average"; the big problem is that people will do whatever produces the best outcome for themselves. And no matter what aggregation function you use, self-interested people can get better results for themselves by proposing something *different from what they really want the allocation to be*. 

This may seem counter-intuitive. Normally when you vote, if you vote for the person you want to win, that person is more likely to win! So there is no incentive to lie. We say that majority voting (between two candidates) is [**strategyproof**](https://en.wikipedia.org/wiki/Strategyproofness), in that there is no voting strategy better than just voting for exactly what you want.

But budget allocation mechanisms are generally not strategyproof. For example, suppose you think 80% of the budget should go to your favorite project, but the average for the group is 40%; your favorite project is under-funded while other projects are over-funded. So you would be better off *saying* you think 100% should go to your favorite project and 0% to the others, thereby raising the final average of your favorite project and lowering the average for the others. 

If there are only two projects, there *is* a [strategyproof mechanism that uses the median](https://en.wikipedia.org/wiki/Median_voter_theorem) instead of the mean. But when there are more than three alternatives, things get ugly. In fact eventually [Allan Gibbard](https://en.wikipedia.org/wiki/Allan_Gibbard) proved that it [just wasn't possible](https://en.wikipedia.org/wiki/Gibbard%27s_theorem) to design a mechanism for choosing among more than two alternatives that was strategyproof and not severely limited in certain ways. 

### Alternatives

So what do we do? It doesn't seem acceptable that one person can impose their will on others by lying. Nevertheless, budgets must be allocated! So let's get realistic. What if *everybody lies*? Or at least we don't even pretend that people's proposed budget is their *preferred* budget. Rather we recognize it as a kind of game, where people make a proposal they think will produce the best results for themselves, given the current set of proposals and the mechanism for aggregating them. And then other people respond, trying to maximize their results given what everyone else is doing. Maybe things balance out?

Here is the point where we move from theory to experiment. These simulations show that, yes, things kind of do balance out.

## Goals of the Simulation

Using a variety of profiles of user preferences, the simulation tells us if:

- if an equilibrium is reached
- how close the final allocation is to the overall [optimal](#defining-optimality)
- if results disproportionately benefit some individuals at the expense of others
- how incentive-aligned the mechanism is (how close individuals reports are to their "true optimal" allocations)

## Setup

`n` users need to allocate a budget across `m` items. Each user has a utility functions that returns their total utility given their allocation vector.

User submits their proposed allocation vectors and the mechanism outputs a final allocation with a total <= 1.0.

Users then take turns updating their reports by best-responding: maximizing their own utility given the reports of other users.

The simulation terminates if no user is able to improve their utility more than some threshold, or when a maximum number of rounds is reached.

## Summary of Results

The following is a summary of the results of the simulation, showing the mean results for each mechanism across a variety of preference profiles.

The results don't necessarily show us which mechanism is "best", because results depends so much on what users actual preference profiles are. But it is interesting to note how close to optimal many mechanisms are for a variety of preference profiles.

    ================================================================================
    OVERALL SUMMARY ACROSS ALL PREFERENCES
    ================================================================================
    ┌────────────────────────┬─────────────┬─────────────────┬─────────────────────┬───────────────┬────────────────────┐
    │ Mechanism              │ Mean Rounds │ Equilibrium (%) │ Mean Optimality (%) │ Mean Envy (%) │ Mean Alignment (%) │
    ├────────────────────────┼─────────────┼─────────────────┼─────────────────────┼───────────────┼────────────────────┤
    │ CoordinatewiseMean     │         4.0 │            90.0 │                95.6 │          16.1 │               64.3 │
    │ CoordinatewiseMedian   │         1.7 │           100.0 │                98.6 │          12.4 │               91.4 │
    │ GeometricMedian        │         3.5 │            90.0 │                98.6 │          13.3 │               84.1 │
    │ PairwiseMeanTradeoff   │         2.9 │           100.0 │                88.9 │          20.8 │               69.9 │
    │ PairwiseMedianTradeoff │         4.3 │            90.0 │                89.7 │          22.1 │               77.1 │
    │ PairwiseProbability    │         1.8 │           100.0 │                88.5 │          19.7 │               94.6 │
    │ QuadraticFunding       │         4.0 │            90.0 │                89.6 │          21.1 │               59.4 │
    │ QuadraticVariant       │         3.9 │            90.0 │                89.5 │          21.3 │               66.4 │
    │ SAP                    │         1.6 │           100.0 │                93.0 │          28.3 │               87.0 │
    │ SAPScaled              │         5.7 │            50.0 │                86.2 │          34.1 │               79.2 │
    └────────────────────────┴─────────────┴─────────────────┴─────────────────────┴───────────────┴────────────────────┘


### Description of Output Columns 

- Equilibrium is the % of profiles for which equilibrium is reached
- Utility is the mean utility-per-voter
- Optimality is the difference between this and the maximum possible normalized utility. Each voter's utility function is normalized so their maximum utility = 1.0.
- Envy is the difference between the utility of the voter who has the maximum utility in the final allocation and the voter with the minimum
- Incentive Alignment is a mean Euclidian distance between voters' "honest" reports and final reports.

## Defining Optimality

The mean optimality is calculated based on total utility (the sum of utilities for all voters). But Kenneth Arrow famously argued that individual subjective utilities can't be added together: “it seems to make no sense to add the utility of one individual, a psychic magnitude in his mind, with the utility of another individual”.

So instead of considering voter's subjective utility as an absolute quantity, we consider each voter's utility as a percentage of their maximum possibility utility.

This is consistent with many intuitive notions of what is fair. For example, if each voter gets 99% of their optimal utility, overall optimality is 99%. If we did not normalize utility, the optimal solution would be weighted towards voters with higher absolute values of subjective utility.

## Results Across Preference Profiles

I've implemented two different classes of preference profiles, with a variety of concrete profiles under each.


### Square Root Preference Profiles

Square root profiles have the form $`Uᵢ(x) = ∑ⱼ b_{i,j}√x_j`$. These are concave and monotonically increasing, which is appropriate for budget allocation settings where there are diminishing marginal utility for the competing projects, but marginal utility never turns negative. This means voters always prefer to "use up" the whole budget, and this their optimal allocation vectors will always sum to one.

Here are the mean results for each mechanism across all Square Root preference profiles.

    ┌────────────────────────┬─────────────┬─────────────────┬─────────────────────┬───────────────┬────────────────────┐
    │ Mechanism              │ Mean Rounds │ Equilibrium (%) │ Mean Optimality (%) │ Mean Envy (%) │ Mean Alignment (%) │
    ├────────────────────────┼─────────────┼─────────────────┼─────────────────────┼───────────────┼────────────────────┤
    │ CoordinatewiseMean     │        2.83 │           100.0 │                98.8 │           8.2 │               69.8 │
    │ CoordinatewiseMedian   │         2.0 │           100.0 │                98.4 │          16.6 │               89.6 │
    │ GeometricMedian        │         4.0 │            83.3 │                98.6 │          14.2 │               86.3 │
    │ PairwiseMeanTradeoff   │        2.17 │           100.0 │                98.2 │           7.8 │               77.2 │
    │ PairwiseMedianTradeoff │        4.33 │           100.0 │                99.6 │          10.1 │               81.9 │
    │ PairwiseProbability    │        1.67 │           100.0 │                98.2 │           6.6 │               97.7 │
    │ QuadraticFunding       │         3.0 │           100.0 │                99.4 │           8.4 │               66.2 │
    │ QuadraticVariant       │        3.17 │           100.0 │                99.2 │           9.0 │               75.4 │
    │ SAP                    │        1.67 │           100.0 │                95.1 │          26.9 │               83.7 │
    │ SAPScaled              │        5.67 │            50.0 │                95.0 │          26.4 │               83.9 │
    └────────────────────────┴─────────────┴─────────────────┴─────────────────────┴───────────────┴────────────────────┘


### Quadratic Preference Profiles

Quadratic profiles have the form $`Uᵢ(Y) = ∑ⱼ 2b_{i,j}x_j - x_j^2`$. These are concave and single-peaked, which is appropriate for budget allocation settings where marginal utilities eventually turn negative. In these settings, voters may not always prefer to use up the whole budget (depending on where the peak is).

Here are the mean results for each mechanism across all Quadratic preference profiles.

    ┌────────────────────────┬─────────────┬─────────────────┬─────────────────────┬───────────────┬────────────────────┐
    │ Mechanism              │ Mean Rounds │ Equilibrium (%) │ Mean Optimality (%) │ Mean Envy (%) │ Mean Alignment (%) │
    ├────────────────────────┼─────────────┼─────────────────┼─────────────────────┼───────────────┼────────────────────┤
    │ CoordinatewiseMean     │        5.75 │            75.0 │                90.7 │          28.0 │               56.0 │
    │ CoordinatewiseMedian   │        1.25 │           100.0 │                99.0 │           6.1 │               94.2 │
    │ GeometricMedian        │        2.75 │           100.0 │                98.6 │          11.8 │               80.9 │
    │ PairwiseMeanTradeoff   │         4.0 │           100.0 │                74.9 │          40.3 │               58.9 │
    │ PairwiseMedianTradeoff │        4.25 │            75.0 │                74.9 │          40.0 │               70.0 │
    │ PairwiseProbability    │         2.0 │           100.0 │                73.9 │          39.3 │               89.9 │
    │ QuadraticFunding       │         5.5 │            75.0 │                75.0 │          40.2 │               49.3 │
    │ QuadraticVariant       │         5.0 │            75.0 │                75.0 │          39.9 │               53.0 │
    │ SAP                    │         1.5 │           100.0 │                89.9 │          30.3 │               92.0 │
    │ SAPScaled              │        5.75 │            50.0 │                73.0 │          45.5 │               72.2 │
    └────────────────────────┴─────────────┴─────────────────┴─────────────────────┴───────────────┴────────────────────┘

Note that many mechanisms produce sub-optimal results with quadratic profiles but work well with square root profiles. Mechanisms such as Pairwise Probability are designed under the assumption that user's *relative* preferences between two items are constant -- which is not the case with quadratic profiles.

### Detailed Simulation Logs

Summary results for each preference profile are available [here](https://github.com/johnwarden/mecsim/blob/master/output/summary.txt)

Detailed simulation logs for each mechanism/preference combination are available [here](https://github.com/johnwarden/mecsim/blob/master/output/log)

## Limitations and Caveats

- The simulation uses Julia's Optim.jl with Nelder-Mead, which is pretty good but it might sometimes find a local optimum and not discover the voter's absolute best response.
- This simulations aren't a substitute for a more formal equilibrium analysis. It assumes players behave in a certain way:
    - Voters always start by reporting their ideal point and only change their reports in response to other voters.
    - Voters play in a fixed order and always play the current "best response", defined as the response that maximizes utility *given the other players' current responses*. This may not be how a rational voter can maximizes expected utility in real life. Specifically, "best-responding" may be a *bad* move for some mechanisms. For example skipping a turn, and allowing the next voter to best-respond, could produce better outcomes in some cases.
    - There are no attempts by groups to collude.

- So rational agent really trying to optimize their results might find other ways to manipulate the output. 
- On the other hand, the simulation does show that in most cases there seems to be a nash equilibrium where no voter can profitably deviate.


## Example

### Defining Mechanisms and Preferences

To implement a new mechanism or preference profile, add a .jl file under the `mechanisms/` or `preferences/` folders directory.

A mechanism is a function that takes an allocation matrix as an input and returns a single allocation vector. The final allocations will be capped by the simulator so that the sum is <= 1.0. 

A preference profile is defined by 1) utility for a given voter allocation vector and 2) a set of optimal points. Helper function will create a square-root profile or quadratic profile for some matrix of coefficients b. 

#### Example Preferences: `preferences/HighConflictTwoVoters.jl`

In this preference profile, voter 1 strongly prefers item 1 over item 2, and voter 2 strongly prefers item 2 over item1.

```julia

# Diametrically opposite preferences between two voters
return sqrt_preferences([
    5.0  1.0
    1.0  3.0
])

```

The simulation generates a plot of the preference profile in output/plots

![Condorcet Cycle Preference Profile](output/plots/preferences/HighConflictTwoVoters.png)

#### Example Mechanism: `SAP.jl`


```julia

# Select at Percentile (SAP) mechanism based on Steve Vitka's SAPTool
# For each column:
# 1. Sort values in ascending order
# 2. Select highest row where sum ≤ 1.0
# 3. Return those values (may not sum to 1.0)
function SAP(reports)
    n, m = size(reports)
    sorted_votes = sort(reports, dims=1)
    row_sums = sum.(eachrow(sorted_votes))
    sp = findlast(≤(1.0), row_sums)
    
    return isnothing(sp) ? zeros(m) : sorted_votes[sp, :]
end

return SAP


```

#### Run the Simulation

    ❯ just sim mechanisms/SAP.jl preferences/sqrt/HighConflictTwoVoters.jl
    time julia --project Main.jl mechanisms/SAP.jl preferences/sqrt/HighConflictTwoVoters.jl
    Loading preferences /Users/jwarden/Dropbox/social-protocols/mecsim/preferences/sqrt/HighConflictTwoVoters.jl
    optimalPoints =
    2×2 Matrix{Float64}:
     0.961538  0.0384615
     0.1       0.9
    overall_optimal_point = [0.5620173672946042, 0.43798263270539584]
    [Running] Pref=HighConflictTwoVoters | Mech=SAP | Round=2 | Alloc=0.10,0.90,... | Optimality=86.5 | Align=46.6 ✅

    Preference Profile: HighConflictTwoVoters

    Optimal Points and Utilities:
    ┌──────┬────────────────────┬─────────────────┐
    │ User │ Optimal Allocation │ Optimal Utility │
    ├──────┼────────────────────┼─────────────────┤
    │    1 │   [0.962, 0.038]   │             1.0 │
    │    2 │     [0.1, 0.9]     │             1.0 │
    │  ALL │   [0.562, 0.438]   │           0.865 │
    └──────┴────────────────────┴─────────────────┘


    Mechanism Outcomes for HighConflictTwoVoters:
    ┌───────────┬────────┬────┬─────────────────────────┬───────────┬──────┬───────┬────────┐
    │ Mechanism │ Rounds │ Eq │ Reports                 │ Alloc     │ Opt% │ Envy% │ Align% │
    ├───────────┼────────┼────┼─────────────────────────┼───────────┼──────┼───────┼────────┤
    │ SAP       │      2 │ ✓  │ [0.03,0.57];[0.10,0.90] │ 0.10,0.90 │ 86.5 │  50.4 │   46.6 │
    └───────────┴────────┴────┴─────────────────────────┴───────────┴──────┴───────┴────────┘


    ================================================================================
    OVERALL SUMMARY ACROSS ALL PREFERENCES
    ================================================================================
    ┌───────────┬─────────────┬─────────────────┬─────────────────────┬───────────────┬────────────────────┐
    │ Mechanism │ Mean Rounds │ Equilibrium (%) │ Mean Optimality (%) │ Mean Envy (%) │ Mean Alignment (%) │
    ├───────────┼─────────────┼─────────────────┼─────────────────────┼───────────────┼────────────────────┤
    │ SAP       │         2.0 │           100.0 │                86.5 │          50.4 │               46.6 │
    └───────────┴─────────────┴─────────────────┴─────────────────────┴───────────────┴────────────────────┘


#### Simulation Output

And a detailed log of the simulation is output to: output/logs/SAP/HighConflictTwoVoters.txt

In this case, voter 1 modifies their proposed allocation to best-respond to voter 2. After this, the voters are already in equilibrium -- neither voter can improve their utility by changing their vote.

    Optimal points: [0.9615384615384615 0.038461538461538436; 0.1 0.9]
    Starting allocation: [0.1, 0.038461538461538436]

    === Round 1 ===
    Current report matrix:
    2×2 Matrix{Float64}:
     0.961538  0.0384615
     0.1       0.9
    Current allocation: [0.1, 0.038461538461538436]
    Voter 1's turn.
      Best response = [0.03396559495192303, 0.5661207932692303]
      New allocation: [0.1, 0.9]
      => Voter 1 improves by switching to best response
      Old utility = 0.34854837493455965
      New utility = 0.49613893835683387
      Honest utility = 0.34854837493455965
      Incentive Alignment = 0.46642345628490733
    Voter 2's turn.
      => No improvement found; voter 2 stays with old report.
      Old utility = 1.0
      New utility = 0.9999969722338864
      Honest utility = 1.0
      Incentive Alignment = 0.46642345628490733

    === Round 2 ===
    Current report matrix:
    2×2 Matrix{Float64}:
     0.0339656  0.566121
     0.1        0.9
    Current allocation: [0.1, 0.9]
    Voter 1's turn.
      => No improvement found; voter 1 stays with old report.
      Old utility = 0.49613893835683387
      New utility = 0.49613893835683387
      Honest utility = 0.34854837493455965
      Incentive Alignment = 0.46642345628490733
    Voter 2's turn.
      => No improvement found; voter 2 stays with old report.
      Old utility = 1.0
      New utility = 0.9999969722338864
      Honest utility = 1.0
      Incentive Alignment = 0.46642345628490733
    Converged! Maximum improvement in utility < 0.0001.
    Final reports:
    2×2 Matrix{Float64}:
     0.0339656  0.566121
     0.1        0.9
    Final Allocation: [0.1, 0.9]
    Mean Utility: 0.7480694691784169
    Optimality: 0.7480694691784169
    Envy: 50.386106164316615
    Incentive Alignment: 0.46642345628490733


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

## Output Files

- Summary tables: `output/log/summary.txt`
- Detailed log files organized by mechanism: `output/log/[mechanism_name]/[preference_name].txt`
- Preference visualization plots: `output/plots/preferences/[preference_name].png`

