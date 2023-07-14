library(dplyr)
library(ggplot2)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

n_lambdas_to_plot = 30

output_file = function(..., read_from_RDS = TRUE) {
    filename = here::here("ATACCC-distributions", ...)
    if (read_from_RDS) return(readRDS(filename))
    return(filename)
}

tbl_ataccc = output_file("posterior_samples.rds")

mvnorm_to_dist = function(draw_matrix) {
    draw_matrix |>
        as_tibble() |>
        tibble::rowid_to_column(".draw") |>
        pivot_longer(!.draw, names_to = "time", values_to = "value") |>
        mutate(time = as.integer(time)) |>
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
logit_normal_mean = output_file("logit_hazard_mean.rds")
logit_normal_cov = output_file("logit_hazard_cov.rds")
tbl_logit_normal = mvtnorm::rmvnorm(
    1e3,
    mean = logit_normal_mean[1:n_lambdas_to_plot],
    sigma = logit_normal_cov[1:n_lambdas_to_plot,1:n_lambdas_to_plot]
) |>
    mvnorm_to_dist()

tbl_priors = bind_rows(
    tbl_ataccc |>
        mutate(version = "Posterior"),
    tbl_logit_normal |>
        mutate(version = "Normal approx"),
)

tbl_priors |>
    group_by(time, version) |>
    median_qi(S) |>
    ggplot(aes(time, S, ymin = .lower, ymax = .upper, colour = version,
                fill = version)) +
    geom_lineribbon(alpha = 0.4) +
    facet_wrap(~version)
