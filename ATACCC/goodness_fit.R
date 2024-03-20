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
  
ggsave(
  filename = "ATACCC/fit_individual_55.pdf",
  plot = p_55,
  width = 15,
  height = 9,
  units = "cm",
  dpi = 300
)

posterior_summary = posterior_predictive |>
  group_by(i, day) |>
  median_qi(yrep) 
all_individuals = unique(posterior_summary$i)
selected_individuals = all_individuals[all_individuals > 8 & all_individuals %% 2 == 1]
p_fits = posterior_summary |>
  filter(i %in% selected_individuals) |>
  ggplot() +
  geom_lineribbon(
    aes(day, yrep, ymin = .lower, ymax = .upper),
    show.legend = FALSE
  ) +
  geom_point(
    aes(day, y, colour = result),
    size = 0.7,
    data = tbl_data |>
      filter(i %in% selected_individuals)
  ) +
  facet_wrap(~i, ncol = 5) +
  theme_trajectory()
ggsave(
    filename = here::here("ATACCC/fits.pdf"),
    plot = p_fits,
    height = 15,
    width = 15,
    units = "cm",
    dpi = 300
)
