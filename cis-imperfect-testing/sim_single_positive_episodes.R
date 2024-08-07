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
        .by = c(.draw, sensitivity),
        num_single = mean(n_pos == 1)
    ) |>
    mutate(sensitivity = as.character(sensitivity)) |>
    replace_na(list(sensitivity = "Varied")) |>
    ggplot() +
    geom_bar(aes(num_single, fill = sensitivity)) +
    geom_vline(aes(xintercept = 3730/4837, colour = "Observed"), linewidth = 1) +
    standard_plot_theming() +
    labs(
        x = "Proportion of episodes",
        y = "Number of simulations",
        fill = "Test sensitivity",
        colour = ""
    )

save_plot(
    filename = here::here("cis-imperfect-testing/sim-single-positive-episodes.pdf"),
    plot = p_single_pos,
    height = 9
)