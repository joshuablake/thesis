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


plot_positivity = ggplot() +
    geom_point(
        aes(date, mean),
        data = raw_counts |> filter(num_tests > 100)
    ) +
    geom_ribbon(
        aes(date, prevalence, ymin = .lower, ymax = .upper),
        data = corrected_model,
        alpha = 0.5
    ) +
    scale_y_continuous(
        labels = scales::percent_format(accuracy = 1),
    ) +
    coord_cartesian(
        c(min(corrected_model$date), max(corrected_model$date))
    ) +
    labs(
        x = "Date",
        y = "Prevalence"
    ) +
    standard_plot_theming() +
    theme(legend.position = "none")
ggsave(
    here::here("biology-data", "CIS-positivity.pdf"),
    plot_positivity,
    width = 6,
    height = 3.5
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
        x = "Date",
        y = "Number of tests"
    ) +
    standard_plot_theming()
ggsave(
    here::here("biology-data", "CIS-num-tests.pdf"),
    plot_num_tests,
    width = 6,
    height = 3.5
)