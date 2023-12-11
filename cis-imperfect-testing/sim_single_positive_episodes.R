suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

sims = readRDS(here::here("cisRuns-output/sim_reps.rds")) |>
    as_tibble()
    
p_single_pos = sims |>
    summarise(
        .by = c(.draw, scenario_name),
        num_single = mean(n_pos == 1)
    ) |>
    mutate(
        sensitivity = stringr::str_split_fixed(scenario_name, "-", 3)[,3] |>
            stringr::str_to_sentence()
    ) |>
    ggplot() +
    geom_bar(aes(num_single, fill = sensitivity)) +
    geom_vline(aes(xintercept = 3730/4837, colour = "Observed"), size = 1) +
    standard_plot_theming() +
    labs(
        x = "Proportion of episodes",
        y = "Number of simulations",
        fill = "Test sensitivity",
        colour = ""
    )

ggsave(
    filename = here::here("cis-imperfect-testing/sim-single-positive-episodes.png"),
    plot = p_single_pos,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)