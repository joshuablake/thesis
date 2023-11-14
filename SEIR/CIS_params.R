library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(tidybayes)
library(tidyr)
source(here::here("utils.R"))


posterior = readr::read_csv(here::here("SEIR/CIS_params.csv")) |>
    extract(
        parameter,
        into = c("parameter", "i"), 
        regex = "^([^\\[]+)(\\[[0-9]+\\])?$"
    ) |>
    transmute(
        region,
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        parameter,
        i = if_else(
            i == "",
            NA_integer_,
            # Remove first and last character from i
            as.integer(substr(i, 2, nchar(i) - 1))
        ),
        value
    )