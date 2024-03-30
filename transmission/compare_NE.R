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


backcalc_prevalence_summary = readRDS(here::here("transmission", "outputs", "region_age.rds")) |>
    filter(region == "North East", daynr > 1) |>
    group_by(date, age_group) |>
    median_qi(incidence, prevalence, .simple_names = FALSE) |>
    ungroup() |>
    mutate(Model = "Phenomenological", age_group = normalise_age_groups(age_group))

seir_incidence_summary = load_seir_predictive() |>
    filter(region == "North East") |>
    rename(age_group = age) |>
    poststratify_SEIR(load_poststrat_table(), new_pcr_pos, age_group) |>
    rename(incidence = val) |>
    group_by(day, age_group) |>
    median_qi(incidence, .simple_names = FALSE) |>
    ungroup() |>
    mutate(Model = "SEIR")

p_compare = bind_rows(
    seir_incidence_summary |>
        rename(
            date = day,
        ),
    backcalc_prevalence_summary,
) |>
    ggplot(aes(date, incidence, ymin = incidence.lower, ymax = incidence.upper, colour = Model, fill = Model)) +
    geom_lineribbon(alpha = 0.4, linewidth = 0.2) +
    facet_wrap(~age_group) +
    standard_plot_theming() +
    theme(legend.position = "bottom") +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date",
        y = "Incidence proportion"
    )
ggsave(
    filename = here::here("transmission", "compare-NE.pdf"),
    device = cairo_pdf,
    plot = p_compare,
    width = 6,
    height = 4
)