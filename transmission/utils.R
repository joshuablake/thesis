normalise_region_names = function(in_names) {
    out = stringr::str_replace_all(in_names, "_", " ") |>
        stringr::str_replace_all(" England", "") |>
        dplyr::case_match(
            c("1_NE", "North East") ~ "North East",
            c("2_NW", "North West") ~ "North West",
            c("3_YH", "Yorkshire and the Humber", "Yorkshire") ~ "Yorkshire",
            c("4_EM", "East Midlands") ~ "East Midlands",
            c("5_WM", "West Midlands") ~ "West Midlands",
            c("6_EE", "East of England", "East", "East of") ~ "East of England",
            c("7_LD", "London") ~ "London",
            c("8_SE", "South East") ~ "South East",
            c("9_SW", "South West") ~ "South West",
            c("0_Eng", "England") ~ "England"
        )
    stopifnot(!is.na(out))
    return(out)
}

normalise_age_groups = function(in_names) {
    paste0("[", stringr::str_sub(in_names, 2, -2), ")") |>
        stringr::str_replace(stringr::fixed("[1,"), "[0,") |>
        stringr::str_replace(stringr::fixed("+"), "Inf") |>
        stringr::str_replace(stringr::fixed(", "), ",")
}

load_poststrat_table = function() {
    readr::read_csv(here::here("transmission", "outputs", "poststrat.csv"), show_col_types = FALSE) |>
        dplyr::filter(!Region_Name %in% c("Wales", "Scotland", "Northern_Ireland")) |>
        dplyr::mutate(
            region = normalise_region_names(Region_Name),
            age_group = normalise_age_groups(age_group),
        ) |>
        dplyr::select(!c(.groups, Region_Name))
}

poststratify_SEIR = function(data, poststrat_table, col, ...) {
    poststrat_table |>
        summarise(
            pop = sum(pop),
            .by = c("region", "age_group")
        ) |>
        dplyr::right_join(
            data,
            by = c("region", "age_group"),
            relationship = "one-to-many"
        ) |>
        # filter(is.na(pop)) |>
        # print()
        assertr::assert(assertr::not_na, pop) |>
        dplyr::mutate(n = {{ col }} * pop) |>
        dplyr::group_by(day, .draw, !!!ensyms(...)) |>
        dplyr::summarise(
            N = sum(pop),
            val = sum(n) / N,
            .groups = "drop"
        )
}
