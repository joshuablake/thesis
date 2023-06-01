library(ggplot2)

neg_test_dates = c(0, 7, 14, 56)
pos_test_dates = c(28, 21)
all_test_dates = sort(c(neg_test_dates, pos_test_dates))

test_lines = function(values, result) {
    if (result) {
        label = "Positive"
        colour = "Red"
    } else {
        label = "Negative"
        colour = "Green"
    }
    list(
        geom_vline(aes(colour = label, xintercept = !!values), linetype = "dotted"),
        geom_hline(aes(colour = label, yintercept = !!values), linetype = "dotted")
    )
}

shade_alpha = 0.3
plot = ggplot() +
    test_lines(pos_test_dates, TRUE) +
    test_lines(neg_test_dates, FALSE) +
    theme_minimal() +
    scale_x_continuous(breaks = all_test_dates, minor_breaks = -100:100, limits = c(-10, 60)) +
    scale_y_continuous(breaks = all_test_dates, minor_breaks = -100:100, limits = c(0, 60)) +
    labs(
        x = "Infection time",
        y = "Recovery time",
        colour = "Test results",
        fill = "Regions"
    ) +
    scale_fill_manual(
        values = c(
            "Admissible" = "purple",
            "Truncated" = "Red",
            "Impossible" = "black"
        )
    ) +
    scale_colour_manual(
        values = c(
            "Positive" = "red",
            "Negative" = "seagreen"
        )
    ) +
    geom_rect(
        aes(fill = "Truncated"),
        xmin = -Inf,
        xmax = 0,
        ymin = -Inf,
        ymax = Inf,
        alpha = shade_alpha
    ) +
    purrr::map2(
        all_test_dates + 1, dplyr::lead(all_test_dates) - 1,
        ~geom_polygon(
            aes(x = c(.x, .x, .y), y = c(.x, .y, .y), fill = "Truncated"),
            alpha = shade_alpha,
        )
    ) +
    geom_polygon(
        aes(
            fill = "Impossible",
            x = c(0, 60, Inf),
            y = c(0, 60, 0)
        ),
        alpha = shade_alpha
    ) +
    geom_rect(
        aes(fill = "Impossible"),
        xmin = 0,
        xmax = Inf,
        ymin = -Inf,
        ymax = 0,
        alpha = shade_alpha
    ) +
    geom_rect(
        aes(fill = "Admissible"),
        xmin = 15,
        xmax = 21,
        ymin = 28,
        ymax = 55,
        alpha = shade_alpha
    ) +
    coord_fixed() +
    guides(
        fill = guide_legend(
            override.aes = list(alpha = shade_alpha),
        )
    ) +
    theme(
        legend.position = "bottom",
        legend.box = "vertical"
    )
ggsave("cis-perfect-testing/regions_diag.png", width = 6, height = 5.5)
