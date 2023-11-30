library(dplyr)
library(ggplot2)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("SEIR/utils.R"))

final_states = readr::read_csv(here::here("SEIR/CIS/final_state.csv")) |>
    mutate(
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        region = region_labels(region),
    ) |>
    select(!c(chain, iteration)) |>
    filter(.iteration >= 500e3)

attack_rate = final_states |>
    filter(state == "R") |>
    select(!state) |>
    group_by(region, age) |>
    median_qi(.simple_names = FALSE)

ggplot(attack_rate, aes(x = age, y = occupancy, colour = age)) +
    geom_pointrange(aes(ymin = occupancy.lower, ymax = occupancy.upper)) +
    facet_wrap(~ region) +
    standard_plot_theming() +
    labs(x = "", y = "Attack rate", colour = "Age") +
    scale_x_discrete(breaks = c()) +
    coord_cartesian(y = c(0, NA))
    theme(text = element_text(size = 20)
