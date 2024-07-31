library(dplyr)
library(lubridate)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("SEIR/utils.R"))

# Read posterior predictives
predictions = readr::read_csv(here::here("SEIR/CIS/predictive.csv")) |>
    mutate(
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        age = normalise_age_groups(age),
        region = normalise_region_names(region)
    ) |>
    select(!c(chain, iteration))

# Read data
data = readr::read_csv(here::here("SEIR/CIS/data.csv")) |>
    filter(!region %in% c("Wales", "Scotland", "Northern_Ireland")) |>
    mutate(
        obs_prevalence = obs_positives / num_tests,
        age = normalise_age_groups(age),
        region = normalise_region_names(region),
    ) |>
    rename(day = date) |>
    filter(
        day >= min(predictions$day),
        day <= max(predictions$day),
    )

# Calculate posterior predictive intervals
prediction_intervals = predictions |>
    group_by(region, day, age) |>
    median_qi()

# Get theta posterior
thetas = readr::read_csv(here::here("SEIR/CIS/params.csv")) |>
    filter(parameter == "theta") |>
    transmute(
        region = normalise_region_names(region),
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        theta = exp(value)
    )

# Generate posterior predictives including sampling noise
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

# Aggregate to weekly predictions because daily are too noisy to interpret
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

create_prev_plot = function(regions, label) {
    plot = weekly_predictions |>
        filter(region %in% regions) |>
        ggplot(aes(week)) +
        geom_point(aes(y = p), size = 0.5) +
        geom_ribbon(aes(ymin = pred_p.lower, ymax = pred_p.upper), alpha = 0.1) +
        geom_lineribbon(
            aes(day, prevalence, ymin = prevalence.lower, ymax = prevalence.upper),
            data = filter(prediction_intervals, region %in% regions),
            alpha = 0.4,
            size = 0.2
        ) +
        facet_grid(age ~ region) +
        standard_plot_theming() +
        labs(
            x = "Date (2020-1)",
            y = "Prevalence"
        ) +
        theme(
            legend.position = "none",
            strip.text = element_text(size = 7),
            axis.text.x = element_text(angle = 45, hjust = 1)
        )

    save_plot(
        plot = plot,
        filename = here::here(
            glue::glue("SEIR/CIS/prev_{label}.pdf")
        ),
        caption_lines = 6
    )
}

# Generate goodness-of-fit plots, separately for age groups due to size
all_regions = unique(weekly_predictions$region)
regions_in_main = c(
    "East of England",
    "North East",
    "London",
    "Yorkshire"
)
regions_in_appendix = all_regions[!all_regions %in% regions_in_main]
create_prev_plot(regions_in_main, "main")
create_prev_plot(regions_in_appendix, "appendix")

# Generate posterior incidence plots
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
        x = "Date (2020-1)",
        y = "Incidence"
    ) +
    standard_plot_theming() +
    theme(legend.position = "bottom")
save_plot(
    filename = here::here("SEIR/CIS/incidence.pdf"),
    plot = p_incidence,
    caption_lines = 1
)

# Calculate when incidence peaks for each posterior sample (by age and region)
peak_days = predictions |>
    group_by(region, age, .draw) |>
    summarise(peak_incidence= as.integer(day[which.max(incidence)])) |>
    ungroup()

# Transform into a daily probability that incidence is at its peak
p_peak = peak_days |>
    count(region, age, peak_incidence) |>
    mutate(tot = sum(n), .by = c(region, age)) |>
    mutate(p_peak = n / tot, peak_incidence = as_date(peak_incidence)) |>
    filter(p_peak > 0.02) |>
    ggplot(aes(peak_incidence, p_peak, colour = age)) +
    geom_point() +
    facet_wrap(~region, nrow = 2) +
    standard_plot_theming() +
    theme(legend.position = "bottom") +
    labs(
        x = "Date (2020-1)",
        y = "Posterior probability",
        colour = "Age group"
    )
save_plot(
    filename = here::here("SEIR/CIS/p_peak.pdf"),
    plot = p_peak,
    height = 13
)
    
# Output peak incidence dates as a CSV for humans
peak_days |>
    group_by(region, age) |>
    median_qi(peak_incidence, .simple_names = FALSE) |>
    ungroup() |>
    mutate(
        across(contains("peak_incidence"), as_date),
        text = paste(peak_incidence, "(", peak_incidence.lower, ",", peak_incidence.upper, ")"),
    ) |>
    select(region, age, text) |>
    pivot_wider(names_from = age, values_from = text) |>
    readr::write_csv("SEIR/CIS/peak_incidence.csv")
