library(dplyr)
library(ggplot2)
library(purrr)
library(rstan)
library(tidybayes)
library(tidyverse)
source("utils.R")

hakki = readRDS("ATACCC/fit.rds")
modified = readRDS("ATACCC/fit2.rds")

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
    facet_grid(name_i ~ name_j)

fit_to_mean = function(fit) {
    fit |>
        spread_draws(vgrow[i, g]) |>
        filter(g == 1) |>
        mutate(name = parameter_names[i])
}

bind_rows(
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
    facet_grid(. ~ name, scales = "free_x")

tibble_diagnostics = function(sims) {
  tibble(
    `Bulk-ESS` = ess_bulk(sims),
    `Tail-ESS` = ess_tail(sims),
    Rhat = Rhat(sims),
    .rows = 1,
  )
}

get_par_diagnostic_tibble = function(fit, pars) {
  t = rstan::extract(fit, pars, permuted = FALSE)
  apply(t, 3, tibble_diagnostics) %>% 
    bind_rows() %>% 
    mutate(Parameter = dimnames(t)$parameters)
}

check_fit = function(fit) {
  check_divergences(fit)
  check_treedepth(fit)
  check_energy(fit)
}

get_diagnostic_warnings = function(diagnostics) {
  min_bulk_ess = min(diagnostics$`Bulk-ESS`, na.rm = TRUE)
  min_tail_ess = min(diagnostics$`Tail-ESS`, na.rm = TRUE)
  max_rhat = max(diagnostics$`Rhat`, na.rm = TRUE)
  
  lst(
    min_bulk_ess = min_bulk_ess,
    min_tail_ess = min_tail_ess,
    max_rhat = max_rhat,
  )
}

fit_diagnostic_summary = function(fit, pars) {
  check_fit(fit)
  diagnostics = get_par_diagnostic_tibble(fit, pars)
  base_output = get_diagnostic_warnings(diagnostics)
  c(list(diagnostics = diagnostics), base_output)
}

indiv_paramater_summary = function(fit) {
  diagnostics = get_par_diagnostic_tibble(fit, c("p_t_max", "n_v"))
  base_output = get_diagnostic_warnings(diagnostics)
  c(list(diagnostics = diagnostics), base_output)
}

hakki_diagnostics = fit_diagnostic_summary(hakki, c("vgrow", "v_sd", "Lc", "v_s", "l_fp",
                                                               "fp_ct_mean", "fp_ct_sd"))
hakki_indiv = indiv_paramater_summary(hakki)
simplified_diagnostics = fit_diagnostic_summary(modified, c("vgrow", "v_sd", "Lc", "v_s", "l_fp"))
simplified_indiv = indiv_paramater_summary(modified)