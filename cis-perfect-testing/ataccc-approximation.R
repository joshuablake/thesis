library(dplyr)
library(ggplot2)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))

n_lambdas_to_plot = 41

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
    20e3,
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

p_surv = tbl_priors |>
    filter(time <= n_lambdas_to_plot - 1) |>
    group_by(time, version) |>
    median_qi(S) |>
    ggplot(aes(time, S, ymin = .lower, ymax = .upper, colour = version,
                fill = version)) +
    geom_lineribbon(alpha = 0.4) +
    standard_plot_theming()
ggsave(
    filename = here::here(
        "cis-perfect-testing/ataccc-approximation-survival.png"
    ),
    plot = p_surv,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)

p_hazard = tbl_priors |>
    filter(time <= 11) |>
    ggplot(aes(lambda, colour = version)) +
    geom_density() +
    facet_wrap(~time, scales = "free", ncol = 4) +
    standard_plot_theming() +
    labs(
        x = expression(lambda),
        y = "Density",
        colour = ""
    ) +
    theme(
        legend.position = "bottom",
        axis.text.x = element_text(angle = 45)
    )

ggsave(
    filename = here::here(
        "cis-perfect-testing/ataccc-approximation-hazard.png"
    ),
    plot = p_hazard,
    width = 15,
    height = 20,
    units = "cm",
    dpi = 300
)
