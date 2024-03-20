suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

output_dir = here::here("transmission/outputs")

alpha_dates = tribble(
    ~region, ~date,
    "North East", lubridate::dmy("09/12/2020"),
    "North West", lubridate::dmy("17/12/2020"),
    "Yorkshire", lubridate::dmy("08/12/2020"),
    "East Midlands", lubridate::dmy("24/11/2020"),
    "West Midlands", lubridate::dmy("27/11/2020"),
    "East of England", lubridate::dmy("27/11/2020"),
    "London", lubridate::dmy("21/11/2020"),
    "South East", lubridate::dmy("03/12/2020"),
    # "South West", lubridate::dmy("21/12/2020"),
)


incidence_plot = function(df) {
    df |>
        filter(daynr > 1) |>
        ggplot(aes(date, incidence)) +
        stat_lineribbon(alpha = 0.3, .width = 0.95) +
        scale_y_continuous(labels = scales::label_percent()) +
        labs(
            x = "Date",
            y = "Incidence proportion",
        ) +
        standard_plot_theming() +
        theme(legend.position = "none")
}

tbl_regions = readRDS(file.path(output_dir, "region.rds"))
p_region = (
    tbl_regions |>
        filter(region == "England") |>
        incidence_plot() +
        labs(subtitle = "(A) England")
) / (
    tbl_regions |>
        filter(region != "England") |>
        incidence_plot() +
        facet_wrap(~region) +
        labs(subtitle = "(B) Regions") +
        theme(panel.spacing.x = unit(7, "mm"))
) +
    plot_layout(heights = c(1, 1.6))

ggsave(
    filename = here::here("transmission", "backcalc-regions.pdf"),
    plot = p_region,
    width = 6.5,
    height = 7
)

tbl_min = readRDS(file.path(output_dir, "region.rds"))  |>
    # for each .draw and region, find the day of minimum
    # incidence between start of Nov and start of Jan
    filter(between(
        date,
        lubridate::dmy("01/11/2020"),
        lubridate::dmy("25/12/2020")
    )) |>
    summarise(
        min_incidence = min(incidence),
        daynr = daynr[which.min(incidence)],
        date = date[which.min(incidence)],
        .by = c(.draw, region)
    )

p_alpha = tbl_min |>
    mutate(date = as.integer(date)) |>
    group_by(region) |>
    median_qi(date) |>
    # date and qi ends back to real data
    mutate(
        across(
            c(date, .lower, .upper),
            ~ as.Date(.)
        )
    ) |>
    left_join(
        rename(alpha_dates, alpha_date = date),
        by = "region"
    ) |>
    filter(!is.na(alpha_date)) |>
    ggplot(aes(alpha_date, date)) +
    geom_pointrange(aes(colour = region, ymin = .lower, ymax = .upper)) +
    standard_plot_theming() +
    geom_smooth(method = "lm", formula = y ~ x) +
    labs(
        x = "Date Alpha rise",
        y = "Date of minimum incidence",
        colour = "Region"
    ) +
    theme(legend.position = "bottom")
ggsave(
    filename = here::here("transmission", "backcalc-alpha.pdf"),
    plot = p_alpha,
    width = 6,
    height = 5.5
)
