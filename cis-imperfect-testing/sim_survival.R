suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

base_plot = function(df, colour_curves_by, colour_key = NULL, facet_suffix = "") {
    p = df |>
        mutate(
            sensitivity.model = factor(sensitivity.model),
            facet_label = latex2exp::TeX(glue::glue(
                "({LETTERS[dense_rank(sensitivity.model)]})\\ $p_{{sens}}{facet_suffix} = {sensitivity.model}"
            ), output = "character")
        ) |>
        ggplot() +
        ggdist::geom_lineribbon(
            aes(
                time, S, ymin = S.lower, ymax = S.upper,
                fill = {{ colour_curves_by }}, colour = {{ colour_curves_by }}
            ),
            linewidth = 1, alpha = 0.3
        ) +
        facet_wrap(~facet_label, labeller = label_parsed) +
        geom_line(aes(time, S), data = truth, alpha = 0.5) +
        theme_survival_time_series()

    if (!is.null(colour_key)) {
        p = p +
            labs(
                colour = colour_key,
                fill = colour_key
            )
    }
    return(p)
}

tbl_posteriors = readRDS(here::here("cisRuns-output/all_posteriors.rds")) |>
    filter(
        survival_prior %in% c(
            "ATACCC",
            "vague"
        ),
    ) |>
    mutate(
        survival_prior = case_match(
            survival_prior,
            "ATACCC" ~ "Combination",
            "vague" ~ "Independent (vague)"
        ),
    )
truth = readRDS(here::here("cisRuns-output/input_curves.rds")) |>
  filter(source == "Combined")

p_constant_sensitivity = tbl_posteriors |>
    filter(sensitivity.simulation == sensitivity.model, sensitivity.simulation < 1) |>
    base_plot(survival_prior)
ggsave(
    filename = here::here("cis-imperfect-testing/sim-constant-sensitivity.pdf"),
    plot = p_constant_sensitivity,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

p_misspecified_sensitivity = tbl_posteriors |>
    filter(sensitivity.simulation == 0.8, survival_prior == "Combination") |>
    base_plot(sensitivity.model, colour_key = expression(p[sens]^`(i)`), facet_suffix = "^{(i)}")
ggsave(
    filename = here::here("cis-imperfect-testing/sim-misspecified-sensitivity.pdf"),
    plot = p_misspecified_sensitivity,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

p_variable_sensitivity = tbl_posteriors |>
    filter(is.na(sensitivity.simulation), survival_prior == "Combination") |>
    base_plot(sensitivity.model, colour_key = expression(p[sens]^`(i)`), facet_suffix = "^{(i)}")
ggsave(
    filename = here::here("cis-imperfect-testing/sim-variable-sensitivity.pdf"),
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
#     filename = here::here("cis-imperfect-testing/sim-all.pdf"),
#     width = 15,
#     height = 50,
#     units = "cm",
#     dpi = 300
# )

# tbl_posteriors |>
#     filter(time == 5, S < 0.8, !stringr::str_detect(model_name, "inform-total")) |>
#     arrange(S) |>
#     select(model_name, sim_name) 
