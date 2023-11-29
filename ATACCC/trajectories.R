library(ggplot2)
source(here::here("ATACCC/trajectory_functions.R"))
source(here::here("utils.R"))

# min_x = -5
# max_x = 15
# x = seq(min_x, max_x, length.out = 1000)

# param_vals = tibble::tribble(
#   ~tau_max, ~a_i, ~b_i,
#   exp(15), 5, 1.4,
#   exp(12.5), 7, 2,
# )

# trajectories = purrr::pmap_dfr(
#   param_vals,
#   function(tau_max, a_i, b_i) {
#     label_text = bquote(tau[max,i] == .(tau_max) * "," ~ a[i] == .(a_i) * "," ~ b[i] == .(b_i))
#     tibble::tibble(
#       # label = parse(
#       #   text = paste0("tau[max,i] = ", tau_max, "; a[i] = ", a_i, "; b[i] = ", b_i)
#       # ),
#       label = as.character(label_text),
#       x = x,
#       y = logVL(x, c(tau_max, a_i, b_i)),
#     )
#   }
# )

# ggplot(trajectories, aes(x, y, colour = label)) +
#   geom_line() +
#   coord_cartesian(ylim = c(0, NA)) +
#   labs(
#     x = "Time from peak viral load",
#     y = "Log viral load"
#   ) +
#   theme_minimal() +  # Replace with your actual theming function
#   scale_colour_manual(
#     values = c("blue", "red"),  # Replace with your desired colors
#     labels = unique(trajectories$label)
#   )

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
