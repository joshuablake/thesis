library(dplyr)
library(ggplot2)
library(purrr)
library(rstan)
library(patchwork)
library(tidybayes)
library(tidyverse)
source(here::here("ATACCC/trajectory_functions.R"))
source(here::here("utils.R"))

hakki = readRDS(here::here("ATACCC/fit.rds"))
modified = readRDS(here::here("ATACCC/fit2.rds"))

parameter_names = c("vmax", "a", "b")

fit_to_cov = function(fit) {
    corr_chol = rstan::extract(fit, pars = "Lc")[["Lc"]]
    corr = apply(corr_chol, 1, function(x) x %*% t(x), simplify = FALSE)
    sds = spread_draws(
        hakki,
        v_sd[i]
    ) |>
        ungroup()
        
    full_join(
        sds |> rename(sd_i = v_sd),
        sds |>
            rename(j = i, sd_j = v_sd),
        by = c(".chain", ".iteration", ".draw"),
        relationship = "many-to-many"
    ) |>
        mutate(
            cor = pmap_dbl(
                list(.draw, i, j),
                function(d, i, j) corr[[d]][i, j]
            ),
            name_i = parameter_names[i],
            name_j = parameter_names[j],
            cov = cor * sd_i * sd_j,
        )
}

fit_to_mean = function(fit, g_to_show = 1) {
    fit |>
        spread_draws(vgrow[i, g]) |>
        filter(g == g_to_show) |>
        mutate(name = parameter_names[i])
}

p_cov = bind_rows(
    fit_to_cov(hakki) |>
        mutate(
            model = "Hakki"
        ),
    fit_to_cov(modified) |>
        mutate(
            model = "Modified"
        )
) |>
    ggplot() +
    geom_density(aes(cov, colour = model)) +
    facet_grid(name_i ~ name_j) +
    standard_plot_theming() +
    labs(
        x = "(Co)variance",
        y = "Posterior density",
        colour = "Model"
    ) +
    geom_vline(xintercept = 0) +
    coord_cartesian(xlim = c(NA, 5))


p_mean = bind_rows(
    fit_to_mean(hakki) |>
        mutate(
            model = "Hakki"
        ),
    fit_to_mean(modified) |>
        mutate(
            model = "Modified"
        )
) |>
    ggplot() +
    geom_density(aes(vgrow, colour = model)) +
    facet_grid(. ~ name, scales = "free_x") +
    standard_plot_theming() +
    labs(
        x = "Parameter value",
        y = "Posterior density",
        colour = "Model"
    )
p_combined = p_mean / p_cov + plot_layout(
    guides = "collect",
    heights = c(1, 2)
)
ggsave(
    filename = here::here("ATACCC/compare_hakki_modified.pdf"),
    plot = p_combined,
    width = 15,
    height = 15,
    units = "cm",
    dpi = 300
)

p_mean_trajectories = modified |>
    spread_draws(vgrow[i, g])  |>
    group_by(.draw, g) |>
    arrange(i, .by_group = TRUE) |>
    reframe(
        time = seq(from = -5, to = 15, length.out = 1000),
        vl = logVL(time, exp(vgrow)),
    ) |>
    group_by(g, time) |>
    median_qi() |>
    mutate(Group = case_match(
        g,
        1 ~ "Unvaccinated",
        2 ~ "Vaccinated",
    )) |>
    ggplot() +
    geom_ribbon(aes(time, ymin = .lower, ymax = .upper, fill = Group), alpha = 0.3) +
    geom_line(aes(time, vl, colour = Group)) +
    standard_plot_theming() +
    labs(
        x = "Time from peak",
        y = "Log viral load",
    ) +
    coord_cartesian(ylim = c(0, NA))
ggsave(
    filename = here::here("ATACCC/mean_trajectories.pdf"),
    plot = p_mean_trajectories,
    width = 15,
    height = 10,
    units = "cm",
    dpi = 300
)
# tibble_diagnostics = function(sims) {
#   tibble(
#     `Bulk-ESS` = ess_bulk(sims),
#     `Tail-ESS` = ess_tail(sims),
#     Rhat = Rhat(sims),
#     .rows = 1,
#   )
# }

# get_par_diagnostic_tibble = function(fit, pars) {
#   t = rstan::extract(fit, pars, permuted = FALSE)
#   apply(t, 3, tibble_diagnostics) %>% 
#     bind_rows() %>% 
#     mutate(Parameter = dimnames(t)$parameters)
# }

# check_fit = function(fit) {
#   check_divergences(fit)
#   check_treedepth(fit)
#   check_energy(fit)
# }

# get_diagnostic_warnings = function(diagnostics) {
#   min_bulk_ess = min(diagnostics$`Bulk-ESS`, na.rm = TRUE)
#   min_tail_ess = min(diagnostics$`Tail-ESS`, na.rm = TRUE)
#   max_rhat = max(diagnostics$`Rhat`, na.rm = TRUE)
  
#   lst(
#     min_bulk_ess = min_bulk_ess,
#     min_tail_ess = min_tail_ess,
#     max_rhat = max_rhat,
#   )
# }

# fit_diagnostic_summary = function(fit, pars) {
#   check_fit(fit)
#   diagnostics = get_par_diagnostic_tibble(fit, pars)
#   base_output = get_diagnostic_warnings(diagnostics)
#   c(list(diagnostics = diagnostics), base_output)
# }

# indiv_paramater_summary = function(fit) {
#   diagnostics = get_par_diagnostic_tibble(fit, c("p_t_max", "n_v"))
#   base_output = get_diagnostic_warnings(diagnostics)
#   c(list(diagnostics = diagnostics), base_output)
# }

# # hakki_diagnostics = fit_diagnostic_summary(hakki, c("vgrow", "v_sd", "Lc", "v_s", "l_fp",
# #                                                                "fp_ct_mean", "fp_ct_sd"))
# # hakki_indiv = indiv_paramater_summary(hakki)
# # simplified_diagnostics = fit_diagnostic_summary(modified, c("vgrow", "v_sd", "Lc", "v_s", "l_fp"))
# # simplified_indiv = indiv_paramater_summary(modified)