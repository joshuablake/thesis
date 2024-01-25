source(here::here("transmission", "utils.R"))

# Plot labels
label_lookup = function(label) {
    dplyr::case_match(
        label,
        "beta[0]" ~ "sigma[epsilon]",
        "psir" ~ "psi",
        "theta" ~ "rho",
        "matrix_modifiers" ~ "q[c]",
        "i0" ~ "i^`+`",
        .default = label
    )
}
# From: https://chat.openai.com/c/7e15bbc2-473a-4f5b-b54c-7bb9cef8c1f5
parameter_labels <- function(label) {
    c(parse(text = label_lookup(label)))
}

parameter_labeller = structure(function (labels) {
    lapply(
        labels,
        function(x) {
            x |>
                as.character() |>
                parameter_labels() |>
                as.list()
        }
    )
}, class = c("function", "labeller"))

# Load SEIR predictive
load_seir_predictive = function() {
    readr::read_csv(
        here::here("SEIR/CIS/predictive.csv"),
        col_types = readr::cols(
            region = readr::col_character(),
            chain = readr::col_integer(),
            iteration = readr::col_integer(),
            age = readr::col_character(),
            incidence = readr::col_double(),
            prevalence = readr::col_double()
        )
    ) |>
        dplyr::mutate(
            .chain = factor(chain + 1),
            .iteration = iteration + 1,
            .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
            age = normalise_age_groups(age),
            region = normalise_region_names(region)
        ) |>
        dplyr::select(!c(chain, iteration))
}
