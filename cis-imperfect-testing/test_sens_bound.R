library(dplyr)
library(ggplot2)
library(tidyr)
source(here::here("utils.R"))

bound_data = readr::read_csv(
    here::here("cis-imperfect-testing/STATS18596/changing-sensitivity/results_by_day_of_episode.csv")
)

p_bound = bound_data |>
    filter(result != "result") |>
    pivot_wider(
        names_from = result,
        values_from = n,
        id_cols = days_since_first_pos,
        values_fill = 0
    ) |>
    transmute(
        days_since_first_pos,
        true_pos = Positive,
        min_false_neg = `Intermittent neg`,
        max_false_neg = min_false_neg + `First neg`,
        min_test_sens = true_pos / (true_pos + max_false_neg),
        max_test_sens = true_pos / (true_pos + min_false_neg),
        proposed = if_else(
            days_since_first_pos <= 50,
            0.9 - (0.9 - 0.5)/50 * days_since_first_pos,
            0.5
        )
    ) |>
    ggplot() +
    geom_line(aes(days_since_first_pos, min_test_sens, colour = "Min")) +
    geom_line(aes(days_since_first_pos, max_test_sens, colour = "Max")) +
    # geom_line(aes(days_since_first_pos, proposed, colour = "Proposed")) +
    standard_plot_theming() +
    labs(
        x = "Days since first positive test",
        y = "Test sensitivity",
        colour = NULL
    )

ggsave(
    filename = here::here("cis-imperfect-testing/test-sens-bound.png"),
    plot = p_bound,
    width = 15,
    height = 9,
    units = "cm",
    dpi = 300
)