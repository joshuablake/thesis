library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))


posterior = readr::read_csv(here::here("SEIR/CIS/params.csv")) |>
    extract(
        parameter,
        into = c("parameter", "i"), 
        regex = "^([^\\[]+)(\\[[0-9]+\\])?$"
    ) |>
    transmute(
        region,
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        parameter,
        i = if_else(
            i == "",
            NA_integer_,
            # Remove first and last character from i
            as.integer(substr(i, 2, nchar(i) - 1))
        ),
        value
    ) |>
    mutate(
        value = if_else(
            parameter %in% c("matrix_modifiers", "theta"),
            exp(value),
            value
        )
    )

# posterior |>
#     filter(.iteration >= 500e3) |>
#     group_nest(region, parameter, i) |>
#     mutate(
#         Rhat = map_dbl(
#             data,
#             ~.x |>
#                 select(!.draw) |>
#                 pivot_wider(
#                     names_from = .chain,
#                 ) |>
#                 select(!.iteration) |>
#                 as.matrix() |>
#                 rstan::Rhat()
#         )
#     ) |>
#     arrange(desc(Rhat))

# posterior |>
#     filter(.iteration >= 500e3) |>
#     group_nest(region, parameter, i) |>
#     mutate(
#         ESS = map_dbl(
#             data,
#             ~.x |>
#                 select(!.draw) |>
#                 pivot_wider(
#                     names_from = .chain,
#                 ) |>
#                 select(!.iteration) |>
#                 as.matrix() |>
#                 rstan::ess_bulk()
#         )
#     ) |>
#     arrange(ESS)

posterior |>
    filter(
        !parameter %in% c("beta", "pi", "theta")
    ) |>
    ggplot(aes(x = value)) +
    geom_density(aes(colour = "Posterior")) +
    geom_density(aes(colour = "Prior"), data = prior_samples) +
    facet_grid(region~parameter, scales = "free") #+
    coord_cartesian(ylim = c(0, 1))

n_prior_samples = 10e3
prior_samples = tibble(
    matrix_modifiers = rlnorm(n_prior_samples, -0.4325, 0.1174),
    i0 = rbeta(n_prior_samples, 0.5, 1000),
    psir = rnorm(n_prior_samples, 0.06, 0.04),
    # theta = rexp(n_prior_samples, 2e5),
) |>
    tibble::rowid_to_column(".draw") |>
    pivot_longer(
        !.draw,
        names_to =  "parameter",
        values_to = "value"
    )
