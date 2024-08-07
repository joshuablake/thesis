suppressMessages(library(dplyr))
library(ggplot2)
suppressMessages(library(lubridate))
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("transmission/utils.R"))

truth = readr::read_csv(here::here("SEIR/sim/sim_output.csv"), show_col_types = FALSE)
posterior_predictive = readr::read_csv(here::here("SEIR/sim/posteriors_predictive.csv"), show_col_types = FALSE)

make_plot = function(x) {
    x |>
        mutate(age = normalise_age_groups(age)) |>
        ggplot(aes(day, mean, colour = factor(.width), fill = factor(.width))) +
        geom_lineribbon(aes(ymin = lower, ymax = upper), alpha = 0.5) +
        geom_hline(aes(yintercept = .width)) +
        standard_plot_theming() +
        facet_wrap(~age) +
        labs(
            x = "Day (2020-1)",
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
    make_plot() +
    ggtitle("(A) Incidence")
p_prevalence = prevalence_coverage |>
    make_plot() +
    ggtitle("(B) Prevalence")
p_combined = p_incidence / p_prevalence +
    # Combine legends and put at bottom of plot
    plot_layout(guides = "collect") &
    theme(
        legend.position = "bottom",
    )
save_plot(
    filename = "SEIR/sim/predictive_coverage.pdf",
    plot = p_combined,
    caption_lines = 3
)
