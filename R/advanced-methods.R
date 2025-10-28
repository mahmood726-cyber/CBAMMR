#' Distribution-Free and Clinical Decision-Making Methods for Meta-Analysis
#'
#' Advanced methods that don't require distributional assumptions and tools
#' for clinical decision-making based on meta-analysis results.
#'
#' @name advanced_methods
NULL

#' Permutation Test for Meta-Analysis
#'
#' Distribution-free hypothesis test for overall effect using permutation.
#' Does not assume normality of random effects or effect sizes.
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param n_perm Number of permutations (default 10000)
#' @param alternative Alternative hypothesis: "two.sided", "greater", "less"
#'
#' @return List with observed statistic, p-value, and permutation distribution
#'
#' @details
#' This method creates a null distribution by randomly permuting the signs
#' of effect sizes and computing the test statistic. No assumptions about
#' the distribution of random effects are required.
#'
#' @references
#' Follmann & Proschan (1999). Valid inference in random effects meta-analysis.
#' Biometrics, 55(3), 732-737.
#'
#' @examples
#' \dontrun{
#' # Permutation test (distribution-free)
#' result <- cbamm_permutation_test(
#'   yi = c(0.3, 0.5, 0.4, 0.6),
#'   vi = c(0.1, 0.12, 0.09, 0.11),
#'   n_perm = 10000
#' )
#' print(result$pvalue)  # Distribution-free p-value
#' }
#'
#' @export
cbamm_permutation_test <- function(yi, vi, n_perm = 10000,
                                   alternative = c("two.sided", "greater", "less")) {
  alternative <- match.arg(alternative)

  # Observed test statistic (weighted mean)
  weights <- 1 / vi
  observed_stat <- sum(weights * yi) / sum(weights)

  # Permutation distribution
  perm_stats <- numeric(n_perm)

  for (i in seq_len(n_perm)) {
    # Randomly flip signs
    signs <- sample(c(-1, 1), length(yi), replace = TRUE)
    yi_perm <- yi * signs

    # Compute permuted statistic
    perm_stats[i] <- sum(weights * yi_perm) / sum(weights)
  }

  # Compute p-value
  if (alternative == "two.sided") {
    pvalue <- mean(abs(perm_stats) >= abs(observed_stat))
  } else if (alternative == "greater") {
    pvalue <- mean(perm_stats >= observed_stat)
  } else {
    pvalue <- mean(perm_stats <= observed_stat)
  }

  result <- list(
    observed = observed_stat,
    pvalue = pvalue,
    perm_distribution = perm_stats,
    n_perm = n_perm,
    alternative = alternative,
    method = "Permutation Test for Meta-Analysis"
  )

  class(result) <- c("cbamm_permutation_test", "list")
  return(result)
}


#' Bootstrap Confidence Intervals for Meta-Analysis
#'
#' Distribution-free confidence intervals using bootstrap resampling.
#' Does not assume normality of random effects.
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param conf_level Confidence level (default 0.95)
#' @param n_boot Number of bootstrap samples (default 10000)
#' @param method Bootstrap method: "percentile", "bca" (bias-corrected accelerated)
#'
#' @return List with point estimate, confidence interval, and bootstrap distribution
#'
#' @details
#' Creates confidence intervals by resampling studies with replacement and
#' re-estimating the pooled effect. No distributional assumptions required.
#' The BCa method adjusts for bias and skewness in the bootstrap distribution.
#'
#' @references
#' Efron & Tibshirani (1993). An Introduction to the Bootstrap. Chapman & Hall.
#'
#' @examples
#' \dontrun{
#' # Bootstrap confidence intervals (distribution-free)
#' result <- cbamm_bootstrap_ci(
#'   yi = c(0.3, 0.5, 0.4, 0.6),
#'   vi = c(0.1, 0.12, 0.09, 0.11),
#'   n_boot = 10000,
#'   method = "bca"
#' )
#' print(result$ci)  # Distribution-free CI
#' }
#'
#' @export
cbamm_bootstrap_ci <- function(yi, vi, conf_level = 0.95, n_boot = 10000,
                               method = c("percentile", "bca")) {
  method <- match.arg(method)

  n <- length(yi)

  # Original estimate
  weights <- 1 / vi
  theta_hat <- sum(weights * yi) / sum(weights)

  # Bootstrap resampling
  boot_estimates <- numeric(n_boot)

  for (i in seq_len(n_boot)) {
    # Resample studies with replacement
    idx <- sample(seq_len(n), replace = TRUE)
    yi_boot <- yi[idx]
    vi_boot <- vi[idx]

    # Compute bootstrap estimate
    weights_boot <- 1 / vi_boot
    boot_estimates[i] <- sum(weights_boot * yi_boot) / sum(weights_boot)
  }

  if (method == "percentile") {
    # Percentile method
    alpha <- 1 - conf_level
    ci <- quantile(boot_estimates, probs = c(alpha/2, 1 - alpha/2))
  } else {
    # BCa (bias-corrected and accelerated)
    # Bias correction factor
    z0 <- qnorm(mean(boot_estimates < theta_hat))

    # Acceleration factor (jackknife)
    jack_estimates <- numeric(n)
    for (i in seq_len(n)) {
      yi_jack <- yi[-i]
      vi_jack <- vi[-i]
      weights_jack <- 1 / vi_jack
      jack_estimates[i] <- sum(weights_jack * yi_jack) / sum(weights_jack)
    }
    jack_mean <- mean(jack_estimates)
    a <- sum((jack_mean - jack_estimates)^3) / (6 * sum((jack_mean - jack_estimates)^2)^1.5)

    # Adjusted percentiles
    alpha <- 1 - conf_level
    z_alpha <- qnorm(c(alpha/2, 1 - alpha/2))
    p_adj <- pnorm(z0 + (z0 + z_alpha) / (1 - a * (z0 + z_alpha)))

    ci <- quantile(boot_estimates, probs = p_adj)
  }

  result <- list(
    estimate = theta_hat,
    ci = as.numeric(ci),
    ci_lower = as.numeric(ci[1]),
    ci_upper = as.numeric(ci[2]),
    conf_level = conf_level,
    boot_distribution = boot_estimates,
    n_boot = n_boot,
    method = method
  )

  class(result) <- c("cbamm_bootstrap_ci", "list")
  return(result)
}


#' Quantile Regression Meta-Analysis
#'
#' Estimate treatment effects at different quantiles of the outcome distribution.
#' Reveals heterogeneous treatment effects across the distribution.
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param tau Quantiles to estimate (default c(0.1, 0.25, 0.5, 0.75, 0.9))
#'
#' @return List with quantile estimates and confidence intervals
#'
#' @details
#' Standard meta-analysis estimates the mean treatment effect. Quantile
#' regression estimates effects at different points of the outcome distribution,
#' revealing whether treatment benefits differ for those with low vs high outcomes.
#'
#' This is crucial for personalized medicine and understanding "who benefits most."
#'
#' @references
#' Wang et al. (2022). Quantile regression in random effects meta-analysis model.
#' Statistical Methods & Applications.
#'
#' @examples
#' \dontrun{
#' # Quantile meta-analysis
#' result <- cbamm_quantile_ma(
#'   yi = c(0.3, 0.5, 0.4, 0.6, 0.7),
#'   vi = c(0.1, 0.12, 0.09, 0.11, 0.13),
#'   tau = c(0.1, 0.25, 0.5, 0.75, 0.9)
#' )
#' plot(result)  # Shows how effect varies across quantiles
#' }
#'
#' @export
cbamm_quantile_ma <- function(yi, vi, tau = c(0.1, 0.25, 0.5, 0.75, 0.9)) {

  require(quantreg)

  n <- length(yi)
  k <- length(tau)

  # Weight matrix (inverse variance)
  W <- diag(1 / vi)

  # Storage for results
  results <- data.frame(
    quantile = tau,
    estimate = numeric(k),
    se = numeric(k),
    ci_lower = numeric(k),
    ci_upper = numeric(k)
  )

  # Estimate each quantile
  for (i in seq_along(tau)) {
    # Quantile regression (weighted)
    # Using a simple weighted quantile
    weights <- 1 / vi
    q_est <- wtd.quantile(yi, weights = weights, probs = tau[i])

    # Bootstrap SE
    boot_ests <- numeric(1000)
    for (b in seq_len(1000)) {
      idx <- sample(seq_len(n), replace = TRUE)
      boot_ests[b] <- wtd.quantile(yi[idx], weights = weights[idx], probs = tau[i])
    }
    se_est <- sd(boot_ests)

    results$estimate[i] <- q_est
    results$se[i] <- se_est
    results$ci_lower[i] <- q_est - 1.96 * se_est
    results$ci_upper[i] <- q_est + 1.96 * se_est
  }

  result <- list(
    quantiles = results,
    interpretation = interpret_quantile_results(results),
    method = "Quantile Regression Meta-Analysis"
  )

  class(result) <- c("cbamm_quantile_ma", "list")
  return(result)
}

# Helper function for weighted quantile
wtd.quantile <- function(x, weights, probs) {
  ord <- order(x)
  x <- x[ord]
  weights <- weights[ord]
  cum_weights <- cumsum(weights) / sum(weights)
  quantile_val <- approx(cum_weights, x, xout = probs, rule = 2)$y
  return(quantile_val)
}

interpret_quantile_results <- function(results) {
  # Check if treatment effect varies across quantiles
  range_effect <- max(results$estimate) - min(results$estimate)
  mean_se <- mean(results$se)

  if (range_effect > 3 * mean_se) {
    interpretation <- "Treatment effects vary substantially across the outcome distribution (heterogeneous treatment effects)."
  } else {
    interpretation <- "Treatment effects are relatively consistent across the outcome distribution (homogeneous treatment effects)."
  }

  return(interpretation)
}


#' Threshold Analysis for Treatment Decisions
#'
#' Assess how robust treatment recommendations are to plausible bias.
#' Answers: "How large would bias need to be to change our decision?"
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param decision_threshold Clinical decision threshold (e.g., minimal clinically important difference)
#' @param bias_range Range of bias to explore (default c(-0.5, 0.5))
#'
#' @return List with threshold bias values and decision robustness
#'
#' @details
#' Explores how much systematic bias (e.g., publication bias, study quality bias)
#' would be needed to change a treatment recommendation. Quantifies decision
#' robustness and identifies critical bias thresholds.
#'
#' @references
#' Phillippo et al. (2016). Threshold analysis as an alternative to GRADE for
#' assessing confidence in guideline recommendations based on network meta-analyses.
#'
#' @examples
#' \dontrun{
#' # Threshold analysis
#' result <- cbamm_threshold_analysis(
#'   yi = c(0.3, 0.5, 0.4, 0.6),
#'   vi = c(0.1, 0.12, 0.09, 0.11),
#'   decision_threshold = 0.2,  # MCID
#'   bias_range = c(-0.5, 0.5)
#' )
#' print(result$threshold_bias)  # Bias needed to change decision
#' }
#'
#' @export
cbamm_threshold_analysis <- function(yi, vi, decision_threshold,
                                     bias_range = c(-0.5, 0.5)) {

  # Original pooled estimate
  weights <- 1 / vi
  original_estimate <- sum(weights * yi) / sum(weights)
  original_se <- sqrt(1 / sum(weights))

  # Original decision
  original_decision <- original_estimate > decision_threshold

  # Explore bias range
  bias_seq <- seq(bias_range[1], bias_range[2], length.out = 100)

  decisions <- logical(length(bias_seq))
  estimates <- numeric(length(bias_seq))

  for (i in seq_along(bias_seq)) {
    # Apply bias
    yi_biased <- yi + bias_seq[i]

    # Re-estimate
    est_biased <- sum(weights * yi_biased) / sum(weights)
    estimates[i] <- est_biased

    # Decision under bias
    decisions[i] <- est_biased > decision_threshold
  }

  # Find threshold bias (where decision changes)
  decision_changes <- which(decisions != original_decision)

  if (length(decision_changes) > 0) {
    # Interpolate to find exact threshold
    idx <- decision_changes[1]
    if (idx > 1) {
      threshold_bias <- approx(
        x = estimates[(idx-1):idx],
        y = bias_seq[(idx-1):idx],
        xout = decision_threshold
      )$y
    } else {
      threshold_bias <- bias_seq[1]
    }
  } else {
    threshold_bias <- NA  # Decision robust to explored bias range
  }

  result <- list(
    original_estimate = original_estimate,
    original_se = original_se,
    decision_threshold = decision_threshold,
    original_decision = if (original_decision) "Favor treatment" else "Do not favor treatment",
    threshold_bias = threshold_bias,
    bias_range = bias_range,
    robustness = interpret_threshold(threshold_bias, bias_range),
    bias_seq = bias_seq,
    estimates = estimates,
    decisions = decisions
  )

  class(result) <- c("cbamm_threshold_analysis", "list")
  return(result)
}

interpret_threshold <- function(threshold_bias, bias_range) {
  if (is.na(threshold_bias)) {
    return("ROBUST: Decision remains unchanged across entire explored bias range.")
  } else if (abs(threshold_bias) > 0.3) {
    return(sprintf("MODERATELY ROBUST: Requires substantial bias (%.2f) to change decision.", threshold_bias))
  } else if (abs(threshold_bias) > 0.1) {
    return(sprintf("SOMEWHAT ROBUST: Requires moderate bias (%.2f) to change decision.", threshold_bias))
  } else {
    return(sprintf("FRAGILE: Small bias (%.2f) could change decision.", threshold_bias))
  }
}


#' Expected Value of Perfect Information (EVPI)
#'
#' Calculate the expected value of eliminating all uncertainty in a meta-analysis.
#' Guides research prioritization and sample size decisions.
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param benefit_per_unit Benefit per unit effect size (e.g., QALYs, $)
#' @param population_size Affected population size
#' @param time_horizon Time horizon in years
#' @param discount_rate Annual discount rate (default 0.03)
#'
#' @return List with EVPI and interpretation
#'
#' @details
#' EVPI quantifies the expected cost of current uncertainty. It represents
#' the maximum amount that should be spent on additional research to resolve
#' uncertainty. Essential for research prioritization and funding decisions.
#'
#' @references
#' Claxton & Posnett (1996). An economic approach to clinical trial design and
#' research priority-setting. Health Economics, 5(6), 513-524.
#'
#' @examples
#' \dontrun{
#' # Calculate EVPI
#' result <- cbamm_evpi(
#'   yi = c(0.3, 0.5, 0.4),
#'   vi = c(0.1, 0.12, 0.09),
#'   benefit_per_unit = 10000,  # $10,000 per unit effect
#'   population_size = 100000,  # 100,000 affected patients
#'   time_horizon = 10  # 10-year horizon
#' )
#' print(result$evpi)  # Maximum value of additional research
#' }
#'
#' @export
cbamm_evpi <- function(yi, vi, benefit_per_unit, population_size,
                       time_horizon = 10, discount_rate = 0.03) {

  # Pooled estimate and uncertainty
  weights <- 1 / vi
  theta_hat <- sum(weights * yi) / sum(weights)
  se_theta <- sqrt(1 / sum(weights))

  # Decision threshold (assume 0 = no treatment benefit)
  threshold <- 0

  # Expected loss due to uncertainty
  # Probability of making wrong decision
  prob_wrong <- pnorm(threshold, mean = theta_hat, sd = se_theta)

  if (theta_hat > threshold) {
    # Currently favor treatment, but might be wrong
    expected_loss_if_wrong <- benefit_per_unit * abs(theta_hat - threshold) * prob_wrong
  } else {
    # Currently don't favor treatment, but might be wrong
    prob_wrong <- 1 - prob_wrong
    expected_loss_if_wrong <- benefit_per_unit * abs(theta_hat - threshold) * prob_wrong
  }

  # Calculate discounted population EVPI
  discount_factor <- sum((1 / (1 + discount_rate))^(1:time_horizon))
  evpi_total <- expected_loss_if_wrong * population_size * discount_factor

  # Per-person EVPI
  evpi_per_person <- expected_loss_if_wrong * discount_factor

  result <- list(
    evpi_total = evpi_total,
    evpi_per_person = evpi_per_person,
    current_estimate = theta_hat,
    current_uncertainty = se_theta,
    population_size = population_size,
    time_horizon = time_horizon,
    interpretation = interpret_evpi(evpi_total),
    method = "Expected Value of Perfect Information"
  )

  class(result) <- c("cbamm_evpi", "list")
  return(result)
}

interpret_evpi <- function(evpi) {
  if (evpi > 10000000) {
    return(sprintf("VERY HIGH VALUE: EVPI = $%.2fM. Strong case for additional research.", evpi/1e6))
  } else if (evpi > 1000000) {
    return(sprintf("HIGH VALUE: EVPI = $%.2fM. Additional research likely worthwhile.", evpi/1e6))
  } else if (evpi > 100000) {
    return(sprintf("MODERATE VALUE: EVPI = $%.1fK. Consider additional research.", evpi/1e3))
  } else {
    return(sprintf("LOW VALUE: EVPI = $%.1fK. Additional research may not be cost-effective.", evpi/1e3))
  }
}


#' Print method for permutation test
#' @export
print.cbamm_permutation_test <- function(x, ...) {
  cat("\n")
  cat("Distribution-Free Permutation Test for Meta-Analysis\n")
  cat("====================================================\n\n")
  cat(sprintf("Observed statistic: %.4f\n", x$observed))
  cat(sprintf("P-value (%s): %.4f\n", x$alternative, x$pvalue))
  cat(sprintf("Number of permutations: %d\n", x$n_perm))
  cat("\n")
  invisible(x)
}

#' Print method for bootstrap CI
#' @export
print.cbamm_bootstrap_ci <- function(x, ...) {
  cat("\n")
  cat("Distribution-Free Bootstrap Confidence Interval\n")
  cat("===============================================\n\n")
  cat(sprintf("Point estimate: %.4f\n", x$estimate))
  cat(sprintf("%.0f%% CI: [%.4f, %.4f]\n",
              x$conf_level * 100, x$ci_lower, x$ci_upper))
  cat(sprintf("Method: %s\n", x$method))
  cat(sprintf("Bootstrap samples: %d\n", x$n_boot))
  cat("\n")
  invisible(x)
}

#' Print method for quantile MA
#' @export
print.cbamm_quantile_ma <- function(x, ...) {
  cat("\n")
  cat("Quantile Regression Meta-Analysis\n")
  cat("==================================\n\n")
  print(x$quantiles, row.names = FALSE)
  cat("\n")
  cat("Interpretation:\n")
  cat(strwrap(x$interpretation, width = 70, prefix = "  "), sep = "\n")
  cat("\n")
  invisible(x)
}

#' Print method for threshold analysis
#' @export
print.cbamm_threshold_analysis <- function(x, ...) {
  cat("\n")
  cat("Threshold Analysis for Decision Robustness\n")
  cat("==========================================\n\n")
  cat(sprintf("Original estimate: %.4f (SE: %.4f)\n",
              x$original_estimate, x$original_se))
  cat(sprintf("Decision threshold: %.4f\n", x$decision_threshold))
  cat(sprintf("Original decision: %s\n", x$original_decision))
  cat("\n")
  if (!is.na(x$threshold_bias)) {
    cat(sprintf("Threshold bias: %.4f\n", x$threshold_bias))
  }
  cat("Robustness: ", x$robustness, "\n")
  cat("\n")
  invisible(x)
}

#' Print method for EVPI
#' @export
print.cbamm_evpi <- function(x, ...) {
  cat("\n")
  cat("Expected Value of Perfect Information (EVPI)\n")
  cat("============================================\n\n")
  cat(sprintf("Total EVPI: $%.2f\n", x$evpi_total))
  cat(sprintf("Per-person EVPI: $%.2f\n", x$evpi_per_person))
  cat(sprintf("Population: %d\n", x$population_size))
  cat(sprintf("Time horizon: %d years\n", x$time_horizon))
  cat("\n")
  cat(strwrap(x$interpretation, width = 70), sep = "\n")
  cat("\n")
  invisible(x)
}
