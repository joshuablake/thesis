library(dplyr)
library(ggplot2)
library(lubridate)
library(patchwork)
library(stringr)
library(tidyr)
source(here::here("utils.R"))

inputs = readr::read_csv(here::here("SEIR/sim/sim_output.csv"), show_col_types = FALSE)

do_plot = function(base_gg, y_axis_label) {
    return(
        base_gg +
        geom_line(aes(date, group = sim), alpha = 0.2) +
        standard_plot_theming() +
        facet_wrap(~age) +
        labs(x = "Date", y = y_axis_label) +
        theme(text = element_text(size = 20))
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

ggsave(
    filename = here::here("SEIR/sim/data.pdf"),
    plot = p_incidence / p_prevalence,
    width = 20,
    height = 25,
    dpi = 300
)
