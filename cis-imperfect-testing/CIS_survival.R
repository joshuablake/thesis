suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

posterior_draws = readRDS(here::here("cis-imperfect-testing/STATS17701/draws.rds"))

posterior_draws |>
    filter(sensitivity == 1)


posterior_draws |>
    filter(time == 1, .draw == 1, missed_model == "total") |>
    count(
        survival_prior,
        sensitivity,
        missed_model,
        r
    )
    filter(survival_prior == "Informative") |>

