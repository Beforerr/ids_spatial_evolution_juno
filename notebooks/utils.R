if (!requireNamespace("ggdensity", quietly = TRUE)) {
  pak::pkg_install("ggdensity")
}
if (!requireNamespace("gaussplotR", quietly = TRUE)) {
  pak::pkg_install("gaussplotR")
}

if (!requireNamespace("ggmagnify", quietly = TRUE)) {
  pak::pkg_install("hughjonesd/ggmagnify")
}

if (!requireNamespace("curry", quietly = TRUE)) {
  pak::pkg_install("curry")
}

if (!requireNamespace("egg", quietly = TRUE)) {
  pak::pkg_install("egg")
}

library(dplyr)
library(purrr)

library(ggplot2)
library(ggdensity)
library(ggpubr)
library(patchwork)
library(egg)
library(see)

library(glue)
library(arrow)
library(gaussplotR)
library(scales)

# Save the plot, if filename is provided
save_plot <- function(filename, ...) {
  if (!is.null(filename)) {
    ggsave(filename = glue("../figures/{filename}.png"), ...)
    ggsave(filename = glue("../figures/{filename}.pdf"), ...)
  }
}

# partial that change default argument of function
# see https://community.rstudio.com/t/how-to-change-default-argument-of-function-so-that-it-can-be-specified-again-when-use/79919 # nolint
partial2 <- function(func, recursive = FALSE, ...) {
  cl <- as.call(c(list(quote(func)), list(...)))
  cl <- match.call(func,cl)
  args <- as.list(cl)[-1]

  function(...) {
    new_cl <- as.call(c(list(quote(func)), list(...)))
    new_cl <- match.call(func,new_cl)
    new_args <- as.list(new_cl)[-1]
    if (recursive) {
      new_args <- modifyList(args, new_args, keep.null = TRUE)
    }  else {
      keep_args <- setdiff(names(args), names(new_args))
      new_args <- c(args[keep_args], new_args)
    }
    do.call(func, new_args)
  }
}

# Plotting function for Level 1 data.
# Similar to the `geom_bin2d` function, but with added functionality
# - Normalize the data to every x-axis value
# - Add peak values
# - Add mean values with error bars

library(scales)
# Helper function to calculate summary statistics for x-binned data
calculate_summary <- function(data, x_col, y_col, x_seq) {
  data %>%
    mutate(!!x_col := x_seq[
      findInterval(data[[x_col]], x_seq, rightmost.closed = TRUE)
    ]) %>%
    group_by(.data[[x_col]]) %>%
    summarise(
      mean_y = mean(.data[[y_col]], na.rm = TRUE),
      sd_y = sd(.data[[y_col]], na.rm = TRUE),
      # median
      median_y = median(.data[[y_col]], na.rm = TRUE),
    )
}


plot_binned_data <- function(
    data, x_col, y_col, x_bins, y_bins,
    y_lim = NULL, y_log = FALSE,
    add_mode = TRUE,
    add_mean = TRUE,
    add_sd = TRUE,
    add_median = TRUE) {
  # If y_lim is provided, filter the data
  if (!is.null(y_lim)) {
    data <- data %>%
      filter(.data[[y_col]] >= y_lim[1], .data[[y_col]] <= y_lim[2])
  }

  # If transform_y_log is TRUE, transform y_col to log scale
  if (y_log) {
    data[[y_col]] <- log10(data[[y_col]])
    if (!is.null(y_lim)) {
      y_lim <- log10(y_lim)
    }
  }

  # Define bins for x and y based on the input parameters
  x_seq <- seq(min(data[[x_col]]), max(data[[x_col]]), length.out = x_bins + 1)
  y_seq <- seq(min(data[[y_col]]), max(data[[y_col]]), length.out = y_bins + 1)

  data_binned_normalized <- data %>%
    mutate(
      !!x_col := x_seq[findInterval(data[[x_col]], x_seq, rightmost.closed = TRUE, )],
      !!y_col := y_seq[findInterval(data[[y_col]], y_seq, rightmost.closed = TRUE, )]
    ) %>%
    count(!!sym(x_col), !!sym(y_col)) %>%
    group_by(!!sym(x_col)) %>%
    mutate(n = n / sum(n))

  plot <- ggplot() +
    geom_tile(
      data = data_binned_normalized,
      aes(x = .data[[x_col]], y = .data[[y_col]], fill = n)
    )

  # Calculate mode for each x-bin
  if (add_mode) {
    modes <- data_binned_normalized %>%
      group_by(.data[[x_col]]) %>%
      slice_max(n, n = 1)

    # Add the mode line
    plot <- plot + geom_line(
      data = modes,
      aes(x = .data[[x_col]], y = .data[[y_col]], group = 1),
      linetype = "dotted"
    )
  }

  data_xbinned <- calculate_summary(data, x_col, y_col, x_seq)

  plot <- plot +
    geom_errorbar(
      data = data_xbinned,
      aes(x = .data[[x_col]], ymin = mean_y - sd_y, ymax = mean_y + sd_y)
    ) +
    geom_line(data = data_xbinned, aes(x = .data[[x_col]], y = mean_y))


  if (add_median) {
    plot <- plot + geom_line(
      data = data_xbinned,
      aes(x = .data[[x_col]], y = median_y),
      linetype = "dashed"
    )
  }

  # Note: ggline will produce another figure, so we use geom_line instead
  plot +
    scale_fill_viridis_c() +
    theme_pubr(base_size = 16, legend = "r") +
    coord_cartesian(ylim = y_lim)
}

## Common labels

lab_j <- expression("Current Density " (nA ~ m^-2))
lab_j_norm <- expression(Normalized ~ Current ~ Density ~ (J[A]))
lab_l <- "Thickness (km)"
lab_l_norm <- expression("Normalized Thickness " (d[i]))
xlab_r <- "Radial Distance (AU)"


lab_j_log <- expression(Log ~ J ~ (nA ~ m^-2))
lab_j_norm_log <- expression(Log ~ Normalized ~ J ~ (J[A]))
lab_l_log <- glue("Log {lab_l}")
lab_l_norm_log <- expression(Log ~ Normalized ~ Thickness ~ (d[i]))

## Plotting function for quantity and normalized quantity

plot_q_and_qnorm <- function(
    df, x, y1, y2,
    xlab, ylab1, ylab2,
    title = NULL,
    y_lim1 = NULL, y_lim2 = NULL, y_log = TRUE,
    x_bins = 5, y_bins = 12) {
  p1 <- plot_binned_data(df, x, y1,
    x_bins = x_bins, y_bins = y_bins, y_lim = y_lim1, y_log = y_log
  ) +
    labs(x = NULL, y = ylab1) + ggtitle(title)

  p2 <- plot_binned_data(df, x, y2,
    x_bins = x_bins, y_bins = y_bins, y_lim = y_lim2, y_log = y_log
  ) +
    labs(x = xlab, y = ylab2)

  p1 + p2 + plot_layout(ncol = 1, guides = "collect")
}


plot_q_and_qnorm_r <- partial2(
  plot_q_and_qnorm,
  x = "radial_distance",
  xlab = xlab_r,
  title = "Juno",
  y_log = TRUE
)

plot_q_and_qnorm_r_j0 <- partial2(
  plot_q_and_qnorm_r,
  y1 = "j0_k",
  y2 = "j0_k_norm",
  ylab1 = lab_j_log,
  ylab2 = lab_j_norm_log,
  y_lim1 = c(0.01, 30),
  y_lim2 = c(0.002, 1)
)

plot_q_and_qnorm_r_l <- partial2(
  plot_q_and_qnorm_r,
  y1 = "L_k",
  y2 = "L_k_norm",
  ylab1 = lab_l_log,
  ylab2 = lab_l_norm_log,
  y_lim1 = c(500, 40000),
  y_lim2 = c(1, 200)
)


plot_dist <- function(
    y, ylab, y_lim = NULL, y_log = TRUE,
    x_bins = 8,
    y_bins = 16,
    df1 = JNO_events_l1,
    df2 = other_events_l1,
    p1title = "Juno",
    p2title = "ARTEMIS, STEREO and Wind") {
  y_log <- y_log

  x_col <- "radial_distance"
  xlab <- xlab_r
  p1 <- plot_binned_data(df1,
    x_col = x_col, y_col = y,
    x_bins = x_bins, y_bins = y_bins, y_lim = y_lim, y_log = y_log
  ) +
    labs(x = xlab, y = ylab) +
    ggtitle(p1title) +
    theme(legend.position = "none")

  x_col <- "time"
  xlab <- "Time"

  p2 <- plot_binned_data(df2,
    x_col = x_col, y_col = y,
    x_bins = x_bins, y_bins = y_bins, y_lim = y_lim, y_log = y_log
  ) +
    labs(x = xlab, y = ylab) +
    ggtitle(p2title)

  p1 + p2 + plot_layout(ncol = 1, guides = "collect")
}


plot_current_comparison <- function(
    df1, df2,
    p1title = p1title,
    x_bins = 5,
    y_bins = 12) {
  add_mode <- FALSE
  y_lim_j0 <- c(0.01, 30)

  x_col <- "radial_distance"

  y_col <- "j0_k"
  ylab <- expression(Log ~ J ~ (nA ~ m^-2))

  p <- plot_binned_data(df1, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim_j0, y_log = TRUE, add_mode = add_mode)
  p1 <- p + labs(x = NULL, y = ylab) + ggtitle(p1title)


  y_col <- "j0_k_norm"
  y_lim_j0_norm <- c(0.002, 1)
  ylab <- lab_j_norm_log
  p <- plot_binned_data(df1, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim_j0_norm, y_log = TRUE, add_mode = add_mode)
  p2 <- p + labs(x = xlab_r, y = ylab)


  x_col <- "time"

  y_col <- "j0_k"
  p <- plot_binned_data(df2, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim_j0, y_log = TRUE, add_mode = add_mode)
  p3 <- p + labs(x = NULL, y = NULL) + ggtitle(p2title)


  y_col <- "j0_k_norm"
  p <- plot_binned_data(df2, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim_j0_norm, y_log = TRUE, add_mode = add_mode)
  p4 <- p + labs(x = x_lab_t, y = NULL)

  (p1 + p2 + p3 + p4) + layout & scale_fill_viridis_c(limits = c(0.01, 0.28), trans = "log10", name = "pdf")
}


plot_thickness_comparison <- function(
    df1,
    df2,
    p1title = p1title,
    y_lim_1 = c(500, 40000),
    y_lim_2 = c(1, 200)) {
  x_col <- "radial_distance"
  x_bins <- 5
  y_bins <- 12
  add_mode <- TRUE

  # y_lim_1 <- NULL

  ## Panel 01
  y_col <- "L_k"

  y_lim <- y_lim_1
  ylab <- lab_l_log
  p <- plot_binned_data(df1, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim, y_log = TRUE, add_mode = add_mode)
  p1 <- p + labs(x = NULL, y = ylab) + ggtitle(p1title)

  ## Panel 02
  y_col <- "L_k_norm"


  y_lim <- y_lim_2
  ylab <- lab_l_norm_log
  p <- plot_binned_data(df1, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim, y_log = TRUE, add_mode = add_mode)
  p2 <- p + labs(x = x_lab_r, y = ylab)

  ## Panel 03
  x_col <- "time"
  y_col <- "L_k"
  y_lim <- y_lim_1
  p <- plot_binned_data(df2, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim, y_log = TRUE, add_mode = add_mode)
  p3 <- p + labs(x = NULL, y = NULL) + ggtitle(p2title)

  ## Panel 04
  y_col <- "L_k_norm"
  y_lim <- y_lim_2
  p <- plot_binned_data(df2, x_col = x_col, y_col = y_col, x_bins = x_bins, y_bins = y_bins, y_lim = y_lim, y_log = TRUE, add_mode = add_mode)
  p4 <- p + labs(x = x_lab_t, y = NULL)

  (p1 + p2 + p3 + p4) + layout & scale_fill_viridis_c(limits = c(0.01, 0.25), trans = "log10", name = "pdf")
}
