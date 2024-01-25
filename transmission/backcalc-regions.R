suppressMessages(library(dplyr))
library(ggplot2)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

output_dir = here::here("transmission/outputs")
label_letters = as_labeller(function(labels, base_labeller = label_value) {
    glue::glue("({LETTERS[seq_along(labels)]}) {base_labeller(labels)}")
})

p_region = readRDS(file.path(output_dir, "region.rds")) |>
    filter(daynr > 1) |>
    mutate(
        panel = case_match(
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
        ),
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
ggsave(
    filename = here::here("transmission", "backcalc-regions.pdf"),
    plot = p_region,
    width = 6,
    height = 5.5
)