# Global variables and helper functions for CBAMMR Shiny App

# Required packages
required_packages <- c(
  "shiny", "bs4Dash", "CBAMMR", "DT", "plotly", "ggplot2",
  "shinyWidgets", "readr", "writexl", "shinyjs", "colourpicker"
)

# Check and load packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(paste("Package", pkg, "is required but not installed."))
  }
  library(pkg, character.only = TRUE)
}

# Helper function to create high-resolution plots
save_highres_plot <- function(plot_obj, filename, width = 10, height = 8, dpi = 300, format = "png") {
  if (format == "png") {
    png(filename, width = width * dpi, height = height * dpi, res = dpi)
  } else if (format == "pdf") {
    pdf(filename, width = width, height = height)
  } else if (format == "svg") {
    svg(filename, width = width, height = height)
  }

  print(plot_obj)
  dev.off()
}

# Create example datasets
create_example_binary_or <- function() {
  set.seed(123)
  data <- simulate_cbamm_binary(n = 20, measure = "OR", true_effect = 0.70)
  data$age_mean <- rnorm(20, 60, 10)
  data$female_pct <- runif(20, 0.3, 0.7)
  data$study_type <- sample(c("RCT", "Obs"), 20, replace = TRUE, prob = c(0.6, 0.4))
  data
}

create_example_continuous_smd <- function() {
  set.seed(456)
  data <- simulate_cbamm_continuous(n = 18, measure = "SMD", true_effect = -0.40)
  data$age_mean <- rnorm(18, 60, 10)
  data$female_pct <- runif(18, 0.3, 0.7)
  data$study_type <- sample(c("RCT", "Obs"), 18, replace = TRUE, prob = c(0.7, 0.3))
  data
}

# Template data for downloads
binary_template <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Brown 2022"),
  ai = c(20, 30, 25),
  bi = c(80, 120, 95),
  ci = c(30, 40, 35),
  di = c(70, 110, 85),
  year = c(2020, 2021, 2022),
  age_mean = c(60, 65, 62),
  female_pct = c(0.45, 0.50, 0.48),
  study_type = c("RCT", "RCT", "Obs")
)

continuous_template <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Brown 2022"),
  yi = c(-0.40, -0.35, -0.42),
  sei = c(0.15, 0.18, 0.16),
  n1i = c(50, 60, 55),
  n2i = c(50, 60, 55),
  year = c(2020, 2021, 2022),
  age_mean = c(60, 65, 62),
  female_pct = c(0.45, 0.50, 0.48)
)

survival_template <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Brown 2022"),
  yi = c(log(0.70), log(0.75), log(0.68)),
  sei = c(0.12, 0.15, 0.13),
  n1i = c(100, 120, 110),
  n2i = c(100, 120, 110),
  year = c(2020, 2021, 2022)
)

#' Enhanced Forest Plot with Full Customization
#'
#' @param fit metafor rma object
#' @param style Plot style: "classic", "meta", "revman", "nejm"
#' @param xlim X-axis limits (NULL = auto)
#' @param alim Actual axis limits to display
#' @param at Tick mark positions (NULL = auto)
#' @param steps Number of tick marks (5 default)
#' @param digits Number of decimal places
#' @param showweights Show study weights
#' @param show_pred Show prediction interval
#' @param col Color for effect sizes
#' @param border Border color
#' @param col_diamond Color for pooled diamond
#' @param col_pred Color for prediction interval
#' @param col_lines Color for axis lines
#' @param col_text Color for text
#' @param col_background Background color
#' @param cex Text size multiplier
#' @param cex_lab Axis label size
#' @param cex_axis Axis tick label size
#' @param lwd Line width
#' @param pch Point character for effects
#' @param xlab X-axis label
#' @param slab Study labels (NULL = auto)
#' @param header Custom header text
#' @param mlab Label for pooled effect
#' @param top Top margin
#' @param annotate Show annotations (default TRUE)
#' @param addfit Add pooled estimate (default TRUE)
#' @param addpred Add prediction interval (default FALSE unless show_pred=TRUE)
#'
#' @return NULL (plots to graphics device)
custom_forest_plot <- function(
    fit,
    style = "classic",
    xlim = NULL,
    alim = NULL,
    at = NULL,
    steps = 5,
    digits = 2,
    showweights = TRUE,
    show_pred = FALSE,
    col = "black",
    border = "black",
    col_diamond = "darkblue",
    col_pred = "darkgreen",
    col_lines = "gray",
    col_text = "black",
    col_background = "white",
    cex = 1.0,
    cex_lab = 1.2,
    cex_axis = 1.0,
    lwd = 1,
    pch = 15,
    xlab = NULL,
    slab = NULL,
    header = NULL,
    mlab = NULL,
    top = 3,
    annotate = TRUE,
    addfit = TRUE,
    addpred = NULL
) {

  # Apply style presets
  if (style == "revman") {
    col <- "black"
    border <- "black"
    col_diamond <- "black"
    col_lines <- "black"
    pch <- 15
    cex <- 0.9
    lwd <- 1
    if (is.null(header)) header <- c("Study", "Effect [95% CI]")
  } else if (style == "nejm") {
    col <- "#003366"
    border <- "#003366"
    col_diamond <- "#990000"
    col_lines <- "#666666"
    pch <- 18
    cex <- 1.1
    lwd <- 2
    if (is.null(header)) header <- c("Trial", "Estimate (95% CI)")
  } else if (style == "meta") {
    col <- "#2E86AB"
    border <- "#2E86AB"
    col_diamond <- "#A23B72"
    col_lines <- "#CCCCCC"
    pch <- 15
    cex <- 1.0
    lwd <- 1.5
  }

  # Default labels
  if (is.null(xlab)) {
    mm <- .cbamm_measure_meta(fit$measure)
    xlab <- paste("Effect Size (", fit$measure, ")", sep = "")
  }

  if (is.null(mlab)) {
    mlab <- "Pooled Effect (Random-Effects Model)"
  }

  # Determine addpred
  if (is.null(addpred)) {
    addpred <- show_pred
  }

  # Set background
  par(bg = col_background, col = col_text, col.axis = col_text, col.lab = col_text)

  # Create forest plot with all custom parameters
  forest(
    fit,
    xlim = xlim,
    alim = alim,
    at = at,
    steps = steps,
    digits = digits,
    showweights = showweights,
    col = col,
    border = border,
    cex = cex,
    cex.lab = cex_lab,
    cex.axis = cex_axis,
    lwd = lwd,
    pch = pch,
    xlab = xlab,
    slab = slab,
    header = header,
    mlab = mlab,
    top = top,
    annotate = annotate,
    addfit = addfit,
    addpred = addpred,
    col.predict = col_pred
  )

  # Add custom grid lines if desired
  if (col_lines != "transparent" && !is.null(at)) {
    abline(v = at, col = col_lines, lty = 3, lwd = 0.5)
  }
}

#' Enhanced Funnel Plot with Full Customization
#'
#' @param fit metafor rma object
#' @param xlim X-axis limits (NULL = auto)
#' @param ylim Y-axis limits (NULL = auto)
#' @param steps Number of tick marks
#' @param digits Decimal places
#' @param col Color for points
#' @param bg Background color for points
#' @param pch Point character
#' @param cex Point size
#' @param lwd Line width
#' @param col_contour Color for contour lines
#' @param col_ref Color for reference line
#' @param col_background Plot background color
#' @param col_text Text color
#' @param shade_contours Shade contour regions (TRUE/FALSE)
#' @param level Confidence level for contours (default 95)
#' @param xlab X-axis label
#' @param ylab Y-axis label
#' @param main Title
#' @param refline Where to draw reference line (default 0 for log measures, NULL otherwise)
#' @param cex_lab Label size
#' @param cex_axis Axis label size
#'
#' @return NULL (plots to graphics device)
custom_funnel_plot <- function(
    fit,
    xlim = NULL,
    ylim = NULL,
    steps = 5,
    digits = 2,
    col = "black",
    bg = "gray",
    pch = 21,
    cex = 1.0,
    lwd = 1,
    col_contour = "blue",
    col_ref = "black",
    col_background = "white",
    col_text = "black",
    shade_contours = TRUE,
    level = 95,
    xlab = NULL,
    ylab = "Standard Error",
    main = "Funnel Plot",
    refline = NULL,
    cex_lab = 1.2,
    cex_axis = 1.0
) {

  # Default x-axis label
  if (is.null(xlab)) {
    mm <- .cbamm_measure_meta(fit$measure)
    xlab <- paste("Effect Size (", fit$measure, ")", sep = "")
  }

  # Default refline
  if (is.null(refline)) {
    # For log measures (OR, RR, HR), refline at 0
    if (fit$measure %in% c("OR", "RR", "HR", "IRR")) {
      refline <- 0
    }
  }

  # Set background and colors
  par(bg = col_background, col = col_text, col.axis = col_text, col.lab = col_text)

  # Create funnel plot
  funnel(
    fit,
    xlim = xlim,
    ylim = ylim,
    steps = steps,
    digits = digits,
    col = col,
    bg = bg,
    pch = pch,
    cex = cex,
    lwd = lwd,
    xlab = xlab,
    ylab = ylab,
    main = main,
    refline = refline,
    level = level,
    shade = if (shade_contours) "white" else FALSE,
    hlines = col_contour,
    cex.lab = cex_lab,
    cex.axis = cex_axis
  )

  # Add reference line with custom color
  if (!is.null(refline)) {
    abline(v = refline, col = col_ref, lwd = 2, lty = 1)
  }
}
