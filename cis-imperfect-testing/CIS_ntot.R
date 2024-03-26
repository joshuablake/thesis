suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))
set.seed(10)

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

cis_mean = posterior |>
    filter(sensitivity == 0.8, survival_prior == "Informative", missed_model == "total", r == 22047)
ataccc_mean = readRDS(here::here("ATACCC-distributions/posterior_samples.rds")) |>
    group_by(.draw) |>
    summarise(mean_surv = sum(S))
cis_mean |>
    sample_n(nrow(ataccc_mean)) |>
    transmute(
        cis = mean_surv,
        ataccc = ataccc_mean$mean_surv,
        increase = cis / ataccc,
    ) |>
    mean_qi() |>
    select(!starts_with(".")) |>
    pivot_longer(
        everything(),
        names_pattern = "([a-z]+)(\\.[a-z]+)?",
        names_to = c("model", "statistic"),
    ) |>
    mutate(statistic = if_else(statistic == "", "Mean", statistic)) |>
    pivot_wider(names_from = statistic, values_from = value)
