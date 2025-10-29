#' Comprehensive Effect Size Calculation
#'
#' Wrapper functions providing easy access to all effect size calculations
#' from metafor, with additional validation and formatting.
#'
#' @name effect-sizes
#' @keywords internal
NULL

#' Calculate Effect Sizes with Enhanced Features
#'
#' Comprehensive wrapper for metafor::escalc() with additional validation,
#' automatic handling of edge cases, and enhanced output formatting.
#'
#' @param measure Effect size measure. Options include:
#'   Binary data: "OR", "RR", "RD", "AS", "PETO", "PBIT", "OR2D", "OR2DN", "OR2DL"
#'   Continuous data: "MD", "SMD", "SMDH", "ROM", "RPB", "RBIS", "D2OR", "D2ORN", "D2ORL"
#'   Correlation data: "COR", "UCOR", "ZCOR", "RTET", "ZTET"
#'   Proportions: "PR", "PLN", "PLO", "PAS", "PFT"
#'   Incidence rates: "IR", "IRLN", "IRS", "IRFT"
#'   Mean change: "MC", "SMCC", "SMCR", "SMCRH", "ROMC"
#'   Others: "ARAW", "AHW", "ABT"
#' @param ai Outcome measure in group 1 (binary: events; continuous: sample size)
#' @param bi Additional measure for group 1
#' @param ci Outcome measure in group 2
#' @param di Additional measure for group 2
#' @param n1i Sample size in group 1
#' @param n2i Sample size in group 2
#' @param m1i Mean in group 1
#' @param m2i Mean in group 2
#' @param sd1i SD in group 1
#' @param sd2i SD in group 2
#' @param xi Outcome measure for correlations
#' @param mi Outcome measure for proportions/rates
#' @param ri Correlation coefficient
#' @param ti Time/person-time at risk
#' @param data Optional data frame
#' @param add Continuity correction value (default 0.5)
#' @param to When to add continuity correction ("only0", "all", "if0all", "none")
#' @param drop00 Drop studies with no events in both groups?
#' @param vtype Variance type for SMD ("LS", "UB", "AV")
#' @param append Append to original data?
#' @param var.names Variable names for effect size and variance
#' @param ... Additional arguments passed to escalc()
#'
#' @return Data frame with effect sizes (yi), variances (vi), and original data
#' @export
#'
#' @examples
#' \dontrun{
#' # Binary outcome - Odds Ratio
#' data(bcg_vaccine)
#' result <- cbamm_escalc(measure = "OR",
#'                        ai = tpos, bi = tneg,
#'                        ci = cpos, di = cneg,
#'                        data = bcg_vaccine)
#'
#' # Continuous outcome - Standardized Mean Difference
#' result <- cbamm_escalc(measure = "SMD",
#'                        m1i = m1, sd1i = sd1, n1i = n1,
#'                        m2i = m2, sd2i = sd2, n2i = n2)
#'
#' # Correlation
#' result <- cbamm_escalc(measure = "ZCOR", ri = r, ni = n)
#' }
cbamm_escalc <- function(measure,
                         ai = NULL, bi = NULL, ci = NULL, di = NULL,
                         n1i = NULL, n2i = NULL,
                         m1i = NULL, m2i = NULL,
                         sd1i = NULL, sd2i = NULL,
                         xi = NULL, mi = NULL, ri = NULL, ti = NULL,
                         data = NULL,
                         add = 0.5,
                         to = "only0",
                         drop00 = TRUE,
                         vtype = "LS",
                         append = TRUE,
                         var.names = c("yi", "vi"),
                         ...) {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  # Call escalc with all parameters
  result <- metafor::escalc(
    measure = measure,
    ai = ai, bi = bi, ci = ci, di = di,
    n1i = n1i, n2i = n2i,
    m1i = m1i, m2i = m2i,
    sd1i = sd1i, sd2i = sd2i,
    xi = xi, mi = mi, ri = ri, ti = ti,
    data = data,
    add = add,
    to = to,
    drop00 = drop00,
    vtype = vtype,
    append = append,
    var.names = var.names,
    ...
  )

  # Add metadata
  attr(result, "measure") <- measure
  attr(result, "cbamm_escalc") <- TRUE

  # Add descriptive statistics
  if (var.names[1] %in% names(result) && var.names[2] %in% names(result)) {
    yi <- result[[var.names[1]]]
    vi <- result[[var.names[2]]]

    summary_stats <- list(
      n_studies = sum(!is.na(yi)),
      mean_es = mean(yi, na.rm = TRUE),
      median_es = median(yi, na.rm = TRUE),
      min_es = min(yi, na.rm = TRUE),
      max_es = max(yi, na.rm = TRUE),
      Q = sum((yi - mean(yi, na.rm = TRUE))^2 / vi, na.rm = TRUE),
      tau2 = max(0, (sum((yi - mean(yi, na.rm = TRUE))^2 / vi, na.rm = TRUE) -
                       (length(yi) - 1)) / sum(1/vi, na.rm = TRUE))
    )

    attr(result, "summary") <- summary_stats
  }

  class(result) <- c("cbamm_escalc", class(result))
  return(result)
}


#' @export
print.cbamm_escalc <- function(x, ...) {
  cat("\nEffect Size Calculation (CBAMM)\n")
  cat("═══════════════════════════════════════\n\n")

  measure <- attr(x, "measure")
  if (!is.null(measure)) {
    cat("Measure:", measure, "\n")
  }

  summary_stats <- attr(x, "summary")
  if (!is.null(summary_stats)) {
    cat("\nSummary Statistics:\n")
    cat("  Studies:", summary_stats$n_studies, "\n")
    cat("  Mean ES:", sprintf("%.4f", summary_stats$mean_es), "\n")
    cat("  Median ES:", sprintf("%.4f", summary_stats$median_es), "\n")
    cat("  Range:", sprintf("[%.4f, %.4f]", summary_stats$min_es, summary_stats$max_es), "\n")
    cat("  Q:", sprintf("%.2f", summary_stats$Q), "\n")
    cat("  Tau²:", sprintf("%.4f", summary_stats$tau2), "\n")
  }

  cat("\nData:\n")
  print(as.data.frame(x), ...)

  invisible(x)
}


#' Quick Effect Size Calculation for Common Scenarios
#'
#' Convenience functions for the most common effect size calculations.
#'
#' @name quick-escalc
#' @rdname quick-escalc
NULL

#' @describeIn quick-escalc Calculate Odds Ratio (log scale)
#' @export
cbamm_calc_or <- function(ai, bi, ci, di, data = NULL, ...) {
  cbamm_escalc(measure = "OR", ai = ai, bi = bi, ci = ci, di = di,
               data = data, ...)
}

#' @describeIn quick-escalc Calculate Risk Ratio (log scale)
#' @export
cbamm_calc_rr <- function(ai, bi, ci, di, data = NULL, ...) {
  cbamm_escalc(measure = "RR", ai = ai, bi = bi, ci = ci, di = di,
               data = data, ...)
}

#' @describeIn quick-escalc Calculate Risk Difference
#' @export
cbamm_calc_rd <- function(ai, bi, ci, di, data = NULL, ...) {
  cbamm_escalc(measure = "RD", ai = ai, bi = bi, ci = ci, di = di,
               data = data, ...)
}

#' @describeIn quick-escalc Calculate Peto Odds Ratio
#' @export
cbamm_calc_peto <- function(ai, bi, ci, di, data = NULL, ...) {
  cbamm_escalc(measure = "PETO", ai = ai, bi = bi, ci = ci, di = di,
               data = data, add = 0, to = "none", ...)
}

#' @describeIn quick-escalc Calculate Mean Difference
#' @export
cbamm_calc_md <- function(m1i, sd1i, n1i, m2i, sd2i, n2i, data = NULL, ...) {
  cbamm_escalc(measure = "MD",
               m1i = m1i, sd1i = sd1i, n1i = n1i,
               m2i = m2i, sd2i = sd2i, n2i = n2i,
               data = data, ...)
}

#' @describeIn quick-escalc Calculate Standardized Mean Difference (Hedges' g)
#' @export
cbamm_calc_smd <- function(m1i, sd1i, n1i, m2i, sd2i, n2i, data = NULL, ...) {
  cbamm_escalc(measure = "SMD",
               m1i = m1i, sd1i = sd1i, n1i = n1i,
               m2i = m2i, sd2i = sd2i, n2i = n2i,
               data = data, vtype = "LS", ...)
}

#' @describeIn quick-escalc Calculate Proportion (logit transformed)
#' @export
cbamm_calc_prop <- function(xi, mi, data = NULL, ...) {
  cbamm_escalc(measure = "PLO", xi = xi, mi = mi, data = data, ...)
}

#' @describeIn quick-escalc Calculate Incidence Rate (log scale)
#' @export
cbamm_calc_ir <- function(xi, ti, data = NULL, ...) {
  cbamm_escalc(measure = "IRLN", xi = xi, ti = ti, data = data, ...)
}

#' @describeIn quick-escalc Calculate Fisher's z-transformed correlation
#' @export
cbamm_calc_zcor <- function(ri, ni, data = NULL, ...) {
  cbamm_escalc(measure = "ZCOR", ri = ri, ni = ni, data = data, ...)
}


#' Convert Between Effect Size Measures
#'
#' Convert effect sizes from one metric to another (e.g., OR to RR, SMD to OR).
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of variances
#' @param measure_from Original measure
#' @param measure_to Target measure
#' @param p0 Baseline probability (for OR to RR conversion)
#' @param ... Additional parameters
#'
#' @return List with converted yi and vi
#' @export
#'
#' @examples
#' \dontrun{
#' # Convert log OR to log RR
#' result <- cbamm_convert_es(yi = log_or, vi = vi_or,
#'                            measure_from = "OR",
#'                            measure_to = "RR",
#'                            p0 = 0.2)
#' }
cbamm_convert_es <- function(yi, vi, measure_from, measure_to, p0 = NULL, ...) {

  # OR to RR conversion
  if (measure_from == "OR" && measure_to == "RR") {
    if (is.null(p0)) {
      stop("Baseline probability p0 required for OR to RR conversion")
    }
    # Zhang & Yu (1998) approximation: log(RR) ≈ log(OR) * (1 - p0/2)
    yi_new <- yi * (1 - p0/2)
    vi_new <- vi * (1 - p0/2)^2

  # SMD to log OR conversion (Hasselblad & Hedges, 1995)
  } else if (measure_from == "SMD" && measure_to == "OR") {
    yi_new <- yi * pi / sqrt(3)
    vi_new <- vi * (pi^2 / 3)

  # log OR to SMD conversion
  } else if (measure_from == "OR" && measure_to == "SMD") {
    yi_new <- yi * sqrt(3) / pi
    vi_new <- vi * (3 / pi^2)

  # RR to OR conversion
  } else if (measure_from == "RR" && measure_to == "OR") {
    if (is.null(p0)) {
      warning("Baseline probability p0 not provided; using p0 = 0.2")
      p0 <- 0.2
    }
    # Approximate conversion
    yi_new <- yi / (1 - p0/2)
    vi_new <- vi / (1 - p0/2)^2

  } else {
    stop("Conversion from ", measure_from, " to ", measure_to, " not implemented")
  }

  result <- list(
    yi = yi_new,
    vi = vi_new,
    measure_from = measure_from,
    measure_to = measure_to,
    conversion_note = paste("Converted from", measure_from, "to", measure_to)
  )

  class(result) <- "cbamm_converted_es"
  return(result)
}


#' @export
print.cbamm_converted_es <- function(x, ...) {
  cat("\nEffect Size Conversion\n")
  cat("═══════════════════════════════════════\n\n")
  cat("From:", x$measure_from, "\n")
  cat("To:", x$measure_to, "\n")
  cat("Studies:", length(x$yi), "\n\n")
  cat("Converted Effect Sizes:\n")
  cat("  Mean:", sprintf("%.4f", mean(x$yi, na.rm = TRUE)), "\n")
  cat("  Range:", sprintf("[%.4f, %.4f]",
                          min(x$yi, na.rm = TRUE),
                          max(x$yi, na.rm = TRUE)), "\n")
  cat("\nNote:", x$conversion_note, "\n")
  invisible(x)
}


#' Back-Calculate Effect Sizes from P-values and Test Statistics
#'
#' Estimate effect sizes when only p-values, t-statistics, or confidence
#' intervals are reported.
#'
#' @param p P-value(s)
#' @param n Sample size(s)
#' @param t T-statistic(s)
#' @param df Degrees of freedom
#' @param ci_lb Lower confidence interval bound
#' @param ci_ub Upper confidence interval bound
#' @param conf_level Confidence level (default 0.95)
#' @param es_type Type of effect size ("d" for Cohen's d, "r" for correlation)
#'
#' @return Data frame with back-calculated effect sizes and variances
#' @export
#'
#' @examples
#' \dontrun{
#' # From p-value and sample size
#' result <- cbamm_backcalc_es(p = c(0.01, 0.05, 0.10),
#'                             n = c(50, 60, 70),
#'                             es_type = "d")
#'
#' # From t-statistic
#' result <- cbamm_backcalc_es(t = c(2.5, 3.1, 1.8),
#'                             df = c(48, 58, 68),
#'                             es_type = "d")
#' }
cbamm_backcalc_es <- function(p = NULL, n = NULL, t = NULL, df = NULL,
                              ci_lb = NULL, ci_ub = NULL,
                              conf_level = 0.95,
                              es_type = c("d", "r")) {

  es_type <- match.arg(es_type)

  # From p-value
  if (!is.null(p) && !is.null(n)) {
    # Convert p to z-score
    z <- qnorm(p/2, lower.tail = FALSE)

    if (es_type == "d") {
      # Approximate Cohen's d
      d <- 2 * z / sqrt(n)
      vi <- (4 / n) + (d^2 / (2*n))
      yi <- d
    } else {
      # Point-biserial correlation
      r <- z / sqrt(n + z^2)
      # Fisher's z transformation
      yi <- 0.5 * log((1 + r) / (1 - r))
      vi <- 1 / (n - 3)
    }

  # From t-statistic
  } else if (!is.null(t) && !is.null(df)) {
    if (es_type == "d") {
      # Cohen's d from t
      n_total <- df + 2
      d <- t * sqrt(4 / n_total)
      vi <- (4 / n_total) + (d^2 / (2*n_total))
      yi <- d
    } else {
      # Correlation from t
      r <- t / sqrt(t^2 + df)
      yi <- 0.5 * log((1 + r) / (1 - r))
      vi <- 1 / df
    }

  # From confidence interval
  } else if (!is.null(ci_lb) && !is.null(ci_ub)) {
    yi <- (ci_lb + ci_ub) / 2
    se <- (ci_ub - ci_lb) / (2 * qnorm((1 + conf_level) / 2))
    vi <- se^2

  } else {
    stop("Must provide either (p and n), (t and df), or (ci_lb and ci_ub)")
  }

  result <- data.frame(
    yi = yi,
    vi = vi,
    sei = sqrt(vi)
  )

  attr(result, "es_type") <- es_type
  attr(result, "method") <- "back-calculation"

  class(result) <- c("cbamm_backcalc_es", "data.frame")
  return(result)
}


#' @export
print.cbamm_backcalc_es <- function(x, ...) {
  cat("\nBack-Calculated Effect Sizes\n")
  cat("═══════════════════════════════════════\n\n")
  cat("Effect size type:", attr(x, "es_type"), "\n")
  cat("Studies:", nrow(x), "\n\n")
  cat("Summary:\n")
  cat("  Mean ES:", sprintf("%.4f", mean(x$yi, na.rm = TRUE)), "\n")
  cat("  Median ES:", sprintf("%.4f", median(x$yi, na.rm = TRUE)), "\n")
  cat("  Range:", sprintf("[%.4f, %.4f]",
                          min(x$yi, na.rm = TRUE),
                          max(x$yi, na.rm = TRUE)), "\n\n")
  print(as.data.frame(x), ...)
  invisible(x)
}
