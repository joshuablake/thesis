
library(dplyr)
library(ggplot2)
library(purrr)
library(rstan)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

hakki_fit = here::here("ATACCC/fit.rds") |>
    readRDS()
simplified_fit = here::here("ATACCC/fit2.rds") |>
    readRDS()

summary(hakki_fit)$summary |>
    as_tibble(rownames = "Param") |>
    filter(!stringr::str_detect(Param, "\\[")) |>
    arrange(desc(Rhat)) |>
    select(Param, Rhat) |>
    print(n = 100)

spread_draws(hakki_fit, l_fp) |>
    ggplot(aes(.iteration, l_fp, colour = factor(.chain))) +
    geom_line()

spread_draws(simplified_fit, l_fp) |>
    ggplot(aes(.iteration, l_fp, colour = factor(.chain))) +
    geom_line()
