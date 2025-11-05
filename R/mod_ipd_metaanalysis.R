# Individual Participant Data (IPD) Meta-Analysis Module
# Based on cutting-edge methods from top journals
# Part of CBAMMR v8.14.0 - Final Comprehensive Release
#
# References:
# - Riley et al. (2010) Annals of Internal Medicine - IPD meta-analysis
# - Debray et al. (2015) BMJ - Individual participant data meta-analysis
# - Stewart & Tierney (2002) Statistics in Medicine - IPD vs aggregate
# - Burke et al. (2017) BMJ - IPD network meta-analysis
# - Riley et al. (2019) BMJ - Prognosis Research Strategy (PROGRESS)

#' One-Stage IPD Meta-Analysis
#'
#' Performs one-stage individual participant data meta-analysis where
#' all participant data are analyzed simultaneously in a single model.
#'
#' @param data Data frame with IPD from all studies
#' @param outcome Name of outcome variable
#' @param treatment Name of treatment variable
#' @param covariates Vector of covariate names
#' @param studyid Name of study identifier variable
#' @param family Family for outcome: "gaussian", "binomial", "survival"
#' @param random_effects Include study-level random effects (default: TRUE)
#' @param stratified Stratify baseline hazard by study (survival only)
#'
#' @return Object of class "cbamm_ipd_onestage" containing:
#'   \item{model}{Fitted mixed-effects model}
#'   \item{treatment_effect}{Overall treatment effect}
#'   \item{heterogeneity}{Between-study heterogeneity}
#'   \item{covariate_effects}{Effects of covariates}
#'
#' @references
#' Riley, R. D., Lambert, P. C., & Abo-Zaid, G. (2010). Meta-analysis of individual
#' participant data: rationale, conduct, and reporting. BMJ, 340, c221.
#'
#' Debray, T. P., Moons, K. G., Abo-Zaid, G. M., Koffijberg, H., & Riley, R. D. (2013).
#' Individual participant data meta-analysis for a binary outcome: one-stage or two-stage?
#' PloS one, 8(4), e60650.
#'
#' @examples
#' \dontrun{
#' # One-stage IPD meta-analysis for binary outcome
#' ipd_result <- cbamm_ipd_onestage(
#'   data = ipd_data,
#'   outcome = "response",
#'   treatment = "treatment",
#'   covariates = c("age", "sex", "baseline_severity"),
#'   studyid = "study",
#'   family = "binomial"
#' )
#' print(ipd_result)
#' }
#'
#' @export
cbamm_ipd_onestage <- function(data, outcome, treatment, covariates = NULL,
                               studyid, family = "gaussian",
                               random_effects = TRUE, stratified = FALSE) {

  # Check for lme4
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' required for one-stage IPD meta-analysis")
  }

  # Input validation
  required_vars <- c(outcome, treatment, studyid)
  if (!all(required_vars %in% names(data))) {
    stop("Required variables not found in data")
  }

  # Build formula
  if (is.null(covariates)) {
    fixed_formula <- paste(outcome, "~", treatment)
  } else {
    fixed_formula <- paste(outcome, "~", treatment, "+",
                          paste(covariates, collapse = " + "))
  }

  # Add random effects
  if (random_effects) {
    # Random intercept and random treatment effect by study
    random_formula <- paste(fixed_formula, "+ (1 +", treatment, "|", studyid, ")")
  } else {
    # Fixed effects only (stratified by study)
    random_formula <- paste(fixed_formula, "+", studyid)
  }

  # Fit model based on family
  if (family == "gaussian") {
    # Linear mixed model
    fit <- lme4::lmer(as.formula(random_formula), data = data, REML = TRUE)

  } else if (family == "binomial") {
    # Logistic mixed model
    fit <- lme4::glmer(as.formula(random_formula), data = data,
                       family = binomial(link = "logit"))

  } else if (family == "survival") {
    # Cox model with frailty
    if (!requireNamespace("survival", quietly = TRUE)) {
      stop("Package 'survival' required for survival analysis")
    }

    # Build survival formula
    if (stratified) {
      surv_formula <- paste("Surv(time, event) ~", treatment,
                           if (!is.null(covariates)) paste("+", paste(covariates, collapse = " + ")) else "",
                           "+ strata(", studyid, ") + frailty(", studyid, ")")
    } else {
      surv_formula <- paste("Surv(time, event) ~", treatment,
                           if (!is.null(covariates)) paste("+", paste(covariates, collapse = " + ")) else "",
                           "+ frailty(", studyid, ")")
    }

    fit <- survival::coxph(as.formula(surv_formula), data = data)

  } else {
    stop("family must be 'gaussian', 'binomial', or 'survival'")
  }

  # Extract treatment effect
  if (family %in% c("gaussian", "binomial")) {
    treat_coef_idx <- grep(paste0("^", treatment), names(lme4::fixef(fit)))
    treatment_effect <- lme4::fixef(fit)[treat_coef_idx]
    treatment_se <- sqrt(diag(vcov(fit)))[treat_coef_idx]
    treatment_ci <- confint(fit, parm = treatment, method = "Wald")

    # Extract random effects variance (heterogeneity)
    vc <- lme4::VarCorr(fit)
    tau2 <- as.data.frame(vc)$vcov[which(as.data.frame(vc)$grp == studyid &
                                          grepl(treatment, as.data.frame(vc)$var1))]
    if (length(tau2) == 0) tau2 <- 0

  } else {
    # Survival
    treat_coef_idx <- grep(paste0("^", treatment), names(coef(fit)))
    treatment_effect <- coef(fit)[treat_coef_idx]
    treatment_se <- sqrt(diag(vcov(fit)))[treat_coef_idx]
    treatment_ci <- confint(fit)[treat_coef_idx, ]

    # Frailty variance
    tau2 <- fit$history[[1]]$theta
  }

  # Covariate effects
  if (!is.null(covariates)) {
    if (family == "survival") {
      covariate_effects <- data.frame(
        covariate = covariates,
        estimate = coef(fit)[covariates],
        se = sqrt(diag(vcov(fit)))[covariates],
        ci_lower = confint(fit)[covariates, 1],
        ci_upper = confint(fit)[covariates, 2]
      )
    } else {
      coef_idx <- which(names(lme4::fixef(fit)) %in% covariates)
      covariate_effects <- data.frame(
        covariate = covariates,
        estimate = lme4::fixef(fit)[coef_idx],
        se = sqrt(diag(vcov(fit)))[coef_idx],
        ci_lower = confint(fit, parm = covariates, method = "Wald")[, 1],
        ci_upper = confint(fit, parm = covariates, method = "Wald")[, 2]
      )
    }
  } else {
    covariate_effects <- NULL
  }

  result <- list(
    model = fit,
    treatment_effect = data.frame(
      estimate = treatment_effect,
      se = treatment_se,
      ci_lower = treatment_ci[1],
      ci_upper = treatment_ci[2]
    ),
    heterogeneity = data.frame(
      tau2 = tau2,
      I2 = NA  # Not directly applicable in IPD
    ),
    covariate_effects = covariate_effects,
    family = family,
    n_studies = length(unique(data[[studyid]])),
    n_participants = nrow(data)
  )

  class(result) <- "cbamm_ipd_onestage"
  return(result)
}


#' Two-Stage IPD Meta-Analysis
#'
#' Performs two-stage IPD meta-analysis: first analyzing each study separately,
#' then meta-analyzing the study-specific estimates.
#'
#' @param data Data frame with IPD from all studies
#' @param outcome Name of outcome variable
#' @param treatment Name of treatment variable
#' @param covariates Vector of covariate names
#' @param studyid Name of study identifier variable
#' @param family Family for outcome: "gaussian", "binomial", "survival"
#' @param method Method for second-stage: "REML", "DL", "FE"
#'
#' @return Object of class "cbamm_ipd_twostage" with pooled estimates
#'
#' @references
#' Debray, T. P., Moons, K. G., Abo-Zaid, G. M., Koffijberg, H., & Riley, R. D. (2013).
#' Individual participant data meta-analysis for a binary outcome: one-stage or two-stage?
#' PloS one, 8(4), e60650.
#'
#' @examples
#' \dontrun{
#' ipd_result <- cbamm_ipd_twostage(
#'   data = ipd_data,
#'   outcome = "response",
#'   treatment = "treatment",
#'   covariates = c("age", "sex"),
#'   studyid = "study",
#'   family = "binomial"
#' )
#' }
#'
#' @export
cbamm_ipd_twostage <- function(data, outcome, treatment, covariates = NULL,
                               studyid, family = "gaussian", method = "REML") {

  studies <- unique(data[[studyid]])
  n_studies <- length(studies)

  # Stage 1: Analyze each study separately
  study_results <- lapply(studies, function(study) {

    study_data <- data[data[[studyid]] == study, ]

    # Build formula
    if (is.null(covariates)) {
      formula_str <- paste(outcome, "~", treatment)
    } else {
      formula_str <- paste(outcome, "~", treatment, "+",
                          paste(covariates, collapse = " + "))
    }

    # Fit model
    if (family == "gaussian") {
      fit <- lm(as.formula(formula_str), data = study_data)
    } else if (family == "binomial") {
      fit <- glm(as.formula(formula_str), data = study_data, family = binomial())
    } else if (family == "survival") {
      if (!requireNamespace("survival", quietly = TRUE)) {
        stop("Package 'survival' required")
      }
      formula_str <- paste("Surv(time, event) ~", treatment,
                          if (!is.null(covariates)) paste("+", paste(covariates, collapse = " + ")) else "")
      fit <- survival::coxph(as.formula(formula_str), data = study_data)
    }

    # Extract treatment effect
    treat_coef_idx <- grep(paste0("^", treatment), names(coef(fit)))

    if (length(treat_coef_idx) == 0) {
      return(NULL)
    }

    list(
      study = study,
      estimate = coef(fit)[treat_coef_idx],
      se = sqrt(diag(vcov(fit)))[treat_coef_idx],
      n = nrow(study_data)
    )
  })

  # Remove NULL results
  study_results <- study_results[!sapply(study_results, is.null)]

  # Extract estimates
  estimates <- sapply(study_results, function(x) x$estimate)
  ses <- sapply(study_results, function(x) x$se)
  study_names <- sapply(study_results, function(x) x$study)

  # Stage 2: Meta-analyze study-specific estimates
  ma_fit <- metafor::rma(yi = estimates, sei = ses, method = method)

  result <- list(
    stage1_results = do.call(rbind, lapply(study_results, as.data.frame)),
    pooled_estimate = data.frame(
      estimate = ma_fit$beta[1],
      se = ma_fit$se,
      ci_lower = ma_fit$ci.lb,
      ci_upper = ma_fit$ci.ub,
      z = ma_fit$zval,
      pval = ma_fit$pval
    ),
    heterogeneity = data.frame(
      tau2 = ma_fit$tau2,
      I2 = ma_fit$I2,
      H2 = ma_fit$H2,
      Q = ma_fit$QE,
      Q_pval = ma_fit$QEp
    ),
    meta_analysis = ma_fit,
    family = family,
    n_studies = length(study_results)
  )

  class(result) <- "cbamm_ipd_twostage"
  return(result)
}


#' IPD Meta-Analysis for Prediction Models
#'
#' Develops and validates prediction models using IPD from multiple studies.
#' Implements methods from PROGRESS framework (Prognosis Research Strategy).
#'
#' @param data Data frame with IPD
#' @param outcome Name of outcome variable
#' @param predictors Vector of predictor names
#' @param studyid Name of study identifier variable
#' @param validation_study Study ID to use for external validation (optional)
#' @param family Family: "binomial" or "survival"
#'
#' @return Object of class "cbamm_ipd_prediction" with model performance
#'
#' @references
#' Riley, R. D., Ensor, J., Snell, K. I., Harrell, F. E., Martin, G. P., Reitsma, J. B., ... & Collins, G. S. (2020).
#' Calculating the sample size required for developing a clinical prediction model.
#' BMJ, 368, m441.
#'
#' Debray, T. P., Dales, J., Ensor, J., Moons, K. G., & Riley, R. D. (2018).
#' Individual participant data (IPD) meta-analyses of diagnostic and prognostic
#' modeling studies: guidance on their use. PLoS medicine, 15(10), e1002697.
#'
#' @examples
#' \dontrun{
#' pred_model <- cbamm_ipd_prediction(
#'   data = ipd_data,
#'   outcome = "mortality",
#'   predictors = c("age", "sex", "comorbidity_score"),
#'   studyid = "study",
#'   family = "binomial"
#' )
#' }
#'
#' @export
cbamm_ipd_prediction <- function(data, outcome, predictors, studyid,
                                 validation_study = NULL, family = "binomial") {

  # Split into development and validation if specified
  if (!is.null(validation_study)) {
    dev_data <- data[data[[studyid]] != validation_study, ]
    val_data <- data[data[[studyid]] == validation_study, ]
  } else {
    # Use 80/20 split across studies
    studies <- unique(data[[studyid]])
    n_dev <- ceiling(length(studies) * 0.8)
    dev_studies <- sample(studies, n_dev)

    dev_data <- data[data[[studyid]] %in% dev_studies, ]
    val_data <- data[!data[[studyid]] %in% dev_studies, ]
  }

  # Build prediction model
  formula_str <- paste(outcome, "~", paste(predictors, collapse = " + "))

  if (family == "binomial") {
    # Logistic regression
    model <- glm(as.formula(formula_str), data = dev_data, family = binomial())

    # Predictions on validation data
    val_data$predicted_prob <- predict(model, newdata = val_data, type = "response")

    # Calculate performance metrics
    if (requireNamespace("pROC", quietly = TRUE)) {
      roc_obj <- pROC::roc(val_data[[outcome]], val_data$predicted_prob, quiet = TRUE)
      auc <- as.numeric(roc_obj$auc)
      auc_ci <- as.numeric(pROC::ci.auc(roc_obj))
    } else {
      auc <- NA
      auc_ci <- c(NA, NA, NA)
    }

    # Calibration (observed vs predicted)
    # Hosmer-Lemeshow type calibration
    val_data$decile <- cut(val_data$predicted_prob, breaks = quantile(val_data$predicted_prob, probs = seq(0, 1, 0.1)),
                          include.lowest = TRUE, labels = FALSE)

    calibration <- aggregate(cbind(observed = val_data[[outcome]], predicted = val_data$predicted_prob),
                            by = list(decile = val_data$decile), FUN = mean, na.rm = TRUE)

    # Brier score
    brier_score <- mean((val_data[[outcome]] - val_data$predicted_prob)^2, na.rm = TRUE)

  } else if (family == "survival") {
    # Cox model
    if (!requireNamespace("survival", quietly = TRUE)) {
      stop("Package 'survival' required")
    }

    formula_str <- paste("Surv(time, event) ~", paste(predictors, collapse = " + "))
    model <- survival::coxph(as.formula(formula_str), data = dev_data)

    # C-index on validation
    val_data$risk_score <- predict(model, newdata = val_data, type = "lp")
    c_index <- survival::survConcordance(Surv(time, event) ~ risk_score, data = val_data)$concordance

    auc <- c_index
    auc_ci <- c(NA, c_index, NA)
    calibration <- NULL
    brier_score <- NA
  }

  performance <- data.frame(
    metric = c("AUC/C-index", "AUC_lower", "AUC_upper", "Brier_score"),
    value = c(auc, auc_ci[1], auc_ci[3], brier_score)
  )

  result <- list(
    model = model,
    performance = performance,
    calibration = calibration,
    n_development = nrow(dev_data),
    n_validation = nrow(val_data),
    predictors = predictors,
    family = family
  )

  class(result) <- "cbamm_ipd_prediction"
  return(result)
}


#' IPD Network Meta-Analysis
#'
#' Performs network meta-analysis using individual participant data,
#' allowing treatment-covariate interactions.
#'
#' @param data Data frame with IPD
#' @param outcome Name of outcome variable
#' @param treatment Name of treatment variable
#' @param covariates Vector of covariate names
#' @param studyid Name of study identifier variable
#' @param reference Reference treatment
#' @param family Family: "gaussian", "binomial", "survival"
#'
#' @return Object of class "cbamm_ipd_nma" with network results
#'
#' @references
#' Donegan, S., Williamson, P., D'Alessandro, U., & Tudur Smith, C. (2013).
#' Assessing key assumptions of network meta-analysis: a review of methods.
#' Research synthesis methods, 4(4), 291-323.
#'
#' @export
cbamm_ipd_nma <- function(data, outcome, treatment, covariates = NULL,
                          studyid, reference = NULL, family = "gaussian") {

  # If no reference, use first treatment alphabetically
  if (is.null(reference)) {
    reference <- sort(unique(data[[treatment]]))[1]
  }

  # Recode treatment with reference as baseline
  data[[treatment]] <- relevel(factor(data[[treatment]]), ref = reference)

  # Use one-stage IPD approach with treatment as factor
  result_onestage <- cbamm_ipd_onestage(
    data = data,
    outcome = outcome,
    treatment = treatment,
    covariates = covariates,
    studyid = studyid,
    family = family,
    random_effects = TRUE
  )

  # Extract treatment effects vs reference
  if (family == "survival") {
    treat_coefs <- coef(result_onestage$model)
    treat_names <- names(treat_coefs)[grepl(treatment, names(treat_coefs))]
  } else {
    treat_coefs <- lme4::fixef(result_onestage$model)
    treat_names <- names(treat_coefs)[grepl(treatment, names(treat_coefs))]
  }

  # Treatment rankings (based on point estimates)
  treatment_effects <- data.frame(
    treatment = gsub(treatment, "", treat_names),
    estimate = treat_coefs[treat_names],
    rank = rank(-treat_coefs[treat_names])
  )

  result <- list(
    onestage_model = result_onestage,
    treatment_effects = treatment_effects,
    reference = reference,
    n_treatments = length(unique(data[[treatment]])),
    n_studies = length(unique(data[[studyid]])),
    n_participants = nrow(data)
  )

  class(result) <- "cbamm_ipd_nma"
  return(result)
}


# S3 Methods ----

#' @export
print.cbamm_ipd_onestage <- function(x, ...) {
  cat("\n=== One-Stage IPD Meta-Analysis ===\n\n")

  cat(sprintf("Family: %s\n", x$family))
  cat(sprintf("Number of studies: %d\n", x$n_studies))
  cat(sprintf("Number of participants: %d\n\n", x$n_participants))

  cat("Treatment Effect:\n")
  print(x$treatment_effect, digits = 3, row.names = FALSE)

  cat("\n\nHeterogeneity:\n")
  print(x$heterogeneity, digits = 3, row.names = FALSE)

  if (!is.null(x$covariate_effects)) {
    cat("\n\nCovariate Effects:\n")
    print(x$covariate_effects, digits = 3, row.names = FALSE)
  }

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_ipd_twostage <- function(x, ...) {
  cat("\n=== Two-Stage IPD Meta-Analysis ===\n\n")

  cat(sprintf("Family: %s\n", x$family))
  cat(sprintf("Number of studies: %d\n\n", x$n_studies))

  cat("Pooled Estimate:\n")
  print(x$pooled_estimate, digits = 3, row.names = FALSE)

  cat("\n\nHeterogeneity:\n")
  print(x$heterogeneity, digits = 3, row.names = FALSE)

  cat("\n\nStudy-Specific Estimates:\n")
  print(x$stage1_results, digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_ipd_prediction <- function(x, ...) {
  cat("\n=== IPD Prediction Model ===\n\n")

  cat(sprintf("Family: %s\n", x$family))
  cat(sprintf("Development sample: %d participants\n", x$n_development))
  cat(sprintf("Validation sample: %d participants\n\n", x$n_validation))

  cat("Predictors:\n")
  cat(paste("  -", x$predictors, collapse = "\n"), "\n\n")

  cat("Performance on Validation Set:\n")
  print(x$performance, digits = 3, row.names = FALSE)

  if (!is.null(x$calibration)) {
    cat("\n\nCalibration (by decile):\n")
    print(x$calibration, digits = 3, row.names = FALSE)
  }

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_ipd_nma <- function(x, ...) {
  cat("\n=== IPD Network Meta-Analysis ===\n\n")

  cat(sprintf("Reference treatment: %s\n", x$reference))
  cat(sprintf("Number of treatments: %d\n", x$n_treatments))
  cat(sprintf("Number of studies: %d\n", x$n_studies))
  cat(sprintf("Number of participants: %d\n\n", x$n_participants))

  cat("Treatment Effects (vs. Reference):\n")
  print(x$treatment_effects, digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}
