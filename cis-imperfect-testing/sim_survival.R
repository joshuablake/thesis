suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

tbl_posteriors = readRDS(here::here("cisRuns-output/all_posteriors.rds")) |>
    filter(
        .width == 0.95, # Credible intervals are narrow anyway so only show 95%
        is.na(type),
        survival_prior %in% c(
            "ATACCC-new",
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
            "vague" ~ "Independent (vague)"
        ),
    )
truth = readRDS(here::here("cisRuns-output/input_curves.rds")) |>
  filter(source == "Combined")

p_constant_sensitivity = tbl_posteriors |>
    filter(sensitivity.simulation == sensitivity.model, sensitivity.simulation < 1) |>
    ggplot() +
    ggdist::geom_lineribbon(aes(time, S, ymin = S.lower, ymax = S.upper, fill = survival_prior, colour = survival_prior), linewidth = 1, alpha = 0.3) +
    facet_wrap(~ sensitivity.model) +
    geom_line(aes(time, S), data = truth) +
    theme_survival_time_series()
ggsave(
    filename = here::here("cis-imperfect-testing/sim-constant-sensitivity.png"),
    plot = p_constant_sensitivity,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

p_misspecified_sensitivity = tbl_posteriors |>
    filter(sensitivity.simulation == 0.8, survival_prior == "Combination") |>
    mutate(sensitivity.model = factor(sensitivity.model)) |>
    ggplot() +
    ggdist::geom_lineribbon(aes(time, S, ymin = S.lower, ymax = S.upper, fill = sensitivity.model, colour = sensitivity.model), linewidth = 1, alpha = 0.3) +
    facet_wrap(~ sensitivity.model) +
    geom_line(aes(time, S), data = truth, alpha = 0.5) +
    theme_survival_time_series() +
    labs(
        colour = expression(p[sens]),
        fill = expression(p[sens])
    )
ggsave(
    filename = here::here("cis-imperfect-testing/sim-misspecified-sensitivity.png"),
    plot = p_misspecified_sensitivity,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

p_variable_sensitivity = tbl_posteriors |>
    filter(is.na(sensitivity.simulation), survival_prior == "Combination") |>
    mutate(sensitivity.model = factor(sensitivity.model)) |>
    ggplot() +
    ggdist::geom_lineribbon(aes(time, S, ymin = S.lower, ymax = S.upper, fill = sensitivity.model, colour = sensitivity.model), linewidth = 1, alpha = 0.3) +
    facet_wrap(~ sensitivity.model) +
    geom_line(aes(time, S), data = truth, alpha = 0.5) +
    theme_survival_time_series() +
    labs(
        colour = expression(p[sens]),
        fill = expression(p[sens])
    )
ggsave(
    filename = here::here("cis-imperfect-testing/sim-variable-sensitivity.png"),
    plot = p_variable_sensitivity,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

# tbl_posteriors |>
#     ggplot() +
#     ggdist::geom_lineribbon(aes(time, S, ymin = S.lower, ymax = S.upper), linewidth = 1, alpha = 0.3) +
#     facet_grid(model_name~sim_name) +
#     geom_line(aes(time, S), data = truth, alpha = 0.5) +
#     theme_survival_time_series() +
#     labs(
#         colour = expression(p[sens]),
#         fill = expression(p[sens])
#     )

# tbl_posteriors |>
#     count(sim_name, model_name, time) |>
#     filter(n > 1)

# ggsave(
#     filename = here::here("cis-imperfect-testing/sim-all.png"),
#     width = 15,
#     height = 50,
#     units = "cm",
#     dpi = 300
# )

# tbl_posteriors |>
#     filter(time == 5, S < 0.8, !stringr::str_detect(model_name, "inform-total")) |>
#     arrange(S) |>
#     select(model_name, sim_name) 
