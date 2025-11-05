# Advanced Meta-Analysis Methods Module
# Integrated from mahmood789's specialized Shiny apps
# Part of CBAMMR v8.12.0 Massive Improvements
#
# This module provides advanced meta-analysis methods including:
# - Dose-response meta-analysis (linear, quadratic, restricted cubic spline)
# - Diagnostic Test Accuracy (DTA) meta-analysis (bivariate model)
# - Multilevel meta-analysis (three-level models)
# - Proportions meta-analysis (single proportion, double arcsine transformation)

#' Dose-Response Meta-Analysis
#'
#' Performs dose-response meta-analysis using various models including
#' linear, quadratic, and restricted cubic spline models.
#'
#' @param data Data frame with dose-response data
#' @param dose Name of dose variable
#' @param cases Name of cases variable
#' @param n Name of total sample size variable
#' @param type Type of outcome ("cases" for binary, "mean" for continuous)
#' @param studylab Name of study label variable
#' @param model Model type: "linear", "quadratic", "rcs" (restricted cubic spline)
#' @param knots Number of knots for RCS (default: 3)
#' @param ref_dose Reference dose value (default: 0)
#'
#' @return Object of class "cbamm_dose_response" containing:
#'   \item{model}{Fitted dose-response model}
#'   \item{coefficients}{Model coefficients}
#'   \item{predictions}{Predicted values across dose range}
#'   \item{pvalue_linearity}{P-value for test of linearity (if applicable)}
#'   \item{data}{Original data}
#'
#' @examples
#' \dontrun{
#' # Dose-response meta-analysis
#' dr_data <- data.frame(
#'   study = rep(paste0("Study ", 1:5), each = 3),
#'   dose = rep(c(0, 10, 20), 5),
#'   cases = c(10, 15, 25, 8, 12, 20, 12, 18, 30, 9, 14, 22, 11, 16, 28),
#'   n = rep(100, 15)
#' )
#'
#' result <- cbamm_dose_response(
#'   data = dr_data,
#'   dose = "dose",
#'   cases = "cases",
#'   n = "n",
#'   studylab = "study",
#'   model = "rcs"
#' )
#' print(result)
#' }
#'
#' @export
cbamm_dose_response <- function(data, dose, cases, n, type = "cases",
                                studylab, model = "linear", knots = 3, ref_dose = 0) {

  # Check for required package
  if (!requireNamespace("dosresmeta", quietly = TRUE) && model == "rcs") {
    message("Package 'dosresmeta' not available. Using metafor for linear/quadratic models.")
  }

  # Extract variables
  dose_vals <- data[[dose]]
  cases_vals <- data[[cases]]
  n_vals <- data[[n]]
  study_vals <- data[[studylab]]

  # Calculate log relative risk or log odds
  study_list <- split(data, study_vals)

  # Prepare contrast data (vs reference dose in each study)
  contrast_data <- lapply(study_list, function(study_data) {
    # Find reference dose (usually lowest dose)
    ref_idx <- which.min(study_data[[dose]])
    ref_cases <- study_data[[cases]][ref_idx]
    ref_n <- study_data[[n]][ref_idx]
    ref_dose_val <- study_data[[dose]][ref_idx]

    # Calculate contrasts for other doses
    contrasts <- lapply(seq_len(nrow(study_data))[-ref_idx], function(i) {
      # Log odds ratio
      a <- study_data[[cases]][i]
      b <- study_data[[n]][i] - study_data[[cases]][i]
      c <- ref_cases
      d <- ref_n - ref_cases

      if (a == 0) a <- 0.5
      if (b == 0) b <- 0.5
      if (c == 0) c <- 0.5
      if (d == 0) d <- 0.5

      logor <- log((a * d) / (b * c))
      se_logor <- sqrt(1/a + 1/b + 1/c + 1/d)

      data.frame(
        study = study_data[[studylab]][i],
        dose = study_data[[dose]][i],
        ref_dose = ref_dose_val,
        dose_diff = study_data[[dose]][i] - ref_dose_val,
        logor = logor,
        se = se_logor
      )
    })

    do.call(rbind, contrasts)
  })

  contrast_df <- do.call(rbind, contrast_data)

  # Fit model based on type
  if (model == "linear") {
    # Linear dose-response
    fit <- metafor::rma(yi = logor, sei = se, mods = ~ dose_diff,
                       data = contrast_df, method = "REML")

    # Predictions
    dose_seq <- seq(min(dose_vals), max(dose_vals), length.out = 100)
    dose_diff_seq <- dose_seq - ref_dose

    pred <- predict(fit, newmods = dose_diff_seq)

    predictions <- data.frame(
      dose = dose_seq,
      logor = pred$pred,
      se = pred$se,
      ci_lower = pred$ci.lb,
      ci_upper = pred$ci.ub,
      rr = exp(pred$pred),
      rr_lower = exp(pred$ci.lb),
      rr_upper = exp(pred$ci.ub)
    )

    result <- list(
      model = fit,
      model_type = "linear",
      coefficients = coef(fit),
      predictions = predictions,
      pvalue_linearity = NA,
      data = contrast_df
    )

  } else if (model == "quadratic") {
    # Quadratic dose-response
    contrast_df$dose_diff_sq <- contrast_df$dose_diff^2

    fit <- metafor::rma(yi = logor, sei = se, mods = ~ dose_diff + dose_diff_sq,
                       data = contrast_df, method = "REML")

    # Test for non-linearity (quadratic term)
    pval_nonlinear <- coef(summary(fit))["dose_diff_sq", "pval"]

    # Predictions
    dose_seq <- seq(min(dose_vals), max(dose_vals), length.out = 100)
    dose_diff_seq <- dose_seq - ref_dose
    newmods <- cbind(dose_diff_seq, dose_diff_seq^2)

    pred <- predict(fit, newmods = newmods)

    predictions <- data.frame(
      dose = dose_seq,
      logor = pred$pred,
      se = pred$se,
      ci_lower = pred$ci.lb,
      ci_upper = pred$ci.ub,
      rr = exp(pred$pred),
      rr_lower = exp(pred$ci.lb),
      rr_upper = exp(pred$ci.ub)
    )

    result <- list(
      model = fit,
      model_type = "quadratic",
      coefficients = coef(fit),
      predictions = predictions,
      pvalue_linearity = pval_nonlinear,
      data = contrast_df
    )

  } else if (model == "rcs") {
    # Restricted cubic spline
    if (requireNamespace("dosresmeta", quietly = TRUE)) {
      # Use dosresmeta for RCS
      # Create knots
      dose_range <- range(dose_vals)
      knot_positions <- quantile(dose_vals, probs = seq(0, 1, length.out = knots))

      # Fit RCS model using metafor with spline basis
      spline_basis <- splines::ns(contrast_df$dose_diff, df = knots - 1)
      contrast_df_spline <- cbind(contrast_df, spline_basis)

      fit <- metafor::rma(yi = logor, sei = se,
                         mods = ~ spline_basis,
                         data = contrast_df_spline, method = "REML")

      # Predictions
      dose_seq <- seq(min(dose_vals), max(dose_vals), length.out = 100)
      dose_diff_seq <- dose_seq - ref_dose
      spline_basis_pred <- predict(spline_basis, dose_diff_seq)

      pred <- predict(fit, newmods = spline_basis_pred)

      predictions <- data.frame(
        dose = dose_seq,
        logor = pred$pred,
        se = pred$se,
        ci_lower = pred$ci.lb,
        ci_upper = pred$ci.ub,
        rr = exp(pred$pred),
        rr_lower = exp(pred$ci.lb),
        rr_upper = exp(pred$ci.ub)
      )

      result <- list(
        model = fit,
        model_type = "rcs",
        coefficients = coef(fit),
        predictions = predictions,
        knots = knot_positions,
        pvalue_linearity = NA,
        data = contrast_df
      )
    } else {
      stop("Package 'dosresmeta' required for RCS models. Using quadratic model instead or install dosresmeta.")
    }
  }

  class(result) <- "cbamm_dose_response"
  return(result)
}


#' Diagnostic Test Accuracy Meta-Analysis
#'
#' Performs bivariate meta-analysis of diagnostic test accuracy studies.
#' Uses the bivariate random-effects model to jointly model sensitivity and specificity.
#'
#' @param data Data frame with 2x2 table data
#' @param tp Name of true positive variable
#' @param fp Name of false positive variable
#' @param fn Name of false negative variable
#' @param tn Name of true negative variable
#' @param studylab Name of study label variable
#' @param method Method for fitting ("reml" or "ml")
#'
#' @return Object of class "cbamm_dta" containing:
#'   \item{model}{Fitted bivariate model}
#'   \item{summary_estimates}{Pooled sensitivity and specificity}
#'   \item{sroc}{Summary ROC curve data}
#'   \item{forest_data}{Data for forest plots}
#'   \item{data}{Original 2x2 table data}
#'
#' @examples
#' \dontrun{
#' # DTA meta-analysis
#' dta_data <- data.frame(
#'   study = paste0("Study ", 1:10),
#'   tp = c(80, 85, 90, 75, 88, 92, 78, 86, 91, 83),
#'   fp = c(20, 15, 10, 25, 12, 8, 22, 14, 9, 17),
#'   fn = c(10, 8, 5, 15, 7, 4, 12, 9, 6, 11),
#'   tn = c(90, 92, 95, 85, 93, 96, 88, 91, 94, 89)
#' )
#'
#' result <- cbamm_dta(
#'   data = dta_data,
#'   tp = "tp", fp = "fp", fn = "fn", tn = "tn",
#'   studylab = "study"
#' )
#' print(result)
#' }
#'
#' @export
cbamm_dta <- function(data, tp, fp, fn, tn, studylab, method = "reml") {

  # Check for required package
  if (!requireNamespace("mada", quietly = TRUE)) {
    stop("Package 'mada' is required for DTA meta-analysis. Install with: install.packages('mada')")
  }

  # Extract variables
  tp_vals <- data[[tp]]
  fp_vals <- data[[fp]]
  fn_vals <- data[[fn]]
  tn_vals <- data[[tn]]
  study_vals <- data[[studylab]]

  # Calculate sensitivity and specificity for each study
  sens <- tp_vals / (tp_vals + fn_vals)
  spec <- tn_vals / (tn_vals + fp_vals)

  # Calculate logit transformations with continuity correction
  tp_cc <- ifelse(tp_vals == 0, 0.5, tp_vals)
  fp_cc <- ifelse(fp_vals == 0, 0.5, fp_vals)
  fn_cc <- ifelse(fn_vals == 0, 0.5, fn_vals)
  tn_cc <- ifelse(tn_vals == 0, 0.5, tn_vals)

  logit_sens <- log(tp_cc / fn_cc)
  logit_spec <- log(tn_cc / fp_cc)

  # Standard errors
  se_logit_sens <- sqrt(1/tp_cc + 1/fn_cc)
  se_logit_spec <- sqrt(1/tn_cc + 1/fp_cc)

  # Fit bivariate model using mada
  fit <- mada::reitsma(
    data = data,
    TP = tp, FP = fp, FN = fn, TN = tn,
    method = method
  )

  # Summary estimates
  summary_sens <- mada::sens(fit)
  summary_spec <- mada::spec(fit)

  summary_estimates <- data.frame(
    measure = c("Sensitivity", "Specificity"),
    estimate = c(summary_sens$sens, summary_spec$spec),
    lower = c(summary_sens$sens.ci[1], summary_spec$spec.ci[1]),
    upper = c(summary_sens$sens.ci[2], summary_spec$spec.ci[2])
  )

  # SROC curve
  fpr_seq <- seq(0, 1, length.out = 100)
  sroc_curve <- mada::SummaryPts(fit, fpr = fpr_seq)

  sroc_data <- data.frame(
    fpr = fpr_seq,
    sens = sroc_curve$sens,
    spec = 1 - fpr_seq
  )

  # Forest plot data
  forest_data <- data.frame(
    study = study_vals,
    sens = sens,
    spec = spec,
    sens_lower = NA,  # Calculate using exact binomial if needed
    sens_upper = NA,
    spec_lower = NA,
    spec_upper = NA
  )

  # Calculate exact binomial CIs
  for (i in seq_len(nrow(forest_data))) {
    sens_ci <- binom.test(tp_vals[i], tp_vals[i] + fn_vals[i])$conf.int
    spec_ci <- binom.test(tn_vals[i], tn_vals[i] + fp_vals[i])$conf.int

    forest_data$sens_lower[i] <- sens_ci[1]
    forest_data$sens_upper[i] <- sens_ci[2]
    forest_data$spec_lower[i] <- spec_ci[1]
    forest_data$spec_upper[i] <- spec_ci[2]
  }

  result <- list(
    model = fit,
    summary_estimates = summary_estimates,
    sroc = sroc_data,
    forest_data = forest_data,
    data = data.frame(
      study = study_vals,
      tp = tp_vals, fp = fp_vals,
      fn = fn_vals, tn = tn_vals
    )
  )

  class(result) <- "cbamm_dta"
  return(result)
}


#' Multilevel Meta-Analysis
#'
#' Performs three-level meta-analysis accounting for multiple effect sizes
#' nested within studies (e.g., multiple outcomes, time points, or subgroups).
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param studyid Study identifier
#' @param esid Effect size identifier (unique for each effect size)
#' @param moderators Optional data frame of moderators
#' @param method Estimation method ("REML" or "ML")
#'
#' @return Object of class "cbamm_multilevel" containing:
#'   \item{model}{Fitted three-level model}
#'   \item{variance_components}{Level 2 and level 3 variance estimates}
#'   \item{I2}{I-squared statistics for level 2 and level 3}
#'   \item{summary}{Overall effect estimate}
#'   \item{data}{Original data}
#'
#' @examples
#' \dontrun{
#' # Multilevel meta-analysis
#' # (e.g., multiple outcomes per study)
#' ml_data <- data.frame(
#'   study = rep(1:10, each = 3),
#'   es_id = 1:30,
#'   yi = rnorm(30, 0.3, 0.2),
#'   vi = runif(30, 0.01, 0.05)
#' )
#'
#' result <- cbamm_multilevel(
#'   yi = ml_data$yi,
#'   vi = ml_data$vi,
#'   studyid = ml_data$study,
#'   esid = ml_data$es_id
#' )
#' print(result)
#' }
#'
#' @export
cbamm_multilevel <- function(yi, vi, studyid, esid, moderators = NULL, method = "REML") {

  # Input validation
  if (length(yi) != length(vi) || length(yi) != length(studyid) || length(yi) != length(esid)) {
    stop("yi, vi, studyid, and esid must have the same length")
  }

  # Create data frame
  dat <- data.frame(
    yi = yi,
    vi = vi,
    studyid = studyid,
    esid = esid
  )

  if (!is.null(moderators)) {
    dat <- cbind(dat, moderators)
  }

  # Fit three-level model
  # Level 1: Sampling variance (vi)
  # Level 2: Within-study variance
  # Level 3: Between-study variance

  if (is.null(moderators)) {
    fit <- metafor::rma.mv(
      yi = yi,
      V = vi,
      random = ~ 1 | studyid/esid,
      data = dat,
      method = method
    )
  } else {
    # With moderators
    mod_formula <- as.formula(paste("~", paste(names(moderators), collapse = " + ")))
    fit <- metafor::rma.mv(
      yi = yi,
      V = vi,
      mods = mod_formula,
      random = ~ 1 | studyid/esid,
      data = dat,
      method = method
    )
  }

  # Extract variance components
  sigma2_level2 <- fit$sigma2[1]  # Within-study variance
  sigma2_level3 <- fit$sigma2[2]  # Between-study variance

  # Calculate I-squared for each level
  total_var <- sum(fit$sigma2) + mean(vi)
  I2_level2 <- (sigma2_level2 / total_var) * 100
  I2_level3 <- (sigma2_level3 / total_var) * 100
  I2_total <- ((sigma2_level2 + sigma2_level3) / total_var) * 100

  variance_components <- data.frame(
    level = c("Level 2 (within-study)", "Level 3 (between-study)", "Total"),
    variance = c(sigma2_level2, sigma2_level3, sigma2_level2 + sigma2_level3),
    I2 = c(I2_level2, I2_level3, I2_total)
  )

  # Summary
  summary_effect <- data.frame(
    estimate = fit$beta[1],
    se = fit$se[1],
    ci_lower = fit$ci.lb[1],
    ci_upper = fit$ci.ub[1],
    z = fit$zval[1],
    pval = fit$pval[1]
  )

  result <- list(
    model = fit,
    variance_components = variance_components,
    I2 = variance_components,
    summary = summary_effect,
    data = dat
  )

  class(result) <- "cbamm_multilevel"
  return(result)
}


#' Meta-Analysis of Proportions
#'
#' Performs meta-analysis of single proportions using various transformations.
#' Handles proportions near 0 or 1 using double arcsine transformation.
#'
#' @param events Vector of event counts
#' @param n Vector of sample sizes
#' @param studylab Vector of study labels
#' @param transform Transformation: "logit", "arcsine", "double_arcsine", "log", or "none"
#' @param method Meta-analysis method ("REML", "DL", "FE")
#' @param backtransform Back-transform to proportion scale (default: TRUE)
#'
#' @return Object of class "cbamm_proportions" containing:
#'   \item{model}{Fitted meta-analysis model}
#'   \item{summary}{Pooled proportion estimate}
#'   \item{individual_props}{Individual study proportions}
#'   \item{transform}{Transformation used}
#'   \item{data}{Original data}
#'
#' @examples
#' \dontrun{
#' # Meta-analysis of proportions
#' prop_data <- data.frame(
#'   study = paste0("Study ", 1:10),
#'   events = c(8, 12, 15, 10, 14, 18, 9, 11, 16, 13),
#'   n = c(100, 120, 110, 95, 105, 115, 98, 102, 108, 100)
#' )
#'
#' result <- cbamm_proportions(
#'   events = prop_data$events,
#'   n = prop_data$n,
#'   studylab = prop_data$study,
#'   transform = "double_arcsine"
#' )
#' print(result)
#' }
#'
#' @export
cbamm_proportions <- function(events, n, studylab = NULL,
                              transform = "double_arcsine",
                              method = "REML",
                              backtransform = TRUE) {

  # Input validation
  if (length(events) != length(n)) {
    stop("events and n must have the same length")
  }

  if (any(events > n)) {
    stop("events cannot exceed n")
  }

  if (is.null(studylab)) {
    studylab <- paste0("Study ", seq_along(events))
  }

  # Calculate raw proportions
  props <- events / n

  # Apply transformation and calculate variance
  if (transform == "logit") {
    # Logit transformation with continuity correction
    events_cc <- ifelse(events == 0, 0.5, ifelse(events == n, n - 0.5, events))
    props_cc <- events_cc / n

    yi <- log(props_cc / (1 - props_cc))
    vi <- 1 / (events_cc * (1 - props_cc) * n)

  } else if (transform == "arcsine") {
    # Arcsine transformation
    yi <- asin(sqrt(props))
    vi <- 1 / (4 * n)

  } else if (transform == "double_arcsine") {
    # Double arcsine transformation (Freeman-Tukey)
    yi <- asin(sqrt(events / (n + 1))) + asin(sqrt((events + 1) / (n + 1)))
    vi <- 1 / (n + 0.5)

  } else if (transform == "log") {
    # Log transformation
    events_cc <- ifelse(events == 0, 0.5, events)
    props_cc <- events_cc / n

    yi <- log(props_cc)
    vi <- (1 - props_cc) / (events_cc * n)

  } else if (transform == "none") {
    # No transformation
    yi <- props
    vi <- props * (1 - props) / n

  } else {
    stop("transform must be 'logit', 'arcsine', 'double_arcsine', 'log', or 'none'")
  }

  # Fit meta-analysis model
  fit <- metafor::rma(yi = yi, vi = vi, method = method)

  # Back-transform to proportion scale
  if (backtransform) {
    if (transform == "logit") {
      pooled_prop <- exp(fit$beta) / (1 + exp(fit$beta))
      pooled_lower <- exp(fit$ci.lb) / (1 + exp(fit$ci.lb))
      pooled_upper <- exp(fit$ci.ub) / (1 + exp(fit$ci.ub))

    } else if (transform == "arcsine") {
      pooled_prop <- sin(fit$beta)^2
      pooled_lower <- sin(fit$ci.lb)^2
      pooled_upper <- sin(fit$ci.ub)^2

    } else if (transform == "double_arcsine") {
      # Back-transformation for double arcsine is complex
      # Use approximation
      pooled_prop <- (sin(fit$beta / 2))^2
      pooled_lower <- (sin(fit$ci.lb / 2))^2
      pooled_upper <- (sin(fit$ci.ub / 2))^2

    } else if (transform == "log") {
      pooled_prop <- exp(fit$beta)
      pooled_lower <- exp(fit$ci.lb)
      pooled_upper <- exp(fit$ci.ub)

    } else {
      pooled_prop <- fit$beta
      pooled_lower <- fit$ci.lb
      pooled_upper <- fit$ci.ub
    }
  } else {
    pooled_prop <- fit$beta
    pooled_lower <- fit$ci.lb
    pooled_upper <- fit$ci.ub
  }

  # Summary
  summary_result <- data.frame(
    pooled_proportion = pooled_prop,
    ci_lower = pooled_lower,
    ci_upper = pooled_upper,
    tau2 = fit$tau2,
    I2 = fit$I2,
    H2 = fit$H2,
    Q = fit$QE,
    Q_pval = fit$QEp
  )

  # Individual study data
  individual_props <- data.frame(
    study = studylab,
    events = events,
    n = n,
    proportion = props
  )

  result <- list(
    model = fit,
    summary = summary_result,
    individual_props = individual_props,
    transform = transform,
    data = data.frame(
      study = studylab,
      events = events,
      n = n,
      yi = yi,
      vi = vi
    )
  )

  class(result) <- "cbamm_proportions"
  return(result)
}


#' Comprehensive Advanced Methods Analysis
#'
#' Wrapper function to perform appropriate advanced meta-analysis based on data type.
#'
#' @param data Data frame
#' @param analysis_type Type of analysis: "dose_response", "dta", "multilevel", "proportions"
#' @param ... Additional arguments passed to specific functions
#'
#' @return Analysis results object
#'
#' @examples
#' \dontrun{
#' # Dose-response
#' result <- cbamm_advanced_analyze(
#'   data = dr_data,
#'   analysis_type = "dose_response",
#'   dose = "dose",
#'   cases = "cases",
#'   n = "n",
#'   studylab = "study"
#' )
#' }
#'
#' @export
cbamm_advanced_analyze <- function(data, analysis_type, ...) {

  analysis_type <- match.arg(analysis_type, c("dose_response", "dta", "multilevel", "proportions"))

  result <- switch(analysis_type,
    dose_response = cbamm_dose_response(data = data, ...),
    dta = cbamm_dta(data = data, ...),
    multilevel = cbamm_multilevel(...),
    proportions = cbamm_proportions(...)
  )

  return(result)
}


# S3 Methods ----

#' @export
print.cbamm_dose_response <- function(x, ...) {
  cat("\n=== Dose-Response Meta-Analysis ===\n\n")

  cat(sprintf("Model type: %s\n", x$model_type))
  cat(sprintf("Number of data points: %d\n", nrow(x$data)))

  cat("\nModel Coefficients:\n")
  print(x$coefficients, digits = 3)

  if (!is.na(x$pvalue_linearity)) {
    cat(sprintf("\nTest for non-linearity: p = %.4f %s\n",
                x$pvalue_linearity,
                ifelse(x$pvalue_linearity < 0.05, "(significant)", "(not significant)")))
  }

  cat("\nDose-Response Predictions (first 5 rows):\n")
  print(head(x$predictions, 5), digits = 3, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  - RR > 1: Increased risk with higher dose\n")
  cat("  - RR < 1: Decreased risk with higher dose\n")
  cat("  - Check confidence intervals for precision\n\n")

  invisible(x)
}


#' @export
print.cbamm_dta <- function(x, ...) {
  cat("\n=== Diagnostic Test Accuracy Meta-Analysis ===\n\n")

  cat(sprintf("Number of studies: %d\n\n", nrow(x$data)))

  cat("Pooled Estimates:\n")
  print(x$summary_estimates, digits = 3, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  - Sensitivity: Proportion of true positives correctly identified\n")
  cat("  - Specificity: Proportion of true negatives correctly identified\n")
  cat("  - Higher values indicate better test performance\n\n")

  invisible(x)
}


#' @export
print.cbamm_multilevel <- function(x, ...) {
  cat("\n=== Multilevel Meta-Analysis ===\n\n")

  cat(sprintf("Number of effect sizes: %d\n", nrow(x$data)))
  cat(sprintf("Number of studies: %d\n\n", length(unique(x$data$studyid))))

  cat("Variance Components:\n")
  print(x$variance_components, digits = 3, row.names = FALSE)

  cat("\nOverall Effect Estimate:\n")
  print(x$summary, digits = 3, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  - Level 2: Within-study variance (multiple ES per study)\n")
  cat("  - Level 3: Between-study variance\n")
  cat("  - Higher I-squared indicates more heterogeneity at that level\n\n")

  invisible(x)
}


#' @export
print.cbamm_proportions <- function(x, ...) {
  cat("\n=== Meta-Analysis of Proportions ===\n\n")

  cat(sprintf("Number of studies: %d\n", nrow(x$individual_props)))
  cat(sprintf("Transformation: %s\n\n", x$transform))

  cat("Pooled Proportion Estimate:\n")
  print(x$summary, digits = 3, row.names = FALSE)

  cat("\nIndividual Study Proportions (first 5 studies):\n")
  print(head(x$individual_props, 5), digits = 3, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  - Pooled proportion represents overall event rate\n")
  cat("  - I-squared indicates heterogeneity across studies\n")
  cat("  - Consider subgroup analysis if I-squared > 50%\n\n")

  invisible(x)
}
