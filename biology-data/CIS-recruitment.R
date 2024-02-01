suppressMessages(library(dplyr))
library(tidyr)
library(ggplot2)
library(lubridate)
library(patchwork)
source(here::here("utils.R"))

swabs = readxl::read_excel(
    here::here("biology-data", "CIS-technical-data.xslx"),
    sheet = "2f",
    range = "A5:E656",
    col_types = c(
        "date", "numeric", "numeric", "numeric", "numeric"
    )
) |>
    transmute(
        date = `Date`,
        expected = `Total expected swabs`,
        enrolments = `Enrolment swab`,
        repeats = `Repeat swab`,
        achieved_prop = `Achieved %` / 100
    ) 

p_recruit = swabs |>
    filter(date < ymd("2021-02-01")) |>
    ggplot(aes(date, enrolments)) +
    geom_col() +
    standard_plot_theming() +
    labs(
        x = "Date",
        y = "Number of enrolment swabs"
    ) +
    ggtitle("(A) Enrolment swabs")
p_total = swabs |>
    filter(date < ymd("2021-02-01")) |>
    ggplot(aes(date, enrolments + repeats)) +
    geom_col() +
    standard_plot_theming() +
    labs(
        x = "Date",
        y = "Number of swabs"
    ) +
    ggtitle("(B) Total swabs")

ggsave(
    filename = here::here("biology-data", "CIS-recruitment.pdf"),
    plot = p_recruit / p_total,
    width = 6, height = 6
)
