# Advanced Clinical Decision-Making Functions for CBAMMR
# Implements net benefit, fragility index, MID/MCID, NNT with baseline risk

# Internal helper functions for cbamm_fragility_index() -----------------

#' Validate inputs for fragility index
#' @keywords internal
.fragility_validate_inputs <- function(results, data, alpha) {
  validate_meta_data(data, required_cols = NULL)

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("metafor package required")
  }

  # Get current meta-analysis result
  if (!is.null(results$pooled$transport)) {
    current_fit <- results$pooled$transport
  } else {
    stop("No pooled results available")
  }

  current_fit
}

#' Check significance status and direction applicability
#' @keywords internal
.fragility_check_significance <- function(current_fit, alpha, direction) {
  current_p <- current_fit$pval
  currently_sig <- current_p < alpha

  if (direction == "loss" && !currently_sig) {
    return(list(
      skip = TRUE,
      result = list(
        fragility_index = NA,
        interpretation = "Result not statistically significant; fragility index not applicable for 'loss' direction"
      )
    ))
  }

  list(skip = FALSE, current_p = current_p, currently_sig = currently_sig)
}

#' Check for binary data availability
#' @keywords internal
.fragility_check_binary_data <- function(data) {
  if (!all(c("ai", "bi", "ci", "di") %in% names(data))) {
    return(list(
      skip = TRUE,
      result = list(
        fragility_index = NA,
        interpretation = "Fragility index requires binary outcome data (ai, bi, ci, di)"
      )
    ))
  }
  list(skip = FALSE)
}

#' Iteratively modify events until significance changes
#' @keywords internal
.fragility_iterate_modifications <- function(data, current_fit, alpha, direction, max_iterations = 1000) {
  fragility <- 0

  for (i in 1:max_iterations) {
    # Modify data by converting non-events to events in treatment group
    data_modified <- data
    idx <- which.max(data_modified$bi)

    if (data_modified$bi[idx] == 0) break  # Can't modify further

    data_modified$ai[idx] <- data_modified$ai[idx] + 1
    data_modified$bi[idx] <- data_modified$bi[idx] - 1

    # Re-run meta-analysis
    fit_modified <- try({
      metafor::rma(measure = current_fit$measure,
                   ai = data_modified$ai,
                   bi = data_modified$bi,
                   ci = data_modified$ci,
                   di = data_modified$di,
                   method = current_fit$method,
                   test = current_fit$test)
    }, silent = TRUE)

    if (inherits(fit_modified, "try-error")) break

    # Check if significance changed
    new_p <- fit_modified$pval
    new_sig <- new_p < alpha

    if (direction == "loss") {
      if (!new_sig) {
        fragility <- i
        break
      }
    } else {  # direction == "gain"
      if (new_sig) {
        fragility <- i
        break
      }
    }
  }

  fragility
}

#' Interpret fragility index
#' @keywords internal
.fragility_interpret_index <- function(fragility) {
  if (fragility == 0) {
    "Could not calculate fragility index"
  } else if (fragility <= 5) {
    sprintf("FRAGILE: FI = %d. Result is fragile and susceptible to small changes", fragility)
  } else if (fragility <= 10) {
    sprintf("MODERATE: FI = %d. Result has moderate robustness", fragility)
  } else if (fragility >= 22) {
    sprintf("ROBUST: FI = %d. Result is robust and precise", fragility)
  } else {
    sprintf("ACCEPTABLE: FI = %d. Result has acceptable robustness", fragility)
  }
}

#' Build fragility index result
#' @keywords internal
.fragility_build_result <- function(fragility, current_p, alpha, data) {
  interpretation <- .fragility_interpret_index(fragility)

  recommendation <- if (fragility <= 5) {
    "Consider these results with caution. Small changes in data could alter conclusions."
  } else if (fragility >= 22) {
    "Results are statistically robust. Unlikely to be altered by small data changes."
  } else {
    "Results have moderate robustness. Sensitivity analyses recommended."
  }

  list(
    fragility_index = fragility,
    current_p_value = current_p,
    alpha = alpha,
    n_studies = nrow(data),
    total_events = sum(data$ai + data$ci),
    interpretation = interpretation,
    recommendation = recommendation
  )
}

#' Calculate Fragility Index for Meta-Analysis
#'
#' The fragility index quantifies the minimum number of event status changes
#' needed to alter the statistical significance of a meta-analysis result.
#' Lower values indicate more fragile (less robust) findings.
#'
#' @param results Results object from run_cbamm_analysis() with binary outcomes
#' @param data Analysis data with event counts (ai, bi, ci, di)
#' @param alpha Significance level (default 0.05)
#' @param direction Character; "loss" (default) for losing significance or "gain" for gaining it
#'
#' @return List with fragility index and interpretation
#' @export
#'
#' @examples
#' \dontrun{
#' results <- run_cbamm_analysis(data, config = setup_cbamm(effect_measure = "OR"))
#' fragility <- cbamm_fragility_index(results, data)
#' print(fragility$interpretation)
#' }
cbamm_fragility_index <- function(results, data, alpha = 0.05, direction = "loss") {

  # Validate inputs
  current_fit <- .fragility_validate_inputs(results, data, alpha)

  # Check significance status
  sig_check <- .fragility_check_significance(current_fit, alpha, direction)
  if (sig_check$skip) return(sig_check$result)

  # Check for binary data
  binary_check <- .fragility_check_binary_data(data)
  if (binary_check$skip) return(binary_check$result)

  # Iteratively modify events until significance changes
  fragility <- .fragility_iterate_modifications(data, current_fit, alpha, direction)

  # Build and return result
  .fragility_build_result(fragility, sig_check$current_p, alpha, data)
}


#' Calculate Number Needed to Treat Stratified by Baseline Risk
#'
#' Calculates NNT across different baseline risk levels, showing how
#' absolute benefit varies by patient risk profile even when relative
#' effect is constant.
#'
#' @param results Results object with pooled effect estimate
#' @param baseline_risks Numeric vector of baseline risk probabilities (e.g., c(0.05, 0.10, 0.20, 0.40))
#' @param measure Effect measure ("OR", "RR", or "RD")
#' @param ci_level Confidence level (default 0.95)
#'
#' @return Data frame with NNT for each baseline risk level
#' @export
cbamm_nnt_by_baseline_risk <- function(results,
                                       baseline_risks = c(0.01, 0.05, 0.10, 0.20, 0.30, 0.40),
                                       measure = NULL,
                                       ci_level = 0.95) {

  # Input validation
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("dplyr required")
  }

  # Validate baseline_risks
  if (!is.numeric(baseline_risks) || any(!is.finite(baseline_risks))) {
    stop("baseline_risks must be a numeric vector of finite values")
  }
  if (any(baseline_risks <= 0) || any(baseline_risks >= 1)) {
    stop("All baseline_risks must be between 0 and 1 (exclusive)")
  }

  # Extract effect estimate
  if (!is.null(results$pooled$transport)) {
    fit <- results$pooled$transport
    if (is.null(measure)) measure <- fit$measure
  } else {
    stop("No pooled results available")
  }

  # Get effect estimate and CI
  mm <- .cbamm_measure_meta(measure)
  pred <- metafor::predict(fit, transf = mm$transf)

  effect_est <- pred$pred
  effect_lb <- pred$ci.lb
  effect_ub <- pred$ci.ub

  # Calculate NNT for each baseline risk
  nnt_data <- lapply(baseline_risks, function(baseline_risk) {

    if (measure == "RD") {
      # For risk difference, NNT = 1 / RD
      ard <- effect_est
      ard_lb <- effect_lb
      ard_ub <- effect_ub

    } else if (measure %in% c("RR", "HR")) {
      # For risk ratio: ARD = baseline_risk * (1 - RR)
      ard <- baseline_risk * (1 - effect_est)
      ard_lb <- baseline_risk * (1 - effect_ub)
      ard_ub <- baseline_risk * (1 - effect_lb)

    } else if (measure == "OR") {
      # Convert OR to risk difference
      # Risk in control = baseline_risk
      # Odds in control = baseline_risk / (1 - baseline_risk)
      # Odds in treatment = OR * odds_control
      # Risk in treatment = odds_treatment / (1 + odds_treatment)

      odds_control <- baseline_risk / (1 - baseline_risk)

      odds_treatment <- effect_est * odds_control
      risk_treatment <- odds_treatment / (1 + odds_treatment)
      ard <- baseline_risk - risk_treatment

      # CI bounds
      odds_treatment_lb <- effect_lb * odds_control
      risk_treatment_lb <- odds_treatment_lb / (1 + odds_treatment_lb)
      ard_lb <- baseline_risk - risk_treatment_lb

      odds_treatment_ub <- effect_ub * odds_control
      risk_treatment_ub <- odds_treatment_ub / (1 + odds_treatment_ub)
      ard_ub <- baseline_risk - risk_treatment_ub

    } else {
      stop("Measure must be OR, RR, HR, or RD")
    }

    # Calculate NNT with overflow protection
    # Define maximum NNT to prevent unrealistic values
    MAX_NNT <- 100000

    # Calculate NNT (handle near-zero ARD and cap extreme values)
    if (abs(ard) < 0.0001) {
      nnt <- NA_real_
    } else {
      nnt <- 1 / abs(ard)
      nnt <- if (is.finite(nnt)) min(nnt, MAX_NNT) else NA_real_
    }

    if (abs(ard_ub) < 0.0001) {
      nnt_lb <- NA_real_
    } else {
      nnt_lb <- 1 / abs(ard_ub)
      nnt_lb <- if (is.finite(nnt_lb)) min(nnt_lb, MAX_NNT) else NA_real_
    }

    if (abs(ard_lb) < 0.0001) {
      nnt_ub <- NA_real_
    } else {
      nnt_ub <- 1 / abs(ard_lb)
      nnt_ub <- if (is.finite(nnt_ub)) min(nnt_ub, MAX_NNT) else NA_real_
    }

    # Determine benefit vs harm
    direction <- if (ard > 0) "NNTB" else if (ard < 0) "NNTH" else "No effect"

    tibble::tibble(
      baseline_risk = baseline_risk,
      baseline_risk_pct = baseline_risk * 100,
      absolute_risk_reduction = ard,
      ard_pct = ard * 100,
      nnt = nnt,
      nnt_lower = nnt_lb,
      nnt_upper = nnt_ub,
      direction = direction
    )
  })

  result <- dplyr::bind_rows(nnt_data)

  message("\n=== Number Needed to Treat by Baseline Risk ===")
  message(sprintf("Effect measure: %s = %.3f (95%% CI: %.3f - %.3f)",
                  measure, effect_est, effect_lb, effect_ub))
  message("\nNNT stratified by patient baseline risk:")
  print(result, n = Inf)

  invisible(result)
}


#' Assess Clinical Significance Using Minimal Important Difference
#'
#' Evaluates whether the meta-analytic effect exceeds the minimal important
#' difference (MID) or minimal clinically important difference (MCID) threshold,
#' providing clinical interpretation beyond statistical significance.
#'
#' @param results Results object from run_cbamm_analysis()
#' @param mid Minimal important difference threshold on the effect scale
#' @param measure Effect measure (for interpretation)
#' @param mid_source Character; source of MID (e.g., "anchor-based", "distribution-based", "expert consensus")
#'
#' @return List with clinical significance assessment
#' @export
cbamm_clinical_significance <- function(results, mid, measure = NULL,
                                        mid_source = "user-specified") {

  if (!is.null(results$pooled$transport)) {
    fit <- results$pooled$transport
    if (is.null(measure)) measure <- fit$measure
  } else {
    stop("No pooled results available")
  }

  # Get effect estimate and CI
  mm <- .cbamm_measure_meta(measure)
  pred <- metafor::predict(fit, transf = mm$transf)

  effect_est <- pred$pred
  effect_lb <- pred$ci.lb
  effect_ub <- pred$ci.ub
  p_value <- fit$pval

  # For ratio measures, MID is typically on the original scale
  # For difference measures, it's a direct threshold

  # Check if effect exceeds MID
  if (mm$is_ratio) {
    # For beneficial effects, we want effect < 1 by at least MID
    # For harmful effects, we want effect > 1 by at least MID
    # Assume MID is expressed as "distance from 1"
    # e.g., MID = 0.10 means OR must be < 0.90 or > 1.10

    exceeds_mid_lower <- effect_est < (1 - mid)
    exceeds_mid_upper <- effect_est > (1 + mid)
    exceeds_mid <- exceeds_mid_lower || exceeds_mid_upper

    ci_fully_exceeds <- (effect_ub < (1 - mid)) || (effect_lb > (1 + mid))

  } else {
    # For difference measures, check absolute difference
    exceeds_mid <- abs(effect_est) > mid
    ci_fully_exceeds <- effect_lb > mid || effect_ub < -mid
  }

  # Prediction interval check
  if (!is.null(fit$pi.lb) && !is.null(fit$pi.ub)) {
    if (mm$is_ratio) {
      pi_fully_exceeds <- (fit$pi.ub < (1 - mid)) || (fit$pi.lb > (1 + mid))
    } else {
      pi_fully_exceeds <- fit$pi.lb > mid || fit$pi.ub < -mid
    }
  } else {
    pi_fully_exceeds <- NA
  }

  # Classification
  classification <- if (!exceeds_mid) {
    "Not clinically significant"
  } else if (ci_fully_exceeds) {
    "Clinically significant (robust)"
  } else if (exceeds_mid && p_value < 0.05) {
    "Clinically significant (point estimate only)"
  } else {
    "Uncertain clinical significance"
  }

  interpretation <- if (!exceeds_mid) {
    sprintf("Effect (%.3f) does not exceed MID threshold (%.3f)", effect_est, mid)
  } else if (ci_fully_exceeds) {
    "Effect and entire confidence interval exceed MID threshold. Robust clinical significance."
  } else if (!ci_fully_exceeds && !is.na(pi_fully_exceeds) && !pi_fully_exceeds) {
    "Point estimate exceeds MID, but CI/PI include clinically trivial effects. Heterogeneity limits certainty of clinical benefit."
  } else {
    "Point estimate exceeds MID. Clinical significance supported but confidence interval crosses threshold."
  }

  list(
    effect_estimate = effect_est,
    ci_lower = effect_lb,
    ci_upper = effect_ub,
    mid_threshold = mid,
    mid_source = mid_source,
    exceeds_mid = exceeds_mid,
    ci_fully_exceeds = ci_fully_exceeds,
    pi_fully_exceeds = pi_fully_exceeds,
    classification = classification,
    interpretation = interpretation,
    p_value = p_value,
    statistically_significant = p_value < 0.05
  )
}


#' Prediction Interval Interpretation with Clinical Thresholds
#'
#' Interprets prediction intervals in the context of clinical benefit/harm
#' thresholds, calculating the probability that a future study would show
#' clinically meaningful effects.
#'
#' @param results Results object from run_cbamm_analysis()
#' @param benefit_threshold Threshold for clinical benefit (on effect scale)
#' @param harm_threshold Threshold for harm (on effect scale)
#' @param measure Effect measure
#'
#' @return List with threshold-based PI interpretation
#' @export
cbamm_prediction_interval_threshold <- function(results,
                                                benefit_threshold = NULL,
                                                harm_threshold = NULL,
                                                measure = NULL) {

  if (!is.null(results$pooled$transport)) {
    fit <- results$pooled$transport
    if (is.null(measure)) measure <- fit$measure
  } else {
    stop("No pooled results available")
  }

  if (is.null(fit$pi.lb) || is.null(fit$pi.ub)) {
    stop("Prediction interval not available in results")
  }

  mm <- .cbamm_measure_meta(measure)
  pred <- metafor::predict(fit, transf = mm$transf)

  # Default thresholds if not provided
  if (mm$is_ratio) {
    if (is.null(benefit_threshold)) benefit_threshold <- 0.80  # 20% reduction
    if (is.null(harm_threshold)) harm_threshold <- 1.20  # 20% increase
    null_value <- 1.0
  } else {
    if (is.null(benefit_threshold)) benefit_threshold <- 0.10
    if (is.null(harm_threshold)) harm_threshold <- -0.10
    null_value <- 0.0
  }

  # Check PI position relative to thresholds
  pi_lb <- pred$pi.lb
  pi_ub <- pred$pi.ub

  if (mm$is_ratio) {
    # For ratio measures (HR, RR, OR where <1 is benefit)
    fully_beneficial <- pi_ub < benefit_threshold
    fully_harmful <- pi_lb > harm_threshold
    includes_null <- pi_lb < null_value && pi_ub > null_value
    includes_benefit <- pi_lb < benefit_threshold
    includes_harm <- pi_ub > harm_threshold

  } else {
    # For difference measures (MD, SMD, RD where >0 is benefit)
    fully_beneficial <- pi_lb > benefit_threshold
    fully_harmful <- pi_ub < harm_threshold
    includes_null <- pi_lb < null_value && pi_ub > null_value
    includes_benefit <- pi_ub > benefit_threshold
    includes_harm <- pi_lb < harm_threshold
  }

  # Interpretation
  if (fully_beneficial) {
    interpretation <- "High confidence: Prediction interval entirely in beneficial range. Future studies highly likely to show benefit."
    strength <- "Strong"
  } else if (fully_harmful) {
    interpretation <- "High confidence: Prediction interval entirely in harmful range. Future studies highly likely to show harm."
    strength <- "Strong (harmful)"
  } else if (includes_null && includes_benefit && includes_harm) {
    interpretation <- "Low confidence: Prediction interval spans null value and both benefit/harm thresholds. Future studies could show opposite effects."
    strength <- "Very weak"
  } else if (includes_null && includes_benefit) {
    interpretation <- "Moderate confidence: Prediction interval includes null but also clinically meaningful benefit. Future studies may show benefit or no effect."
    strength <- "Moderate"
  } else if (includes_null && includes_harm) {
    interpretation <- "Moderate confidence: Prediction interval includes null but also clinically meaningful harm. Future studies may show harm or no effect."
    strength <- "Moderate"
  } else {
    interpretation <- "Variable confidence: Prediction interval suggests heterogeneous effects across settings."
    strength <- "Weak"
  }

  # Approximate probability calculations (assuming normality)
  tau <- sqrt(fit$tau2)
  if (tau > 0) {
    # P(future effect > benefit threshold)
    if (mm$is_ratio) {
      prob_benefit <- stats::pnorm(log(benefit_threshold), mean = fit$beta[1], sd = tau, lower.tail = TRUE)
      prob_harm <- stats::pnorm(log(harm_threshold), mean = fit$beta[1], sd = tau, lower.tail = FALSE)
    } else {
      prob_benefit <- stats::pnorm(benefit_threshold, mean = fit$beta[1], sd = tau, lower.tail = FALSE)
      prob_harm <- stats::pnorm(harm_threshold, mean = fit$beta[1], sd = tau, lower.tail = TRUE)
    }
  } else {
    prob_benefit <- if (pred$pred > benefit_threshold || pred$pred < benefit_threshold) 1 else 0
    prob_harm <- 0
  }

  message("\n=== Prediction Interval Clinical Threshold Analysis ===")
  message(sprintf("95%% Prediction Interval: [%.3f, %.3f]", pi_lb, pi_ub))
  message(sprintf("Benefit threshold: %.3f", benefit_threshold))
  message(sprintf("Harm threshold: %.3f", harm_threshold))
  message(sprintf("\nProbability future study shows benefit: %.1f%%", prob_benefit * 100))
  message(sprintf("Probability future study shows harm: %.1f%%", prob_harm * 100))
  message(sprintf("\nInterpretation: %s", interpretation))

  list(
    pi_lower = pi_lb,
    pi_upper = pi_ub,
    benefit_threshold = benefit_threshold,
    harm_threshold = harm_threshold,
    fully_beneficial = fully_beneficial,
    fully_harmful = fully_harmful,
    includes_null = includes_null,
    prob_benefit = prob_benefit,
    prob_harm = prob_harm,
    interpretation = interpretation,
    strength = strength,
    tau2 = fit$tau2
  )
}


#' Enhanced Net Clinical Benefit Analysis
#'
#' Calculates net benefit across a range of threshold probabilities,
#' helping determine whether using the intervention would lead to better
#' clinical decisions compared to treating all or no patients.
#'
#' @param results Results object with binary outcomes
#' @param data Analysis data
#' @param baseline_risk Baseline event probability in control group
#' @param threshold_probs Vector of threshold probabilities to evaluate
#' @param preferences Optional weights for harms vs benefits (default 1)
#'
#' @return Data frame with net benefit across thresholds, and decision curve plot
#' @export
cbamm_net_clinical_benefit <- function(results, data,
                                       baseline_risk = NULL,
                                       threshold_probs = seq(0, 1, by = 0.01),
                                       preferences = 1) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 required")
  }

  # Extract effect estimate (assume OR or RR for binary outcome)
  if (!is.null(results$pooled$transport)) {
    fit <- results$pooled$transport
    measure <- fit$measure
  } else {
    stop("No pooled results available")
  }

  # Estimate baseline risk if not provided
  if (is.null(baseline_risk)) {
    if (all(c("ai", "bi", "ci", "di") %in% names(data))) {
      baseline_risk <- sum(data$ci) / sum(data$ci + data$di)
      message(sprintf("Using estimated baseline risk: %.3f", baseline_risk))
    } else {
      stop("baseline_risk must be provided or data must have ai, bi, ci, di columns")
    }
  }

  # Transform effect to RR scale if needed
  mm <- .cbamm_measure_meta(measure)
  pred <- metafor::predict(fit, transf = mm$transf)
  effect_est <- pred$pred

  if (measure == "OR") {
    # Approximate RR from OR: RR ≈ OR / (1 - baseline_risk + baseline_risk * OR)
    rr <- effect_est / (1 - baseline_risk + baseline_risk * effect_est)
  } else if (measure %in% c("RR", "HR")) {
    rr <- effect_est
  } else {
    stop("Net benefit analysis requires OR, RR, or HR measure")
  }

  # Calculate risk with treatment
  risk_treatment <- baseline_risk * rr

  # Calculate net benefit across threshold probabilities
  nb_data <- lapply(threshold_probs, function(pt) {

    # Net benefit of intervention
    # NB = (TP / n) - (FP / n) * (pt / (1 - pt)) * preferences
    # Simplified for population perspective:
    # NB_intervention = benefit_rate - harm_rate * odds(pt)

    # For meta-analysis, we use population-level probabilities
    # NB_treat_all = baseline_risk - (1 - baseline_risk) * (pt / (1 - pt))
    # NB_treat_with_model = risk_treatment - (1 - risk_treatment) * (pt / (1 - pt))

    nb_treat_all <- baseline_risk - (1 - baseline_risk) * (pt / (1 - pt + 1e-10))
    nb_treat_none <- 0
    nb_intervention <- risk_treatment - (1 - risk_treatment) * (pt / (1 - pt + 1e-10)) * preferences

    tibble::tibble(
      threshold_prob = pt,
      nb_treat_all = nb_treat_all,
      nb_treat_none = nb_treat_none,
      nb_intervention = nb_intervention,
      best_strategy = if (nb_intervention > max(nb_treat_all, nb_treat_none)) {
        "Intervention"
      } else if (nb_treat_all > nb_treat_none) {
        "Treat all"
      } else {
        "Treat none"
      }
    )
  })

  nb_df <- dplyr::bind_rows(nb_data)

  # Create decision curve
  p <- ggplot2::ggplot(nb_df, ggplot2::aes(x = threshold_prob)) +
    ggplot2::geom_line(ggplot2::aes(y = nb_treat_all, color = "Treat all"), linewidth = 1) +
    ggplot2::geom_line(ggplot2::aes(y = nb_treat_none, color = "Treat none"), linewidth = 1) +
    ggplot2::geom_line(ggplot2::aes(y = nb_intervention, color = "Intervention"), linewidth = 1.2) +
    ggplot2::labs(
      title = "Decision Curve Analysis: Net Clinical Benefit",
      subtitle = sprintf("Baseline risk = %.3f, Relative effect = %.3f", baseline_risk, rr),
      x = "Threshold Probability",
      y = "Net Benefit",
      color = "Strategy"
    ) +
    ggplot2::scale_color_manual(values = c("Treat all" = "gray60",
                                           "Treat none" = "gray30",
                                           "Intervention" = "#E31A1C")) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = ggplot2::element_text(face = "bold")
    )

  # Summary
  optimal_range <- nb_df %>%
    dplyr::filter(best_strategy == "Intervention") %>%
    dplyr::summarise(
      min_threshold = min(threshold_prob),
      max_threshold = max(threshold_prob)
    )

  message("\n=== Net Clinical Benefit Analysis ===")
  if (nrow(optimal_range) > 0 && optimal_range$min_threshold != optimal_range$max_threshold) {
    message(sprintf("Intervention provides net benefit for threshold probabilities: %.3f - %.3f",
                    optimal_range$min_threshold, optimal_range$max_threshold))
  } else {
    message("Intervention does not provide net benefit across the evaluated range.")
  }

  list(
    net_benefit_data = nb_df,
    decision_curve = p,
    baseline_risk = baseline_risk,
    relative_effect = rr,
    optimal_threshold_range = optimal_range
  )
}
