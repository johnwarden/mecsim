# Create a sqrt preference from a sample of reports from the SAP tool.
# We can derive the coefficients of the implied utility functions from the users reports.

sampleSAPToolReports = [
    200 454 70  6   38  25  0   0   0   30  55
    50  233 0   6   67  98  0   70  0   30  16
    60  67  0   6   72  32  8   0   400 50  15
    65  0   0   6   57  44  20  0   0   50  78
    200 0   300 6   42  92  40  0   0   30  203
    1  89  100 6   61  96  14  100 0   0   489
    1   116 300 6   107 110 8   34  100 30  0
    55  120 653 6   25  23  24  70  0   0   24
    200 140 200 6   25  100 20  70  100 40  27
    173 130 0   6   12  100 16  0   0   50  150
]

prefMatrix = sqrt_preference_matrix_from_reports(sampleSAPToolReports)

return sqrt_preferences(prefMatrix)
