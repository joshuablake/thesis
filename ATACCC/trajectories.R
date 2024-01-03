library(ggplot2)
source(here::here("ATACCC/trajectory_functions.R"))
source(here::here("utils.R"))

min_x = -5
max_x = 15
x = seq(min_x, max_x, length.out = 1000)

param_vals = tibble::tribble(
  ~tau_max, ~a_i, ~b_i,
  exp(15), 5, 1.4,
  exp(12.5), 3, 2,
)

trajectories = purrr::pmap_dfr(
  param_vals,
  function(tau_max, a_i, b_i) {
    label_text = bquote(tau[max,i] == .(tau_max) * "," ~ a[i] == .(a_i) * "," ~ b[i] == .(b_i))
    tibble::tibble(
      label = paste0("log v = ", log(tau_max), "; a = ", a_i, "; b = ", b_i),
      #  parse(
      #   text = paste0("tau[max,i] = ", tau_max, "; a[i] = ", a_i, "; b[i] = ", b_i)
      # ),
      # label = as.character(label_text),
      x = x,
      y = logVL(x, c(tau_max, a_i, b_i)),
    )
  }
)

p_typical_trajectory = ggplot(trajectories, aes(x, y, colour = label)) +
  geom_line() +
  coord_cartesian(ylim = c(0, NA)) +
  labs(
    x = "Time from peak viral load",
    y = "Log viral load",
    colour = "Parameter values"
  ) +
  standard_plot_theming()
ggsave(
  filename = "ATACCC/typical_trajectory.png",
  plot = p_typical_trajectory,
  width = 15,
  height = 9,
  units = "cm",
  dpi = 300
)
