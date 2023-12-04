library(dplyr)
library(ggplot2)
library(lubridate)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

truth = readr::read_csv(here::here("SEIR/sim/sim_output.csv"))
posterior_predictive = readr::read_csv(here::here("SEIR/sim/posteriors_predictive.csv"))

make_plot = function(x) {
    x |>
        ggplot(aes(day, mean, colour = factor(.width), fill = factor(.width))) +
        geom_lineribbon(aes(ymin = lower, ymax = upper), alpha = 0.5) +
        geom_hline(aes(yintercept = .width)) +
        standard_plot_theming() +
        facet_wrap(~age) +
        labs(
            x = "Day",
            y = "Coverage",
            fill = "Interval width",
            colour = "Interval width"
        )
}

posterior_intervals = posterior_predictive |>
    rename(.iteration = iteration) |>
    group_by(sim, day, age) |>
    median_qi(.width = c(0.5, 0.75, 0.95)) |>
    ungroup() |>
    left_join(
        truth, by = c("sim", "day" = "date", "age"),
        suffix = c(".pred", ".true")
    )

incidence_coverage = posterior_intervals |>
    mutate(
        contains = incidence.lower <= incidence.true
            & incidence.true <= incidence.upper,
    ) |>
    summarise(
        x = sum(contains),
        n = n(),
        .by = c(day, age, .width)
    ) |>
    mutate(binom::binom.confint(x, n, methods = "exact"))

prevalence_coverage = posterior_intervals |>
    mutate(
        contains = prevalence.lower <= prevalence.true
            & prevalence.true <= prevalence.upper,
    ) |>
    summarise(
        x = sum(contains),
        n = n(),
        .by = c(day, age, .width)
    ) |>
    mutate(binom::binom.confint(x, n, methods = "exact"))

p_incidence = incidence_coverage |>
    make_plot()
p_prevalence = prevalence_coverage |>
    make_plot()
p_combined = p_incidence / p_prevalence +
    # Combine legends and put at bottom of plot
    plot_layout(guides = "collect") &
    theme(
        legend.position = "bottom",
    )
ggsave(
    filename = "SEIR/sim/predictive_coverage.png",
    plot = p_combined,
    width = 15,
    height = 15
)
