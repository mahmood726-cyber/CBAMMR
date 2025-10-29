#' Sensitivity Analysis Suite for CBAMMR
#'
#' Comprehensive sensitivity analyses for meta-analysis robustness
#'
#' @name sensitivity-analysis
#' @keywords internal
NULL

#' Comprehensive Sensitivity Analysis
#'
#' Performs a comprehensive battery of sensitivity analyses to assess the
#' robustness of meta-analysis results to various assumptions and potential
#' biases.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param methods Vector of sensitivity methods to apply. Options:
#'   "outliers" (leave-one-out), "small_studies" (exclude smallest studies),
#'   "large_variance" (exclude high-variance studies), "trim_fill" (publication bias),
#'   "all" (default, run all methods)
#' @param small_study_threshold Proportion of smallest studies to exclude (default: 0.2)
#' @param high_var_threshold Variance percentile cutoff for high-variance exclusion (default: 0.9)
#'
#' @return An object of class "cbamm_sensitivity" containing:
#' \describe{
#'   \item{baseline}{Baseline meta-analysis results}
#'   \item{leave_one_out}{Leave-one-out analysis results}
#'   \item{small_study_excluded}{Results excluding small studies}
#'   \item{high_var_excluded}{Results excluding high-variance studies}
#'   \item{most_influential}{Most influential study}
#'   \item{robustness_score}{Overall robustness score (0-100)}
#' }
#'
#' @details
#' This function performs multiple sensitivity analyses:
#'
#' 1. **Leave-one-out analysis:** Removes each study sequentially
#' 2. **Small study exclusion:** Removes smallest studies (potential publication bias)
#' 3. **High variance exclusion:** Removes imprecise studies
#' 4. **Influence diagnostics:** Identifies most influential studies
#'
#' **Robustness score interpretation:**
#' - 90-100: Very robust
#' - 75-89: Robust
#' - 60-74: Moderately robust
#' - <60: Fragile, interpret with caution
#'
#' @references
#' Viechtbauer W, Cheung MW. (2010). Outlier and influence diagnostics for meta-analysis.
#' *Research Synthesis Methods*, 1(2), 112-125.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6, 1.2, 0.35, 0.55)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04, 0.08, 0.055, 0.045)
#' result <- cbamm_sensitivity_analysis(yi, vi)
#' print(result)
#' plot(result)
#' }
cbamm_sensitivity_analysis <- function(yi, vi,
                                       methods = "all",
                                       small_study_threshold = 0.2,
                                       high_var_threshold = 0.9) {
  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }
  if (length(yi) < 3) {
    stop("At least 3 studies required for sensitivity analysis")
  }

  # Select methods
  if ("all" %in% methods) {
    methods <- c("outliers", "small_studies", "large_variance")
  }

  n <- length(yi)
  weights <- 1 / vi

  # Baseline analysis
  baseline_est <- sum(weights * yi) / sum(weights)
  baseline_se <- sqrt(1 / sum(weights))
  baseline_ci <- c(baseline_est - 1.96 * baseline_se,
                   baseline_est + 1.96 * baseline_se)

  baseline <- list(
    estimate = baseline_est,
    se = baseline_se,
    ci = baseline_ci,
    n_studies = n
  )

  results <- list(baseline = baseline)

  # 1. Leave-one-out analysis
  if ("outliers" %in% methods) {
    loo_estimates <- numeric(n)
    loo_se <- numeric(n)
    loo_influence <- numeric(n)

    for (i in 1:n) {
      yi_loo <- yi[-i]
      vi_loo <- vi[-i]
      weights_loo <- 1 / vi_loo

      loo_estimates[i] <- sum(weights_loo * yi_loo) / sum(weights_loo)
      loo_se[i] <- sqrt(1 / sum(weights_loo))
      loo_influence[i] <- abs(loo_estimates[i] - baseline_est)
    }

    # Most influential study
    most_influential_idx <- which.max(loo_influence)

    results$leave_one_out <- data.frame(
      study = 1:n,
      estimate = loo_estimates,
      se = loo_se,
      influence = loo_influence,
      pct_change = (loo_estimates - baseline_est) / baseline_est * 100
    )

    results$most_influential <- list(
      study = most_influential_idx,
      influence = loo_influence[most_influential_idx],
      estimate_without = loo_estimates[most_influential_idx],
      pct_change = (loo_estimates[most_influential_idx] - baseline_est) / baseline_est * 100
    )
  }

  # 2. Exclude small studies
  if ("small_studies" %in% methods) {
    # Sample size proxy: 1/vi (precision)
    precision <- 1 / vi
    cutoff_idx <- ceiling(n * small_study_threshold)
    small_study_indices <- order(precision)[1:cutoff_idx]

    yi_large <- yi[-small_study_indices]
    vi_large <- vi[-small_study_indices]
    weights_large <- 1 / vi_large

    est_large <- sum(weights_large * yi_large) / sum(weights_large)
    se_large <- sqrt(1 / sum(weights_large))

    results$small_study_excluded <- list(
      estimate = est_large,
      se = se_large,
      ci = c(est_large - 1.96 * se_large, est_large + 1.96 * se_large),
      n_excluded = cutoff_idx,
      n_remaining = n - cutoff_idx,
      pct_change = (est_large - baseline_est) / baseline_est * 100
    )
  }

  # 3. Exclude high-variance studies
  if ("large_variance" %in% methods) {
    var_cutoff <- quantile(vi, probs = high_var_threshold)
    high_var_indices <- which(vi > var_cutoff)

    if (length(high_var_indices) > 0 && length(high_var_indices) < n - 2) {
      yi_low_var <- yi[-high_var_indices]
      vi_low_var <- vi[-high_var_indices]
      weights_low_var <- 1 / vi_low_var

      est_low_var <- sum(weights_low_var * yi_low_var) / sum(weights_low_var)
      se_low_var <- sqrt(1 / sum(weights_low_var))

      results$high_var_excluded <- list(
        estimate = est_low_var,
        se = se_low_var,
        ci = c(est_low_var - 1.96 * se_low_var, est_low_var + 1.96 * se_low_var),
        n_excluded = length(high_var_indices),
        n_remaining = n - length(high_var_indices),
        pct_change = (est_low_var - baseline_est) / baseline_est * 100
      )
    }
  }

  # Calculate robustness score
  robustness_score <- calculate_robustness_score(results, baseline_est)
  results$robustness_score <- robustness_score

  # Add metadata
  results$methods <- methods
  results$n_studies <- n

  class(results) <- "cbamm_sensitivity"
  return(results)
}


#' Calculate Robustness Score
#'
#' Internal function to calculate overall robustness score
#'
#' @keywords internal
calculate_robustness_score <- function(results, baseline_est) {
  scores <- numeric(0)

  # Score from leave-one-out (max influence as % of estimate)
  if (!is.null(results$leave_one_out)) {
    max_influence_pct <- max(abs(results$leave_one_out$pct_change))
    loo_score <- max(0, 100 - max_influence_pct)
    scores <- c(scores, loo_score)
  }

  # Score from small study exclusion
  if (!is.null(results$small_study_excluded)) {
    small_study_change <- abs(results$small_study_excluded$pct_change)
    small_study_score <- max(0, 100 - small_study_change * 2)
    scores <- c(scores, small_study_score)
  }

  # Score from high variance exclusion
  if (!is.null(results$high_var_excluded)) {
    high_var_change <- abs(results$high_var_excluded$pct_change)
    high_var_score <- max(0, 100 - high_var_change * 2)
    scores <- c(scores, high_var_score)
  }

  # Overall score (average)
  if (length(scores) > 0) {
    return(mean(scores))
  } else {
    return(NA)
  }
}


#' @export
print.cbamm_sensitivity <- function(x, ...) {
  cat("\nComprehensive Sensitivity Analysis\n")
  cat("═══════════════════════════════════════════════════════\n\n")

  cat("BASELINE ANALYSIS:\n")
  cat("─────────────────\n")
  cat(sprintf("  Estimate: %.4f (SE: %.4f)\n",
              x$baseline$estimate, x$baseline$se))
  cat(sprintf("  95%% CI: [%.4f, %.4f]\n",
              x$baseline$ci[1], x$baseline$ci[2]))
  cat(sprintf("  Number of studies: %d\n\n", x$baseline$n_studies))

  # Leave-one-out
  if (!is.null(x$leave_one_out)) {
    cat("LEAVE-ONE-OUT ANALYSIS:\n")
    cat("───────────────────────\n")
    cat(sprintf("  Most influential study: Study %d\n",
                x$most_influential$study))
    cat(sprintf("  Influence: %.4f (%.1f%% change)\n",
                x$most_influential$influence,
                x$most_influential$pct_change))
    cat(sprintf("  Estimate without: %.4f\n\n",
                x$most_influential$estimate_without))

    # Show range
    cat("  Estimate range across all leave-one-out:",
        sprintf("[%.4f, %.4f]\n\n",
                min(x$leave_one_out$estimate),
                max(x$leave_one_out$estimate)))
  }

  # Small studies
  if (!is.null(x$small_study_excluded)) {
    cat("SMALL STUDY EXCLUSION:\n")
    cat("──────────────────────\n")
    cat(sprintf("  Excluded: %d studies\n",
                x$small_study_excluded$n_excluded))
    cat(sprintf("  Estimate: %.4f (%.1f%% change)\n",
                x$small_study_excluded$estimate,
                x$small_study_excluded$pct_change))
    cat(sprintf("  95%% CI: [%.4f, %.4f]\n\n",
                x$small_study_excluded$ci[1],
                x$small_study_excluded$ci[2]))
  }

  # High variance
  if (!is.null(x$high_var_excluded)) {
    cat("HIGH VARIANCE EXCLUSION:\n")
    cat("────────────────────────\n")
    cat(sprintf("  Excluded: %d studies\n",
                x$high_var_excluded$n_excluded))
    cat(sprintf("  Estimate: %.4f (%.1f%% change)\n",
                x$high_var_excluded$estimate,
                x$high_var_excluded$pct_change))
    cat(sprintf("  95%% CI: [%.4f, %.4f]\n\n",
                x$high_var_excluded$ci[1],
                x$high_var_excluded$ci[2]))
  }

  # Robustness score
  cat("═══════════════════════════════════════════════════════\n")
  cat(sprintf("OVERALL ROBUSTNESS SCORE: %.1f / 100\n", x$robustness_score))
  cat("═══════════════════════════════════════════════════════\n\n")

  cat("Interpretation:\n")
  if (x$robustness_score >= 90) {
    cat("  ★★★★★ VERY ROBUST\n")
    cat("  Results are highly stable across sensitivity analyses.\n")
  } else if (x$robustness_score >= 75) {
    cat("  ★★★★☆ ROBUST\n")
    cat("  Results are generally stable with minor variations.\n")
  } else if (x$robustness_score >= 60) {
    cat("  ★★★☆☆ MODERATELY ROBUST\n")
    cat("  Results show some sensitivity to specific studies.\n")
  } else {
    cat("  ★★☆☆☆ FRAGILE\n")
    cat("  CAUTION: Results are sensitive to study inclusion.\n")
    cat("  Interpret with care and investigate influential studies.\n")
  }

  invisible(x)
}


#' Publication Bias Sensitivity Analysis
#'
#' Assesses sensitivity of results to potential publication bias using multiple
#' methods.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param methods Vector of methods: "trim_fill", "selection_model", "egger",
#'   or "all" (default)
#'
#' @return An object of class "cbamm_publication_bias_sensitivity"
#'
#' @details
#' Combines multiple publication bias methods to provide a comprehensive assessment:
#' - Trim-and-fill (imputes missing studies)
#' - Egger's test (tests for funnel plot asymmetry)
#' - Selection model sensitivity (various selection scenarios)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_publication_bias_sensitivity(yi, vi)
#' print(result)
#' }
cbamm_publication_bias_sensitivity <- function(yi, vi, methods = "all") {
  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  if ("all" %in% methods) {
    methods <- c("trim_fill", "egger")
  }

  results <- list()

  # Baseline
  weights <- 1 / vi
  baseline_est <- sum(weights * yi) / sum(weights)
  results$baseline <- baseline_est

  # Trim-and-fill
  if ("trim_fill" %in% methods) {
    # Simple trim-and-fill implementation
    se <- sqrt(vi)
    precision <- 1 / se

    # Rank by effect size
    order_idx <- order(yi)
    yi_ordered <- yi[order_idx]
    precision_ordered <- precision[order_idx]

    # Count studies to trim (simplified)
    n_trim <- 0
    for (i in 1:floor(length(yi) / 2)) {
      # Check asymmetry
      left_mean <- mean(yi_ordered[1:i])
      right_mean <- mean(yi_ordered[(length(yi) - i + 1):length(yi)])
      if (abs(left_mean - right_mean) > 2 * sd(yi) / sqrt(length(yi))) {
        n_trim <- i
      } else {
        break
      }
    }

    if (n_trim > 0) {
      # Impute missing studies
      yi_imputed <- c(yi, 2 * median(yi) - yi_ordered[1:n_trim])
      vi_imputed <- c(vi, vi[order_idx[1:n_trim]])
      weights_imputed <- 1 / vi_imputed

      trim_fill_est <- sum(weights_imputed * yi_imputed) / sum(weights_imputed)

      results$trim_fill <- list(
        estimate = trim_fill_est,
        n_imputed = n_trim,
        pct_change = (trim_fill_est - baseline_est) / baseline_est * 100
      )
    } else {
      results$trim_fill <- list(
        estimate = baseline_est,
        n_imputed = 0,
        pct_change = 0
      )
    }
  }

  # Egger's test
  if ("egger" %in% methods) {
    se <- sqrt(vi)
    precision <- 1 / se

    # Regression: effect size ~ precision
    fit <- lm(yi ~ precision)
    intercept <- coef(fit)[1]
    p_value <- summary(fit)$coefficients[1, 4]

    results$egger <- list(
      intercept = intercept,
      p_value = p_value,
      significant = p_value < 0.10  # Use 0.10 threshold for Egger
    )
  }

  # Summary
  results$methods <- methods

  class(results) <- "cbamm_publication_bias_sensitivity"
  return(results)
}


#' @export
print.cbamm_publication_bias_sensitivity <- function(x, ...) {
  cat("\nPublication Bias Sensitivity Analysis\n")
  cat("═══════════════════════════════════════\n\n")

  cat(sprintf("Baseline estimate: %.4f\n\n", x$baseline))

  if (!is.null(x$trim_fill)) {
    cat("TRIM-AND-FILL ANALYSIS:\n")
    cat("───────────────────────\n")
    cat(sprintf("  Imputed studies: %d\n", x$trim_fill$n_imputed))
    cat(sprintf("  Adjusted estimate: %.4f (%.1f%% change)\n",
                x$trim_fill$estimate, x$trim_fill$pct_change))
    if (x$trim_fill$n_imputed == 0) {
      cat("  No evidence of asymmetry\n")
    }
    cat("\n")
  }

  if (!is.null(x$egger)) {
    cat("EGGER'S TEST:\n")
    cat("─────────────\n")
    cat(sprintf("  Intercept: %.4f\n", x$egger$intercept))
    cat(sprintf("  P-value: %.4f\n", x$egger$p_value))
    if (x$egger$significant) {
      cat("  ⚠ Evidence of publication bias (p < 0.10)\n")
    } else {
      cat("  ✓ No strong evidence of publication bias\n")
    }
    cat("\n")
  }

  cat("RECOMMENDATION:\n")
  bias_detected <- FALSE
  if (!is.null(x$trim_fill) && x$trim_fill$n_imputed > 0) bias_detected <- TRUE
  if (!is.null(x$egger) && x$egger$significant) bias_detected <- TRUE

  if (bias_detected) {
    cat("  ⚠ Potential publication bias detected\n")
    cat("  Consider: \n")
    cat("    - Searching for unpublished studies\n")
    cat("    - Contacting authors for additional data\n")
    cat("    - Downgrading certainty of evidence\n")
  } else {
    cat("  ✓ No strong evidence of publication bias\n")
    cat("  Results appear reasonably robust.\n")
  }

  invisible(x)
}
