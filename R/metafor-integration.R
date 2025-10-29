#' Metafor Package Integration
#'
#' Wrapper functions providing seamless access to metafor's comprehensive
#' plotting and analysis capabilities through CBAMMR interface.
#'
#' @name metafor-integration
#' @keywords internal
NULL

#' Forest Plot using metafor
#'
#' Creates publication-quality forest plots using metafor's forest() function.
#' Provides access to metafor's extensive customization options while maintaining
#' CBAMMR's unified interface.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors (alternative to vi)
#' @param study_labels Optional vector of study labels
#' @param slab Optional study labels (passed to metafor)
#' @param method Meta-analysis method ("FE", "DL", "REML", "EB", "HE", "HS", "SJ", "ML", "GENQ")
#' @param measure Effect size measure for proper labeling
#' @param xlab Label for x-axis
#' @param header Character vector of column headers
#' @param top Optional top margin
#' @param annotate Logical; add effect sizes and CIs as text?
#' @param addfit Logical; add summary polygon?
#' @param addcred Logical; add credibility interval?
#' @param showweights Logical; show study weights?
#' @param ... Additional arguments passed to metafor::forest()
#'
#' @return Invisibly returns the metafor rma object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4)
#' vi <- c(0.05, 0.04, 0.06, 0.05)
#' cbamm_forest_metafor(yi, vi, study_labels = paste("Study", 1:4))
#' }
cbamm_forest_metafor <- function(yi, vi = NULL, sei = NULL,
                                  study_labels = NULL,
                                  slab = NULL,
                                  method = "REML",
                                  measure = "GEN",
                                  xlab = "Effect Size",
                                  header = c("Study", "Effect [95% CI]"),
                                  top = 2,
                                  annotate = TRUE,
                                  addfit = TRUE,
                                  addcred = TRUE,
                                  showweights = FALSE,
                                  ...) {
  # Check if metafor is available
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  # Input validation
  if (length(yi) < 2) {
    stop("At least 2 studies required")
  }

  # Handle sei vs vi
  if (is.null(vi) && is.null(sei)) {
    stop("Either vi or sei must be provided")
  }
  if (!is.null(sei)) {
    vi <- sei^2
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  # Set study labels
  if (is.null(slab)) {
    if (!is.null(study_labels)) {
      slab <- study_labels
    } else {
      slab <- paste("Study", seq_along(yi))
    }
  }

  # Fit meta-analysis model
  res <- metafor::rma(yi = yi, vi = vi, method = method, measure = measure)

  # Create forest plot
  metafor::forest(res,
                  slab = slab,
                  xlab = xlab,
                  header = header,
                  top = top,
                  annotate = annotate,
                  addfit = addfit,
                  addcred = addcred,
                  showweights = showweights,
                  ...)

  invisible(res)
}


#' Funnel Plot using metafor
#'
#' Creates funnel plots for publication bias assessment using metafor.
#' Supports contour-enhanced, trim-and-fill, and various customization options.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#' @param level Confidence level for contours (default c(90, 95, 99))
#' @param shade Shading colors for contours
#' @param refline Reference line position (defaults to pooled estimate)
#' @param xlab Label for x-axis
#' @param ylab Label for y-axis
#' @param back Background color for contours
#' @param legend Logical; add legend?
#' @param ... Additional arguments passed to metafor::funnel()
#'
#' @return Invisibly returns the metafor rma object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' cbamm_funnel_metafor(yi, vi)
#' }
cbamm_funnel_metafor <- function(yi, vi,
                                  method = "REML",
                                  level = c(90, 95, 99),
                                  shade = c("white", "gray85", "gray70"),
                                  refline = NULL,
                                  xlab = "Effect Size",
                                  ylab = "Standard Error",
                                  back = "gray90",
                                  legend = TRUE,
                                  ...) {
  # Check metafor availability
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  # Fit model
  res <- metafor::rma(yi = yi, vi = vi, method = method)

  # Set reference line to pooled estimate if not specified
  if (is.null(refline)) {
    refline <- res$beta[1]
  }

  # Create funnel plot with contours
  metafor::funnel(res,
                  level = level,
                  shade = shade,
                  refline = refline,
                  xlab = xlab,
                  ylab = ylab,
                  back = back,
                  legend = legend,
                  ...)

  invisible(res)
}


#' Radial (Galbraith) Plot using metafor
#'
#' Creates radial plots for detecting outliers and heterogeneity patterns.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#' @param xlab Label for x-axis
#' @param ylab Label for y-axis
#' @param ... Additional arguments passed to metafor::radial()
#'
#' @return Invisibly returns the metafor rma object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' cbamm_radial_metafor(yi, vi)
#' }
cbamm_radial_metafor <- function(yi, vi,
                                  method = "REML",
                                  xlab = "Inverse Standard Error",
                                  ylab = "Standardized Effect",
                                  ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  res <- metafor::rma(yi = yi, vi = vi, method = method)
  metafor::radial(res, xlab = xlab, ylab = ylab, ...)

  invisible(res)
}


#' Baujat Plot using metafor
#'
#' Creates Baujat plots to identify studies contributing to heterogeneity
#' and influencing the overall result.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#' @param symbol Plotting symbol
#' @param xlab Label for x-axis
#' @param ylab Label for y-axis
#' @param ... Additional arguments passed to metafor::baujat()
#'
#' @return Invisibly returns the metafor rma object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' cbamm_baujat_metafor(yi, vi)
#' }
cbamm_baujat_metafor <- function(yi, vi,
                                  method = "REML",
                                  symbol = 19,
                                  xlab = "Contribution to Heterogeneity",
                                  ylab = "Influence on Result",
                                  ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  res <- metafor::rma(yi = yi, vi = vi, method = method)
  metafor::baujat(res, symbol = symbol, xlab = xlab, ylab = ylab, ...)

  invisible(res)
}


#' L'Abbé Plot using metafor
#'
#' Creates L'Abbé plots for visualizing treatment effects in binary outcome studies.
#' Shows control vs treatment event rates for each study.
#'
#' @param ai Treatment group events
#' @param bi Treatment group non-events
#' @param ci Control group events
#' @param di Control group non-events
#' @param xlab Label for x-axis
#' @param ylab Label for y-axis
#' @param ... Additional arguments passed to metafor::labbe()
#'
#' @return Invisibly returns plot data
#' @export
#'
#' @examples
#' \dontrun{
#' ai <- c(10, 15, 12)
#' bi <- c(40, 35, 38)
#' ci <- c(5, 8, 6)
#' di <- c(45, 42, 44)
#' cbamm_labbe_metafor(ai, bi, ci, di)
#' }
cbamm_labbe_metafor <- function(ai, bi, ci, di,
                                 xlab = "Control Group Event Rate",
                                 ylab = "Treatment Group Event Rate",
                                 ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  # Input validation
  if (length(ai) != length(bi) || length(ai) != length(ci) || length(ai) != length(di)) {
    stop("All input vectors must have the same length")
  }

  metafor::labbe(ai = ai, bi = bi, ci = ci, di = di,
                 xlab = xlab, ylab = ylab, ...)

  invisible(NULL)
}


#' Influence Analysis using metafor
#'
#' Comprehensive influence diagnostics including leave-one-out analysis,
#' Cook's distances, covariance ratios, and hat values.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#'
#' @return An object of class "cbamm_influence_metafor" containing:
#' \describe{
#'   \item{influence}{Full influence diagnostics from metafor}
#'   \item{outliers}{Indices of identified outliers}
#'   \item{influential}{Indices of influential studies}
#'   \item{summary}{Summary of influence diagnostics}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_influence_metafor(yi, vi)
#' print(result)
#' plot(result)
#' }
cbamm_influence_metafor <- function(yi, vi, method = "REML") {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  # Fit model
  res <- metafor::rma(yi = yi, vi = vi, method = method)

  # Get influence diagnostics
  inf <- metafor::influence(res)

  # Identify outliers and influential studies
  # Outliers: studentized residuals > 2
  outliers <- which(abs(inf$inf$rstudent) > 2)

  # Influential: Cook's distance > 4/k or hat > 2p/k
  k <- length(yi)
  p <- 1  # intercept-only model
  cook_threshold <- 4 / k
  hat_threshold <- 2 * p / k

  influential <- which(inf$inf$cook.d > cook_threshold | inf$inf$hat > hat_threshold)

  # Summary
  summary_text <- list(
    n_studies = k,
    n_outliers = length(outliers),
    outlier_indices = outliers,
    n_influential = length(influential),
    influential_indices = influential,
    max_cooks_d = max(inf$inf$cook.d),
    max_hat = max(inf$inf$hat)
  )

  result <- list(
    influence = inf,
    outliers = outliers,
    influential = influential,
    summary = summary_text,
    yi = yi,
    vi = vi,
    method = method
  )

  class(result) <- "cbamm_influence_metafor"
  return(result)
}


#' @export
print.cbamm_influence_metafor <- function(x, ...) {
  cat("\nInfluence Diagnostics (metafor)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Studies:\n")
  cat("  Total:", x$summary$n_studies, "\n")
  cat("  Outliers:", x$summary$n_outliers, "\n")
  if (x$summary$n_outliers > 0) {
    cat("    Indices:", paste(x$summary$outlier_indices, collapse = ", "), "\n")
  }
  cat("  Influential:", x$summary$n_influential, "\n")
  if (x$summary$n_influential > 0) {
    cat("    Indices:", paste(x$summary$influential_indices, collapse = ", "), "\n")
  }

  cat("\nDiagnostic Statistics:\n")
  cat("  Max Cook's Distance:", sprintf("%.4f", x$summary$max_cooks_d), "\n")
  cat("  Max Hat Value:", sprintf("%.4f", x$summary$max_hat), "\n")

  cat("\nInterpretation:\n")
  if (x$summary$n_outliers > 0) {
    cat("  ⚠ Outliers detected - consider sensitivity analysis\n")
  }
  if (x$summary$n_influential > 0) {
    cat("  ⚠ Influential studies detected - assess impact on results\n")
  }
  if (x$summary$n_outliers == 0 && x$summary$n_influential == 0) {
    cat("  ✓ No outliers or influential studies detected\n")
  }

  invisible(x)
}


#' @export
plot.cbamm_influence_metafor <- function(x, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Plot influence diagnostics using metafor's plot method
  plot(x$influence, ...)
}


#' Cumulative Meta-Analysis using metafor
#'
#' Performs cumulative meta-analysis showing how the pooled estimate evolves
#' as studies are added (typically in chronological order).
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param study_labels Optional study labels
#' @param order Optional ordering vector (default: studies in given order)
#' @param method Meta-analysis method
#' @param transf Transformation function for display
#'
#' @return An object of class "cbamm_cumulative_metafor" containing:
#' \describe{
#'   \item{cumulative}{Cumulative results from metafor}
#'   \item{estimates}{Vector of cumulative estimates}
#'   \item{ci_lb}{Lower confidence bounds}
#'   \item{ci_ub}{Upper confidence bounds}
#'   \item{order}{Study order used}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_cumulative_metafor(yi, vi)
#' plot(result)
#' }
cbamm_cumulative_metafor <- function(yi, vi,
                                      study_labels = NULL,
                                      order = NULL,
                                      method = "REML",
                                      transf = NULL) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  # Set order
  if (is.null(order)) {
    order <- seq_along(yi)
  }

  # Reorder data
  yi_ordered <- yi[order]
  vi_ordered <- vi[order]

  # Fit initial model
  res <- metafor::rma(yi = yi_ordered, vi = vi_ordered, method = method)

  # Cumulative meta-analysis
  cumul <- metafor::cumul(res, transf = transf)

  # Extract results
  estimates <- cumul$estimate
  ci_lb <- cumul$ci.lb
  ci_ub <- cumul$ci.ub

  # Set study labels
  if (is.null(study_labels)) {
    study_labels <- paste("Study", seq_along(yi))
  }
  study_labels_ordered <- study_labels[order]

  result <- list(
    cumulative = cumul,
    estimates = estimates,
    ci_lb = ci_lb,
    ci_ub = ci_ub,
    order = order,
    study_labels = study_labels_ordered,
    method = method,
    n_studies = length(yi)
  )

  class(result) <- "cbamm_cumulative_metafor"
  return(result)
}


#' @export
print.cbamm_cumulative_metafor <- function(x, ...) {
  cat("\nCumulative Meta-Analysis (metafor)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Method:", x$method, "\n")
  cat("Studies:", x$n_studies, "\n\n")

  cat("Cumulative Estimates:\n")
  for (i in 1:x$n_studies) {
    cat(sprintf("  After %2d studies: %.4f [%.4f, %.4f]\n",
                i, x$estimates[i], x$ci_lb[i], x$ci_ub[i]))
  }

  cat("\nFinal Estimate: ", sprintf("%.4f [%.4f, %.4f]\n",
                                     x$estimates[x$n_studies],
                                     x$ci_lb[x$n_studies],
                                     x$ci_ub[x$n_studies]))

  invisible(x)
}


#' @export
plot.cbamm_cumulative_metafor <- function(x, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Create cumulative forest plot
  metafor::forest(x$cumulative, ...)
}


#' Leave-One-Out Analysis using metafor
#'
#' Performs leave-one-out meta-analysis to assess sensitivity to individual studies.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param study_labels Optional study labels
#' @param method Meta-analysis method
#' @param digits Number of decimal places for display
#'
#' @return An object of class "cbamm_loo_metafor" containing leave-one-out results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_loo_metafor(yi, vi)
#' print(result)
#' }
cbamm_loo_metafor <- function(yi, vi,
                               study_labels = NULL,
                               method = "REML",
                               digits = 4) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  # Fit model
  res <- metafor::rma(yi = yi, vi = vi, method = method)

  # Leave-one-out
  loo <- metafor::leave1out(res, digits = digits)

  # Set study labels
  if (is.null(study_labels)) {
    study_labels <- paste("Study", seq_along(yi))
  }

  result <- list(
    loo = loo,
    study_labels = study_labels,
    method = method,
    n_studies = length(yi)
  )

  class(result) <- "cbamm_loo_metafor"
  return(result)
}


#' @export
print.cbamm_loo_metafor <- function(x, ...) {
  cat("\nLeave-One-Out Analysis (metafor)\n")
  cat("═══════════════════════════════════════\n\n")

  print(x$loo)

  invisible(x)
}


#' GOSH Plot using metafor
#'
#' Creates Graphical Display of Study Heterogeneity (GOSH) plots to detect
#' patterns of heterogeneity and outliers using all possible subsets.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#' @param subsets Number of subsets to analyze (default 10000 or all if fewer)
#' @param parallel Parallel processing strategy
#' @param progbar Logical; show progress bar?
#'
#' @return An object of class "cbamm_gosh_metafor" containing GOSH results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6, 0.8)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04, 0.06)
#' result <- cbamm_gosh_metafor(yi, vi, subsets = 1000)
#' plot(result)
#' }
cbamm_gosh_metafor <- function(yi, vi,
                                method = "REML",
                                subsets = 10000,
                                parallel = "no",
                                progbar = TRUE) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  if (length(yi) < 4) {
    stop("GOSH plot requires at least 4 studies")
  }

  # Fit model
  res <- metafor::rma(yi = yi, vi = vi, method = method)

  # Run GOSH diagnostics
  gosh_res <- metafor::gosh(res, subsets = subsets, parallel = parallel, progbar = progbar)

  result <- list(
    gosh = gosh_res,
    method = method,
    n_studies = length(yi),
    n_subsets = nrow(gosh_res$res)
  )

  class(result) <- "cbamm_gosh_metafor"
  return(result)
}


#' @export
print.cbamm_gosh_metafor <- function(x, ...) {
  cat("\nGOSH Diagnostics (metafor)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Method:", x$method, "\n")
  cat("Studies:", x$n_studies, "\n")
  cat("Subsets analyzed:", format(x$n_subsets, big.mark = ","), "\n\n")

  cat("Use plot(result) to visualize GOSH diagnostics\n")

  invisible(x)
}


#' @export
plot.cbamm_gosh_metafor <- function(x, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Plot GOSH diagnostics
  plot(x$gosh, ...)
}


#' Trim and Fill Analysis using metafor
#'
#' Performs trim-and-fill analysis to estimate and adjust for publication bias
#' by imputing potentially missing studies.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#' @param estimator Estimator for number of missing studies ("L0", "R0", "Q0")
#' @param side Side to impute studies ("right", "left")
#'
#' @return An object of class "cbamm_trimfill_metafor" containing trim-and-fill results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_trimfill_metafor(yi, vi)
#' print(result)
#' }
cbamm_trimfill_metafor <- function(yi, vi,
                                    method = "REML",
                                    estimator = "L0",
                                    side = NULL) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  # Fit model
  res <- metafor::rma(yi = yi, vi = vi, method = method)

  # Trim and fill
  taf <- metafor::trimfill(res, estimator = estimator, side = side)

  result <- list(
    trimfill = taf,
    n_imputed = taf$k0,
    original_estimate = res$beta[1],
    adjusted_estimate = taf$beta[1],
    method = method,
    estimator = estimator
  )

  class(result) <- "cbamm_trimfill_metafor"
  return(result)
}


#' @export
print.cbamm_trimfill_metafor <- function(x, ...) {
  cat("\nTrim-and-Fill Analysis (metafor)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Method:", x$method, "\n")
  cat("Estimator:", x$estimator, "\n")
  cat("Imputed studies:", x$n_imputed, "\n\n")

  cat("Results:\n")
  cat("  Original estimate:", sprintf("%.4f", x$original_estimate), "\n")
  cat("  Adjusted estimate:", sprintf("%.4f", x$adjusted_estimate), "\n")
  cat("  Change:", sprintf("%.4f", x$adjusted_estimate - x$original_estimate), "\n")

  if (x$n_imputed == 0) {
    cat("\n✓ No missing studies imputed - low concern for publication bias\n")
  } else {
    cat("\n⚠ Studies were imputed - consider publication bias\n")
  }

  invisible(x)
}
