#' Meta Package Integration
#'
#' Wrapper functions providing seamless access to meta package's plotting
#' and analysis capabilities through CBAMMR interface.
#'
#' @name meta-integration
#' @keywords internal
NULL

#' Forest Plot using meta package
#'
#' Creates forest plots using meta package's forest() function with different
#' styling options than metafor.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param study_labels Optional vector of study labels
#' @param sm Summary measure ("MD", "SMD", "OR", "RR", "RD", "HR")
#' @param method Meta-analysis method ("Inverse", "MH", "Peto", "GLMM")
#' @param method_tau Method for tau² estimation ("DL", "PM", "REML", "ML", "HS", "SJ", "HE", "EB")
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Logical; add prediction interval?
#' @param col_study Color for study estimates
#' @param col_square Color for study squares
#' @param col_diamond Color for summary diamond
#' @param ... Additional arguments passed to meta functions
#'
#' @return An object of class "cbamm_forest_meta" containing meta results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05))
#' cbamm_forest_meta(yi, sei = sei, sm = "MD")
#' }
cbamm_forest_meta <- function(yi, vi = NULL, sei = NULL,
                               study_labels = NULL,
                               sm = "MD",
                               method = "Inverse",
                               method_tau = "REML",
                               hakn = FALSE,
                               prediction = TRUE,
                               col_study = "black",
                               col_square = "gray",
                               col_diamond = "blue",
                               ...) {
  # Check if meta is available
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  # Input validation
  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Set study labels
  if (is.null(study_labels)) {
    study_labels <- paste("Study", seq_along(yi))
  }

  # Fit meta-analysis using metagen (generic inverse variance)
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    studlab = study_labels,
    sm = sm,
    method.tau = method_tau,
    hakn = hakn,
    prediction = prediction
  )

  # Create forest plot
  meta::forest(res,
               col.study = col_study,
               col.square = col_square,
               col.diamond = col_diamond,
               ...)

  result <- list(
    meta_object = res,
    estimate = res$TE.random,
    ci_lb = res$lower.random,
    ci_ub = res$upper.random,
    I2 = res$I2,
    tau2 = res$tau2,
    sm = sm,
    method_tau = method_tau
  )

  class(result) <- "cbamm_forest_meta"
  return(result)
}


#' @export
print.cbamm_forest_meta <- function(x, ...) {
  cat("\nForest Plot (meta package)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Summary measure:", x$sm, "\n")
  cat("Tau² method:", x$method_tau, "\n\n")

  cat("Random-effects estimate:", sprintf("%.4f [%.4f, %.4f]\n",
                                           x$estimate, x$ci_lb, x$ci_ub))
  cat("I²:", sprintf("%.1f%%\n", x$I2 * 100))
  cat("Tau²:", sprintf("%.4f\n", x$tau2))

  invisible(x)
}


#' Funnel Plot using meta package
#'
#' Creates funnel plots using meta package with various enhancements.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param contour Logical; add contour-enhanced funnel plot?
#' @param col Color for study points
#' @param bg Background color
#' @param ... Additional arguments passed to meta::funnel()
#'
#' @return Invisibly returns the meta object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' cbamm_funnel_meta(yi, sei = sei)
#' }
cbamm_funnel_meta <- function(yi, vi = NULL, sei = NULL,
                               sm = "MD",
                               method_tau = "REML",
                               contour = TRUE,
                               col = "black",
                               bg = "gray",
                               ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau
  )

  # Create funnel plot
  if (contour) {
    # Contour-enhanced funnel plot
    meta::funnel(res, contour = c(0.9, 0.95, 0.99),
                 col = col, bg = bg, ...)
  } else {
    meta::funnel(res, col = col, bg = bg, ...)
  }

  invisible(res)
}


#' Radial Plot using meta package
#'
#' Creates radial (Galbraith) plots using meta package.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param ... Additional arguments passed to meta::radial()
#'
#' @return Invisibly returns the meta object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' cbamm_radial_meta(yi, sei = sei)
#' }
cbamm_radial_meta <- function(yi, vi = NULL, sei = NULL,
                               sm = "MD",
                               method_tau = "REML",
                               ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau
  )

  # Create radial plot
  meta::radial(res, ...)

  invisible(res)
}


#' Baujat Plot using meta package
#'
#' Creates Baujat plots using meta package to identify heterogeneity contributors.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param ... Additional arguments passed to meta::baujat()
#'
#' @return Invisibly returns the meta object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' cbamm_baujat_meta(yi, sei = sei)
#' }
cbamm_baujat_meta <- function(yi, vi = NULL, sei = NULL,
                               sm = "MD",
                               method_tau = "REML",
                               ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau
  )

  # Create Baujat plot
  meta::baujat(res, ...)

  invisible(res)
}


#' L'Abbé Plot using meta package
#'
#' Creates L'Abbé plots using meta package for binary outcome studies.
#'
#' @param ai Treatment group events
#' @param bi Treatment group non-events
#' @param ci Control group events
#' @param di Control group non-events
#' @param sm Summary measure ("OR", "RR", "RD")
#' @param method Meta-analysis method
#' @param ... Additional arguments passed to meta::labbe()
#'
#' @return Invisibly returns the meta object
#' @export
#'
#' @examples
#' \dontrun{
#' ai <- c(10, 15, 12)
#' bi <- c(40, 35, 38)
#' ci <- c(5, 8, 6)
#' di <- c(45, 42, 44)
#' cbamm_labbe_meta(ai, bi, ci, di, sm = "OR")
#' }
cbamm_labbe_meta <- function(ai, bi, ci, di,
                              sm = "OR",
                              method = "MH",
                              ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Input validation
  if (length(ai) != length(bi) || length(ai) != length(ci) || length(ai) != length(di)) {
    stop("All input vectors must have the same length")
  }

  # Calculate event counts and totals
  n1i <- ai + bi
  n2i <- ci + di

  # Fit meta-analysis for binary outcomes
  if (sm == "OR") {
    res <- meta::metabin(
      event.e = ai,
      n.e = n1i,
      event.c = ci,
      n.c = n2i,
      sm = sm,
      method = method
    )
  } else {
    res <- meta::metabin(
      event.e = ai,
      n.e = n1i,
      event.c = ci,
      n.c = n2i,
      sm = sm,
      method = method
    )
  }

  # Create L'Abbé plot
  meta::labbe(res, ...)

  invisible(res)
}


#' Bubble Plot using meta package
#'
#' Creates bubble plots for meta-regression showing effect of a covariate.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param x Covariate vector
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param col Color for bubbles
#' @param xlab Label for x-axis
#' @param ylab Label for y-axis
#' @param ... Additional arguments passed to meta::bubble()
#'
#' @return Invisibly returns the meta-regression object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' x <- c(50, 55, 60, 52, 58)  # e.g., mean age
#' cbamm_bubble_meta(yi, sei = sei, x = x, xlab = "Mean Age")
#' }
cbamm_bubble_meta <- function(yi, vi = NULL, sei = NULL, x,
                               sm = "MD",
                               method_tau = "REML",
                               col = "blue",
                               xlab = "Covariate",
                               ylab = "Effect Size",
                               ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei) || length(yi) != length(x)) {
    stop("yi, sei, and x must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau
  )

  # Fit meta-regression
  reg <- meta::metareg(res, ~ x)

  # Create bubble plot
  meta::bubble(reg, col = col, xlab = xlab, ylab = ylab, ...)

  invisible(reg)
}


#' Drapery Plot using meta package
#'
#' Creates drapery plots showing p-value functions for all studies and pooled estimate.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param labels Logical; add study labels?
#' @param ... Additional arguments passed to meta::drapery()
#'
#' @return Invisibly returns the meta object
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' cbamm_drapery_meta(yi, sei = sei)
#' }
cbamm_drapery_meta <- function(yi, vi = NULL, sei = NULL,
                                sm = "MD",
                                method_tau = "REML",
                                labels = TRUE,
                                ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau
  )

  # Create drapery plot
  meta::drapery(res, labels = labels, ...)

  invisible(res)
}


#' Meta-Regression using meta package
#'
#' Performs meta-regression using meta package with comprehensive output.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param moderators Data frame or matrix of moderator variables
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param hakn Use Hartung-Knapp adjustment?
#'
#' @return An object of class "cbamm_metareg_meta" containing regression results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' moderators <- data.frame(age = c(50, 55, 60, 52, 58))
#' result <- cbamm_metareg_meta(yi, sei = sei, moderators = moderators)
#' print(result)
#' }
cbamm_metareg_meta <- function(yi, vi = NULL, sei = NULL,
                                moderators,
                                sm = "MD",
                                method_tau = "REML",
                                hakn = TRUE) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau,
    hakn = hakn
  )

  # Fit meta-regression
  formula_rhs <- paste(names(moderators), collapse = " + ")
  formula_obj <- as.formula(paste("~", formula_rhs))

  reg <- meta::metareg(res, formula_obj, data = moderators, hakn = hakn)

  result <- list(
    metareg_object = reg,
    coefficients = reg$b,
    se = reg$se,
    pval = reg$pval,
    tau2 = reg$tau2,
    R2 = reg$R2,
    sm = sm,
    method_tau = method_tau
  )

  class(result) <- "cbamm_metareg_meta"
  return(result)
}


#' @export
print.cbamm_metareg_meta <- function(x, ...) {
  cat("\nMeta-Regression (meta package)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Summary measure:", x$sm, "\n")
  cat("Tau² method:", x$method_tau, "\n\n")

  cat("Coefficients:\n")
  coef_df <- data.frame(
    Estimate = x$coefficients,
    SE = x$se,
    pval = x$pval
  )
  print(coef_df)

  cat("\nModel Statistics:\n")
  cat("  Residual tau²:", sprintf("%.4f\n", x$tau2))
  if (!is.null(x$R2)) {
    cat("  R²:", sprintf("%.1f%%\n", x$R2 * 100))
  }

  invisible(x)
}


#' Trim and Fill Analysis using meta package
#'
#' Performs trim-and-fill analysis using meta package.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param sm Summary measure
#' @param method_tau Method for tau² estimation
#' @param left Logical; trim on left side?
#' @param ... Additional arguments passed to meta::trimfill()
#'
#' @return An object of class "cbamm_trimfill_meta" containing trim-and-fill results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' sei <- sqrt(c(0.05, 0.04, 0.06, 0.05, 0.04))
#' result <- cbamm_trimfill_meta(yi, sei = sei)
#' print(result)
#' }
cbamm_trimfill_meta <- function(yi, vi = NULL, sei = NULL,
                                 sm = "MD",
                                 method_tau = "REML",
                                 left = NULL,
                                 ...) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Handle sei vs vi
  if (is.null(sei) && is.null(vi)) {
    stop("Either sei or vi must be provided")
  }
  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  # Fit meta-analysis
  res <- meta::metagen(
    TE = yi,
    seTE = sei,
    sm = sm,
    method.tau = method_tau
  )

  # Trim and fill
  if (is.null(left)) {
    taf <- meta::trimfill(res, ...)
  } else {
    taf <- meta::trimfill(res, left = left, ...)
  }

  result <- list(
    trimfill_object = taf,
    n_imputed = taf$k0,
    original_estimate = res$TE.random,
    adjusted_estimate = taf$TE.random,
    sm = sm,
    method_tau = method_tau
  )

  class(result) <- "cbamm_trimfill_meta"
  return(result)
}


#' @export
print.cbamm_trimfill_meta <- function(x, ...) {
  cat("\nTrim-and-Fill Analysis (meta package)\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Summary measure:", x$sm, "\n")
  cat("Tau² method:", x$method_tau, "\n")
  cat("Imputed studies:", x$n_imputed, "\n\n")

  cat("Results:\n")
  cat("  Original estimate:", sprintf("%.4f\n", x$original_estimate))
  cat("  Adjusted estimate:", sprintf("%.4f\n", x$adjusted_estimate))
  cat("  Change:", sprintf("%.4f\n", x$adjusted_estimate - x$original_estimate))

  if (x$n_imputed == 0) {
    cat("\n✓ No missing studies imputed\n")
  } else {
    cat("\n⚠ Studies were imputed - consider publication bias\n")
  }

  invisible(x)
}
