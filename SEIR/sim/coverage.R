library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))



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
posterior_intervals = posterior_samples |>
    filter(iteration > 30e3) |>
    group_by(sim, parameter) |>
    median_qi(value, .width = c(0.5, 0.75, 0.95))
true_params =  readr::read_csv(
    here::here("SEIR/sim/true_vals.csv")
)
coverage = posterior_intervals |>
    left_join(true_params, by = c("sim", "parameter" = "param")) |>
    mutate(
        contains = .lower <= true & true <= .upper,
        .width = .width,
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
    )
ggsave(
    filename = here::here("SEIR/sim/coverage.png"),
    plot = p_coverage,
    width = 10,
    height = 10,
    unit = "cm"
)
posterior_intervals |>
    # grab any width: only care about point estimates here
    filter(.width == 0.95, !str_detect(parameter, "beta")) |>
    # calculate bias by joining with true values
    left_join(true_params, by = c("sim", "parameter" = "param")) |>
    mutate(
        bias = value - true,
        rel_bias = bias / true,
    )
posterior_intervals |>
    # grab any width: only care about point estimates here
    filter(.width == 0.95, !str_detect(parameter, "beta"), sim != 59) |>
    # calculate bias by joining with true values
    left_join(true_params, by = c("sim", "parameter" = "param")) |>
    ggplot(aes(value, true)) +
    facet_wrap(~ parameter, scales = "free") +
    geom_abline(slope = 1, intercept = 0) +
    geom_smooth(method = "lm", formula = y ~ x) +
    standard_plot_theming() +
    geom_point() +
    labs(
        x = "Posterior median",
        y = "True value"
    )
posterior_intervals |>
    # grab any width: only care about point estimates here
    filter(.width == 0.95, !str_detect(parameter, "beta"), sim != 59) |>
    # calculate bias by joining with true values
    left_join(true_params, by = c("sim", "parameter" = "param")) |>
    mutate(
        bias = value - true,
        rel_bias = bias / abs(true),
    ) |>
    # average over simulations
    summarise(
        mean_bias = mean(bias),
        mean_true = mean(true),
        mean_rel_bias = mean(rel_bias),
        sd_rel_bias = sd(rel_bias),
        lower = mean_rel_bias - qt(0.975, df = n() - 1) * sd_rel_bias / sqrt(n()),
        upper = mean_rel_bias + qt(0.975, df = n() - 1) * sd_rel_bias / sqrt(n()),
        .by = parameter
    ) |>
    ggplot(aes(mean_rel_bias, parameter)) +
    geom_point() +
    geom_errorbarh(
        aes(xmin = lower, xmax = upper),
        height = 0
    ) +
    geom_vline(xintercept = 0) +
    standard_plot_theming() +
    scale_x_continuous(
        breaks = seq(-1, 1, 0.05),
        minor_breaks = seq(-1, 1, 0.01),
        labels = scales::percent
    ) +
    labs(
        x = "Bias",
        y = "Parameter"
    )


# sim 59 issues
posterior_samples |>
    filter(sim == 59) |>
    ggplot(aes(iteration, value)) +
    facet_wrap(~ parameter, scales = "free") +
    geom_line()
data = readr::read_csv(
    here::here("SEIR/sim/sim_output.csv")
)
data |>
    filter(sim == 50) |>
    ggplot(aes(date, obs_prevalence)) +
    geom_point() +
    facet_wrap(~age) + 
    geom_line(aes(y = prevalence))

data |>
    ggplot(aes(date)) +
    facet_wrap(~age) + 
    geom_line(aes(y = prevalence, colour = (sim == 59), group = sim), alpha = 0.1)
