suppressMessages(library(dplyr))
library(ggplot2)
library(purrr)
suppressMessages(library(rstan))
library(patchwork)
library(tidybayes)
source(here::here("ATACCC/trajectory_functions.R"))
source(here::here("utils.R"))

fit = here::here("ATACCC/fit2.rds") |>
    readRDS()

tbl_data = here::here("ATACCC/data.rds") |>
    readRDS() |>
    mutate(group = case_when(
        (vaccinated == FALSE) & (WGS == "Pre-Alpha") ~ 1,
        (vaccinated == FALSE) & (WGS == "Alpha") ~ 1,
        (vaccinated == FALSE) & (WGS == "Delta") ~ 1,
        (vaccinated == TRUE) & (WGS == "Delta") ~ 2
    )) |>
    filter(!is.na(group), !is.na(copy)) |> 
    mutate(
        i = as.integer(factor(id_sub, levels=unique(id_sub))),
        y = if_else(
            copy == 1,
            0,
            log(copy) - 3.43
        ),
        result = if_else(
            y > 0,
            "Positive",
            "Negative"
        ),
    )

theme_trajectory = function() {
  list(
    standard_plot_theming(),
    coord_cartesian(c(-1, 20), c(0, 20)),
    scale_y_continuous(breaks = c(0, 10, 20), minor_breaks = seq(0, 20, 5)),
    theme(
      legend.position = "bottom"
    ),
    labs(
      x = "Time since first test (days)",
      y = "Log viral load",
      colour = ""
    ) 
  )
}

posterior_predictive = spread_draws(fit, pred_vl[m], v_s) |>
  ungroup() |>
  mutate(
    i = (m - 1) %/% 42 + 1,
    day = (m - 1) %% 42 - 14,
    yrep = rnorm(n(), pred_vl, v_s),
  )

p_55 = posterior_predictive |>
  filter(i == 55) |>
  group_by(.chain, day) |>
  median_qi(yrep) |>
  mutate(
    .chain = factor(.chain),
  ) |>
  ggplot() +
  geom_point(aes(day, y, colour = result), data = filter(tbl_data, i == 55)) +
  geom_lineribbon(
    aes(day, yrep, ymin = .lower, ymax = .upper, fill = .chain),
    alpha = 0.1, show.legend = FALSE, linewidth = 0.1
  ) +
  theme_trajectory()
  
save_plot(
  filename = "ATACCC/fit_individual_55.pdf",
  plot = p_55,
  height = 9
)

produce_gof_plot = function(individuals) {
  p_fits = posterior_summary |>
    filter(i %in% individuals) |>
    ggplot() +
    geom_lineribbon(
      aes(day, yrep, ymin = .lower, ymax = .upper),
      show.legend = FALSE
    ) +
    geom_point(
      aes(day, y, colour = result),
      size = 0.7,
      data = tbl_data |>
        filter(i %in% individuals)
    ) +
    facet_wrap(~i, ncol = 5) +
    theme_trajectory()
}

posterior_summary = posterior_predictive |>
  group_by(i, day) |>
  median_qi(yrep) 
all_individuals = unique(posterior_summary$i)
selected_individuals = all_individuals[all_individuals > 8 & all_individuals %% 2 == 1]
appendix_individuals = all_individuals[!all_individuals %in% selected_individuals]

save_plot(
    filename = here::here("ATACCC/fits.pdf"),
    plot = produce_gof_plot(selected_individuals),
    caption_lines = 6
)

save_plot(
    filename = here::here("ATACCC/appendix_fits.pdf"),
    plot = produce_gof_plot(appendix_individuals),
    caption_lines = 6
)
