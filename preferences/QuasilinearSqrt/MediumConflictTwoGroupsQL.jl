# Diametrically opposite preferences between two users
begin 
    x = [
        .6  .4
        .6  .4
        .6  .4
        .6  .4
        .6  .4
        .3  .7
        .3  .7
    ]

    return quasilinear_sqrt_preferences(sqrt.(x) ./ sum(sqrt.(x), dims=2) * 4)
end