library(dplyr)
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
        geom_vline(aes(colour = label, xintercept = !!values)),
        geom_hline(aes(colour = label, yintercept = !!values))
    )
}

tbl_labels = inner_join(
    tibble::tibble(x1 = all_test_dates, x2 = lead(all_test_dates)),
    tibble::tibble(y1 = all_test_dates, y2 = lead(all_test_dates)),
    by = join_by(x1 < y1)
) |>
    tidyr::replace_na(list(y2 = 60)) |>
    arrange(desc(y1), x1) |>
    tibble::rowid_to_column("label") |>
    mutate(
        x = (x1 + x2) / 2,
        y = (y1 + y2) / 2,
    )

shade_alpha = 0.3
plot = ggplot() +
    test_lines(pos_test_dates, TRUE) +
    test_lines(neg_test_dates, FALSE) +
    geom_hline(aes(yintercept = all_test_dates - 0.5), linetype = "dashed") +
    geom_vline(aes(xintercept = all_test_dates + 0.5), linetype = "dashed") +
    # add labels
    geom_text(
        data = tbl_labels,
        aes(x, y, label = label),
        size = 10
    ) +
    theme_minimal() +
    scale_x_continuous(breaks = all_test_dates, minor_breaks = -100:100, limits = c(-10, 60), expand = c(0, 0)) +
    scale_y_continuous(breaks = all_test_dates, minor_breaks = -100:100, limits = c(0, 59.5), expand = c(0, 0)) +
    geom_point(
        aes(x, y),
        tidyr::expand_grid(x = -100:100, y = -100:100),
        size = 0.1,
        alpha = 0.5,
        colour = "grey"
    ) +
    labs(
        x = expression(b[j]),
        y = expression(e[j]),
        colour = "Test results",
        fill = "Regions"
    ) +
    scale_fill_manual(
        values = c(
            "Admissible" = "purple",
            "Undetected" = "red",
            "Impossible" = "black",
            "Inadmissible" = "white"
        ),
        labels = c(
            "Admissible" = "Possible detected episodes, compatible with observations",
            "Undetected" = "Possible undetected episode(s)",
            "Impossible" = "Impossible",
            "Inadmissible" = "Possible detected episodes, ruled out by observations"
        )
    ) +
    scale_colour_manual(
        values = c(
            "Positive" = "red",
            "Negative" = "seagreen"
        )
    ) +
    # Invisible rectangle to force the legend to show the "Inadmissible" colour
    geom_rect(
        aes(fill = "Inadmissible"),
        xmin = -Inf, 
        xmax = Inf, 
        ymin = -Inf, 
        ymax = Inf, 
        alpha = 0, # invisible
        key_glyph = "blank"
    ) +
    geom_rect(
        aes(fill = "Undetected"),
        xmin = -Inf,
        xmax = 0.5,
        ymin = -Inf,
        ymax = Inf,
        alpha = shade_alpha,
        key_glyph = "blank"
    ) +
    purrr::map2(
        c(all_test_dates, 60) + 1, lead(c(all_test_dates, 60)) - 1,
        ~geom_polygon(
            aes(x = c(.x, .x, .y + 1.5) - 0.5, y = c(.x - 1.5, .y, .y) + 0.5, fill = "Undetected"),
            alpha = shade_alpha,
            key_glyph = "blank"
        )
    ) +
    geom_polygon(
        aes(
            fill = "Impossible",
            x = c(0.5, 60, Inf),
            y = c(0, 59.5, 0)
        ),
        alpha = shade_alpha,
        key_glyph = "blank"
    ) +
    geom_rect(
        aes(fill = "Impossible"),
        xmin = 0,
        xmax = Inf,
        ymin = -Inf,
        ymax = 0,
        alpha = shade_alpha,
        key_glyph = "blank"
    ) +
    geom_rect(
        aes(fill = "Admissible"),
        xmin = 14.5,
        xmax = 21.5,
        ymin = 27.5,
        ymax = 55.5,
        alpha = shade_alpha
    ) +
    coord_fixed() +
    guides(
        fill = guide_legend(
            override.aes = list(
                linetype = "solid",
                colour = "black"
            ),
            nrow=2,byrow=TRUE
        )
    ) +
    theme(
        legend.position = "bottom",
        legend.box = "vertical"
    )
ggsave("cis-perfect-testing/regions_diag.pdf", width = 19, height = 20, device = cairo_pdf, units = "cm")
