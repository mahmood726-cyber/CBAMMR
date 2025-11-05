#' Missing Data and Sensitivity Analysis Module
#'
#' Comprehensive methods for handling missing data in meta-analysis and
#' conducting sensitivity analyses. Implements multiple imputation, pattern-mixture
#' models, informative missingness odds ratios (IMOR), and various sensitivity approaches.
#'
#' @name mod_missing_data_sensitivity
#' @family CBAMMR Modules
#'
#' @references
#' White IR, Higgins JPT, Wood AM (2008). Statistics in Medicine 27:625-650.
#' Higgins JPT, White IR, Wood AM (2008). Statistics in Medicine 27:2715-2733.
#' Carpenter JR, Kenward MG (2008). BMJ 336:697-700.
#' Mavridis D, White IR, Higgins JPT, et al. (2015). Statistics in Medicine 34:2481-2495.
#' Spineli LM, Higgins JPT, Cipriani A, et al. (2013). Statistics in Medicine 32:4308-4317.
#' Turner NL, Dias S, Ades AE, et al. (2015). Research Synthesis Methods 6:388-403.
#' Rubin DB (1987). Multiple Imputation for Nonresponse in Surveys. Wiley.
#'
NULL


#' Multiple Imputation for Missing Outcome Data
#'
#' Implements multiple imputation (MI) for missing outcome data in meta-analysis.
#' Supports various imputation methods including predictive mean matching (PMM),
#' Bayesian bootstrap, and conditional imputation.
#'
#' @param data Data frame containing study data
#' @param yi Effect size estimates (with missing values allowed)
#' @param vi Sampling variances (with missing values allowed)
#' @param studlab Study labels
#' @param covariates Optional matrix of study-level covariates for imputation model
#' @param method Imputation method: "pmm" (predictive mean matching), "norm" (normal),
#'   "bootstrap" (Bayesian bootstrap), or "conditional" (conditional on observed)
#' @param m Number of imputations (default: 50)
#' @param maxit Maximum iterations for imputation algorithm (default: 20)
#' @param seed Random seed for reproducibility
#'
#' @return List containing:
#'   \item{pooled_estimate}{Pooled effect size across imputations (Rubin's rules)}
#'   \item{pooled_se}{Pooled standard error}
#'   \item{pooled_ci}{Pooled confidence interval}
#'   \item{between_imputation_var}{Between-imputation variance}
#'   \item{within_imputation_var}{Within-imputation variance}
#'   \item{relative_increase_var}{Relative increase in variance due to missing data}
#'   \item{fraction_missing_info}{Fraction of missing information}
#'   \item{imputed_datasets}{List of m completed datasets}
#'   \item{convergence}{Convergence diagnostics}
#'
#' @details
#' Implements Rubin's rules for combining multiple imputation results:
#' - Total variance = Within-imputation variance + (1 + 1/m) * Between-imputation variance
#' - Degrees of freedom adjusted using Barnard-Rubin method
#'
#' @export
#' @examples
#' \dontrun{
#' # Simulate data with missing outcomes
#' set.seed(123)
#' yi <- c(0.2, NA, 0.5, NA, 0.3, 0.6, NA, 0.4)
#' vi <- c(0.01, 0.02, 0.015, 0.025, 0.012, 0.018, 0.022, 0.016)
#' studlab <- paste0("Study", 1:8)
#'
#' # Multiple imputation
#' mi_result <- cbamm_multiple_imputation(
#'   yi = yi, vi = vi, studlab = studlab,
#'   method = "pmm", m = 50
#' )
#' print(mi_result$pooled_estimate)
#' }
cbamm_multiple_imputation <- function(data = NULL, yi, vi, studlab,
                                      covariates = NULL,
                                      method = c("pmm", "norm", "bootstrap", "conditional"),
                                      m = 50, maxit = 20, seed = NULL) {
  method <- match.arg(method)

  if (!is.null(seed)) set.seed(seed)

  # Prepare data
  if (!is.null(data)) {
    yi <- data[[deparse(substitute(yi))]]
    vi <- data[[deparse(substitute(vi))]]
    studlab <- data[[deparse(substitute(studlab))]]
  }

  n <- length(yi)
  missing_yi <- is.na(yi)
  missing_vi <- is.na(vi)
  n_missing <- sum(missing_yi)

  if (n_missing == 0) {
    stop("No missing effect sizes to impute")
  }

  # Initialize storage
  imputed_datasets <- vector("list", m)
  estimates <- numeric(m)
  ses <- numeric(m)

  cat(sprintf("Performing multiple imputation with m = %d imputations...\n", m))
  cat(sprintf("Missing data: %d/%d (%.1f%%) effect sizes\n",
              n_missing, n, 100*n_missing/n))

  # Perform m imputations
  for (imp in 1:m) {
    yi_imp <- yi
    vi_imp <- vi

    if (method == "pmm") {
      # Predictive Mean Matching
      # 1. Fit model to observed data
      obs_idx <- !missing_yi
      if (!is.null(covariates)) {
        fit_data <- data.frame(yi = yi[obs_idx], covariates[obs_idx, , drop = FALSE])
        fit <- lm(yi ~ ., data = fit_data, weights = 1/vi[obs_idx])
      } else {
        fit <- lm(yi[obs_idx] ~ 1, weights = 1/vi[obs_idx])
      }

      # 2. Predict for missing values
      if (!is.null(covariates)) {
        pred_data <- data.frame(covariates[missing_yi, , drop = FALSE])
        pred <- predict(fit, newdata = pred_data)
      } else {
        pred <- rep(coef(fit)[1], sum(missing_yi))
      }

      # 3. Match each missing value to k nearest observed values
      k <- min(5, sum(obs_idx))
      for (i in which(missing_yi)) {
        if (!is.null(covariates)) {
          pred_i <- predict(fit, newdata = data.frame(covariates[i, , drop = FALSE]))
        } else {
          pred_i <- coef(fit)[1]
        }

        # Find k nearest observed values
        obs_pred <- predict(fit)
        distances <- abs(obs_pred - pred_i)
        nearest <- order(distances)[1:k]

        # Randomly select one
        yi_imp[i] <- yi[obs_idx][sample(nearest, 1)]
      }

    } else if (method == "norm") {
      # Normal imputation
      obs_idx <- !missing_yi

      # Estimate parameters from observed data
      if (!is.null(covariates)) {
        fit <- lm(yi ~ ., data = data.frame(yi = yi[obs_idx], covariates[obs_idx, , drop = FALSE]),
                  weights = 1/vi[obs_idx])
        pred_data <- data.frame(covariates[missing_yi, , drop = FALSE])
        pred_mean <- predict(fit, newdata = pred_data)
        pred_se <- sqrt(sum(residuals(fit)^2) / (sum(obs_idx) - length(coef(fit))))
      } else {
        mu_est <- weighted.mean(yi[obs_idx], 1/vi[obs_idx])
        tau_est <- sqrt(max(0, var(yi[obs_idx]) - mean(vi[obs_idx])))
        pred_mean <- rep(mu_est, sum(missing_yi))
        pred_se <- tau_est
      }

      # Draw imputations
      yi_imp[missing_yi] <- rnorm(sum(missing_yi), pred_mean, pred_se)

    } else if (method == "bootstrap") {
      # Bayesian bootstrap
      obs_idx <- !missing_yi
      obs_yi <- yi[obs_idx]
      obs_vi <- vi[obs_idx]

      # Bootstrap sample from observed
      boot_weights <- rexp(sum(obs_idx), 1)
      boot_weights <- boot_weights / sum(boot_weights)

      # Weighted mean and variance
      mu_boot <- sum(boot_weights * obs_yi)
      tau_boot <- sqrt(max(0, sum(boot_weights * (obs_yi - mu_boot)^2)))

      # Impute
      yi_imp[missing_yi] <- rnorm(sum(missing_yi), mu_boot, tau_boot)

    } else if (method == "conditional") {
      # Conditional imputation (assuming MAR)
      obs_idx <- !missing_yi

      # Draw from predictive distribution
      mu_obs <- weighted.mean(yi[obs_idx], 1/vi[obs_idx])
      tau_obs <- sqrt(max(0, var(yi[obs_idx]) - mean(vi[obs_idx])))

      # Account for uncertainty in parameters
      se_mu <- tau_obs / sqrt(sum(obs_idx))
      mu_draw <- rnorm(1, mu_obs, se_mu)

      yi_imp[missing_yi] <- rnorm(sum(missing_yi), mu_draw, tau_obs)
    }

    # Impute missing variances using median or regression
    if (any(missing_vi)) {
      if (!is.null(covariates)) {
        # Regression imputation for variances
        fit_vi <- lm(log(vi) ~ ., data = data.frame(log_vi = log(vi[!missing_vi]),
                                                     covariates[!missing_vi, , drop = FALSE]))
        pred_data <- data.frame(covariates[missing_vi, , drop = FALSE])
        vi_imp[missing_vi] <- exp(predict(fit_vi, newdata = pred_data))
      } else {
        # Use median
        vi_imp[missing_vi] <- median(vi[!missing_vi])
      }
    }

    # Store imputed dataset
    imputed_datasets[[imp]] <- data.frame(
      studlab = studlab,
      yi = yi_imp,
      vi = vi_imp,
      imputed = missing_yi
    )

    # Fit meta-analysis to imputed dataset
    ma <- metafor::rma(yi = yi_imp, vi = vi_imp, method = "REML")
    estimates[imp] <- ma$b[1]
    ses[imp] <- ma$se
  }

  # Pool results using Rubin's rules
  pooled_estimate <- mean(estimates)
  within_var <- mean(ses^2)
  between_var <- var(estimates)
  total_var <- within_var + (1 + 1/m) * between_var
  pooled_se <- sqrt(total_var)

  # Relative increase in variance due to missing data
  r <- (1 + 1/m) * between_var / within_var

  # Fraction of missing information
  lambda <- (between_var + between_var/m) / total_var

  # Degrees of freedom (Barnard-Rubin adjustment)
  df_old <- (m - 1) / lambda^2
  df_obs <- n - 1  # Observed data df
  df_adj <- (df_old * df_obs) / (df_old + df_obs)

  # Confidence interval
  t_crit <- qt(0.975, df_adj)
  pooled_ci <- c(pooled_estimate - t_crit * pooled_se,
                 pooled_estimate + t_crit * pooled_se)

  # Convergence diagnostics
  convergence <- list(
    gelman_rubin = NA,  # Could implement if we save chains
    effective_sample_size = m / (1 + r),
    monte_carlo_error = pooled_se * sqrt(1/m)
  )

  cat(sprintf("\nPooled estimate: %.4f (95%% CI: %.4f to %.4f)\n",
              pooled_estimate, pooled_ci[1], pooled_ci[2]))
  cat(sprintf("Fraction of missing information: %.3f\n", lambda))

  return(list(
    pooled_estimate = pooled_estimate,
    pooled_se = pooled_se,
    pooled_ci = pooled_ci,
    within_imputation_var = within_var,
    between_imputation_var = between_var,
    total_variance = total_var,
    relative_increase_var = r,
    fraction_missing_info = lambda,
    df_adjusted = df_adj,
    imputed_datasets = imputed_datasets,
    convergence = convergence,
    method = method,
    m = m,
    n_missing = n_missing
  ))
}


#' Pattern-Mixture Model for Missing Data
#'
#' Implements pattern-mixture models for handling missing outcome data under
#' Missing Not At Random (MNAR) assumptions. Allows different treatment effects
#' for different missingness patterns.
#'
#' @param yi Effect size estimates (with missing values allowed)
#' @param vi Sampling variances
#' @param studlab Study labels
#' @param n_total Total sample size per study
#' @param n_missing Number with missing outcomes per study
#' @param delta_mnar MNAR sensitivity parameter (mean difference between observed
#'   and missing outcomes). Can be single value or vector per study.
#' @param method Method for combining patterns: "weighted" (inverse variance),
#'   "equal" (equal weights), or "bootstrap"
#' @param bootstrap_reps Number of bootstrap replications if method = "bootstrap"
#'
#' @return List containing:
#'   \item{estimate}{Overall treatment effect estimate}
#'   \item{se}{Standard error}
#'   \item{ci}{Confidence interval}
#'   \item{pattern_specific_estimates}{Estimates by missingness pattern}
#'   \item{sensitivity_range}{Range of estimates across delta_mnar values}
#'
#' @details
#' Pattern-mixture models stratify by missingness pattern and estimate separate
#' effects for each pattern, then combine using weights. The delta_mnar parameter
#' specifies systematic differences between observed and missing outcomes.
#'
#' @export
#' @references
#' Carpenter JR, Kenward MG (2008). BMJ 336:697-700.
#' White IR, Higgins JPT, Wood AM (2008). Statistics in Medicine 27:625-650.
cbamm_pattern_mixture_model <- function(yi, vi, studlab,
                                        n_total, n_missing,
                                        delta_mnar = 0,
                                        method = c("weighted", "equal", "bootstrap"),
                                        bootstrap_reps = 1000) {
  method <- match.arg(method)

  n <- length(yi)

  # Calculate missingness proportion
  prop_missing <- n_missing / n_total
  prop_observed <- 1 - prop_missing

  # Adjust effect sizes based on MNAR assumption
  if (length(delta_mnar) == 1) {
    delta_mnar <- rep(delta_mnar, n)
  }

  # Adjusted effect size accounting for missing data
  # Under MNAR, observed effect is biased by delta_mnar * prop_missing
  yi_adjusted <- yi - delta_mnar * prop_missing

  # Adjust variance (additional uncertainty from missing data)
  vi_adjusted <- vi * (1 + prop_missing / (1 - prop_missing))

  # Fit meta-analysis with adjusted data
  ma <- metafor::rma(yi = yi_adjusted, vi = vi_adjusted, method = "REML")

  # Pattern-specific estimates (observed vs missing)
  pattern_observed <- metafor::rma(yi = yi, vi = vi, weights = 1 - prop_missing, method = "REML")
  pattern_missing <- list(
    estimate = mean(yi - delta_mnar),
    se = sqrt(mean(vi) + var(delta_mnar))
  )

  # Bootstrap for uncertainty if requested
  if (method == "bootstrap") {
    boot_estimates <- numeric(bootstrap_reps)

    for (b in 1:bootstrap_reps) {
      # Resample studies with replacement
      boot_idx <- sample(1:n, n, replace = TRUE)

      yi_boot <- yi[boot_idx] - delta_mnar[boot_idx] * prop_missing[boot_idx]
      vi_boot <- vi[boot_idx] * (1 + prop_missing[boot_idx] / (1 - prop_missing[boot_idx]))

      ma_boot <- tryCatch(
        metafor::rma(yi = yi_boot, vi = vi_boot, method = "REML"),
        error = function(e) NULL
      )

      if (!is.null(ma_boot)) {
        boot_estimates[b] <- ma_boot$b[1]
      } else {
        boot_estimates[b] <- weighted.mean(yi_boot, 1/vi_boot)
      }
    }

    # Use bootstrap SE
    se <- sd(boot_estimates)
    ci <- quantile(boot_estimates, c(0.025, 0.975))
  } else {
    se <- ma$se
    ci <- c(ma$ci.lb, ma$ci.ub)
  }

  # Sensitivity analysis across range of delta_mnar values
  delta_range <- seq(-2, 2, by = 0.25)
  sensitivity_estimates <- numeric(length(delta_range))

  for (i in seq_along(delta_range)) {
    yi_sens <- yi - delta_range[i] * prop_missing
    vi_sens <- vi * (1 + prop_missing / (1 - prop_missing))
    ma_sens <- metafor::rma(yi = yi_sens, vi = vi_sens, method = "REML")
    sensitivity_estimates[i] <- ma_sens$b[1]
  }

  cat(sprintf("Pattern-Mixture Model Results (delta_MNAR = %.3f):\n", mean(delta_mnar)))
  cat(sprintf("Adjusted estimate: %.4f (95%% CI: %.4f to %.4f)\n",
              ma$b[1], ci[1], ci[2]))
  cat(sprintf("Average missingness: %.1f%%\n", 100 * mean(prop_missing)))

  return(list(
    estimate = ma$b[1],
    se = se,
    ci = ci,
    tau2 = ma$tau2,
    I2 = ma$I2,
    pattern_specific = list(
      observed = list(estimate = pattern_observed$b[1], se = pattern_observed$se),
      missing = pattern_missing
    ),
    sensitivity_range = data.frame(
      delta_mnar = delta_range,
      estimate = sensitivity_estimates
    ),
    missingness_props = prop_missing,
    method = method,
    model = ma
  ))
}


#' Informative Missingness Odds Ratio (IMOR) Sensitivity Analysis
#'
#' Performs sensitivity analysis using Informative Missingness Odds Ratios (IMOR)
#' for binary outcomes. IMOR represents the odds of an event in participants with
#' missing outcomes relative to those with observed outcomes.
#'
#' @param events_treat Number of events in treatment group (observed)
#' @param n_treat Total in treatment group
#' @param events_control Number of events in control group (observed)
#' @param n_control Total in control group
#' @param missing_treat Number with missing outcomes in treatment
#' @param missing_control Number with missing outcomes in control
#' @param studlab Study labels
#' @param imor_treat IMOR for treatment group (default: 1 = MAR)
#' @param imor_control IMOR for control group (default: 1 = MAR)
#' @param imor_range Range of IMOR values for sensitivity analysis
#'
#' @return List containing:
#'   \item{estimate}{Pooled odds ratio under specified IMOR}
#'   \item{ci}{Confidence interval}
#'   \item{sensitivity_plot_data}{Data for plotting sensitivity analysis}
#'   \item{tipping_point}{IMOR value where conclusion changes (if exists)}
#'
#' @details
#' IMOR = 1 implies MAR (missing at random)
#' IMOR > 1 implies worse outcomes in those with missing data
#' IMOR < 1 implies better outcomes in those with missing data
#'
#' @export
#' @references
#' White IR, Higgins JPT, Wood AM (2008). Statistics in Medicine 27:625-650.
#' Higgins JPT, White IR, Wood AM (2008). Statistics in Medicine 27:2715-2733.
#' Mavridis D, White IR, Higgins JPT, et al. (2015). Statistics in Medicine 34:2481-2495.
cbamm_imor_sensitivity <- function(events_treat, n_treat,
                                   events_control, n_control,
                                   missing_treat, missing_control,
                                   studlab,
                                   imor_treat = 1, imor_control = 1,
                                   imor_range = c(0.5, 0.67, 1, 1.5, 2, 3, 5)) {

  n_studies <- length(events_treat)

  # Calculate observed odds in each group
  obs_treat <- n_treat - missing_treat
  obs_control <- n_control - missing_control

  odds_obs_treat <- events_treat / (obs_treat - events_treat)
  odds_obs_control <- events_control / (obs_control - events_control)

  # Function to impute events for missing participants
  impute_events <- function(imor_t, imor_c) {
    # Treatment group: impute events in missing participants
    odds_missing_treat <- odds_obs_treat * imor_t
    prob_missing_treat <- odds_missing_treat / (1 + odds_missing_treat)
    events_missing_treat <- missing_treat * prob_missing_treat

    # Control group: impute events in missing participants
    odds_missing_control <- odds_obs_control * imor_c
    prob_missing_control <- odds_missing_control / (1 + odds_missing_control)
    events_missing_control <- missing_control * prob_missing_control

    # Total events after imputation
    total_events_treat <- events_treat + events_missing_treat
    total_events_control <- events_control + events_missing_control

    # Calculate ORs
    ai <- total_events_treat
    bi <- n_treat - total_events_treat
    ci <- total_events_control
    di <- n_control - total_events_control

    # Log OR and SE
    yi <- log((ai * di) / (bi * ci))
    vi <- 1/ai + 1/bi + 1/ci + 1/di

    return(list(yi = yi, vi = vi))
  }

  # Main analysis with specified IMOR
  imputed <- impute_events(imor_treat, imor_control)
  ma <- metafor::rma(yi = imputed$yi, vi = imputed$vi, method = "REML")

  # Sensitivity analysis across IMOR range
  sensitivity_results <- expand.grid(
    imor_treat = imor_range,
    imor_control = imor_range
  )

  sensitivity_results$estimate <- NA
  sensitivity_results$ci_lb <- NA
  sensitivity_results$ci_ub <- NA
  sensitivity_results$significant <- NA

  for (i in 1:nrow(sensitivity_results)) {
    imputed_i <- impute_events(sensitivity_results$imor_treat[i],
                                sensitivity_results$imor_control[i])

    ma_i <- tryCatch(
      metafor::rma(yi = imputed_i$yi, vi = imputed_i$vi, method = "REML"),
      error = function(e) NULL
    )

    if (!is.null(ma_i)) {
      sensitivity_results$estimate[i] <- exp(ma_i$b[1])
      sensitivity_results$ci_lb[i] <- exp(ma_i$ci.lb)
      sensitivity_results$ci_ub[i] <- exp(ma_i$ci.ub)
      sensitivity_results$significant[i] <- (ma_i$ci.lb > 0) | (ma_i$ci.ub < 0)
    }
  }

  # Find tipping point (where CI crosses 1)
  mar_idx <- which(sensitivity_results$imor_treat == 1 &
                     sensitivity_results$imor_control == 1)
  mar_sig <- sensitivity_results$significant[mar_idx]

  tipping_point <- NULL
  if (mar_sig) {
    # Find first scenario where conclusion changes
    changed <- which(sensitivity_results$significant != mar_sig)
    if (length(changed) > 0) {
      tipping_point <- sensitivity_results[changed[1], c("imor_treat", "imor_control")]
    }
  }

  cat(sprintf("IMOR Sensitivity Analysis Results:\n"))
  cat(sprintf("IMOR (Treatment/Control): %.2f / %.2f\n", imor_treat, imor_control))
  cat(sprintf("Pooled OR: %.3f (95%% CI: %.3f to %.3f)\n",
              exp(ma$b[1]), exp(ma$ci.lb), exp(ma$ci.ub)))

  if (!is.null(tipping_point)) {
    cat(sprintf("\nTipping point: IMOR_treat = %.2f, IMOR_control = %.2f\n",
                tipping_point$imor_treat, tipping_point$imor_control))
  } else {
    cat("\nNo tipping point found in specified IMOR range\n")
  }

  return(list(
    estimate = exp(ma$b[1]),
    log_estimate = ma$b[1],
    se = ma$se,
    ci = c(exp(ma$ci.lb), exp(ma$ci.ub)),
    tau2 = ma$tau2,
    I2 = ma$I2,
    sensitivity_results = sensitivity_results,
    tipping_point = tipping_point,
    imor_specified = c(treat = imor_treat, control = imor_control),
    model = ma
  ))
}


#' Best-Worst Case Sensitivity Analysis
#'
#' Performs best-case and worst-case sensitivity analyses by imputing extreme
#' outcomes for participants with missing data.
#'
#' @param events_treat Number of events in treatment group (observed)
#' @param n_treat Total in treatment group
#' @param events_control Number of events in control group (observed)
#' @param n_control Total in control group
#' @param missing_treat Number with missing outcomes in treatment
#' @param missing_control Number with missing outcomes in control
#' @param studlab Study labels
#' @param outcome_type "beneficial" (event is good) or "harmful" (event is bad)
#'
#' @return List containing:
#'   \item{observed}{Analysis with only observed data}
#'   \item{best_case}{Best-case scenario}
#'   \item{worst_case}{Worst-case scenario}
#'   \item{range}{Range of plausible estimates}
#'   \item{robust}{TRUE if conclusion is robust across scenarios}
#'
#' @details
#' Best case: Assume all missing in treatment had favorable outcomes,
#'            all missing in control had unfavorable outcomes
#' Worst case: Opposite of best case
#'
#' @export
cbamm_best_worst_case <- function(events_treat, n_treat,
                                  events_control, n_control,
                                  missing_treat, missing_control,
                                  studlab,
                                  outcome_type = c("harmful", "beneficial")) {

  outcome_type <- match.arg(outcome_type)

  # Observed data only (complete case analysis)
  obs_treat <- n_treat - missing_treat
  obs_control <- n_control - missing_control

  ai_obs <- events_treat
  bi_obs <- obs_treat - events_treat
  ci_obs <- events_control
  di_obs <- obs_control - events_control

  yi_obs <- log((ai_obs * di_obs) / (bi_obs * ci_obs))
  vi_obs <- 1/ai_obs + 1/bi_obs + 1/ci_obs + 1/di_obs

  ma_obs <- metafor::rma(yi = yi_obs, vi = vi_obs, method = "REML")

  # Best-case scenario
  if (outcome_type == "harmful") {
    # Best case: no events in missing treatment, all events in missing control
    ai_best <- events_treat  # No additional events
    bi_best <- n_treat - events_treat
    ci_best <- events_control + missing_control  # All missing have events
    di_best <- n_control - ci_best
  } else {
    # Best case: all events in missing treatment, no events in missing control
    ai_best <- events_treat + missing_treat
    bi_best <- n_treat - ai_best
    ci_best <- events_control
    di_best <- n_control - events_control
  }

  yi_best <- log((ai_best * di_best) / (bi_best * ci_best))
  vi_best <- 1/ai_best + 1/bi_best + 1/ci_best + 1/di_best

  ma_best <- metafor::rma(yi = yi_best, vi = vi_best, method = "REML")

  # Worst-case scenario
  if (outcome_type == "harmful") {
    # Worst case: all events in missing treatment, no events in missing control
    ai_worst <- events_treat + missing_treat
    bi_worst <- n_treat - ai_worst
    ci_worst <- events_control
    di_worst <- n_control - events_control
  } else {
    # Worst case: no events in missing treatment, all events in missing control
    ai_worst <- events_treat
    bi_worst <- n_treat - events_treat
    ci_worst <- events_control + missing_control
    di_worst <- n_control - ci_worst
  }

  yi_worst <- log((ai_worst * di_worst) / (bi_worst * ci_worst))
  vi_worst <- 1/ai_worst + 1/bi_worst + 1/ci_worst + 1/di_worst

  ma_worst <- metafor::rma(yi = yi_worst, vi = vi_worst, method = "REML")

  # Check robustness
  # Conclusion is robust if CIs don't cross 1 in all scenarios
  robust_favorable <- (ma_obs$ci.ub < 0) & (ma_best$ci.ub < 0) & (ma_worst$ci.ub < 0)
  robust_unfavorable <- (ma_obs$ci.lb > 0) & (ma_best$ci.lb > 0) & (ma_worst$ci.lb > 0)
  robust <- robust_favorable | robust_unfavorable

  cat("Best-Worst Case Sensitivity Analysis:\n\n")
  cat("Observed (complete case):\n")
  cat(sprintf("  OR = %.3f (95%% CI: %.3f to %.3f)\n",
              exp(ma_obs$b[1]), exp(ma_obs$ci.lb), exp(ma_obs$ci.ub)))
  cat("\nBest case:\n")
  cat(sprintf("  OR = %.3f (95%% CI: %.3f to %.3f)\n",
              exp(ma_best$b[1]), exp(ma_best$ci.lb), exp(ma_best$ci.ub)))
  cat("\nWorst case:\n")
  cat(sprintf("  OR = %.3f (95%% CI: %.3f to %.3f)\n",
              exp(ma_worst$b[1]), exp(ma_worst$ci.lb), exp(ma_worst$ci.ub)))
  cat(sprintf("\nConclusion is %s across scenarios\n",
              ifelse(robust, "ROBUST", "NOT ROBUST")))

  return(list(
    observed = list(
      estimate = exp(ma_obs$b[1]),
      ci = c(exp(ma_obs$ci.lb), exp(ma_obs$ci.ub)),
      model = ma_obs
    ),
    best_case = list(
      estimate = exp(ma_best$b[1]),
      ci = c(exp(ma_best$ci.lb), exp(ma_best$ci.ub)),
      model = ma_best
    ),
    worst_case = list(
      estimate = exp(ma_worst$b[1]),
      ci = c(exp(ma_worst$ci.lb), exp(ma_worst$ci.ub)),
      model = ma_worst
    ),
    range = c(
      min(exp(ma_best$b[1]), exp(ma_worst$b[1])),
      max(exp(ma_best$b[1]), exp(ma_worst$b[1]))
    ),
    robust = robust,
    outcome_type = outcome_type
  ))
}


#' Impute Missing Standard Deviations
#'
#' Imputes missing standard deviations in meta-analysis using various methods.
#'
#' @param mean Treatment effect means
#' @param sd Standard deviations (with missing values allowed)
#' @param n Sample sizes
#' @param studlab Study labels
#' @param method Imputation method: "median", "regression", "cv", or "bootstrap"
#' @param covariates Optional covariates for regression method
#'
#' @return List containing:
#'   \item{sd_imputed}{Imputed standard deviations}
#'   \item{imputed_indicator}{Logical vector indicating which were imputed}
#'   \item{method}{Method used}
#'
#' @export
cbamm_impute_sd <- function(mean, sd, n, studlab,
                           method = c("median", "regression", "cv", "bootstrap"),
                           covariates = NULL) {

  method <- match.arg(method)

  missing_sd <- is.na(sd)
  n_missing <- sum(missing_sd)

  if (n_missing == 0) {
    return(list(
      sd_imputed = sd,
      imputed_indicator = rep(FALSE, length(sd)),
      method = method
    ))
  }

  sd_imputed <- sd

  if (method == "median") {
    # Simple median imputation
    sd_imputed[missing_sd] <- median(sd[!missing_sd])

  } else if (method == "regression") {
    # Regression on mean and/or covariates
    if (!is.null(covariates)) {
      fit_data <- data.frame(
        log_sd = log(sd[!missing_sd]),
        mean = mean[!missing_sd],
        covariates[!missing_sd, , drop = FALSE]
      )
      fit <- lm(log_sd ~ ., data = fit_data)

      pred_data <- data.frame(
        mean = mean[missing_sd],
        covariates[missing_sd, , drop = FALSE]
      )
      sd_imputed[missing_sd] <- exp(predict(fit, newdata = pred_data))
    } else {
      # Regression on mean only
      fit <- lm(log(sd[!missing_sd]) ~ mean[!missing_sd])
      sd_imputed[missing_sd] <- exp(predict(fit, newdata = data.frame(mean = mean[missing_sd])))
    }

  } else if (method == "cv") {
    # Coefficient of variation method
    cv <- sd[!missing_sd] / abs(mean[!missing_sd])
    median_cv <- median(cv, na.rm = TRUE)
    sd_imputed[missing_sd] <- abs(mean[missing_sd]) * median_cv

  } else if (method == "bootstrap") {
    # Bootstrap from observed SDs
    for (i in which(missing_sd)) {
      # Bootstrap sample
      boot_sd <- sample(sd[!missing_sd], 1000, replace = TRUE)
      sd_imputed[i] <- median(boot_sd)
    }
  }

  cat(sprintf("Imputed %d missing standard deviations using %s method\n",
              n_missing, method))

  return(list(
    sd_imputed = sd_imputed,
    imputed_indicator = missing_sd,
    method = method,
    n_imputed = n_missing
  ))
}


#' Comprehensive Sensitivity Analysis Dashboard
#'
#' Performs a comprehensive suite of sensitivity analyses for missing data
#' and provides an integrated summary.
#'
#' @param yi Effect sizes (with missing values allowed)
#' @param vi Sampling variances
#' @param studlab Study labels
#' @param n_total Total sample sizes (for pattern-mixture models)
#' @param n_missing Number with missing outcomes (for pattern-mixture models)
#' @param events_treat,n_treat,events_control,n_control Binary outcome data
#'   (for IMOR and best-worst case)
#' @param missing_treat,missing_control Missing counts for binary outcomes
#'
#' @return List containing results from all sensitivity analyses with integrated
#'   summary and recommendations
#'
#' @export
cbamm_sensitivity_dashboard <- function(yi = NULL, vi = NULL, studlab = NULL,
                                        n_total = NULL, n_missing = NULL,
                                        events_treat = NULL, n_treat = NULL,
                                        events_control = NULL, n_control = NULL,
                                        missing_treat = NULL, missing_control = NULL) {

  results <- list()

  cat("=" %R% 70 %R% "\n")
  cat("COMPREHENSIVE SENSITIVITY ANALYSIS DASHBOARD\n")
  cat("=" %R% 70 %R% "\n\n")

  # 1. Multiple Imputation (if continuous data)
  if (!is.null(yi) && any(is.na(yi))) {
    cat("1. MULTIPLE IMPUTATION ANALYSIS\n")
    cat("-" %R% 70 %R% "\n")
    results$multiple_imputation <- cbamm_multiple_imputation(
      yi = yi, vi = vi, studlab = studlab, method = "pmm", m = 50
    )
    cat("\n")
  }

  # 2. Pattern-Mixture Model (if missingness data available)
  if (!is.null(n_total) && !is.null(n_missing)) {
    cat("2. PATTERN-MIXTURE MODEL (MNAR)\n")
    cat("-" %R% 70 %R% "\n")
    results$pattern_mixture <- cbamm_pattern_mixture_model(
      yi = yi, vi = vi, studlab = studlab,
      n_total = n_total, n_missing = n_missing,
      delta_mnar = 0, method = "weighted"
    )
    cat("\n")
  }

  # 3. IMOR Sensitivity (if binary data)
  if (!is.null(events_treat) && !is.null(missing_treat)) {
    cat("3. IMOR SENSITIVITY ANALYSIS\n")
    cat("-" %R% 70 %R% "\n")
    results$imor <- cbamm_imor_sensitivity(
      events_treat = events_treat, n_treat = n_treat,
      events_control = events_control, n_control = n_control,
      missing_treat = missing_treat, missing_control = missing_control,
      studlab = studlab, imor_treat = 1, imor_control = 1
    )
    cat("\n")
  }

  # 4. Best-Worst Case (if binary data)
  if (!is.null(events_treat) && !is.null(missing_treat)) {
    cat("4. BEST-WORST CASE ANALYSIS\n")
    cat("-" %R% 70 %R% "\n")
    results$best_worst <- cbamm_best_worst_case(
      events_treat = events_treat, n_treat = n_treat,
      events_control = events_control, n_control = n_control,
      missing_treat = missing_treat, missing_control = missing_control,
      studlab = studlab, outcome_type = "harmful"
    )
    cat("\n")
  }

  # Integrated summary
  cat("=" %R% 70 %R% "\n")
  cat("INTEGRATED SUMMARY\n")
  cat("=" %R% 70 %R% "\n\n")

  # Check consistency across methods
  estimates <- c()
  if (!is.null(results$multiple_imputation)) {
    estimates <- c(estimates, results$multiple_imputation$pooled_estimate)
  }
  if (!is.null(results$pattern_mixture)) {
    estimates <- c(estimates, results$pattern_mixture$estimate)
  }

  if (length(estimates) > 1) {
    estimate_range <- range(estimates)
    cat(sprintf("Range of estimates across methods: %.4f to %.4f\n",
                estimate_range[1], estimate_range[2]))

    if (diff(estimate_range) < 0.1) {
      cat("✓ Conclusions are ROBUST across sensitivity analyses\n")
    } else {
      cat("⚠ CAUTION: Conclusions vary across sensitivity analyses\n")
    }
  }

  # Recommendations
  cat("\nRECOMMENDATIONS:\n")
  if (!is.null(results$best_worst)) {
    if (results$best_worst$robust) {
      cat("✓ Results are robust to extreme missing data scenarios\n")
    } else {
      cat("⚠ Results are sensitive to missing data assumptions\n")
      cat("  → Report findings with appropriate caveats\n")
      cat("  → Consider collecting additional data if possible\n")
    }
  }

  if (!is.null(results$multiple_imputation)) {
    lambda <- results$multiple_imputation$fraction_missing_info
    if (lambda > 0.3) {
      cat(sprintf("⚠ High fraction of missing information (%.1f%%)\n", 100*lambda))
      cat("  → Interpret results with caution\n")
    }
  }

  cat("\n")

  return(results)
}


# Helper function for string repetition
`%R%` <- function(x, n) {
  paste(rep(x, n), collapse = "")
}
