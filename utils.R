standard_plot_theming = function() {
    rlang::list2(
        theme_minimal(),
    )
}

theme_survival_time_series = function() {
    rlang::list2(
        standard_plot_theming(),
        scale_x_continuous(breaks = 0:100*14, minor_breaks = 0:100*2),
        scale_y_continuous(breaks = 0:10/10, minor_breaks = 0:20/20),
        labs(
            x = "t",
            fill = "Hazard prior",
            colour = "Hazard prior"
        ),
        theme(legend.position = "bottom"),
        coord_cartesian(xlim = c(0, 100))
    )
}

logit = function(x) log(x) - log(1 - x)
expit = function(x) 1 / (1 + exp(-x))