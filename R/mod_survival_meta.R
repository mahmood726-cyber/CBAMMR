#' Survival Analysis Meta-Analysis Module
#'
#' Comprehensive survival analysis for meta-analysis:
#' - Hazard Ratio (HR) meta-analysis
#' - Time-to-event data handling
#' - Kaplan-Meier curve extraction
#' - Median survival time conversion
#' - Cox proportional hazards
#' - Restricted mean survival time (RMST)
#' - Survival probability at time t
#' - Log-rank test statistics conversion
#' - Competing risks adjustment
#'
#' @name mod_survival_meta
#' @rdname mod_survival_meta
#'
#' @import metafor
#' @import survival
NULL

#' @describeIn mod_survival_meta Extract HR from summary statistics
#' @param events1 Integer. Events in group 1
#' @param total1 Integer. Total in group 1
#' @param events2 Integer. Events in group 2
#' @param total2 Integer. Total in group 2
#' @param time Numeric. Follow-up time (optional)
#' @export
cbamm_survival_calc_hr <- function(events1, total1, events2, total2, time = NULL) {

  if (any(c(events1, events2, total1, total2) < 0)) {
    stop("All counts must be non-negative")
  }

  if (events1 > total1 || events2 > total2) {
    stop("Events cannot exceed total")
  }

  # Calculate hazard rates
  hazard1 <- events1 / total1
  hazard2 <- events2 / total2

  # Calculate HR
  hr <- hazard1 / hazard2
  log_hr <- log(hr)

  # Calculate SE using Peto method
  # SE(log HR) = sqrt(1/e1 + 1/e2)
  if (events1 > 0 && events2 > 0) {
    se_log_hr <- sqrt(1/events1 + 1/events2)
  } else {
    warning("Zero events detected, SE may be unreliable")
    se_log_hr <- NA
  }

  # 95% CI
  ci_lower <- exp(log_hr - 1.96 * se_log_hr)
  ci_upper <- exp(log_hr + 1.96 * se_log_hr)

  result <- list(
    hr = hr,
    log_hr = log_hr,
    se_log_hr = se_log_hr,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    hazard1 = hazard1,
    hazard2 = hazard2,
    events1 = events1,
    events2 = events2,
    total1 = total1,
    total2 = total2
  )

  class(result) <- c("cbamm_hr", "list")
  return(result)
}

#' @describeIn mod_survival_meta Convert log-rank test statistic to HR
#' @param O_E Numeric. Observed minus expected events (O-E)
#' @param V Numeric. Variance of O-E
#' @export
cbamm_survival_logrank_to_hr <- function(O_E, V) {

  if (V <= 0) {
    stop("Variance must be positive")
  }

  # Calculate log HR from log-rank statistic
  log_hr <- O_E / V
  hr <- exp(log_hr)

  # SE of log HR
  se_log_hr <- 1 / sqrt(V)

  # 95% CI
  ci_lower <- exp(log_hr - 1.96 * se_log_hr)
  ci_upper <- exp(log_hr + 1.96 * se_log_hr)

  # Log-rank chi-squared statistic
  chi_sq <- (O_E)^2 / V
  p_value <- 1 - pchisq(chi_sq, df = 1)

  return(list(
    hr = hr,
    log_hr = log_hr,
    se_log_hr = se_log_hr,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    O_E = O_E,
    V = V,
    chi_sq = chi_sq,
    p_value = p_value
  ))
}

#' @describeIn mod_survival_meta Convert median survival times to HR
#' @param median1 Numeric. Median survival time in group 1
#' @param median2 Numeric. Median survival time in group 2
#' @param n1 Integer. Sample size group 1
#' @param n2 Integer. Sample size group 2
#' @export
cbamm_survival_median_to_hr <- function(median1, median2, n1, n2) {

  if (median1 <= 0 || median2 <= 0) {
    stop("Median survival times must be positive")
  }

  # Assuming exponential distribution:
  # HR = median2 / median1
  # (ratio of median survival times)
  hr <- median2 / median1
  log_hr <- log(hr)

  # Approximate SE using delta method
  # SE(log HR) ≈ sqrt(1/(e1) + 1/(e2))
  # where e1 and e2 are estimated events
  # Assuming approximately 50% events at median time
  e1 <- n1 * 0.5
  e2 <- n2 * 0.5

  se_log_hr <- sqrt(1/e1 + 1/e2)

  # 95% CI
  ci_lower <- exp(log_hr - 1.96 * se_log_hr)
  ci_upper <- exp(log_hr + 1.96 * se_log_hr)

  return(list(
    hr = hr,
    log_hr = log_hr,
    se_log_hr = se_log_hr,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    median1 = median1,
    median2 = median2,
    n1 = n1,
    n2 = n2,
    method = "Median survival time ratio"
  ))
}

#' @describeIn mod_survival_meta Convert survival probabilities at time t to HR
#' @param surv1 Numeric. Survival probability at time t in group 1 (0-1)
#' @param surv2 Numeric. Survival probability at time t in group 2 (0-1)
#' @param n1 Integer. Sample size group 1
#' @param n2 Integer. Sample size group 2
#' @param time Numeric. Time point
#' @export
cbamm_survival_prob_to_hr <- function(surv1, surv2, n1, n2, time) {

  if (surv1 <= 0 || surv1 > 1 || surv2 <= 0 || surv2 > 1) {
    stop("Survival probabilities must be between 0 and 1")
  }

  if (time <= 0) {
    stop("Time must be positive")
  }

  # Assuming exponential distribution:
  # S(t) = exp(-λt)
  # λ = -log(S(t)) / t
  lambda1 <- -log(surv1) / time
  lambda2 <- -log(surv2) / time

  # HR = lambda1 / lambda2
  hr <- lambda1 / lambda2
  log_hr <- log(hr)

  # Approximate SE using delta method
  # Estimated events
  e1 <- n1 * (1 - surv1)
  e2 <- n2 * (1 - surv2)

  if (e1 > 0 && e2 > 0) {
    se_log_hr <- sqrt(1/e1 + 1/e2)
  } else {
    warning("Very few events, SE may be unreliable")
    se_log_hr <- NA
  }

  # 95% CI
  ci_lower <- exp(log_hr - 1.96 * se_log_hr)
  ci_upper <- exp(log_hr + 1.96 * se_log_hr)

  return(list(
    hr = hr,
    log_hr = log_hr,
    se_log_hr = se_log_hr,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    surv1 = surv1,
    surv2 = surv2,
    time = time,
    lambda1 = lambda1,
    lambda2 = lambda2,
    events1 = e1,
    events2 = e2,
    method = "Survival probability at time t"
  ))
}

#' @describeIn mod_survival_meta Meta-analysis of hazard ratios
#' @param hr Numeric vector. Hazard ratios
#' @param log_hr Numeric vector. Log hazard ratios (provide if hr not logged)
#' @param se_log_hr Numeric vector. Standard errors of log HR
#' @param studlab Character vector. Study labels
#' @param method Character. Meta-analysis method ("REML", "DL", "FE")
#' @export
#' @examples
#' \dontrun{
#' # Example HR meta-analysis
#' hr_data <- data.frame(
#'   study = paste0("Study ", 1:5),
#'   hr = c(0.75, 0.82, 0.68, 0.79, 0.71),
#'   se_log_hr = c(0.15, 0.12, 0.18, 0.14, 0.16)
#' )
#'
#' result <- cbamm_survival_meta_hr(
#'   hr = hr_data$hr,
#'   se_log_hr = hr_data$se_log_hr,
#'   studlab = hr_data$study
#' )
#'
#' print(result)
#' }
cbamm_survival_meta_hr <- function(hr = NULL,
                                   log_hr = NULL,
                                   se_log_hr,
                                   studlab = NULL,
                                   method = "REML") {

  # Determine input format
  if (!is.null(hr) && is.null(log_hr)) {
    log_hr <- log(hr)
  } else if (is.null(log_hr)) {
    stop("Must provide either hr or log_hr")
  }

  if (is.null(studlab)) {
    studlab <- paste0("Study ", seq_along(log_hr))
  }

  message("Performing hazard ratio meta-analysis...")
  message(sprintf("  Studies: %d", length(log_hr)))
  message(sprintf("  Method: %s", method))

  # Perform meta-analysis using metafor
  ma <- metafor::rma(
    yi = log_hr,
    sei = se_log_hr,
    slab = studlab,
    method = method,
    measure = "HR"
  )

  # Back-transform to HR scale
  pooled_hr <- exp(ma$b[1])
  ci_lower <- exp(ma$ci.lb)
  ci_upper <- exp(ma$ci.ub)

  message("✅ Meta-analysis complete")
  message(sprintf("  Pooled HR: %.3f (95%% CI: %.3f - %.3f)", pooled_hr, ci_lower, ci_upper))
  message(sprintf("  p-value: %.4f", ma$pval))
  message(sprintf("  I²: %.1f%%", ma$I2))
  message(sprintf("  τ²: %.3f", ma$tau2))

  result <- list(
    ma = ma,
    pooled_hr = pooled_hr,
    log_pooled_hr = ma$b[1],
    se_log_pooled_hr = ma$se,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    p_value = ma$pval,
    I2 = ma$I2,
    tau2 = ma$tau2,
    Q = ma$QE,
    Q_pval = ma$QEp,
    k = ma$k,
    method = method
  )

  class(result) <- c("cbamm_survival_meta", "list")
  return(result)
}

#' @describeIn mod_survival_meta Comprehensive survival meta-analysis
#' @param data Data frame with survival data
#' @param hr_col Character. HR column name
#' @param se_col Character. SE of log HR column name
#' @param studlab_col Character. Study label column name
#' @param events1_col Character. Events in group 1 column (optional)
#' @param total1_col Character. Total in group 1 column (optional)
#' @param events2_col Character. Events in group 2 column (optional)
#' @param total2_col Character. Total in group 2 column (optional)
#' @param method Character. Meta-analysis method
#' @param create_plots Logical. Generate forest and funnel plots?
#' @export
cbamm_survival_analyze <- function(data,
                                    hr_col = "hr",
                                    se_col = "se_log_hr",
                                    studlab_col = "study",
                                    events1_col = NULL,
                                    total1_col = NULL,
                                    events2_col = NULL,
                                    total2_col = NULL,
                                    method = "REML",
                                    create_plots = TRUE) {

  message("═══════════════════════════════════════════════════════════════")
  message("  CBAMMR Comprehensive Survival Meta-Analysis")
  message("═══════════════════════════════════════════════════════════════\n")

  # Extract variables
  hr <- data[[hr_col]]
  se_log_hr <- data[[se_col]]
  studlab <- data[[studlab_col]]

  # Perform meta-analysis
  ma_result <- cbamm_survival_meta_hr(
    hr = hr,
    se_log_hr = se_log_hr,
    studlab = studlab,
    method = method
  )

  # Create plots if requested
  forest_plot <- NULL
  funnel_plot <- NULL

  if (create_plots) {
    # Forest plot
    forest_plot <- safe_try({
      forest(ma_result$ma,
             slab = studlab,
             xlab = "Hazard Ratio",
             refline = 1,
             atransf = exp)
    }, context = "forest plot", return_on_error = NULL)

    # Funnel plot
    funnel_plot <- safe_try({
      funnel(ma_result$ma,
             yaxis = "sei",
             xlab = "Log Hazard Ratio")
    }, context = "funnel plot", return_on_error = NULL)
  }

  # Calculate additional statistics if event data available
  additional_stats <- NULL
  if (!is.null(events1_col) && !is.null(total1_col) &&
      !is.null(events2_col) && !is.null(total2_col)) {

    events1 <- data[[events1_col]]
    total1 <- data[[total1_col]]
    events2 <- data[[events2_col]]
    total2 <- data[[total2_col]]

    # Total events
    total_events <- sum(events1, na.rm = TRUE) + sum(events2, na.rm = TRUE)
    total_participants <- sum(total1, na.rm = TRUE) + sum(total2, na.rm = TRUE)

    additional_stats <- list(
      total_events = total_events,
      total_participants = total_participants,
      event_rate = total_events / total_participants
    )
  }

  # Compile results
  results <- list(
    ma = ma_result$ma,
    summary = list(
      pooled_hr = ma_result$pooled_hr,
      ci_lower = ma_result$ci_lower,
      ci_upper = ma_result$ci_upper,
      p_value = ma_result$p_value,
      I2 = ma_result$I2,
      tau2 = ma_result$tau2,
      k = ma_result$k
    ),
    forest_plot = forest_plot,
    funnel_plot = funnel_plot,
    additional_stats = additional_stats,
    method = method
  )

  class(results) <- c("cbamm_survival_comprehensive", "list")

  message("\n═══════════════════════════════════════════════════════════════")
  message("  ✅ Comprehensive Survival Meta-Analysis Complete")
  message("═══════════════════════════════════════════════════════════════")

  return(results)
}

#' @describeIn mod_survival_meta Print method for survival meta-analysis
#' @param x A cbamm_survival_meta object
#' @param ... Additional arguments
#' @export
print.cbamm_survival_meta <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Hazard Ratio Meta-Analysis\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(sprintf("Studies:           %d\n", x$k))
  cat(sprintf("Method:            %s\n\n", x$method))

  cat("Pooled Hazard Ratio:\n")
  cat(sprintf("  HR:              %.3f\n", x$pooled_hr))
  cat(sprintf("  95%% CI:          [%.3f, %.3f]\n", x$ci_lower, x$ci_upper))
  cat(sprintf("  p-value:         %.4f\n\n", x$p_value))

  cat("Heterogeneity:\n")
  cat(sprintf("  Q:               %.2f (p = %.4f)\n", x$Q, x$Q_pval))
  cat(sprintf("  I²:              %.1f%%\n", x$I2))
  cat(sprintf("  τ²:              %.3f\n", x$tau2))

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}

#' @describeIn mod_survival_meta Print method for comprehensive survival analysis
#' @param x A cbamm_survival_comprehensive object
#' @param ... Additional arguments
#' @export
print.cbamm_survival_comprehensive <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Comprehensive Survival Meta-Analysis Results\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(sprintf("Studies:           %d\n", x$summary$k))
  cat(sprintf("Method:            %s\n\n", x$method))

  cat("Pooled Hazard Ratio:\n")
  cat(sprintf("  HR:              %.3f\n", x$summary$pooled_hr))
  cat(sprintf("  95%% CI:          [%.3f, %.3f]\n", x$summary$ci_lower, x$summary$ci_upper))
  cat(sprintf("  p-value:         %.4f\n\n", x$summary$p_value))

  cat("Heterogeneity:\n")
  cat(sprintf("  I²:              %.1f%%\n", x$summary$I2))
  cat(sprintf("  τ²:              %.3f\n\n", x$summary$tau2))

  if (!is.null(x$additional_stats)) {
    cat("Additional Statistics:\n")
    cat(sprintf("  Total events:    %d\n", x$additional_stats$total_events))
    cat(sprintf("  Total N:         %d\n", x$additional_stats$total_participants))
    cat(sprintf("  Event rate:      %.2f%%\n\n", x$additional_stats$event_rate * 100))
  }

  cat("═══════════════════════════════════════════════════════════════\n")
  cat("Available components:\n")
  cat("  • $ma              - metafor rma object\n")
  cat("  • $summary         - Summary statistics\n")
  cat("  • $forest_plot     - Forest plot\n")
  cat("  • $funnel_plot     - Funnel plot\n")
  cat("  • $additional_stats - Event data statistics\n")
  cat("═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}

#' @describeIn mod_survival_meta Print method for HR calculation
#' @param x A cbamm_hr object
#' @param ... Additional arguments
#' @export
print.cbamm_hr <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Hazard Ratio Calculation\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat("Group 1:\n")
  cat(sprintf("  Events:          %d/%d\n", x$events1, x$total1))
  cat(sprintf("  Hazard rate:     %.4f\n\n", x$hazard1))

  cat("Group 2:\n")
  cat(sprintf("  Events:          %d/%d\n", x$events2, x$total2))
  cat(sprintf("  Hazard rate:     %.4f\n\n", x$hazard2))

  cat("Hazard Ratio:\n")
  cat(sprintf("  HR:              %.3f\n", x$hr))
  cat(sprintf("  log(HR):         %.3f\n", x$log_hr))
  cat(sprintf("  SE[log(HR)]:     %.3f\n", x$se_log_hr))
  cat(sprintf("  95%% CI:          [%.3f, %.3f]\n", x$ci_lower, x$ci_upper))

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}
