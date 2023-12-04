library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(lubridate)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

start_date = ymd("2020-08-31")

posterior = readr::read_csv(here::here("SEIR/CIS/params.csv")) |>
    filter(stringr::str_starts(parameter, "beta"), iteration >= 500e3) |>
    extract(
        parameter,
        into = c("parameter", "i"), 
        regex = "^([^\\[]+)(\\[[0-9]+\\])?$"
    ) |>
    transmute(
        region,
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        i = if_else(
            i == "",
            NA_integer_,
            # Remove first and last character from i
            as.integer(substr(i, 2, nchar(i) - 1))
        ),
        value,
    ) |>
    mutate(
        # Use centered parameterisation
        .by = c(region, .draw),
        value = if_else(
            i == 0,
            0,
            value * exp(value[i == 0])
        ),
    )

walk = posterior |>
    group_by(region, .draw) |>
    arrange(i, .by_group = TRUE) |>
    mutate(
        beta = value |>
            cumsum() |>
            exp()
    ) |>
    ungroup()

walk_summary = walk |>
    group_by(region, i) |>
    median_qi()

walk_summary |>
    mutate(date = start_date + i * 7) |>
    ggplot(aes(date, beta, color = region)) +
    geom_point() +
    geom_errorbar(aes(ymin = beta.lower, ymax = beta.upper), alpha = 0.5) +
    facet_wrap(~region) +
    standard_plot_theming() +
    geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.5) +
    scale_y_log10(
        breaks = c(0.5, 1, 2, 0.67, 1.5),
        limits = c(0.5, NA),
        minor_breaks = numeric()
    )


# A violin plot of the posterior distribution of beta for each region and week.
p_walk = walk |>
    mutate(date = start_date + i * 7) |>
    ggplot(aes(factor(date), beta)) +
    stat_slab(side = "both") +
    facet_wrap(~region, ncol = 2) +
    standard_plot_theming() +
    scale_y_log10(
        breaks = c(0.5, 1, 2, 0.67, 1.5),
        limits = c(0.5, NA),
        minor_breaks = numeric()
    ) +
    # tick labels every 3 weeks
    scale_x_discrete(
        breaks = function(x) x[c(TRUE, rep(FALSE, 3))]
    ) +
    geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.5) +
    # Angle text for readability
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(
        x = "Date",
        y = expression(beta[t])
    )
ggsave(
    plot = p_walk,
    filename = here::here("SEIR/CIS/beta_walk.png"),
    width = 15,
    height = 20,
    units = "cm",
    dpi = 300
)