suppressMessages(library(dplyr))
library(ggplot2)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

decide_panel = function(region) {
    case_match(
        region,
        "England" ~ "England",
        "North East" ~ "North",
        "North West" ~ "North",
        "Yorkshire" ~ "North",
        "East Midlands" ~ "Midlands",
        "West Midlands" ~ "Midlands",
        "East of England" ~ "Midlands",
        "London" ~ "South",
        "South East" ~ "South",
        "South West" ~ "South",
    )
}

output_dir = here::here("transmission/outputs")
label_letters = as_labeller(function(labels, base_labeller = label_value) {
    glue::glue("({LETTERS[seq_along(labels)]}) {base_labeller(labels)}")
})

# alpha_dates = tribble(
#     ~region, ~date,
#     "North East", lubridate::dmy("09/12/2020"),
#     "North West", lubridate::dmy("17/12/2020"),
#     "Yorkshire", lubridate::dmy("08/12/2020"),
#     "East Midlands", lubridate::dmy("24/11/2020"),
#     "West Midlands", lubridate::dmy("27/11/2020"),
#     "East of England", lubridate::dmy("27/11/2020"),
#     "London", lubridate::dmy("21/11/2020"),
#     "South East", lubridate::dmy("03/12/2020"),
#     "South West", lubridate::dmy("21/12/2020"),
# ) |>
    #  mutate(panel = decide_panel(region))

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
) |>
    mutate(panel = decide_panel(region))

p_region = readRDS(file.path(output_dir, "region.rds")) |>
    filter(daynr > 1) |>
    mutate(
        panel = decide_panel(region),
    ) |>
    ggplot(aes(date, incidence, colour = region, fill = region)) +
    stat_lineribbon(alpha = 0.3, .width = 0.95) +
    facet_wrap(~panel, labeller = label_letters) +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date",
        y = "Incidence proportion",
        fill = "Region",
        colour = "Region"
    ) +
    standard_plot_theming() +
    theme(legend.position = "bottom")

p_region +
    # vertical line at alpha_dates
    geom_vline(
        data = alpha_dates,
        aes(xintercept = date, colour = region),
        linetype = "dashed",
        linewidth = 0.5
    )
ggsave(
    filename = here::here("transmission", "backcalc-regions.pdf"),
    plot = p_region,
    width = 6,
    height = 5.5
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
