library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

flat_params = c(0.5, 1)
dist_levels = c(
  map_chr(flat_params, ~glue::glue("Beta({.x}, {.x})")),
  "ATACCC"
)

sample_priors = function(alpha, beta, n_samples = 1000) {
  stopifnot(length(alpha) == length(beta))
  tibble(
    time = 1:length(alpha),
    alpha = alpha,
    beta = beta
  ) %>%
    mutate(
      lambda = map2(alpha, beta, ~rbeta(n_samples, .x, .y)),
      .draw = list(1:n_samples),
    ) %>%
    unnest(c(.draw, lambda)) |>
    group_by(.draw) |>
    reframe(
      time = c(time, max(time) + 1),
      S = c(1, cumprod(1 - lambda)),
      lambda = c(lambda, 0)
    )
}

sample_constant_prior = function(alpha, beta, prior_len, n_samples = 1000) {
  stopifnot(length(alpha) == 1)
  stopifnot(length(beta) == 1)
  sample_priors(rep(alpha, prior_len), rep(beta, prior_len), n_samples)
}

beta_plot_dens = function(alpha, beta) {
  reduce2(
    alpha,
    beta,
    function(p, a, b) p + stat_function(aes(colour = glue::glue("Beta({a}, {b})")),
                                        fun = dbeta, args = list(a, b)),
    .init = ggplot(NULL) + labs(colour = "Dist", x = "Value", y = "Density")
  ) +
  standard_plot_theming()
}

beta_plot_surv = function(alpha, beta, prior_len = 30) {
  purrr::map2(
    alpha, beta,
    ~sample_constant_prior(.x, .y, prior_len) |>
      mutate(dist = glue::glue("Beta({.x}, {.y})"))
  ) |>
  bind_rows(
    ataccc_posterior |>
      mutate(dist = "ATACCC")
  ) |>
  group_by(dist, time) |>
  mean_qi(S, .simple.names = FALSE) |>
  mutate(dist = factor(dist, levels = dist_levels)) |>
  ggplot(aes(time, S, ymin = S.lower, ymax = S.upper, group = dist)) +
  geom_line(aes(colour = dist)) +
  geom_ribbon(aes(fill = dist), alpha = 0.5) +
  labs(
    x = "Day",
    y = "Survival",
    colour = "Distribution",
    fill = "Distribution"
  ) +
  coord_cartesian(c(0, prior_len)) +
  standard_plot_theming()
}

ataccc_posterior = readRDS(here::here("cisRuns-output/input_curves.rds")) |>
  filter(source == "ATACCC")

p_flat_dens = beta_plot_dens(flat_params, flat_params) +
  theme(legend.position = "none")
p_flat_surv = beta_plot_surv(flat_params, flat_params, prior_len = 15)
p_flat = p_flat_dens + p_flat_surv
ggsave(
  filename = "cis-perfect-testing/flat-prior.png",
  plot = p_flat,
  width = 15,
  height = 10,
  units = "cm",
  dpi = 300
)