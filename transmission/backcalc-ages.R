suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

output_dir = here::here("transmission/outputs")
p_age_base = readRDS(file.path(output_dir, "age_incidence.rds")) |>
    filter(daynr > 1) |>
    ggplot(aes(date, val, colour = age_group, fill = age_group)) +
    stat_lineribbon(alpha = 0.3, .width = 0.95) +
    labs(
        x = "Date",
        y = "Incidence proportion",
        fill = "Age group",
        colour = "Age group"
    ) +
    standard_plot_theming()
p_age = (p_age_base + scale_y_continuous(labels = scales::label_percent())) +
        (p_age_base + scale_y_log10(labels = scales::label_percent()) + theme(axis.title.y = element_blank())) +
        # collect legends and move to bottom of plot
        plot_layout(guides = "collect") &
        theme(legend.position = "bottom")

ggsave(
    filename = here::here("transmission", "backcalc-ages.pdf"),
    plot = p_age,
    width = 6.5,
    height = 3.6
)