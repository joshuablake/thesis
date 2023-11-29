# Plot labels
# From: https://chat.openai.com/c/7e15bbc2-473a-4f5b-b54c-7bb9cef8c1f5
parameter_labels <- function(label) {
    labels <- dplyr::case_match(
        label,
        "beta[0]" ~ "sigma[epsilon]",
        "psir" ~ "psi",
        "theta" ~ "rho",
        "matrix_modifiers" ~ "q[c]",
        "i0" ~ "i^`+`",
        .default = label
    )
    parse(text = labels)
}

region_labels = function(label) {
    stringr::str_replace_all(label, "_", " ") |>
        stringr::str_replace_all(" England", "")
}
