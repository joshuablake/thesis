library(dplyr)
library(ggplot2)
library(tibble)
library(tidyr)
source(here::here("utils.R"))

plot_testing_schedule = function(x, break_modifier = 0) {
  scale_colours = c(
      test = "black",
      positive = "red",
      negative = "seagreen",
      infected = "blue",
      recovered = "blue"
  )
  scale_colours = scale_colours[unique(x$type)]
  scale_shapes = c(
    test = 4,
    positive = 4,
    negative = 4,
    infected = 20,
    recovered = 20
  )
  scale_shapes = scale_shapes[unique(x$type)]
  
  inf_boxes = x %>% 
    filter(type %in% c("infected", "recovered")) %>% 
    pivot_wider(id_cols = individual, names_from = type, values_from = time)
  
  x_breaks = c((0:3) * 7, (1:5) * 28) - break_modifier
  
  p = x %>% 
    ggplot(aes(time, individual)) +
    geom_point(aes(shape = type, colour = type), size = 3, stroke = 2) +
    geom_hline(aes(yintercept = individual), colour = "grey") +
    scale_y_discrete() +
    scale_x_continuous(breaks = x_breaks, minor_breaks = NULL) +
    scale_shape_manual(values = scale_shapes) +
    scale_colour_manual(values = scale_colours) +
    xlab("Time") +
    standard_plot_theming() +
    theme(
      axis.title.y = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      legend.title = element_blank(),
      legend.position = "bottom",
    #   axis.text = element_text(size = 18),
    #   axis.title = element_text(size = 18),
      panel.grid.major = element_line(colour = "black"),
    #   legend.text = element_text(size = 18)
    )
  
  if (nrow(inf_boxes) > 0) {
    p = p +
      geom_rect(aes(xmin = infected, xmax = recovered,
                  ymin = individual - 0.5, ymax = individual + 0.5,
                  x = NULL),
              data = inf_boxes, fill = "red", alpha = 0.1)
  }
  
  return(p)
}

p_censor = tibble(
  time = c((0:3) * 7, (1:3) * 28),
) %>% 
  mutate(
    type = if_else(time >= 10 & time <= 30,
                   "positive", "negative")
  ) %>% 
  bind_rows(tribble(
    ~time, ~type,
    10, "infected",
    40, "recovered",
  )) %>% 
  mutate(individual = 1) %>% 
  plot_testing_schedule()
save_plot(
  filename = "cis-perfect-testing/double-interval-censor.pdf",
  plot = p_censor,
  height = 4
)

p_truncation = expand_grid(
  time = c((0:3) * 7, (1:3) * 28),
  individual = 1:2,
  type = "negative",
) %>% 
  bind_rows(tribble(
    ~individual, ~time, ~type,
    1, 33, "infected",
    1, 43, "recovered",
  )) %>% 
  plot_testing_schedule()
save_plot(
  filename = "cis-perfect-testing/truncation.pdf",
  plot = p_truncation,
  height = 5
)