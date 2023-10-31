library(ggplot2)
source("utils.R")

logVL <- function(t, vp) {
  vl <- log(vp[1]) + log(vp[2] + vp[3]) - log_sum_exp(log(vp[3]) - vp[2] * t, log(vp[2]) + vp[3] * t)
  return(vl)
}

log_sum_exp <- function(x, y) {
  max_value <- pmax(x, y)
  max_value + log1p(exp(pmin(x, y) - max_value))
}

p_typical_trajectory = ggplot(NULL) +
  stat_function(fun = logVL, args = list(exp(c(15, 1.6, 0.3))), xlim = c(-5, 15)) +
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

params = exp(c(15, 1.6, 0.3))
logVL(c(-3.34, 0, 12), params)
-(log(params[1])+log(params[2]+params[3])-log(params[3]))/params[2]
(log(params[3])-log(params[2]+params[3])-log(params[1]))/params[2]
