suppressMessages(library(dplyr))
library(ggplot2)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

output_dir = here::here("transmission/outputs")
p_start_effect = readRDS(file.path(output_dir, "region_incidence.rds")) |>
    filter(daynr <= 20, region == "England") |>
    ggplot(aes(date, val)) +
    stat_lineribbon(alpha = 0.8, .width = 0.95) +
    scale_y_continuous(labels = scales::label_percent()) +
    scale_fill_brewer() +
    labs(
        x = "Date",
        y = "Incidence proportion",
    ) +
    standard_plot_theming() +
    theme(legend.position = "none")
ggsave(
    filename = here::here("transmission", "backcalc-start-effect.pdf"),
    plot = p_start_effect,
    width = 4,
    height = 3.8
)