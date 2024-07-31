library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

ataccc_posterior = readRDS(here::here("cisRuns-output/input_curves.rds"))

plot = ataccc_posterior |>
  filter(between(time, 0, 40)) |>
  mutate(source = case_match(
    source,
    "SARAH (CIS)" ~ "CIS",
    .default = source
  )) |>
  ggplot(aes(time, S, colour = source)) +
  geom_line() +
  standard_plot_theming() +
  scale_x_continuous(breaks = 0:100*14, minor_breaks = 0:100*2) +
  labs(
    x = "t",
    colour = ""
  )

save_plot(
  filename = "cis-perfect-testing/input-duration-dists.pdf",
  plot = plot,
  height = 9
)