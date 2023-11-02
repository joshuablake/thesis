library(dplyr)
library(tidyr)
library(tidybayes)
modified = readRDS(here::here("ATACCC/fit2.rds"))
mean_vals = spread_draws(modified, vgrow[i, g])
mean_vals |>
    ungroup() |>
    mutate(exp_vgrow = exp(vgrow)) |>
    group_by(i, g) |>
    median_qi() |>
    print(width = Inf)
