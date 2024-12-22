
return quadraticPreferenceProfile([
    5.0  2.0  1.0
    6.0  3.0  1.0
    4.0  2.0  2.0
])

# ┌──────────────────────┬────────┬─────────────┬───────────────────────┬──────────────┬────────────┬───────────┐
# │ Mechanism            │ Rounds │ Equilibrium │   Final Allocation    │ Mean Utility │ Optimality │ Alignment │
# ├──────────────────────┼────────┼─────────────┼───────────────────────┼──────────────┼────────────┼───────────┤
# │ CoordinatewiseMedian │     10 │       false │ [0.691, 0.249, 0.06]  │        5.647 │     99.483 │     0.387 │
# │ PairwiseMean         │      6 │        true │ [0.65, 0.195, 0.155]  │        5.587 │     98.418 │     0.734 │
# │ PairwiseMedian       │     10 │       false │ [0.807, 0.163, 0.029] │        5.664 │      99.78 │      0.48 │
# │ PairwisePercentage   │      1 │        true │ [0.507, 0.288, 0.205] │        5.417 │     95.421 │       1.0 │
# │ QuadraticFunding     │      7 │        true │ [0.667, 0.167, 0.167] │         5.58 │     98.292 │     0.292 │
# │ SAPTool              │      3 │        true │ [0.783, 0.167, 0.051] │        5.676 │     99.994 │     0.987 │
# │ SAPToolScaled        │     10 │       false │ [0.703, 0.256, 0.041] │        5.643 │     99.406 │      0.26 │
# │ SelectAtMedian       │      3 │        true │ [0.783, 0.167, 0.051] │        5.676 │     99.994 │     0.987 │
# └──────────────────────┴────────┴─────────────┴───────────────────────┴──────────────┴────────────┴───────────┘