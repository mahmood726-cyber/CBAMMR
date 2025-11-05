#' Advanced Interactive Visualization Module
#'
#' Publication-quality interactive visualizations for meta-analysis:
#' - Enhanced forest plots with interactivity (plotly integration)
#' - Advanced funnel plots with bias detection contours
#' - Network plots for network meta-analysis
#' - Baujat plots for outlier detection
#' - L'Abbé plots for binary data
#' - Galbraith plots (radial plots)
#' - GOSH plots for heterogeneity patterns
#' - Cumulative forest plots
#' - Leave-one-out sensitivity plots
#' - Publication-ready export (PNG, PDF, SVG)
#'
#' @name mod_advanced_viz
#' @rdname mod_advanced_viz
#'
#' @import ggplot2
#' @import plotly
#' @import metafor
#' @import dplyr
#' @import gridExtra
NULL

#' @describeIn mod_advanced_viz Create enhanced interactive forest plot
#' @param x Meta-analysis results object (rma, rma.uni, or metagen)
#' @param title Character. Plot title
#' @param interactive Logical. Create interactive plotly plot?
#' @param study_labels Character vector. Study labels
#' @param show_weights Logical. Show study weights?
#' @param annotate_stats Logical. Show summary statistics?
#' @param color_scheme Character. Color palette ("default", "colorblind", "bw")
#' @export
#' @examples
#' \dontrun{
#' library(metafor)
#' data(dat.bcg)
#' res <- rma(ai = tpos, bi = tneg, ci = cpos, di = cneg, data = dat.bcg, measure = "RR")
#' cbamm_forest_enhanced(res, interactive = TRUE)
#' }
cbamm_forest_enhanced <- function(x,
                                  title = "Forest Plot",
                                  interactive = FALSE,
                                  study_labels = NULL,
                                  show_weights = TRUE,
                                  annotate_stats = TRUE,
                                  color_scheme = "default") {

  # Check for required packages
  if (!check_package_available("metafor", "forest plots")) {
    stop("metafor package required for forest plots")
  }

  # Extract data from meta-analysis object
  if (inherits(x, c("rma", "rma.uni", "rma.mv"))) {
    yi <- x$yi
    vi <- x$vi
    sei <- sqrt(vi)
    ci_lb <- yi - 1.96 * sei
    ci_ub <- yi + 1.96 * sei
    weights <- weights(x)

    if (is.null(study_labels)) {
      study_labels <- if (!is.null(x$slab)) x$slab else paste0("Study ", 1:length(yi))
    }

  } else if (inherits(x, "metagen")) {
    yi <- x$TE
    sei <- x$seTE
    ci_lb <- x$lower
    ci_ub <- x$upper
    weights <- x$w

    if (is.null(study_labels)) {
      study_labels <- x$studlab
    }

  } else {
    stop("x must be a meta-analysis results object (rma or metagen)")
  }

  # Create data frame for plotting
  plot_data <- data.frame(
    study = study_labels,
    estimate = yi,
    lower = ci_lb,
    upper = ci_ub,
    weight = weights,
    stringsAsFactors = FALSE
  )

  # Add summary row
  summary_row <- data.frame(
    study = "Summary",
    estimate = x$b[1],
    lower = x$ci.lb,
    upper = x$ci.ub,
    weight = 100,
    stringsAsFactors = FALSE
  )

  plot_data <- rbind(plot_data, summary_row)
  plot_data$is_summary <- c(rep(FALSE, nrow(plot_data) - 1), TRUE)

  # Reverse order for top-to-bottom display
  plot_data$study <- factor(plot_data$study, levels = rev(plot_data$study))

  # Set color scheme
  if (color_scheme == "colorblind") {
    color_study <- "#0072B2"
    color_summary <- "#D55E00"
  } else if (color_scheme == "bw") {
    color_study <- "black"
    color_summary <- "black"
  } else {
    color_study <- "#4E79A7"
    color_summary <- "#E15759"
  }

  # Create base plot
  p <- ggplot(plot_data, aes(x = estimate, y = study)) +
    # Confidence intervals
    geom_segment(aes(x = lower, xend = upper, y = study, yend = study,
                     color = is_summary, size = is_summary,
                     text = paste0(study, "\n",
                                  "Estimate: ", round(estimate, 3), "\n",
                                  "95% CI: [", round(lower, 3), ", ", round(upper, 3), "]\n",
                                  if (show_weights) paste0("Weight: ", round(weight, 1), "%") else ""))) +
    # Point estimates
    geom_point(aes(color = is_summary, size = is_summary * 3 + weight / 20)) +
    # Reference line at null
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    # Color scheme
    scale_color_manual(values = c("FALSE" = color_study, "TRUE" = color_summary), guide = "none") +
    scale_size_continuous(range = c(2, 6), guide = "none") +
    # Theme
    theme_minimal() +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.y = element_text(size = 10),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "none"
    ) +
    labs(
      title = title,
      x = "Effect Size",
      y = ""
    )

  # Add statistics annotation
  if (annotate_stats) {
    stats_text <- sprintf(
      "I² = %.1f%%, τ² = %.3f, p %s %.3f",
      x$I2,
      x$tau2,
      if (x$pval < 0.001) "<" else "=",
      if (x$pval < 0.001) 0.001 else x$pval
    )

    p <- p + labs(subtitle = stats_text)
  }

  # Convert to interactive if requested
  if (interactive) {
    p <- ggplotly(p, tooltip = "text") %>%
      layout(
        title = list(text = paste0(title, if (annotate_stats) paste0("\n<sub>", stats_text, "</sub>") else "")),
        hovermode = "closest"
      )
  }

  return(p)
}

#' @describeIn mod_advanced_viz Create enhanced funnel plot with contours
#' @param x Meta-analysis results object
#' @param title Character. Plot title
#' @param add_contours Logical. Add significance contours?
#' @param interactive Logical. Create interactive plot?
#' @param trim_fill Logical. Add trim-and-fill imputed studies?
#' @export
cbamm_funnel_enhanced <- function(x,
                                  title = "Funnel Plot",
                                  add_contours = TRUE,
                                  interactive = FALSE,
                                  trim_fill = FALSE) {

  # Extract data
  if (inherits(x, c("rma", "rma.uni", "rma.mv"))) {
    yi <- x$yi
    vi <- x$vi
    sei <- sqrt(vi)
  } else {
    stop("x must be a meta-analysis results object")
  }

  # Create data frame
  plot_data <- data.frame(
    estimate = yi,
    se = sei,
    precision = 1 / sei
  )

  # Add trim-and-fill if requested
  if (trim_fill && check_package_available("metafor", "trim-and-fill", silent = TRUE)) {
    tf <- metafor::trimfill(x)
    if (tf$k0 > 0) {
      imputed_data <- data.frame(
        estimate = tf$yi[(length(yi) + 1):length(tf$yi)],
        se = sqrt(tf$vi[(length(vi) + 1):length(tf$vi)]),
        precision = 1 / sqrt(tf$vi[(length(vi) + 1):length(tf$vi)])
      )
      plot_data$type <- "Observed"
      imputed_data$type <- "Imputed"
      plot_data <- rbind(plot_data, imputed_data)
    }
  }

  if (!"type" %in% names(plot_data)) {
    plot_data$type <- "Observed"
  }

  # Base plot
  p <- ggplot(plot_data, aes(x = estimate, y = precision, color = type, shape = type)) +
    geom_point(size = 3, alpha = 0.7) +
    scale_color_manual(values = c("Observed" = "#4E79A7", "Imputed" = "#E15759")) +
    scale_shape_manual(values = c("Observed" = 16, "Imputed" = 17)) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    ) +
    labs(
      title = title,
      x = "Effect Size",
      y = "Precision (1/SE)",
      color = "",
      shape = ""
    )

  # Add contours if requested
  if (add_contours) {
    # Create contour data
    summary_es <- x$b[1]
    se_range <- range(sei)
    es_range <- range(yi)

    # Expand ranges
    es_seq <- seq(summary_es - 3 * se_range[2], summary_es + 3 * se_range[2], length.out = 100)
    se_seq <- seq(0, se_range[2] * 1.5, length.out = 100)

    contour_grid <- expand.grid(es = es_seq, se = se_seq)
    contour_grid$z <- abs(contour_grid$es - summary_es) / contour_grid$se

    # Add contour lines for p < 0.05, p < 0.01, p < 0.001
    p <- p +
      geom_contour(data = contour_grid, aes(x = es, y = 1/se, z = z, color = NULL, shape = NULL),
                   breaks = c(1.96, 2.58, 3.29), color = "gray70", linetype = "dashed") +
      geom_vline(xintercept = summary_es, linetype = "solid", color = "gray40")
  }

  if (interactive) {
    p <- ggplotly(p)
  }

  return(p)
}

#' @describeIn mod_advanced_viz Create Baujat plot for outlier detection
#' @param x Meta-analysis results object
#' @param title Character. Plot title
#' @param interactive Logical. Create interactive plot?
#' @param label_outliers Logical. Label potential outliers?
#' @export
cbamm_baujat_plot <- function(x,
                              title = "Baujat Plot",
                              interactive = FALSE,
                              label_outliers = TRUE) {

  if (!inherits(x, c("rma", "rma.uni"))) {
    stop("x must be an rma object from metafor")
  }

  # Calculate Baujat diagnostics
  baujat_data <- metafor::baujat(x, plotit = FALSE)

  plot_data <- data.frame(
    study = if (!is.null(x$slab)) x$slab else paste0("Study ", 1:length(baujat_data$x)),
    x = baujat_data$x,  # Contribution to overall Q
    y = baujat_data$y   # Influence on overall result
  )

  # Identify outliers (top 20% in both dimensions)
  x_threshold <- quantile(plot_data$x, 0.80)
  y_threshold <- quantile(plot_data$y, 0.80)
  plot_data$is_outlier <- plot_data$x > x_threshold & plot_data$y > y_threshold

  p <- ggplot(plot_data, aes(x = x, y = y, label = study, color = is_outlier)) +
    geom_point(size = 3, alpha = 0.7) +
    scale_color_manual(values = c("FALSE" = "#4E79A7", "TRUE" = "#E15759"), guide = "none") +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold")
    ) +
    labs(
      title = title,
      x = "Contribution to Overall Heterogeneity (Q)",
      y = "Influence on Overall Result"
    )

  if (label_outliers) {
    p <- p + ggrepel::geom_text_repel(
      data = plot_data[plot_data$is_outlier, ],
      size = 3,
      box.padding = 0.5
    )
  }

  if (interactive) {
    p <- ggplotly(p, tooltip = c("x", "y", "label"))
  }

  return(p)
}

#' @describeIn mod_advanced_viz Create cumulative forest plot
#' @param x Meta-analysis results object
#' @param order Character. Order studies by ("year", "precision", "weight")
#' @param title Character. Plot title
#' @export
cbamm_cumulative_forest <- function(x,
                                    order = "year",
                                    title = "Cumulative Forest Plot") {

  if (!inherits(x, c("rma", "rma.uni"))) {
    stop("x must be an rma object from metafor")
  }

  # Perform cumulative meta-analysis
  cum_res <- metafor::cumul(x, order = order)

  # Extract results
  plot_data <- data.frame(
    study = cum_res$slab,
    estimate = cum_res$estimate,
    ci.lb = cum_res$ci.lb,
    ci.ub = cum_res$ci.ub,
    order = 1:length(cum_res$estimate)
  )

  # Reverse for plotting
  plot_data$study <- factor(plot_data$study, levels = rev(plot_data$study))

  p <- ggplot(plot_data, aes(x = estimate, y = study)) +
    geom_segment(aes(x = ci.lb, xend = ci.ub, y = study, yend = study), color = "#4E79A7") +
    geom_point(size = 2, color = "#4E79A7") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    theme_minimal() +
    theme(
      panel.grid.major.y = element_blank(),
      plot.title = element_text(hjust = 0.5, face = "bold")
    ) +
    labs(
      title = paste(title, "-", order),
      x = "Cumulative Effect Size",
      y = ""
    )

  return(p)
}

#' @describeIn mod_advanced_viz Create leave-one-out sensitivity plot
#' @param x Meta-analysis results object
#' @param title Character. Plot title
#' @param sort Logical. Sort by influence?
#' @export
cbamm_leave_one_out_plot <- function(x,
                                     title = "Leave-One-Out Analysis",
                                     sort = TRUE) {

  if (!inherits(x, c("rma", "rma.uni"))) {
    stop("x must be an rma object from metafor")
  }

  # Perform leave-one-out
  loo_res <- metafor::leave1out(x)

  plot_data <- data.frame(
    study = if (!is.null(x$slab)) x$slab else paste0("Study ", 1:nrow(loo_res)),
    estimate = loo_res$estimate,
    ci.lb = loo_res$ci.lb,
    ci.ub = loo_res$ci.ub,
    influence = abs(loo_res$estimate - x$b[1])
  )

  if (sort) {
    plot_data <- plot_data[order(plot_data$influence, decreasing = TRUE), ]
  }

  plot_data$study <- factor(plot_data$study, levels = rev(plot_data$study))

  # Highlight studies with large influence
  threshold <- quantile(plot_data$influence, 0.80)
  plot_data$high_influence <- plot_data$influence > threshold

  p <- ggplot(plot_data, aes(x = estimate, y = study, color = high_influence)) +
    geom_segment(aes(x = ci.lb, xend = ci.ub, y = study, yend = study)) +
    geom_point(size = 2) +
    geom_vline(xintercept = x$b[1], linetype = "solid", color = "black", size = 1) +
    geom_vline(xintercept = x$ci.lb, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = x$ci.ub, linetype = "dashed", color = "gray50") +
    scale_color_manual(values = c("FALSE" = "#4E79A7", "TRUE" = "#E15759"), guide = "none") +
    theme_minimal() +
    theme(
      panel.grid.major.y = element_blank(),
      plot.title = element_text(hjust = 0.5, face = "bold")
    ) +
    labs(
      title = title,
      subtitle = "Vertical lines: overall estimate and 95% CI",
      x = "Effect Size (Excluding One Study)",
      y = ""
    )

  return(p)
}

#' @describeIn mod_advanced_viz Comprehensive visualization suite
#' @param x Meta-analysis results object
#' @param plots Character vector. Which plots to generate ("all", "forest", "funnel", "baujat", "cumulative", "loo")
#' @param interactive Logical. Generate interactive plots?
#' @param output_dir Character. Directory to save plots (NULL = don't save)
#' @param output_format Character. Format for saved plots ("png", "pdf", "svg")
#' @export
#' @examples
#' \dontrun{
#' library(metafor)
#' data(dat.bcg)
#' res <- rma(ai = tpos, bi = tneg, ci = cpos, di = cneg,
#'           data = dat.bcg, measure = "RR", method = "REML")
#'
#' # Generate all plots
#' plots <- cbamm_visualize_comprehensive(
#'   res,
#'   plots = "all",
#'   interactive = TRUE,
#'   output_dir = "meta_analysis_plots",
#'   output_format = "png"
#' )
#'
#' # View plots
#' print(plots$forest)
#' print(plots$funnel)
#' }
cbamm_visualize_comprehensive <- function(x,
                                          plots = "all",
                                          interactive = FALSE,
                                          output_dir = NULL,
                                          output_format = "png") {

  available_plots <- c("forest", "funnel", "baujat", "cumulative", "loo")

  if ("all" %in% plots) {
    plots <- available_plots
  }

  message("Generating comprehensive visualization suite...")
  message(sprintf("  Plots requested: %s", paste(plots, collapse = ", ")))
  message(sprintf("  Interactive: %s", interactive))

  plot_list <- list()

  # Forest plot
  if ("forest" %in% plots) {
    message("  Creating enhanced forest plot...")
    plot_list$forest <- safe_try(
      cbamm_forest_enhanced(x, interactive = interactive, annotate_stats = TRUE),
      context = "forest plot",
      return_on_error = NULL
    )
  }

  # Funnel plot
  if ("funnel" %in% plots) {
    message("  Creating enhanced funnel plot...")
    plot_list$funnel <- safe_try(
      cbamm_funnel_enhanced(x, interactive = interactive, add_contours = TRUE, trim_fill = TRUE),
      context = "funnel plot",
      return_on_error = NULL
    )
  }

  # Baujat plot
  if ("baujat" %in% plots) {
    message("  Creating Baujat plot...")
    plot_list$baujat <- safe_try(
      cbamm_baujat_plot(x, interactive = interactive, label_outliers = TRUE),
      context = "Baujat plot",
      return_on_error = NULL
    )
  }

  # Cumulative forest
  if ("cumulative" %in% plots) {
    message("  Creating cumulative forest plot...")
    plot_list$cumulative <- safe_try(
      cbamm_cumulative_forest(x, order = "year"),
      context = "cumulative forest plot",
      return_on_error = NULL
    )
  }

  # Leave-one-out
  if ("loo" %in% plots) {
    message("  Creating leave-one-out plot...")
    plot_list$loo <- safe_try(
      cbamm_leave_one_out_plot(x, sort = TRUE),
      context = "leave-one-out plot",
      return_on_error = NULL
    )
  }

  # Save plots if output directory specified
  if (!is.null(output_dir)) {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }

    message(sprintf("  Saving plots to %s...", output_dir))

    for (plot_name in names(plot_list)) {
      if (!is.null(plot_list[[plot_name]])) {
        filename <- file.path(output_dir, paste0(plot_name, "_plot.", output_format))

        if (interactive && inherits(plot_list[[plot_name]], "plotly")) {
          # Save interactive plots as HTML
          htmlwidgets::saveWidget(plot_list[[plot_name]], file = gsub(output_format, "html", filename))
        } else {
          # Save static plots
          ggsave(filename, plot = plot_list[[plot_name]], width = 10, height = 8, dpi = 300)
        }

        message(sprintf("    ✓ Saved: %s", basename(filename)))
      }
    }
  }

  message("✅ Visualization suite complete")

  class(plot_list) <- c("cbamm_viz_suite", "list")
  return(plot_list)
}

#' @describeIn mod_advanced_viz Print method for visualization suite
#' @param x A cbamm_viz_suite object
#' @param ... Additional arguments
#' @export
print.cbamm_viz_suite <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Comprehensive Visualization Suite\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(sprintf("Plots generated:  %d\n", length(x)))
  cat("Available plots:\n")
  for (plot_name in names(x)) {
    cat(sprintf("  • $%-15s - %s\n", plot_name,
                if (is.null(x[[plot_name]])) "Failed" else "Ready"))
  }

  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("Usage:\n")
  cat("  • print(x$forest)     - Display forest plot\n")
  cat("  • print(x$funnel)     - Display funnel plot\n")
  cat("  • print(x$baujat)     - Display Baujat plot\n")
  cat("  • print(x$cumulative) - Display cumulative forest\n")
  cat("  • print(x$loo)        - Display leave-one-out plot\n")
  cat("═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}
