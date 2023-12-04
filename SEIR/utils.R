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

region_labels = function(label) {
    stringr::str_replace_all(label, "_", " ") |>
        stringr::str_replace_all(" England", "")
}