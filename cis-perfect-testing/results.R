suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

tbl_posteriors = readRDS(here::here("cisRuns-output/perfect_posteriors.rds")) |>
    filter(
        .width == 0.95, # Credible intervals are narrow anyway so only show 95%
        survival_prior %in% c(
            "ATACCC-new",
            "RW2-infer-sigma",
            "vague"
        ),
        # Use the reference prior on the number of missed infections as this doesn't matter
        missed_prior == "vague", 
        missing_model == "total"
    ) |>
    mutate(
        survival_prior = case_match(
            survival_prior,
            "ATACCC-new" ~ "Combination",
            "RW2-infer-sigma" ~ "Smoothing (RW2)",
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
    dpi = 300
)

tbl_samples = readRDS(here::here("cisRuns-output/vague_perfect_hazard_posterior_samples.rds"))
hazard_pairs = tbl_samples |>
    filter(between(time, 10, 20)) |>
    pivot_wider(names_from = time, values_from = lambda, id_cols = .draw) |>
    select(!.draw) |>
    GGally::ggpairs()
ggsave(
    filename = here::here("cis-perfect-testing/hazard-pairs-results.pdf"),
    plot = hazard_pairs,
    width = 15,
    height = 15,
    units = "cm",
    dpi = 300
)