library(ggplot2)
source(here::here("ATACCC/trajectory_functions.R"))
source(here::here("utils.R"))

p_typical_trajectory = ggplot(NULL) +
  stat_function(fun = logVL, args = list(c(exp(15), 5, 1.4)), xlim = c(-5, 15), n = 1000) +
  coord_cartesian(ylim = c(0, NA)) +
  labs(
    x = "Time from peak viral load",
    y = "Log viral load"
  ) +
  standard_plot_theming()
ggsave(
  "ATACCC/typical_trajectory.png",
  width = 15,
  height = 9,
  units = "cm",
  dpi = 300
)
