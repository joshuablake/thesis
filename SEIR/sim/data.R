library(dplyr)
library(ggplot2)
library(lubridate)
library(patchwork)
library(stringr)
library(tidyr)
source(here::here("utils.R"))
source(here::here("transmission/utils.R"))

inputs = readr::read_csv(here::here("SEIR/sim/sim_output.csv"), show_col_types = FALSE) |>
    mutate(age = normalise_age_groups(age))

do_plot = function(base_gg, y_axis_label) {
    return(
        base_gg +
        geom_line(aes(date, group = sim), alpha = 0.2) +
        standard_plot_theming() +
        facet_wrap(~age) +
        labs(x = "Date (2020-1)", y = y_axis_label)
    )
}

p_incidence = inputs |>
    ggplot(aes(y = incidence)) |>
    do_plot("Incidence") +
    ggtitle("(A) Incidence")

p_prevalence = inputs |>
    ggplot(aes(y = prevalence)) |>
    do_plot("Prevalence") +
    ggtitle("(B) Prevalence")

save_plot(
    filename = here::here("SEIR/sim/data.pdf"),
    plot = p_incidence / p_prevalence,
    caption_lines = 3
)
