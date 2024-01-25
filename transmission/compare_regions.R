suppressMessages(library(dplyr))
library(lubridate)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("SEIR/utils.R"))
source(here::here("transmission/utils.R"))

seir_predictive = load_seir_predictive()
seir_incidence_summary = seir_predictive |>
    rename(age_group = age) |>
    poststratify_SEIR(load_poststrat_table(), new_pcr_pos, region) |>
    rename(incidence = val) |>
    group_by(day, region) |>
    median_qi(incidence, .simple_names = FALSE) |>
    ungroup() |>
    mutate(Model = "SEIR")

backcalc_prevalence_summary = readRDS(here::here("transmission", "outputs", "region.rds")) |>
    group_by(date, region) |>
    median_qi(incidence, prevalence, .simple_names = FALSE) |>
    ungroup() |>
    mutate(Model = "Backcalculation")

p_compare = bind_rows(
    seir_incidence_summary |>
        rename(
            date = day,
        ),
    backcalc_prevalence_summary,
) |>
    mutate(region = normalise_region_names(region)) |>
    filter(region != "England") |>
    ggplot(aes(date, incidence, ymin = incidence.lower, ymax = incidence.upper, colour = Model, fill = Model)) +
    geom_lineribbon(alpha = 0.4, linewidth = 0.2) +
    facet_wrap(~region) +
    standard_plot_theming() +
    theme(legend.position = "bottom") +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date",
        y = "Incidence proportion"
    )
ggsave(
    filename = here::here("transmission", "compare-regions.pdf"),
    plot = p_compare,
    width = 6,
    height = 5.5
)