suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

#############################################################################################
### LOAD THE ESTIMATES TO PLOT
#############################################################################################
posterior = readRDS(here::here("cis-imperfect-testing/STATS18744/means.rds"))

#############################################################################################
### CREATE FIGURE
#############################################################################################
fig = posterior |>
    filter(sensitivity == 0.8, survival_prior == "Informative", missed_model == "total") |>
    ggplot() +
    stat_pointinterval(
        aes(r, n_tot),
        .width = 0.95
    ) +
    standard_plot_theming() +
    scale_x_log10() +
    labs(y = expression(n[tot]))
ggsave(
    filename = here::here("cis-imperfect-testing/CIS_ntot.pdf"),
    plot = fig,
    width = 11,
    height = 7,
    units = "cm",
    dpi = 300
)