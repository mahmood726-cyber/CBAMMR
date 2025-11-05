#' Comprehensive Small-Study Effects Assessment
#'
#' Complete toolkit for detecting and adjusting for small-study effects
#' and publication bias in meta-analysis.
#'
#' @name small-study-effects
#' @keywords internal
NULL

#' Comprehensive Small-Study Effects Analysis
#'
#' All-in-one function for assessing small-study effects using multiple
#' methods: Egger's test, Begg's test, trim-and-fill, PET-PEESE, and more.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param method Meta-analysis method
#'
#' @return Object of class "cbamm_small_study" with comprehensive results
#' @export
#'
#' @examples
#' \dontrun{
#' data(tobacco_lung_cancer)
#' result <- cbamm_small_study_effects(
#'   yi = tobacco_lung_cancer$yi,
#'   vi = tobacco_lung_cancer$vi
#' )
#' print(result)
#' plot(result)
#' }
cbamm_small_study_effects <- function(yi, vi, sei = NULL, method = "REML") {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  if (is.null(sei)) {
    sei <- sqrt(vi)
  }

  k <- length(yi)

  # 1. Egger's regression test
  egger <- cbamm_egger_test(yi, vi, method = method)

  # 2. Begg's rank correlation test
  begg <- cbamm_begg_test(yi, vi)

  # 3. Trim and fill
  taf <- cbamm_trimfill_metafor(yi, vi, method = method)

  # 4. PET-PEESE
  pet_peese_result <- pet_peese(yi, vi, method = method)

  # 5. Funnel plot asymmetry (FAT)
  fat <- .funnel_asymmetry_test(yi, sei)

  # 6. Test of excess significance
  tes <- .test_excess_significance(yi, vi)

  # Overall assessment
  n_significant <- sum(c(
    egger$p_value < 0.05,
    begg$p_value < 0.05,
    fat$p_value < 0.05
  ))

  if (n_significant >= 2) {
    overall <- "Strong evidence of small-study effects"
    concern_level <- "High"
  } else if (n_significant == 1) {
    overall <- "Some evidence of small-study effects"
    concern_level <- "Moderate"
  } else {
    overall <- "Little evidence of small-study effects"
    concern_level <- "Low"
  }

  result <- list(
    k = k,
    egger = egger,
    begg = begg,
    trimfill = taf,
    pet_peese = pet_peese_result,
    fat = fat,
    tes = tes,
    overall = overall,
    concern_level = concern_level,
    yi = yi,
    vi = vi,
    sei = sei
  )

  class(result) <- "cbamm_small_study"
  return(result)
}


#' @export
print.cbamm_small_study <- function(x, ...) {
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Comprehensive Small-Study Effects Analysis\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat("Studies:", x$k, "\n\n")

  cat("1. Egger's Regression Test:\n")
  cat(sprintf("   Bias = %.4f, SE = %.4f, p = %.4f\n",
              x$egger$estimate, x$egger$se, x$egger$p_value))
  cat(sprintf("   %s\n\n", x$egger$interpretation))

  cat("2. Begg's Rank Correlation Test:\n")
  cat(sprintf("   Kendall's tau = %.3f, p = %.4f\n",
              x$begg$tau, x$begg$p_value))
  cat(sprintf("   %s\n\n", x$begg$interpretation))

  cat("3. Trim-and-Fill:\n")
  cat(sprintf("   Imputed studies: %d\n", x$trimfill$n_imputed))
  cat(sprintf("   Adjusted estimate: %.4f (original: %.4f)\n",
              x$trimfill$adjusted_estimate, x$trimfill$original_estimate))
  cat(sprintf("   Change: %.4f\n\n", x$trimfill$adjusted_estimate - x$trimfill$original_estimate))

  cat("4. PET-PEESE:\n")
  if (!is.null(x$pet_peese$pet_significant)) {
    if (x$pet_peese$pet_significant) {
      cat(sprintf("   Using PEESE: Adjusted estimate = %.4f\n",
                  x$pet_peese$peese_estimate))
    } else {
      cat(sprintf("   Using PET: Adjusted estimate = %.4f\n",
                  x$pet_peese$pet_estimate))
    }
  }

  cat("\n5. Funnel Asymmetry Test:\n")
  cat(sprintf("   Z = %.3f, p = %.4f\n\n", x$fat$z, x$fat$p_value))

  cat("Overall Assessment:\n")
  cat(sprintf("  %s\n", x$overall))
  cat(sprintf("  Concern level: %s\n", x$concern_level))

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}


#' @export
plot.cbamm_small_study <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required")
  }

  # Create contour-enhanced funnel plot
  df <- data.frame(
    yi = x$yi,
    sei = x$sei
  )

  # Calculate pooled estimate
  weights <- 1 / x$vi
  pooled <- sum(weights * x$yi) / sum(weights)

  # Create contours
  sei_range <- seq(0, max(x$sei) * 1.1, length.out = 100)
  contours <- data.frame()
  for (level in c(0.90, 0.95, 0.99)) {
    z <- qnorm((1 + level)/2)
    contours <- rbind(contours,
                     data.frame(sei = sei_range,
                               lb = pooled - z * sei_range,
                               ub = pooled + z * sei_range,
                               level = factor(level)))
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = yi, y = sei)) +
    ggplot2::geom_ribbon(data = contours,
                        ggplot2::aes(x = NULL, y = sei, xmin = lb, xmax = ub,
                                    fill = level),
                        alpha = 0.2) +
    ggplot2::geom_point(size = 2, alpha = 0.7) +
    ggplot2::geom_vline(xintercept = pooled, linetype = "dashed", color = "blue") +
    ggplot2::scale_y_reverse() +
    ggplot2::labs(
      title = "Funnel Plot with Contours",
      subtitle = sprintf("Overall: %s (Concern: %s)",
                        x$overall, x$concern_level),
      x = "Effect Size",
      y = "Standard Error",
      fill = "Confidence Level"
    ) +
    ggplot2::theme_minimal()

  print(p)
  invisible(x)
}


#' Egger's Regression Test
#'
#' Test for funnel plot asymmetry using Egger's regression.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Meta-analysis method
#'
#' @return Object of class "cbamm_egger" with test results
#' @export
cbamm_egger_test <- function(yi, vi, method = "REML") {
  # Input validation
  validate_meta_inputs(yi, vi)
  validate_sample_size(length(yi), "publication-bias", warning_only = TRUE)

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  sei <- sqrt(vi)

  # Egger's regression: yi ~ sei
  res <- metafor::rma(yi = yi, vi = vi, mods = ~ sei, method = method)

  # Intercept is the bias term
  bias <- res$beta[1]
  bias_se <- res$se[1]
  bias_z <- res$zval[1]
  bias_p <- res$pval[1]

  # Interpretation
  if (bias_p < 0.01) {
    interpretation <- "Strong evidence of funnel plot asymmetry"
  } else if (bias_p < 0.05) {
    interpretation <- "Evidence of funnel plot asymmetry"
  } else {
    interpretation <- "No significant funnel plot asymmetry"
  }

  result <- list(
    estimate = bias,
    se = bias_se,
    z_value = bias_z,
    p_value = bias_p,
    interpretation = interpretation,
    k = length(yi)
  )

  class(result) <- "cbamm_egger"
  return(result)
}


#' Begg's Rank Correlation Test
#'
#' Test for funnel plot asymmetry using Begg's rank correlation.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#'
#' @return Object of class "cbamm_begg" with test results
#' @export
cbamm_begg_test <- function(yi, vi) {

  # Input validation
  validate_meta_inputs(yi, vi)
  validate_sample_size(length(yi), "publication-bias", warning_only = TRUE)

  # Kendall's tau between effect sizes and their variances
  test_result <- cor.test(yi, vi, method = "kendall")

  tau <- test_result$estimate
  p_value <- test_result$p.value

  # Interpretation
  if (p_value < 0.05) {
    interpretation <- "Significant rank correlation - possible publication bias"
  } else {
    interpretation <- "No significant rank correlation"
  }

  result <- list(
    tau = tau,
    p_value = p_value,
    interpretation = interpretation,
    k = length(yi)
  )

  class(result) <- "cbamm_begg"
  return(result)
}


#' Funnel Asymmetry Test
#' @keywords internal
.funnel_asymmetry_test <- function(yi, sei) {

  # Rank-based test for funnel asymmetry
  # Test correlation between standardized effect and precision

  precision <- 1 / sei
  std_effect <- yi * precision

  # Test for asymmetry
  cor_result <- cor.test(std_effect, precision, method = "pearson")

  z <- cor_result$statistic
  p_value <- cor_result$p.value

  list(
    z = z,
    p_value = p_value
  )
}


#' Test of Excess Significance
#' @keywords internal
.test_excess_significance <- function(yi, vi) {

  # Calculate power for each study
  # Using pooled effect as "true" effect
  weights <- 1 / vi
  pooled <- sum(weights * yi) / sum(weights)

  # Calculate expected number of significant results
  k <- length(yi)
  sei <- sqrt(vi)
  z <- yi / sei
  powers <- pnorm(abs(z) - 1.96) + (1 - pnorm(abs(z) + 1.96))

  expected_sig <- sum(powers)
  observed_sig <- sum(abs(z) > 1.96)

  # Chi-square test
  if (expected_sig > 0 && expected_sig < k) {
    expected_nonsig <- k - expected_sig
    observed_nonsig <- k - observed_sig

    chisq <- ((observed_sig - expected_sig)^2 / expected_sig) +
             ((observed_nonsig - expected_nonsig)^2 / expected_nonsig)
    p_value <- pchisq(chisq, df = 1, lower.tail = FALSE)
  } else {
    p_value <- NA
  }

  list(
    expected = expected_sig,
    observed = observed_sig,
    p_value = p_value
  )
}


#' Selection Model for Publication Bias
#'
#' Fit selection models to adjust for publication bias (Vevea & Hedges).
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param steps P-value cutpoints for selection (default c(0.025, 0.5, 1))
#' @param method Estimation method
#'
#' @return Object of class "cbamm_selection_model" with adjusted results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_selection_model(yi, vi)
#' print(result)
#' }
cbamm_selection_model <- function(yi, vi,
                                   steps = c(0.025, 0.5, 1),
                                   method = "REML") {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Calculate one-sided p-values
  sei <- sqrt(vi)
  z <- yi / sei
  p_values <- pnorm(-abs(z))

  # Assign weights based on p-value intervals
  k <- length(yi)
  weights <- numeric(k)

  # Default weights (1 for p < 0.025, decreasing for larger p)
  default_weights <- c(1, 0.8, 0.5)

  for (i in 1:k) {
    p <- p_values[i]
    if (p < steps[1]) {
      weights[i] <- default_weights[1]
    } else if (p < steps[2]) {
      weights[i] <- default_weights[2]
    } else {
      weights[i] <- default_weights[3]
    }
  }

  # Weighted meta-analysis
  vi_weighted <- vi / weights^2

  res_weighted <- metafor::rma(yi = yi, vi = vi_weighted, method = method)
  res_standard <- metafor::rma(yi = yi, vi = vi, method = method)

  result <- list(
    estimate_adjusted = res_weighted$beta[1],
    se_adjusted = res_weighted$se,
    ci_lb_adjusted = res_weighted$ci.lb,
    ci_ub_adjusted = res_weighted$ci.ub,
    estimate_standard = res_standard$beta[1],
    se_standard = res_standard$se,
    difference = res_weighted$beta[1] - res_standard$beta[1],
    weights = weights,
    steps = steps
  )

  class(result) <- "cbamm_selection_model"
  return(result)
}


#' @export
print.cbamm_selection_model <- function(x, ...) {
  cat("\nSelection Model for Publication Bias\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Standard Estimate:\n")
  cat(sprintf("  %.4f (SE = %.4f)\n\n", x$estimate_standard, x$se_standard))

  cat("Selection-Adjusted Estimate:\n")
  cat(sprintf("  %.4f [%.4f, %.4f]\n", x$estimate_adjusted,
              x$ci_lb_adjusted, x$ci_ub_adjusted))
  cat(sprintf("  SE = %.4f\n\n", x$se_adjusted))

  cat(sprintf("Adjustment: %.4f\n", x$difference))

  if (abs(x$difference) > 0.1) {
    cat("\nSubstantial adjustment suggests publication bias\n")
  } else {
    cat("\nMinimal adjustment\n")
  }

  invisible(x)
}


#' P-Curve Analysis
#'
#' Analyze the distribution of p-values to detect publication bias
#' and assess evidential value.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#'
#' @return Object of class "cbamm_pcurve" with p-curve analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_pcurve(yi, vi)
#' print(result)
#' plot(result)
#' }
cbamm_pcurve <- function(yi, vi) {

  # Input validation
  validate_meta_inputs(yi, vi)
  validate_sample_size(length(yi), "publication-bias", warning_only = TRUE)

  # Calculate p-values
  sei <- sqrt(vi)
  z <- yi / sei
  p_values <- 2 * pnorm(-abs(z))

  # Focus on significant results (p < 0.05)
  sig_idx <- p_values < 0.05
  p_sig <- p_values[sig_idx]

  if (length(p_sig) < 3) {
    stop("Need at least 3 significant results for p-curve analysis")
  }

  # Test if distribution is right-skewed (evidential value)
  # Under null, p-values should be uniform
  # Under alternative with evidential value, should be right-skewed

  # Binomial test: proportion with p < 0.025
  n_very_sig <- sum(p_sig < 0.025)
  n_sig <- length(p_sig)
  expected_prop <- 0.5  # Expected under uniform distribution

  binom_test <- binom.test(n_very_sig, n_sig, p = expected_prop, alternative = "greater")

  # Kolmogorov-Smirnov test against uniform
  ks_test <- ks.test(p_sig, "punif", min = 0, max = 0.05)

  # Interpretation
  if (binom_test$p.value < 0.05) {
    interpretation <- "Right-skewed p-curve: Evidence of evidential value"
    evidential_value <- "Present"
  } else if (binom_test$p.value < 0.10) {
    interpretation <- "Marginally right-skewed p-curve"
    evidential_value <- "Weak"
  } else {
    interpretation <- "Flat p-curve: Possible publication bias or p-hacking"
    evidential_value <- "Absent"
  }

  result <- list(
    n_total = length(yi),
    n_significant = n_sig,
    n_very_significant = n_very_sig,
    prop_very_sig = n_very_sig / n_sig,
    binom_p = binom_test$p.value,
    ks_p = ks_test$p.value,
    interpretation = interpretation,
    evidential_value = evidential_value,
    p_values = p_sig
  )

  class(result) <- "cbamm_pcurve"
  return(result)
}


#' @export
print.cbamm_pcurve <- function(x, ...) {
  cat("\nP-Curve Analysis\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Studies:\n")
  cat(sprintf("  Total: %d\n", x$n_total))
  cat(sprintf("  Significant (p < 0.05): %d\n", x$n_significant))
  cat(sprintf("  Very significant (p < 0.025): %d (%.1f%%)\n\n",
              x$n_very_significant, x$prop_very_sig * 100))

  cat("Tests:\n")
  cat(sprintf("  Binomial test: p = %.4f\n", x$binom_p))
  cat(sprintf("  K-S test: p = %.4f\n\n", x$ks_p))

  cat("Interpretation:\n")
  cat(sprintf("  %s\n", x$interpretation))
  cat(sprintf("  Evidential value: %s\n", x$evidential_value))

  invisible(x)
}


#' @export
plot.cbamm_pcurve <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required")
  }

  df <- data.frame(p = x$p_values)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = p)) +
    ggplot2::geom_histogram(bins = 10, fill = "#3498db", alpha = 0.7,
                           boundary = 0) +
    ggplot2::geom_hline(yintercept = x$n_significant / 10,
                       linetype = "dashed", color = "red") +
    ggplot2::labs(
      title = "P-Curve",
      subtitle = sprintf("%s (Evidential value: %s)",
                        x$interpretation, x$evidential_value),
      x = "P-value",
      y = "Frequency"
    ) +
    ggplot2::scale_x_continuous(limits = c(0, 0.05), breaks = seq(0, 0.05, 0.01)) +
    ggplot2::theme_minimal()

  print(p)
  invisible(x)
}
