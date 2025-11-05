# Meta-Regression and ML Heterogeneity Functions for CBAMMR

#' Run Meta-Regression with Natural Splines
#'
#' Fit meta-regression model with natural splines on year
#'
#' @param data Data frame with yi, se, and year
#' @param config Configuration object
#'
#' @return List with fit and predictions
#' @keywords internal
run_meta_regression_ns <- function(data, config) {
  if (!("year" %in% names(data))) { cat("\n=== META-REGRESSION (NS) ===\nSkipped (no 'year')\n"); return(NULL) }
  if (nrow(data) < 6) { cat("\n=== META-REGRESSION (NS) ===\nSkipped (k<6)\n"); return(NULL) }
  cat("\n=== META-REGRESSION (NS on year; df=", config$meta_regression_df, ") ===\n", sep="")
  df <- config$meta_regression_df; mods <- ~ ns(year, df = df)
  fit <- safe_try(
    robust_rma(data$yi, data$se, data = data, method = "REML",
               weights = data$analysis_weights, mods = mods, use_hksj = config$use_hksj),
    context = "meta-regression with natural splines on year",
    return_on_error = NULL
  )
  if (is.null(fit)) { cat("meta-regression failed.\n"); return(NULL) }
  yr_seq <- seq(min(data$year, na.rm=TRUE), max(data$year, na.rm=TRUE), by = 1)
  newdat <- data.frame(year = yr_seq)
  pr <- safe_try(
    predict(fit, newmods = model.matrix(~ ns(year, df = df), data = newdat),
            transf = .cbamm_measure_meta(config$effect_measure)$transf),
    context = "predicting meta-regression trend over years",
    return_on_error = NULL
  )
  invisible(list(fit = fit, preds = if (!is.null(pr)) data.frame(year = yr_seq, fit = pr$pred, lo = pr$ci.lb, hi = pr$ci.ub) else NULL))
}

#' Run ML Heterogeneity Analysis
#'
#' Use random forest to explore heterogeneity sources
#'
#' @param data Data frame with yi and moderators
#'
#' @return List with ranger model and variable importance
#' @keywords internal
run_ml_heterogeneity <- function(data) {
  if (!requireNamespace("ranger", quietly = TRUE)) { cat("\n=== ML HETEROGENEITY ===\nSkipped (ranger not available)\n"); return(NULL) }
  cat("\n=== ML HETEROGENEITY (ranger) ===\n")
  xvars <- c("study_type", "year", "age_mean", "female_pct", "bmi_mean", "charlson", "neg_ctrl", "tte_compliant")
  xvars <- intersect(xvars, names(data))
  if (length(xvars) < 2) { cat("Not enough moderators.\n"); return(NULL) }
  df <- data %>% dplyr::select(dplyr::all_of(c("yi", xvars))) %>% dplyr::mutate(dplyr::across(where(is.factor), as.character))
  fit <- ranger::ranger(yi ~ ., data = df, importance = "impurity", num.trees = 500, seed = 2025)
  vi <- sort(fit$variable.importance, decreasing = TRUE)
  print(vi)
  invisible(list(model = fit, importance = vi))
}
