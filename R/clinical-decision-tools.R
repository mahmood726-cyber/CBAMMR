#' Clinical Decision-Making Tools from Meta-Analysis
#'
#' Advanced tools for translating meta-analysis results into clinical decisions,
#' including individualized treatment effects, decision curves, and value-based
#' recommendations.
#'
#' @name clinical_decision_tools
NULL

#' Individualized Treatment Effect Estimation
#'
#' Estimate treatment effects for individual patients based on their
#' characteristics, accounting for heterogeneity in treatment response.
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param moderators Matrix of moderator variables
#' @param patient_profile Vector of patient characteristics
#'
#' @return List with individualized treatment effect estimate and uncertainty
#'
#' @details
#' Uses meta-regression to model how treatment effects vary with patient
#' characteristics. Predicts the expected treatment effect for a specific
#' patient profile, enabling personalized treatment recommendations.
#'
#' Essential for precision medicine and shared decision-making.
#'
#' @references
#' Kent et al. (2024). Using Individualized Treatment Effects to Assess
#' Treatment Effect Heterogeneity. arXiv:2502.00713
#'
#' @examples
#' \dontrun{
#' # Individualized treatment effect
#' moderators <- cbind(age = c(50, 60, 55, 65),
#'                     baseline_risk = c(0.2, 0.3, 0.25, 0.35))
#' patient <- c(age = 62, baseline_risk = 0.28)
#'
#' result <- cbamm_individualized_effect(
#'   yi = c(0.3, 0.5, 0.4, 0.6),
#'   vi = c(0.1, 0.12, 0.09, 0.11),
#'   moderators = moderators,
#'   patient_profile = patient
#' )
#' print(result$predicted_effect)  # Effect for this specific patient
#' }
#'
#' @export
cbamm_individualized_effect <- function(yi, vi, moderators, patient_profile) {

  # Validate inputs
  validate_meta_inputs(yi, vi)

  if (!is.matrix(moderators) && !is.data.frame(moderators)) {
    stop("'moderators' must be a matrix or data frame")
  }

  # Fit meta-regression with moderators
  fit <- metafor::rma(yi, vi, mods = moderators, method = "REML")

  # Predict for patient profile
  # Add intercept
  X_new <- c(1, patient_profile)

  # Predicted effect
  pred_effect <- sum(fit$beta * X_new)

  # Prediction variance
  pred_var <- sum(X_new %*% fit$vb %*% X_new) + fit$tau2
  pred_se <- sqrt(pred_var)

  # Prediction interval
  pred_ci <- pred_effect + c(-1, 1) * qnorm(0.975) * pred_se

  # Interpretation
  interpretation <- interpret_individualized_effect(pred_effect, pred_se)

  result <- list(
    predicted_effect = pred_effect,
    se = pred_se,
    ci_lower = pred_ci[1],
    ci_upper = pred_ci[2],
    patient_profile = patient_profile,
    moderator_effects = fit$beta,
    interpretation = interpretation,
    method = "Individualized Treatment Effect Estimation"
  )

  class(result) <- c("cbamm_individualized_effect", "list")
  return(result)
}

interpret_individualized_effect <- function(effect, se) {
  ci_lower <- effect - 1.96 * se
  ci_upper <- effect + 1.96 * se

  if (ci_lower > 0) {
    return("Strong evidence of benefit for this patient profile.")
  } else if (ci_upper < 0) {
    return("Strong evidence of harm for this patient profile.")
  } else if (effect > 0) {
    return("Potential benefit, but with uncertainty. Consider patient preferences.")
  } else {
    return("Potential harm, but with uncertainty. Likely not recommended.")
  }
}


#' Decision Curve Analysis for Meta-Analysis
#'
#' Evaluate the clinical utility of using meta-analysis results to guide
#' treatment decisions across a range of decision thresholds.
#'
#' @param yi Effect sizes
#' @param vi Sampling variances
#' @param threshold_range Range of decision thresholds to explore
#' @param harm_benefit_ratio Ratio of harm to benefit (default 1)
#'
#' @return List with net benefit across thresholds
#'
#' @details
#' Decision curve analysis quantifies the net benefit of using meta-analysis
#' results to make treatment decisions, compared to treating all or no patients.
#' Identifies the threshold probability at which using the evidence provides
#' the most clinical benefit.
#'
#' @references
#' Vickers & Elkin (2006). Decision curve analysis: a novel method for
#' evaluating prediction models. Medical Decision Making, 26(6), 565-574.
#'
#' @examples
#' \dontrun{
#' # Decision curve analysis
#' result <- cbamm_decision_curve(
#'   yi = c(0.3, 0.5, 0.4),
#'   vi = c(0.1, 0.12, 0.09),
#'   threshold_range = seq(0.1, 0.9, by = 0.05)
#' )
#' plot(result)  # Shows optimal decision threshold
#' }
#'
#' @export
cbamm_decision_curve <- function(yi, vi, threshold_range = seq(0.1, 0.9, by = 0.05),
                                 harm_benefit_ratio = 1) {

  # Pooled estimate
  weights <- 1 / vi
  theta_hat <- sum(weights * yi) / sum(weights)
  se_theta <- sqrt(1 / sum(weights))

  # Net benefit calculations
  n_thresholds <- length(threshold_range)
  net_benefit_model <- numeric(n_thresholds)
  net_benefit_all <- numeric(n_thresholds)
  net_benefit_none <- numeric(n_thresholds)

  for (i in seq_along(threshold_range)) {
    pt <- threshold_range[i]

    # Probability of benefit > threshold
    prob_benefit <- 1 - pnorm(pt, mean = theta_hat, sd = se_theta)

    # Net benefit of using model
    net_benefit_model[i] <- prob_benefit - (1 - prob_benefit) * (pt / (1 - pt)) * harm_benefit_ratio

    # Net benefit of treating all
    net_benefit_all[i] <- 1 - (pt / (1 - pt)) * harm_benefit_ratio

    # Net benefit of treating none
    net_benefit_none[i] <- 0
  }

  # Find optimal threshold
  optimal_idx <- which.max(net_benefit_model)
  optimal_threshold <- threshold_range[optimal_idx]

  result <- list(
    threshold_range = threshold_range,
    net_benefit_model = net_benefit_model,
    net_benefit_all = net_benefit_all,
    net_benefit_none = net_benefit_none,
    optimal_threshold = optimal_threshold,
    interpretation = interpret_decision_curve(optimal_threshold),
    method = "Decision Curve Analysis"
  )

  class(result) <- c("cbamm_decision_curve", "list")
  return(result)
}

interpret_decision_curve <- function(optimal_threshold) {
  sprintf("Using meta-analysis results provides maximum net benefit at a decision threshold of %.2f.
Treatment should be considered for patients with probability of benefit exceeding this threshold.",
          optimal_threshold)
}


#' Restricted Mean Survival Time (RMST) Meta-Analysis
#'
#' Distribution-free meta-analysis for time-to-event data using RMST.
#' Does not require proportional hazards assumption.
#'
#' @param rmst1 RMST in treatment group
#' @param rmst0 RMST in control group
#' @param se1 Standard error of RMST in treatment
#' @param se0 Standard error of RMST in control
#' @param time_horizon Restricted time horizon
#'
#' @return List with pooled RMST difference and interpretation
#'
#' @details
#' RMST represents the average time patients survive (or are event-free) up to
#' a specified time horizon. Does not assume constant hazard ratios over time,
#' making it more robust than HR-based meta-analysis.
#'
#' Clinically interpretable: difference in average survival time.
#'
#' @references
#' Androulakis et al. (2025). Meta-Analysis of Time-to-Event Data Using
#' Non-Parametric Measures. Statistics in Biosciences.
#'
#' @examples
#' \dontrun{
#' # RMST meta-analysis (distribution-free for survival)
#' result <- cbamm_rmst_meta(
#'   rmst1 = c(24.5, 26.3, 25.1),  # months in treatment
#'   rmst0 = c(20.1, 21.5, 19.8),  # months in control
#'   se1 = c(1.2, 1.5, 1.3),
#'   se0 = c(1.1, 1.4, 1.2),
#'   time_horizon = 36  # 36-month horizon
#' )
#' print(result$rmst_difference)  # Extra months of survival
#' }
#'
#' @export
cbamm_rmst_meta <- function(rmst1, rmst0, se1, se0, time_horizon) {

  # Input validation
  if (!is.numeric(rmst1) || !is.numeric(rmst0) || !is.numeric(se1) || !is.numeric(se0)) {
    stop("rmst1, rmst0, se1, and se0 must be numeric vectors")
  }
  if (any(rmst1 <= 0, na.rm = TRUE) || any(rmst0 <= 0, na.rm = TRUE)) {
    stop("RMST values (rmst1, rmst0) must be positive")
  }
  if (any(se1 <= 0, na.rm = TRUE) || any(se0 <= 0, na.rm = TRUE)) {
    stop("Standard errors (se1, se0) must be positive")
  }
  if (!is.numeric(time_horizon) || length(time_horizon) != 1 || time_horizon <= 0) {
    stop("time_horizon must be a positive numeric value")
  }
  validate_sample_size(length(rmst1), "meta-analysis", warning_only = TRUE)

  # Check package availability
  check_package_available("metafor", "cbamm_rmst_meta")

  # RMST differences
  rmst_diff <- rmst1 - rmst0

  # Variance of differences
  var_diff <- se1^2 + se0^2

  # Meta-analysis of RMST differences
  fit <- metafor::rma(yi = rmst_diff, vi = var_diff, method = "REML")

  # Results
  pooled_diff <- fit$beta[1]
  se_diff <- fit$se
  ci_lower <- fit$ci.lb
  ci_upper <- fit$ci.ub

  # Interpretation
  interpretation <- interpret_rmst(pooled_diff, time_horizon)

  result <- list(
    rmst_difference = as.numeric(pooled_diff),
    se = as.numeric(se_diff),
    ci_lower = as.numeric(ci_lower),
    ci_upper = as.numeric(ci_upper),
    pvalue = fit$pval,
    time_horizon = time_horizon,
    I2 = fit$I2,
    tau2 = fit$tau2,
    interpretation = interpretation,
    method = "Restricted Mean Survival Time Meta-Analysis"
  )

  class(result) <- c("cbamm_rmst_meta", "list")
  return(result)
}

interpret_rmst <- function(diff, horizon) {
  if (diff > 0) {
    sprintf("Treatment extends average survival by %.1f time units within the %d-unit horizon.
This is a clinically meaningful benefit that does not assume constant hazard ratios.",
            abs(diff), horizon)
  } else {
    sprintf("Treatment reduces average survival by %.1f time units within the %d-unit horizon.
This suggests potential harm.", abs(diff), horizon)
  }
}


#' Probability of Being Best Treatment
#'
#' Calculate the probability that a treatment is the best option based on
#' meta-analysis results. Useful for treatment ranking and selection.
#'
#' @param yi Effect sizes for multiple treatments
#' @param vi Sampling variances
#' @param treatment_names Names of treatments
#' @param n_sim Number of simulations (default 10000)
#'
#' @return Data frame with probabilities of being best for each treatment
#'
#' @details
#' Simulates from the posterior distribution of treatment effects and calculates
#' how often each treatment has the highest effect. Provides probabilistic
#' treatment rankings that account for uncertainty.
#'
#' More informative than simple ranking by point estimates.
#'
#' @examples
#' \dontrun{
#' # Probability of being best treatment
#' result <- cbamm_prob_best(
#'   yi = list(trtA = 0.3, trtB = 0.5, trtC = 0.4),
#'   vi = list(trtA = 0.1, trtB = 0.12, trtC = 0.09),
#'   treatment_names = c("Treatment A", "Treatment B", "Treatment C")
#' )
#' print(result)  # Probability each treatment is best
#' }
#'
#' @export
cbamm_prob_best <- function(yi, vi, treatment_names = NULL, n_sim = 10000) {

  # Input validation
  validate_meta_inputs(yi, vi)
  validate_sample_size(length(yi), "meta-analysis", warning_only = TRUE)

  # Convert to vectors if lists
  if (is.list(yi)) yi <- unlist(yi)
  if (is.list(vi)) vi <- unlist(vi)

  n_treatments <- length(yi)

  if (is.null(treatment_names)) {
    treatment_names <- paste0("Treatment_", seq_len(n_treatments))
  }

  # Simulate from posterior
  sim_effects <- matrix(nrow = n_sim, ncol = n_treatments)

  for (i in seq_len(n_treatments)) {
    sim_effects[, i] <- rnorm(n_sim, mean = yi[i], sd = sqrt(vi[i]))
  }

  # Count how often each treatment is best
  best_idx <- apply(sim_effects, 1, which.max)
  prob_best <- table(factor(best_idx, levels = seq_len(n_treatments))) / n_sim

  # Expected rank
  ranks <- t(apply(sim_effects, 1, rank, ties.method = "average"))
  expected_rank <- n_treatments + 1 - colMeans(ranks)  # Higher effect = better rank

  # Surface Under Cumulative Ranking (SUCRA)
  sucra <- (expected_rank - 1) / (n_treatments - 1)

  results <- data.frame(
    treatment = treatment_names,
    prob_best = as.numeric(prob_best),
    expected_rank = expected_rank,
    sucra = sucra
  )

  results <- results[order(-results$prob_best), ]

  result <- list(
    rankings = results,
    interpretation = interpret_prob_best(results),
    method = "Probability of Being Best Treatment"
  )

  class(result) <- c("cbamm_prob_best", "list")
  return(result)
}

interpret_prob_best <- function(results) {
  best_trt <- results$treatment[1]
  best_prob <- results$prob_best[1]

  if (best_prob > 0.7) {
    sprintf("%s has a %.0f%% probability of being the best treatment - strong evidence of superiority.",
            best_trt, best_prob * 100)
  } else if (best_prob > 0.5) {
    sprintf("%s has a %.0f%% probability of being the best treatment - moderate evidence of superiority.",
            best_trt, best_prob * 100)
  } else {
    sprintf("No treatment clearly superior. %s has highest probability (%.0f%%) but uncertainty is substantial.",
            best_trt, best_prob * 100)
  }
}


#' Number Needed to Treat from Meta-Analysis
#'
#' Calculate NNT with confidence intervals from meta-analysis of odds ratios
#' or risk ratios, accounting for baseline risk.
#'
#' @param yi Log odds ratio or log risk ratio
#' @param vi Sampling variance
#' @param baseline_risk Baseline risk in control group (0-1)
#' @param measure Type of effect measure: "OR" or "RR"
#' @param time_horizon Time horizon for NNT (in original study units)
#'
#' @return List with NNT, confidence intervals, and interpretation
#'
#' @details
#' NNT translates relative treatment effects into absolute terms: the number
#' of patients needed to treat to prevent one additional adverse event.
#' Accounts for baseline risk, making results clinically interpretable.
#'
#' Essential for shared decision-making and patient communication.
#'
#' @examples
#' \dontrun{
#' # NNT from meta-analysis
#' result <- cbamm_nnt_meta(
#'   yi = log(0.7),  # log OR
#'   vi = 0.05,
#'   baseline_risk = 0.20,  # 20% baseline risk
#'   measure = "OR",
#'   time_horizon = 5  # 5-year NNT
#' )
#' print(result$nnt)  # How many to treat to prevent 1 event
#' }
#'
#' @export
cbamm_nnt_meta <- function(yi, vi, baseline_risk, measure = c("OR", "RR"),
                           time_horizon = 1) {

  # Input validation
  validate_meta_inputs(yi, vi)

  if (!is.numeric(baseline_risk) || length(baseline_risk) != 1 || !is.finite(baseline_risk)) {
    stop("baseline_risk must be a single finite numeric value")
  }
  if (baseline_risk <= 0 || baseline_risk >= 1) {
    stop("baseline_risk must be between 0 and 1 (exclusive)")
  }

  measure <- match.arg(measure)

  # Pooled effect (if multiple studies, take weighted mean)
  if (length(yi) > 1) {
    weights <- 1 / vi
    yi_pooled <- sum(weights * yi) / sum(weights)
    vi_pooled <- 1 / sum(weights)
  } else {
    yi_pooled <- yi
    vi_pooled <- vi
  }

  # Back-transform to OR or RR
  if (measure == "OR") {
    or <- exp(yi_pooled)

    # Convert OR to absolute risk reduction
    baseline_odds <- baseline_risk / (1 - baseline_risk)
    treatment_odds <- baseline_odds * or
    treatment_risk <- treatment_odds / (1 + treatment_odds)

    arr <- baseline_risk - treatment_risk  # Absolute risk reduction
  } else {
    rr <- exp(yi_pooled)
    treatment_risk <- baseline_risk * rr
    arr <- baseline_risk - treatment_risk
  }

  # NNT with overflow protection
  MAX_NNT <- 100000  # Cap unrealistic NNT values

  if (abs(arr) < 0.0001) {
    nnt <- NA_real_
    warning("Absolute risk reduction is near zero; NNT is undefined")
  } else {
    nnt <- 1 / abs(arr)
    if (!is.finite(nnt)) {
      nnt <- NA_real_
      warning("NNT calculation resulted in non-finite value")
    } else if (nnt > MAX_NNT) {
      nnt <- MAX_NNT
      warning(sprintf("NNT capped at maximum value of %d (extremely small treatment effect)", MAX_NNT))
    }
  }

  # Confidence interval (delta method)
  se_yi <- sqrt(vi_pooled)

  if (measure == "OR") {
    # Derivative of ARR with respect to log(OR)
    deriv <- -baseline_odds * or / (1 + baseline_odds * or)^2
  } else {
    # Derivative of ARR with respect to log(RR)
    deriv <- -baseline_risk * rr
  }

  se_arr <- abs(deriv) * se_yi

  # CI for ARR
  arr_ci <- arr + c(-1, 1) * qnorm(0.975) * se_arr

  # CI for NNT (reciprocal) with overflow protection
  nnt_ci <- numeric(2)
  for (i in 1:2) {
    if (abs(arr_ci[i]) < 0.0001) {
      nnt_ci[i] <- NA_real_
    } else {
      nnt_ci[i] <- 1 / abs(arr_ci[i])
      if (!is.finite(nnt_ci[i])) {
        nnt_ci[i] <- NA_real_
      } else if (nnt_ci[i] > MAX_NNT) {
        nnt_ci[i] <- MAX_NNT
      }
    }
  }
  nnt_ci <- sort(nnt_ci)  # Ensure lower < upper

  # Interpretation
  interpretation <- interpret_nnt(nnt, arr, time_horizon)

  result <- list(
    nnt = nnt,
    nnt_ci = nnt_ci,
    arr = arr,
    baseline_risk = baseline_risk,
    treatment_risk = treatment_risk,
    measure = measure,
    time_horizon = time_horizon,
    interpretation = interpretation,
    method = "Number Needed to Treat from Meta-Analysis"
  )

  class(result) <- c("cbamm_nnt_meta", "list")
  return(result)
}

interpret_nnt <- function(nnt, arr, time_horizon) {
  if (arr > 0) {
    sprintf("Need to treat %.0f patients for %d time units to prevent one additional adverse event.
Absolute risk reduction: %.1f%%.",
            nnt, time_horizon, arr * 100)
  } else {
    sprintf("Treatment increases risk. Number needed to harm: %.0f patients for %d time units.",
            abs(nnt), time_horizon)
  }
}


#' Print methods for clinical decision tools
#' @export
print.cbamm_individualized_effect <- function(x, ...) {
  cat("\n")
  cat("Individualized Treatment Effect Estimation\n")
  cat("==========================================\n\n")
  cat("Patient Profile:\n")
  print(x$patient_profile)
  cat("\n")
  cat(sprintf("Predicted Effect: %.4f (SE: %.4f)\n", x$predicted_effect, x$se))
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", x$ci_lower, x$ci_upper))
  cat("\n")
  cat(strwrap(x$interpretation, width = 70), sep = "\n")
  cat("\n")
  invisible(x)
}

#' @export
print.cbamm_decision_curve <- function(x, ...) {
  cat("\n")
  cat("Decision Curve Analysis\n")
  cat("=======================\n\n")
  cat(sprintf("Optimal decision threshold: %.2f\n", x$optimal_threshold))
  cat("\n")
  cat(strwrap(x$interpretation, width = 70), sep = "\n")
  cat("\n")
  invisible(x)
}

#' @export
print.cbamm_rmst_meta <- function(x, ...) {
  cat("\n")
  cat("Restricted Mean Survival Time Meta-Analysis\n")
  cat("============================================\n\n")
  cat(sprintf("RMST Difference: %.2f (SE: %.2f)\n", x$rmst_difference, x$se))
  cat(sprintf("95%% CI: [%.2f, %.2f]\n", x$ci_lower, x$ci_upper))
  cat(sprintf("P-value: %.4f\n", x$pvalue))
  cat(sprintf("Time Horizon: %d units\n", x$time_horizon))
  cat(sprintf("I²: %.1f%%\n", x$I2))
  cat("\n")
  cat(strwrap(x$interpretation, width = 70), sep = "\n")
  cat("\n")
  invisible(x)
}

#' @export
print.cbamm_prob_best <- function(x, ...) {
  cat("\n")
  cat("Probability of Being Best Treatment\n")
  cat("====================================\n\n")
  print(x$rankings, row.names = FALSE)
  cat("\n")
  cat(strwrap(x$interpretation, width = 70), sep = "\n")
  cat("\n")
  invisible(x)
}

#' @export
print.cbamm_nnt_meta <- function(x, ...) {
  cat("\n")
  cat("Number Needed to Treat from Meta-Analysis\n")
  cat("==========================================\n\n")
  cat(sprintf("NNT: %.0f (95%% CI: [%.0f, %.0f])\n",
              x$nnt, x$nnt_ci[1], x$nnt_ci[2]))
  cat(sprintf("Baseline Risk: %.1f%%\n", x$baseline_risk * 100))
  cat(sprintf("Treatment Risk: %.1f%%\n", x$treatment_risk * 100))
  cat(sprintf("Absolute Risk Reduction: %.1f%%\n", x$arr * 100))
  cat(sprintf("Time Horizon: %d units\n", x$time_horizon))
  cat("\n")
  cat(strwrap(x$interpretation, width = 70), sep = "\n")
  cat("\n")
  invisible(x)
}
