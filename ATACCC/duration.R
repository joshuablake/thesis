library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

posterior_draws = readRDS(here::here("ATACCC-distributions/posterior_samples.rds"))
posterior_draws2 = readRDS(here::here("ATACCC-distributions/posterior_samples2.rds"))

# posterior_draws |>
#     group_by(.draw) |>
#     arrange(time, .by_group = TRUE) |>
#     summarise(median = time[min(which(F >= 0.5))]) |>
#     median_qi()

# posterior_draws2 |>
#     group_by(.draw) |>
#     arrange(time, .by_group = TRUE) |>
#     summarise(median = time[min(which(F >= 0.5))]) |>
#     median_qi()

p_durations = bind_rows(
    posterior_draws |>
        mutate(Group = "Unvaccinated"),
    posterior_draws2 |>
        mutate(Group = "Vaccinated")
) |>
    ggplot() +
    stat_lineribbon(
        aes(time, S, fill = Group, colour = Group),
        alpha = 0.3,
        .width = 0.95
    ) +
    theme_survival_time_series () +
    coord_cartesian(xlim = c(0, 40))
save_plot(
    filename = here::here("ATACCC/duration.pdf"),
    plot = p_durations,
    height = 9
)

bind_rows(
    posterior_draws |>
        mutate(Group = "Unvaccinated"),
    posterior_draws2 |>
        mutate(Group = "Vaccinated")
) |>
    summarise(
        median = time[min(which(F >= 0.5))],
        .by = c(.draw, Group),
    ) |>
    pivot_wider(
        names_from = Group,
        values_from = median,
        id_cols = .draw
    ) |>
    mutate(vaccinated_shorter = Vaccinated < Unvaccinated) |>
    summarise(p_vaccinated_shorter_median = mean(vaccinated_shorter))
