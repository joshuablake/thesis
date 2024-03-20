library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("SEIR/utils.R"))

# rename_params = function(name) {
#     case_match(
#         "beta[0]" ~ "sigma",
#         "matrix_modifiers" ~ "beta[c]",
#         "i0" ~ "i"
#     )
# }

# posterior_intervals |>
#     distinct(parameter) |>
#     mutate(a = rename_params(parameter))

posterior_samples = readr::read_csv(
    here::here("SEIR/sim/posteriors_combined.csv")
)
# posterior_samples |>
#     filter(parameter == "psir", iteration > 500e3) |>
#     ggplot(aes(iteration, value)) +
#     geom_line() +
#     facet_wrap(~ sim, scales = "free_y")
posterior_intervals = posterior_samples |>
    filter(iteration > 500e3) |>
    group_by(sim, parameter) |>
    median_qi(value, .width = c(0.5, 0.75, 0.95))
true_params = readr::read_csv(
    here::here("SEIR/sim/true_vals.csv")
) |>
    rename(parameter = param)
coverage = posterior_intervals |>
    left_join(true_params, by = c("sim", "parameter")) |>
    mutate(
        contains = .lower <= true & true <= .upper,
    ) |>
    summarise(
        x = sum(contains),
        n = n(),
        .by = c(parameter, .width)
    ) |>
    mutate(binom::binom.confint(x, n, methods = "exact"))
p_coverage = ggplot(coverage, aes(colour = factor(.width))) +
    geom_point(aes(y = parameter, x = mean)) +
    geom_errorbarh(
        aes(xmin = lower, xmax = upper, y = parameter),
        height = 0
    ) +
    standard_plot_theming() +
    coord_cartesian(xlim = c(0, 1)) +
    scale_x_continuous(
        breaks = seq(0, 1, 0.2),
        minor_breaks = seq(0, 1, 0.1),
        labels = scales::percent
    ) +
    geom_vline(
        aes(xintercept = .width, colour = factor(.width)),
        data = tibble(distinct(coverage, .width))
    ) +
    labs(
        x = "Coverage",
        y = "Parameter",
        colour = "CrI width"
    ) +
    theme(
        legend.position = "bottom",
        axis.text.y = element_text(
            size = 5,
            lineheight = 1.2
        )
    ) +
    scale_y_discrete(labels = parameter_labels)
ggsave(
    filename = here::here("SEIR/sim/coverage.pdf"),
    plot = p_coverage,
    width = 12,
    height = 10,
    unit = "cm"
)

p_true_vs_posterior = posterior_intervals |>
    # grab any width: only care about point estimates here
    filter(.width == 0.95, !str_detect(parameter, "beta")) |>
    # calculate bias by joining with true values
    left_join(true_params, by = c("sim", "parameter")) |>
    mutate(across(
        c(value, true),
        ~case_when(
            parameter == "i0" | str_starts(parameter, "pi") ~ expit(.x),
            parameter %in% c("theta", "matrix_modifiers") ~ exp(.x),
            TRUE ~ .x
        )
    )) |>
    ggplot(aes(value, true)) +
    facet_wrap(~ parameter, scales = "free", labeller = parameter_labeller, ncol = 3) +
    geom_abline(slope = 1, intercept = 0) +
    geom_smooth(method = "lm", formula = y ~ x) +
    standard_plot_theming() +
    geom_point() +
    labs(
        x = "Posterior median",
        y = "True value"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(
    filename = here::here("SEIR/sim/true_vs_posterior.pdf"),
    plot = p_true_vs_posterior,
    width = 20,
    height = 22,
    units = "cm",
    dpi = 300
)

# Figure for combined posterior
# posterior_samples |>
#     filter(!stringr::str_detect(parameter, "beta"), iteration > 500e3) |>
#     # calculate bias by joining with true values
#     ggplot() +
#     geom_histogram(aes(value, after_stat(density), colour = "Combined posterior", fill = "Combined posterior"), bins = 100) +
#     geom_density(aes(true, colour = "Prior"), data = filter(true_params, !stringr::str_detect(parameter, "beta"))) +
#     facet_wrap(~parameter, scales = "free") +
#     geom_abline(slope = 1, intercept = 0) +
#     geom_smooth(method = "lm", formula = y ~ x) +
#     standard_plot_theming() +
#     geom_point() +
#     labs(
#         x = "Posterior median",
#         y = "True value"
#     )

# posterior_samples |>
#     filter(!stringr::str_detect(parameter, "beta"), iteration > 500e3) |>
#     ggplot() +
#     standard_plot_theming() +
#     geom_density(aes(value, after_stat(density), group = sim), alpha = 0.1) +
#     geom_density(aes(true, colour = "Prior"), data = filter(true_params, !stringr::str_detect(parameter, "beta"))) +
#     facet_wrap(~parameter, scales = "free")

# ggsave(
#     filename = here::here("SEIR/sim/summary.pdf"),
#     plot = p_coverage + p_true_vs_posterior,
#     width = 20,
#     height = 15,
#     units = "cm",
#     dpi = 300
# )

# # Plot bias with error bars
# posterior_intervals |>
#     # grab any width: only care about point estimates here
#     filter(.width == 0.95, !str_detect(parameter, "beta"), sim != 59) |>
#     # calculate bias by joining with true values
#     left_join(true_params, by = c("sim", "parameter" = "param")) |>
#     mutate(
#         bias = value - true,
#         rel_bias = bias / abs(true),
#     ) |>
#     # average over simulations
#     summarise(
#         mean_bias = mean(bias),
#         mean_true = mean(true),
#         mean_rel_bias = mean(rel_bias),
#         sd_rel_bias = sd(rel_bias),
#         lower = mean_rel_bias - qt(0.975, df = n() - 1) * sd_rel_bias / sqrt(n()),
#         upper = mean_rel_bias + qt(0.975, df = n() - 1) * sd_rel_bias / sqrt(n()),
#         .by = parameter
#     ) |>
#     ggplot(aes(mean_rel_bias, parameter)) +
#     geom_point() +
#     geom_errorbarh(
#         aes(xmin = lower, xmax = upper),
#         height = 0
#     ) +
#     geom_vline(xintercept = 0) +
#     standard_plot_theming() +
#     scale_x_continuous(
#         breaks = seq(-1, 1, 0.05),
#         minor_breaks = seq(-1, 1, 0.01),
#         labels = scales::percent
#     ) +
#     labs(
#         x = "Bias",
#         y = "Parameter"
#     )


# # sim 59 issues
# posterior_samples |>
#     filter(sim == 59) |>
#     ggplot(aes(iteration, value)) +
#     facet_wrap(~ parameter, scales = "free") +
#     geom_line()
# data = readr::read_csv(
#     here::here("SEIR/sim/sim_output.csv")
# )
# data |>
#     filter(sim == 50) |>
#     ggplot(aes(date, obs_prevalence)) +
#     geom_point() +
#     facet_wrap(~age) + 
#     geom_line(aes(y = prevalence))

# data |>
#     ggplot(aes(date)) +
#     facet_wrap(~age) + 
#     geom_line(aes(y = prevalence, colour = (sim == 59), group = sim), alpha = 0.1)

# posterior_intervals |>
#     filter(parameter == "theta", value < -30, .width == 0.95)
# posterior_samples |>
#     filter(parameter == "theta", sim == 11, iteration > 500e3) |>
#     ggplot(aes(iteration, value)) +
#     geom_line() +
#     standard_plot_theming()

# posterior_intervals |>
#     filter(value == .lower | value == .upper, .width == 0.5) |>
#     count(sim)
