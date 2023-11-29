library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

fit = readRDS(here::here("ATACCC/fit.rds"))

false_pos = spread_draws(fit, l_fp) |>
    mutate(fp = exp(-l_fp))

false_pos |>
    median_qi(fp)

false_pos |>
    ggplot(aes(exp(-l_fp))) +
    geom_density()
