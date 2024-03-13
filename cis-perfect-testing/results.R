suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

tbl_posteriors = readRDS(here::here("cisRuns-output/perfect_posteriors.rds")) |>
    mutate(
        survival_prior = case_match(
            survival_prior,
            "ATACCC" ~ "Combination",
            "RW2" ~ "Smoothing (RW2)",
            "vague" ~ "Independent (vague)"
        ),
    )
truth = readRDS(here::here("cisRuns-output/input_curves.rds")) |>
  filter(source == "Combined")

surv_nat_plot = tbl_posteriors |>
      ggplot() +
      ggdist::geom_lineribbon(
        aes(time, S, ymin = S.lower, ymax = S.upper, fill = survival_prior, colour = survival_prior),
        linewidth = 1, alpha = 0.3
    ) +
    geom_line(aes(time, S), data = truth) +
    theme_survival_time_series() +
    ylab("S(t)")

surv_log_plot = surv_nat_plot +
    scale_y_log10(
        minor_breaks = map(
            -1:-3,
            ~seq(from = 10^.x, to = 10^(.x+1), by = 10^.x)
        ) |>
        unlist()
    ) +
    coord_cartesian(c(0, 100), c(0.001, 1))

surv_plot = surv_nat_plot + surv_log_plot + plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

ggsave(
    filename = here::here("cis-perfect-testing/survival-results.pdf"),
    plot = surv_plot,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

hazard_plot = tbl_posteriors |>
      ggplot() +
      ggdist::geom_lineribbon(
        aes(time, lambda, ymin = lambda.lower, ymax = lambda.upper, fill = survival_prior, colour = survival_prior),
        linewidth = 1, alpha = 0.3
    ) +
    geom_line(aes(time, lambda), data = truth) +
    theme_survival_time_series() +
    ylab("λ(t)")
ggsave(
    filename = here::here("cis-perfect-testing/hazard-results.pdf"),
    plot = hazard_plot,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300,
    device = cairo_pdf
)
