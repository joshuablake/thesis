suppressMessages(library(dplyr))
library(ggdist)
library(tidyr)
library(ggplot2)
source(here::here("utils.R"))

raw_counts = readr::read_csv(
    here::here("SEIR", "CIS", "data.csv"),
    col_types = readr::cols(
        region = readr::col_character(),
        date = readr::col_date(format = ""),
        age = readr::col_character(),
        num_tests = readr::col_double(),
        obs_positives = readr::col_double()
    )
) |>
    summarise(
        num_tests = sum(num_tests),
        obs_positives = sum(obs_positives),
        .by = date
    ) |>
    mutate(
        # Add exact 95% CI using binom package
        binom::binom.confint(
            obs_positives, num_tests, conf.level = 0.95,
            method = "exact"
        ),
    )

corrected_model = readRDS(
    here::here("transmission", "outputs", "region.rds")
) |>
    filter(region == "England") |>
    group_by(date) |>
    mean_qi(prevalence)

counts_to_plot = raw_counts |>
    filter(
        num_tests > 100,
        between(date, min(corrected_model$date), max(corrected_model$date))
    )

plot_positivity = ggplot() +
    geom_point(
        aes(date, mean),
        data = counts_to_plot
    ) +
    geom_ribbon(
        aes(date, prevalence, ymin = .lower, ymax = .upper),
        data = corrected_model,
        alpha = 0.5
    ) +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date (2020-1)",
        y = "Prevalence"
    ) +
    standard_plot_theming() +
    theme(legend.position = "none")
save_plot(
    here::here("biology-data", "CIS-positivity.pdf"),
    plot_positivity,
    height = 8
)

plot_num_tests = raw_counts |>
    ggplot() +
    geom_col(
        aes(date, num_tests),
    ) +
    coord_cartesian(
        c(min(corrected_model$date), max(corrected_model$date))
    ) +
    labs(
        x = "Date (2020-1)",
        y = "Number of tests"
    ) +
    standard_plot_theming()
save_plot(
    here::here("biology-data", "CIS-num-tests.pdf"),
    plot_num_tests,
    height = 8
)