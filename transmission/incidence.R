suppressMessages(library(dplyr))
library(ggplot2)
library(tidybayes)
library(tidyr)

base_data_dir = here::here("transmission/outputs")
load_prevalence = function() {
    readRDS(file.path(base_data_dir, "predict.rds")) |>
    left_join(
        readr::read_csv(
            file.path(base_data_dir, "groups.csv"),
            show_col_types = FALSE
        ),
        by = ".group"
    ) |>
    mutate(prev_predict = expit(.predict))
}

load_incidence = function() {
    readRDS(file.path(base_data_dir, "deconv.rds"))
}

group_by_strata = function(x, ...) {
  all_cols = rlang::exprs(region, daynr, sex, age_group, ethnicityg)
  exclude = rlang::ensyms(...)
  stopifnot(all(exclude %in% all_cols))
  include = setdiff(all_cols, exclude)
  return(group_by(x, !!!include))
}

load_poststrat_table = function() {
    readr::read_csv(file.path(base_data_dir, "poststrat.csv"), show_col_types = FALSE) |>
        select(!.groups) |>
        mutate(
            region = case_match(
                Region_Name,
                "North_East_England"  ~ "1_NE",
                "North_West_England"  ~ "2_NW",
                "Yorkshire"  ~ "3_YH",
                "East_Midlands"  ~ "4_EM",
                "West_Midlands"  ~ "5_WM",
                "East_England"  ~ "6_EE",
                "London"  ~ "7_LD",
                "South_East_England"  ~ "8_SE",
                "South_West_England"  ~ "9_SW",
                .default = NA_character_
            )
        ) |>
        assertr::verify(
            !is.na(region)
            | Region_Name %in% c("Wales", "Scotland", "Northern_Ireland")
        ) |>
        filter(!is.na(region))
}

poststratify = function(data, postrat_table, col, ...) {
    left_join(
        data,
        postrat_table,
        by = c("region", "age_group", "ethnicityg" = "ethnicity", "sex")
    ) |>
        assertr::assert(assertr::not_na, pop) |>
        mutate(n = {{ col }} * pop) |>
        group_by(daynr, .draw, !!!ensyms(...)) |>
        summarise(
            N = sum(pop),
            val = sum(n) / N,
            .groups = "drop"
        )
}

incidence = load_incidence()
poststrat_table = load_poststrat_table()

region_incidence = poststratify(incidence, poststrat_table, incidence, region) |>
    bind_rows(
        poststratify(incidence, poststrat_table, incidence) |>
            mutate(region = "0_Eng")
    ) 
p_region = region_incidence |>
    mutate(
        panel = case_match(
            region,
            "0_Eng" ~ "England",
            "1_NE" ~ "North",
            "2_NW" ~ "North",
            "3_YH" ~ "North",
            "4_EM" ~ "Midlands/East",
            "5_WM" ~ "Midlands/East",
            "6_EE" ~ "Midlands/East",
            "7_LD" ~ "South",
            "8_SE" ~ "South",
            "9_SW" ~ "South",
        ),
        date = daynr + day0,
        region = rename_regions(region),
    ) |>
    ggplot(aes(date, val, colour = region, fill = region)) +
    stat_lineribbon(alpha = 0.3, .width = 0.95) +
    facet_wrap(~panel) +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date",
        y = "Incidence proportion",
    )
stop()
    
poststratify(incidence, poststrat_table, incidence, region, age_group) |>
    group_by(daynr, region, age_group) |>
    median_qi(val) |>
    ggplot(aes(daynr, val, ymin = .lower, ymax = .upper)) +
    geom_lineribbon(alpha = 0.3) +
    facet_grid(region~age_group)
