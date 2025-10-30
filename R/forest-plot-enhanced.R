#' Enhanced Forest Plot with Multiple Styles
#'
#' Create forest plots using metafor, meta, or custom ggplot2 styles.
#' Provides access to the beautiful forest plots from both packages.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of variances
#' @param sei Vector of standard errors (alternative to vi)
#' @param slab Study labels
#' @param style Forest plot style: "metafor" (default), "meta", "ggplot", or "auto"
#' @param method Estimation method (REML, ML, DL, etc.)
#' @param measure Effect size measure (for proper labeling)
#' @param title Plot title
#' @param xlab X-axis label (auto-generated if NULL)
#' @param order Ordering: "obs" (observed), "fit" (fitted), "prec" (precision), or numeric vector
#' @param refline Reference line value (default: 0 for diff, 1 for ratio)
#' @param digits Number of digits for display (default: 2)
#' @param showweights Show weights? (default: TRUE)
#' @param header Include header row? (default: TRUE)
#' @param top Top margin (default: 3)
#' @param alim X-axis limits (default: NULL for auto)
#' @param at Tick mark positions (default: NULL for auto)
#' @param ilab Additional study information columns
#' @param ilab.xpos X positions for additional columns
#' @param ilab.pos Position of additional columns (default: 2)
#' @param subset Subset of studies to include
#' @param transf Transformation function (e.g., exp for log OR)
#' @param atransf Transformation for axis labels
#' @param col Color scheme (metafor-specific)
#' @param shade Shade alternate rows? (default: TRUE for metafor)
#' @param colout Color for  overall estimate
#' @param addfit Add fitted values? (metafor)
#' @param addcred Add credibility interval? (metafor)
#' @param level Confidence level (default: 95)
#' @param ... Additional arguments passed to forest functions
#'
#' @return Forest plot (metafor/meta object or ggplot2 object)
#' @export
#'
#' @examples
#' \dontrun{
#' # Example data
#' yi <- c(-0.5, -0.3, -0.7, -0.4, -0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' slab <- paste("Study", 1:5)
#'
#' # Metafor style (default)
#' cbamm_forest(yi, vi, slab = slab, style = "metafor")
#'
#' # Meta package style
#' cbamm_forest(yi, vi, slab = slab, style = "meta")
#'
#' # Custom ggplot2 style
#' cbamm_forest(yi, vi, slab = slab, style = "ggplot")
#'
#' # For odds ratios (transform to natural scale)
#' cbamm_forest(yi, vi, slab = slab,
#'              style = "metafor",
#'              transf = exp,
#'              refline = 1,
#'              xlab = "Odds Ratio")
#' }
cbamm_forest <- function(yi, vi = NULL, sei = NULL,
                         slab = NULL,
                         style = c("metafor", "meta", "ggplot", "auto"),
                         method = "REML",
                         measure = NULL,
                         title = NULL,
                         xlab = NULL,
                         order = NULL,
                         refline = NULL,
                         digits = 2,
                         showweights = TRUE,
                         header = TRUE,
                         top = 3,
                         alim = NULL,
                         at = NULL,
                         ilab = NULL,
                         ilab.xpos = NULL,
                         ilab.pos = 2,
                         subset = NULL,
                         transf = NULL,
                         atransf = NULL,
                         col = NULL,
                         shade = TRUE,
                         colout = "black",
                         addfit = TRUE,
                         addcred = FALSE,
                         level = 95,
                         ...) {

  # Validate style
  style <- match.arg(style)

  # Handle vi vs sei
  if (is.null(vi) && !is.null(sei)) {
    vi <- sei^2
  }
  if (is.null(vi)) {
    stop("Either 'vi' (variance) or 'sei' (standard error) must be provided")
  }

  # Generate study labels if not provided
  if (is.null(slab)) {
    slab <- paste("Study", seq_along(yi))
  }

  # Determine refline if not specified
  if (is.null(refline)) {
    # Check if measure is ratio-based
    if (!is.null(measure) && measure %in% c("OR", "RR", "ROM", "IRR", "VR")) {
      refline <- ifelse(is.null(transf), 0, 1)
    } else if (!is.null(transf) && identical(transf, exp)) {
      refline <- 1
    } else {
      refline <- 0
    }
  }

  # Auto-generate xlab if not provided
  if (is.null(xlab)) {
    if (!is.null(measure)) {
      xlab <- switch(measure,
                     "OR" = if(is.null(transf)) "Log Odds Ratio" else "Odds Ratio",
                     "RR" = if(is.null(transf)) "Log Risk Ratio" else "Risk Ratio",
                     "RD" = "Risk Difference",
                     "SMD" = "Standardized Mean Difference",
                     "MD" = "Mean Difference",
                     "ZCOR" = "Fisher's Z",
                     "Effect Size")
    } else {
      xlab <- "Effect Size"
    }
  }

  # Choose style based on data if auto
  if (style == "auto") {
    k <- length(yi)
    if (k <= 20) {
      style <- "metafor"  # Best for smaller k
    } else if (k <= 50) {
      style <- "meta"     # Good for moderate k
    } else {
      style <- "ggplot"   # Better for large k
    }
  }

  # Create forest plot based on style
  if (style == "metafor") {
    .cbamm_forest_metafor(yi = yi, vi = vi, slab = slab, method = method,
                          xlab = xlab, refline = refline, digits = digits,
                          showweights = showweights, header = header,
                          top = top, alim = alim, at = at,
                          ilab = ilab, ilab.xpos = ilab.xpos, ilab.pos = ilab.pos,
                          subset = subset, transf = transf, atransf = atransf,
                          col = col, shade = shade, colout = colout,
                          addfit = addfit, addcred = addcred, level = level, ...)

  } else if (style == "meta") {
    .cbamm_forest_meta(yi = yi, vi = vi, slab = slab, method = method,
                       xlab = xlab, refline = refline, digits = digits,
                       title = title, transf = transf, level = level, ...)

  } else if (style == "ggplot") {
    .cbamm_forest_ggplot(yi = yi, vi = vi, slab = slab, method = method,
                         xlab = xlab, refline = refline, title = title,
                         transf = transf, level = level, ...)
  }
}


#' Forest Plot using metafor style
#' @keywords internal
.cbamm_forest_metafor <- function(yi, vi, slab, method, xlab, refline, digits,
                                   showweights, header, top, alim, at,
                                   ilab, ilab.xpos, ilab.pos, subset, transf,
                                   atransf, col, shade, colout, addfit, addcred,
                                   level, ...) {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required for metafor-style forest plots. Install with: install.packages('metafor')")
  }

  # Fit model
  fit <- metafor::rma(yi = yi, vi = vi, slab = slab, method = method, level = level)

  # Create forest plot using metafor::forest()
  metafor::forest(fit,
                  xlab = xlab,
                  refline = refline,
                  digits = digits,
                  showweights = showweights,
                  header = header,
                  top = top,
                  alim = alim,
                  at = at,
                  ilab = ilab,
                  ilab.xpos = ilab.xpos,
                  ilab.pos = ilab.pos,
                  subset = subset,
                  transf = transf,
                  atransf = atransf,
                  col = col,
                  shade = shade,
                  colout = colout,
                  addfit = addfit,
                  addcred = addcred,
                  ...)

  invisible(fit)
}


#' Forest Plot using meta package style
#' @keywords internal
.cbamm_forest_meta <- function(yi, vi, slab, method, xlab, refline, digits,
                                title, transf, level, ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required for meta-style forest plots. Install with: install.packages('meta')")
  }

  # Map method to meta package equivalent
  method_meta <- switch(method,
                        "REML" = "REML",
                        "ML" = "ML",
                        "DL" = "DL",
                        "EB" = "EB",
                        "REML")  # Default

  # Convert to SE
  sei <- sqrt(vi)

  # Create meta object
  m <- meta::metagen(TE = yi,
                     seTE = sei,
                     studlab = slab,
                     sm = if(is.null(transf)) "MD" else "OR",
                     method.tau = method_meta,
                     level = level / 100,
                     ...)

  # Create forest plot
  meta::forest(m,
               xlab = xlab,
               refline = refline,
               digits = digits,
               label.left = if(refline > 0) "Favours Control" else NULL,
               label.right = if(refline > 0) "Favours Treatment" else NULL,
               ...)

  invisible(m)
}


#' Forest Plot using ggplot2 style
#' @keywords internal
.cbamm_forest_ggplot <- function(yi, vi, slab, method, xlab, refline, title,
                                  transf, level, ...) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for ggplot-style forest plots.")
  }

  # Fit model
  if (requireNamespace("metafor", quietly = TRUE)) {
    fit <- metafor::rma(yi = yi, vi = vi, slab = slab, method = method, level = level)
  } else {
    # Simple weighted mean if metafor not available
    wi <- 1 / vi
    estimate <- sum(wi * yi) / sum(wi)
    se <- sqrt(1 / sum(wi))
    ci_lb <- estimate - qnorm(1 - (1 - level/100)/2) * se
    ci_ub <- estimate + qnorm(1 - (1 - level/100)/2) * se

    fit <- list(
      beta = estimate,
      ci.lb = ci_lb,
      ci.ub = ci_ub,
      se = se
    )
  }

  # Calculate study-level CIs
  z <- qnorm(1 - (1 - level/100)/2)
  sei <- sqrt(vi)
  ci_lb <- yi - z * sei
  ci_ub <- yi + z * sei

  # Apply transformation if specified
  if (!is.null(transf)) {
    yi_plot <- transf(yi)
    ci_lb_plot <- transf(ci_lb)
    ci_ub_plot <- transf(ci_ub)
    est_plot <- transf(fit$beta)
    est_ci_lb_plot <- transf(fit$ci.lb)
    est_ci_ub_plot <- transf(fit$ci.ub)
  } else {
    yi_plot <- yi
    ci_lb_plot <- ci_lb
    ci_ub_plot <- ci_ub
    est_plot <- fit$beta
    est_ci_lb_plot <- fit$ci.lb
    est_ci_ub_plot <- fit$ci.ub
  }

  # Create data frame
  df <- data.frame(
    study = factor(c(slab, "Overall"), levels = c("Overall", rev(slab))),
    estimate = c(yi_plot, est_plot),
    ci_lb = c(ci_lb_plot, est_ci_lb_plot),
    ci_ub = c(ci_ub_plot, est_ci_ub_plot),
    type = c(rep("Study", length(yi)), "Overall"),
    stringsAsFactors = FALSE
  )

  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(y = study, x = estimate, xmin = ci_lb, xmax = ci_ub)) +
    ggplot2::geom_vline(xintercept = refline, linetype = "dashed", color = "gray50") +
    ggplot2::geom_errorbarh(ggplot2::aes(color = type), height = 0.3) +
    ggplot2::geom_point(ggplot2::aes(color = type, size = type, shape = type)) +
    ggplot2::scale_color_manual(values = c("Study" = "#3498db", "Overall" = "#e74c3c")) +
    ggplot2::scale_size_manual(values = c("Study" = 3, "Overall" = 4)) +
    ggplot2::scale_shape_manual(values = c("Study" = 16, "Overall" = 18)) +
    ggplot2::labs(
      title = if(is.null(title)) "Forest Plot" else title,
      x = xlab,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "none",
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(hjust = 0)
    )

  # Add log scale for ratio measures if appropriate
  if (!is.null(transf) && identical(transf, exp)) {
    p <- p + ggplot2::scale_x_log10()
  }

  return(p)
}


#' Create Forest Plot from cbamm_auto result
#'
#' Convenience function to create forest plot from automated analysis result
#'
#' @param result Object of class "cbamm_auto"
#' @param style Forest plot style: "metafor", "meta", "ggplot", or "auto"
#' @param ... Additional arguments passed to cbamm_forest()
#'
#' @return Forest plot
#' @export
#'
#' @examples
#' \dontrun{
#' data <- read.csv("my_data.csv")
#' result <- cbamm_auto(data)
#' cbamm_forest_auto(result, style = "metafor")
#' cbamm_forest_auto(result, style = "meta")
#' }
cbamm_forest_auto <- function(result, style = "auto", ...) {
  if (!inherits(result, "cbamm_auto")) {
    stop("Input must be an object of class 'cbamm_auto'")
  }

  # Extract study labels if available
  slab <- if (!is.null(result$study_metadata$study_names)) {
    result$study_metadata$study_names
  } else {
    paste("Study", seq_along(result$yi))
  }

  # Determine if transformation needed
  transf <- NULL
  if (!is.null(result$effect_size_measure)) {
    if (result$effect_size_measure %in% c("OR", "RR", "ROM", "IRR")) {
      transf <- exp
    }
  }

  # Create forest plot
  cbamm_forest(
    yi = result$yi,
    vi = result$vi,
    slab = slab,
    style = style,
    method = result$estimator,
    measure = result$effect_size_measure,
    transf = transf,
    ...
  )
}
