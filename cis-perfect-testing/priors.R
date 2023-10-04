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
  "Beta(0.1, 1.9)",
  "ATACCC",
  "RW2"
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

beta_plot_surv = function(alpha, beta, prior_len = 30, include_ATACCC = FALSE) {
  priors = purrr::map2(
    alpha, beta,
    ~sample_constant_prior(.x, .y, prior_len) |>
      mutate(dist = glue::glue("Beta({.x}, {.y})"))
  ) |>
  bind_rows()
  if (include_ATACCC) {
    priors = bind_rows(
      priors,
      ataccc_posterior |>
        mutate(dist = "ATACCC")
    )
  }
  priors |>
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
    scale_x_continuous(breaks = seq(0, 100) * 14, minor_breaks = seq(0, 100) * 2) +
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
  height = 9,
  units = "cm",
  dpi = 300
)

p_vague_dens = beta_plot_dens(0.1, 1.9) +
  theme(legend.position = "none")
p_vague_surv = beta_plot_surv(0.1, 1.9, prior_len = 30) +
  theme(legend.position = "none")
p_vague = p_vague_dens + p_vague_surv
ggsave(
  filename = "cis-perfect-testing/vague-prior.png",
  plot = p_vague,
  width = 15,
  height = 9,
  units = "cm",
  dpi = 300
)

logits_to_dist = function(x) {
    x |>
        mutate(lambda = expit(value)) |>
        group_by(.draw) |>
        arrange(time, .by_group = TRUE) |>
        mutate(
            S = c(1, cumprod(1 - lambda)[-n()]),
            F = c(lead(1 - S)[-(n())], 1),
            f = diff(c(0, F))
        ) |>
        ungroup()
}

rw1_from_known_start = function(start, sd, n_steps) {
    n_samples = length(start)
    # Generate random steps matrix
    random_steps = matrix(
        rnorm(n_samples * (n_steps - 1), mean = 0, sd = sd),
        nrow = n_samples
    )

    # Compute cumulative sum along rows
    cumulative_random_steps = t(apply(random_steps, 1, cumsum))

    # Add starting points to the random walks
    random_walks = sweep(cumulative_random_steps, 1, start, FUN = "+")

    # Add starting points as the first time step
    return(cbind(start, random_walks))
}

sim_rw2 = function(seed = 123, n_samples = 1000, n_steps = 35, start_mean = -17.5,
                    start_sd = 6, gradient_mean = 1.09, gradient_sd = 0.03,
                    walk_sd_rate = 10) {

    walk_sd = rexp(n_samples, walk_sd_rate)
    # Generate starting point and gradient
    starts <- rnorm(n_samples, start_mean, start_sd)
    gradient_start <- rnorm(n_samples, gradient_mean, gradient_sd)
    gradients = rw1_from_known_start(gradient_start, walk_sd, n_steps - 1)
    random_walk_steps = t(apply(gradients, 1, cumsum))
    random_walks = cbind(
        starts,
        sweep(random_walk_steps, 1, starts, FUN = "+")
    )
    tibble(
        time = rep(0:(n_steps-1), n_samples),
        value = as.vector(t(random_walks)),
        .draw = rep(1:n_samples, each = n_steps)
    ) |>
        logits_to_dist()
}
random_walks_df2 = sim_rw2()
# Plot the random walks
rw2_logit_hazard_draws = ggplot(random_walks_df2, aes(x = time, y = value, group = .draw)) +
  geom_line(alpha = 0.1) +
  labs(x = "Time", y = "LogitHazard", title = "100 realisations of the prior") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 100) * 14, minor_breaks = seq(0, 100) * 2) +
    geom_line(
      aes(time, logit(lambda), group = NULL, colour = "ATACCC"),
      data = ataccc_posterior
    )

rw2_surv_plot = random_walks_df2 |>
    group_by(time) |>
    mean_qi(S, .width = c(0.95)) |>
    mutate(dist = factor("RW2", levels = dist_levels)) |>
    bind_rows(ataccc_posterior |> mutate(dist = factor("ATACCC", levels = dist_levels))) |>
    ggplot() +
    geom_line(aes(time, S, colour = dist)) +
    geom_ribbon(aes(time, ymin = .lower, ymax = .upper, fill = dist), alpha = 0.5) +
    labs(
      x = "Day",
      y = "Survival",
      colour = "",
      fill = ""
    ) +
    scale_x_continuous(breaks = seq(0, 100) * 14, minor_breaks = seq(0, 100) * 2) +
    standard_plot_theming() +
    coord_cartesian(c(0, 30)) +
    theme(legend.position = "bottom")

rw2_hazard = random_walks_df2 |>
    group_by(time) |>
    mean_qi(lambda, .width = c(0.5, 0.8, 0.95)) |>
    ggplot() +
    geom_lineribbon(aes(time, lambda, ymin = .lower, ymax = .upper)) +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 100) * 14, minor_breaks = seq(0, 100) * 2) +
    geom_line(
      aes(time, lambda, colour = "ATACCC"),
      data = ataccc_posterior
    )
ggsave(
  filename = "cis-perfect-testing/rw2-prior.png",
  plot = rw2_surv_plot,
  width = 15,
  height = 9,
  units = "cm",
  dpi = 300
)