library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

predictions = readr::read_csv(here::here("SEIR/CIS/predictive.csv")) |>
    mutate(
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        age = str_replace(age, fixed("+"), "Inf")
    ) |>
    select(!c(chain, iteration))

data = readr::read_csv(here::here("SEIR/CIS/data.csv")) |>
    mutate(
        obs_prevalence = obs_positives / num_tests,
        age = str_replace(age, fixed("("), "[") |>
            str_replace(fixed("]"), ")")
    ) |>
    rename(day = date) |>
    filter(
        day >= min(predictions$day),
        day <= max(predictions$day),
    )

prediction_intervals = predictions |>
    group_by(region, day, age) |>
    median_qi()

# get theta parameter values
thetas = readr::read_csv(here::here("SEIR/CIS/params.csv")) |>
    filter(parameter == "theta") |>
    transmute(
        region,
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        theta = exp(value)
    )

noisy_predict = predictions |>
    left_join(data, by = join_by(region, day, age)) |>
    left_join(thetas, by = join_by(region, .chain, .iteration)) |>
    mutate(
        predict_out = VGAM::rbetabinom.ab(
            n = n(),
            size = num_tests,
            shape1 = prevalence / theta,
            shape2 = (1 - prevalence) / theta,
        )
    )

weekly_predictions = noisy_predict |>
    group_by(
        region, .draw, age,
        week = lubridate::floor_date(day, unit = "week", week_start = "Monday") + 3,
    ) |>
    summarise(
        n = sum(num_tests),
        y = sum(obs_positives),
        p = y / n,
        pred_y = sum(predict_out),
        pred_p = pred_y / n,
    ) |>
    group_by(region, age, week) |>
    median_qi()

create_prev_plot = function(age_groups, label) {
    plot = weekly_predictions |>
        filter(age %in% age_groups) |>
        ggplot(aes(week)) +
        geom_point(aes(y = p)) +
        geom_errorbar(aes(ymin = pred_p.lower, ymax = pred_p.upper)) +
        geom_lineribbon(
            aes(day, prevalence, ymin = prevalence.lower, ymax = prevalence.upper),
            data = filter(prediction_intervals, age %in% age_groups),
            alpha = 0.4
        ) +
        facet_grid(region ~ age) +
        standard_plot_theming() +
        labs(
            x = "Date",
            y = "Prevalence"
        ) +
        theme(legend.position = "none")

    ggsave(
        filename = here::here(
            glue::glue("SEIR/CIS/prev_{label}.png")
        ),
        plot = plot,
        width = 15,
        height = 20,
        units = "cm",
        dpi = 300
    )
}

young_ages = unique(weekly_predictions$age)[1:3]
old_ages = unique(weekly_predictions$age)[4:6]
create_prev_plot(young_ages, "young")
create_prev_plot(old_ages, "old")

create_incidence_plot = function(age_groups, label) {
    plot = prediction_intervals |>
        filter(age %in% age_groups) |>
        ggplot() +
        geom_lineribbon(
            aes(day, incidence),
            data = prediction_intervals,
            alpha = 0.4
        ) +
        labs(
            x = "Date",
            y = "Incidence"
        ) +
        standard_plot_theming() +
        theme(legend.position = "none")
    ggsave(
        filename = here::here(
            glue::glue("SEIR/CIS/incidence_{label}.png")
        ),
        plot = plot,
        width = 15,
        height = 20,
        units = "cm",
        dpi = 300
    )
}
