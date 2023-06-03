library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

tbl_posteriors = readRDS(here::here("cisRuns-output/perfect_posteriors.rds"))
truth = readRDS(here::here("cisRuns-output/input_curves.rds")) |>
  filter(source == "Combined")

theme_survival_time_series = function() {
    rlang::list2(
        standard_plot_theming(),
        scale_x_continuous(breaks = 0:100*14, minor_breaks = 0:100*2, limits = c(0, 50))
    )
}

surv_plot = tbl_posteriors |>
    filter(.width == 0.95, survival_prior != "ATACCC-old", missed_prior == "vague") |>
      ggplot() +
      ggdist::geom_lineribbon(
        aes(time, S, ymin = S.lower, ymax = S.upper, fill = survival_prior, colour = survival_prior),
        linewidth = 1, alpha = 0.3
    ) +
    geom_line(aes(time, S), data = truth) +
    theme_survival_time_series()
ggsave(
    filename = here::here("cis-perfect-testing/survival-results.png"),
    plot = surv_plot,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

hazard_plot = tbl_posteriors |>
    filter(.width == 0.95, survival_prior != "ATACCC-old", missed_prior == "vague") |>
      ggplot() +
      ggdist::geom_lineribbon(
        aes(time, lambda, ymin = lambda.lower, ymax = lambda.upper, fill = survival_prior, colour = survival_prior),
        linewidth = 1, alpha = 0.3
    ) +
    geom_line(aes(time, lambda), data = truth) +
    theme_survival_time_series()
ggsave(
    filename = here::here("cis-perfect-testing/hazard-results.png"),
    plot = hazard_plot,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

tbl_samples = readRDS(here::here("cisRuns-output/vague_perfect_hazard_posterior_samples.rds"))
hazard_pairs = tbl_samples |>
    filter(between(time, 10, 20)) |>
    pivot_wider(names_from = time, values_from = lambda, id_cols = .draw) |>
    select(!.draw) |>
    GGally::ggpairs()
ggsave(
    filename = here::here("cis-perfect-testing/hazard-pairs-results.png"),
    plot = hazard_pairs,
    width = 15,
    height = 15,
    units = "cm",
    dpi = 300
)