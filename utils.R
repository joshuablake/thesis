standard_plot_theming = function() {
    rlang::list2(
        theme_minimal()
    )
}

logit = function(x) log(x) - log(1 - x)
expit = function(x) 1 / (1 + exp(-x))