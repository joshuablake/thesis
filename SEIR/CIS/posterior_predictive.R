library(dplyr)
library(lubridate)
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
        week = floor_date(day, unit = "week", week_start = "Monday") + 3,
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
        geom_ribbon(aes(ymin = pred_p.lower, ymax = pred_p.upper), alpha = 0.1) +
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

p_incidence = prediction_intervals |>
    ggplot() +
    geom_ribbon(
        aes(
            day,
            ymin = incidence.lower,
            ymax = incidence.upper,
            fill = age
        ),
        alpha = 0.4
    ) +
    facet_wrap(~region, ncol = 2) +
    labs(
        x = "Date",
        y = "Incidence"
    ) +
    standard_plot_theming() +
    theme(legend.position = "none")
ggsave(
    filename = here::here(
        glue::glue("SEIR/CIS/incidence.png")
    ),
    plot = p_incidence,
    width = 15,
    height = 20,
    units = "cm",
    dpi = 300
)

peak_days = predictions |>
    group_by(region, age, .draw) |>
    summarise(peak_incidence= as.integer(day[which.max(incidence)])) |>
    ungroup()

p_peak = peak_days |>
    count(region, age, peak_incidence) |>
    mutate(tot = sum(n), .by = c(region, age)) |>
    mutate(p_peak = n / tot, peak_incidence = as_date(peak_incidence)) |>
    filter(p_peak > 0.02) |>
    ggplot(aes(peak_incidence, p_peak, colour = age)) +
    geom_point() +
    facet_wrap(~region, ncol = 2) 
    
# peak_days |>
#     group_by(region, age) |>
#     median_qi(peak_incidence, .simple_names = FALSE) |>
#     ungroup() |>
#     mutate(
#         across(contains("peak_incidence"), as_date),
#         text = paste(peak_incidence, "(", peak_incidence.lower, ",", peak_incidence.upper, ")"),
#     ) |>
#     select(region, age, text) |>
#     pivot_wider(names_from = age, values_from = text) |>
#     readr::write_csv("SEIR/CIS/peak_incidence.csv")
