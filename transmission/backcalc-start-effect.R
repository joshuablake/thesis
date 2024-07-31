suppressMessages(library(dplyr))
library(ggplot2)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

output_dir = here::here("transmission/outputs")
p_start_effect = readRDS(file.path(output_dir, "region.rds")) |>
    filter(daynr <= 20, region == "England") |>
    ggplot(aes(date, incidence)) +
    stat_lineribbon(alpha = 0.8, .width = 0.95) +
    scale_y_continuous(labels = scales::label_percent(), limits = c(0, NA)) +
    scale_fill_brewer() +
    labs(
        x = "Date (2020)",
        y = "Incidence proportion",
    ) +
    standard_plot_theming() +
    theme(legend.position = "none")
save_plot(
    filename = here::here("transmission", "backcalc-start-effect.pdf"),
    plot = p_start_effect,
    width = 10,
    height = 10
)