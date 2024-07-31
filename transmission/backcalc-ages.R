suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
source(here::here("transmission/utils.R"))

output_dir = here::here("transmission/outputs")
p_age_base = readRDS(file.path(output_dir, "age.rds")) |>
    filter(daynr > 1) |>
    mutate(age_group = normalise_age_groups(age_group)) |>
    ggplot(aes(date, incidence, colour = age_group, fill = age_group)) +
    stat_lineribbon(alpha = 0.3, .width = 0.95, linewidth = 0.5) +
    labs(
        x = "Date (2020-1)",
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

save_plot(
    filename = here::here("transmission", "backcalc-ages.pdf"),
    plot = p_age,
    height = 10
)