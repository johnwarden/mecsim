
return quadraticPreferenceProfile([
    5.0  2.0  1.0
    1.0  5.0  2.0
    2.0  1.0  5.0
])

# ┌──────────────────────┬────────┬─────────────┬───────────────────────┬──────────────┬────────────┬───────────┐
# │ Mechanism            │ Rounds │ Equilibrium │   Final Allocation    │ Mean Utility │ Optimality │ Alignment │
# ├──────────────────────┼────────┼─────────────┼───────────────────────┼──────────────┼────────────┼───────────┤
# │ CoordinatewiseMedian │      9 │        true │ [0.319, 0.35, 0.331]  │        4.618 │     99.982 │     0.828 │
# │ PairwiseMean         │      5 │        true │ [0.333, 0.333, 0.333] │        4.619 │      100.0 │     0.821 │
# │ PairwiseMedian       │     10 │       false │ [0.33, 0.337, 0.333]  │        4.619 │     99.999 │     0.818 │
# │ PairwisePercentage   │      1 │        true │ [0.333, 0.333, 0.333] │        4.619 │      100.0 │       1.0 │
# │ QuadraticFunding     │      5 │        true │ [0.337, 0.333, 0.331] │        4.619 │     99.999 │     0.792 │
# │ SAPTool              │      2 │        true │ [0.133, 0.733, 0.133] │        4.231 │     91.605 │      0.75 │
# │ SAPToolScaled        │     10 │       false │ [0.408, 0.037, 0.555] │        4.203 │     90.997 │     0.819 │
# │ SelectAtMedian       │      2 │        true │ [0.133, 0.733, 0.133] │        4.231 │     91.605 │      0.75 │
# └──────────────────────┴────────┴─────────────┴───────────────────────┴──────────────┴────────────┴───────────┘

