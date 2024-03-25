library(dplyr)
library(ggplot2)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("SEIR/utils.R"))
source(here::here("transmission/utils.R"))

final_states = readr::read_csv(here::here("SEIR/CIS/final_state.csv"), show_col_types = FALSE) |>
    mutate(
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        region = normalise_region_names(region),
    ) |>
    select(!c(chain, iteration)) |>
    filter(.iteration >= 500e3)

raw_params = readr::read_csv(here::here("SEIR/CIS/params.csv"), show_col_types = FALSE) |>
    filter(stringr::str_starts(parameter, "pi"))#
initial_attack = raw_params |>
    separate_wider_position(parameter, c(3, "age" = 1, 1)) |>
    transmute(
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        region = normalise_region_names(region),
        age_int = as.integer(age) + 1,
        initial_attack = 1 - expit(value),
    )

attack_rate = final_states |>
    filter(state == "S") |>
    mutate(
        occupancy = 1 - occupancy,
        age = forcats::as_factor(age),
        age_int = as.integer(age),
    ) |>
    # filter(region=="North East",age_int==1,.chain==1,)#.iteration==1)
    left_join(
        initial_attack,
        by = c(
            "region", "age_int",
            ".chain", ".iteration"
        )
    ) |>
    select(!state) |>
    mutate(
        increase = occupancy - initial_attack,
        age = normalise_age_groups(age),
    ) |>
    group_by(region, age) |>
    median_qi(occupancy, increase, initial_attack, .simple_names = FALSE)
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
    height = 5,
    device = cairo_pdf
)
