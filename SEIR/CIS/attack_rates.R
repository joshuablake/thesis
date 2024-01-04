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
    filter(state == "S") |>
    mutate(occupancy = 1 - occupancy) |>
    select(!state) |>
    group_by(region, age) |>
    median_qi(.simple_names = FALSE)
readr::write_csv(attack_rate, here::here("SEIR/CIS/attack_rates.csv"))

p_attack_rate = ggplot(attack_rate, aes(x = age, y = occupancy, colour = age)) +
    geom_pointrange(
        aes(ymin = occupancy.lower, ymax = occupancy.upper),
        size = 0.1
    ) +
    facet_wrap(~ region) +
    standard_plot_theming() +
    labs(x = "", y = "Attack rate", colour = "Age") +
    scale_x_discrete(breaks = c()) +
    coord_cartesian(y = c(0, NA))
ggsave(
    filename = here::here("SEIR/CIS/attack_rates.pdf"),
    plot = p_attack_rate,
    width = 5,
    height = 5
)
