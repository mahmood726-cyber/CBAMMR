# Analysis Pipeline Functions for CBAMMR

#' Run Adaptive Advisor
#'
#' Provide recommendations based on data characteristics
#'
#' @param data Data frame
#' @param pooled_results Pooled analysis results
#' @param config Configuration object
#'
#' @return List with recommendations
#' @keywords internal
run_adaptive_advisor <- function(data, pooled_results, config) {
  cat("\n=== ADAPTIVE ADVISOR ===\n")
  k <- nrow(data); dup <- any(duplicated(data$study_id))
  fit <- pooled_results$transport; I2 <- if (!is.null(fit)) fit$I2 else NA_real_
  eg <- try(metafor::regtest(fit, model = "lm"), silent = TRUE); bias_flag <- (!inherits(eg, "try-error")) && is.finite(eg$pval) && eg$pval < 0.10
  rec <- c()
  if (k < 5) rec <- c(rec, "Fixed-effects is defensible (very small k); otherwise keep REML+HKSJ.") else rec <- c(rec, "Random-effects (REML+HKSJ) appropriate.")
  if (is.finite(I2) && I2 > 75) rec <- c(rec, "High heterogeneity: inspect moderators/time trends.")
  if (dup) rec <- c(rec, "Dependent effects: report CR2 RVE and/or MV results.")
  if (bias_flag) rec <- c(rec, "Funnel asymmetry: report PET–PEESE, selection-models, RoBMA/p-uniform*.")
  if (all(c("age_mean","female_pct","bmi_mean","charlson") %in% names(data))) rec <- c(rec, "Covariates present: keep transport weighting.")
  cat(sprintf("k = %d, I² ≈ %s%%\n", k, ifelse(is.finite(I2), sprintf("%.1f", I2), "NA")))
  if (!inherits(eg, "try-error")) cat(sprintf("Egger test (lm) p = %.3f\n", eg$pval))
  cat("Inference: ", if (config$use_hksj) "HKSJ (Knapp–Hartung)" else "Wald z", "\n", sep = "")
  cat("Recommendations:\n"); for (r in rec) cat(" - ", r, "\n", sep="")
  invisible(list(k = k, I2 = I2, egger_p = ifelse(inherits(eg,"try-error"), NA, eg$pval), rec = rec))
}

#' Run Stratified Meta-Analysis
#'
#' Run separate meta-analyses by study type
#'
#' @param data Data frame
#' @param config Configuration object
#'
#' @return List of fitted models by type
#' @keywords internal
run_stratified_analysis <- function(data, config) {
  cat("\n=== STRATIFIED META-ANALYSIS (HKSJ + PI) ===\n")
  res <- list()
  for (type in unique(as.character(data$study_type))) {
    d <- dplyr::filter(data, study_type == type)
    if (nrow(d) < 3) { cat(sprintf("%-8s: insufficient studies (n=%d)\n", type, nrow(d))); res[[type]] <- NULL; next }
    w <- d$analysis_weights
    fit <- try(robust_rma(d$yi, d$se, data = d, method = "REML", weights = w, use_hksj = config$use_hksj), silent = TRUE)
    if (!inherits(fit, "try-error")) {
      report_meta_result(fit, sprintf("%-8s", type), include_pi = TRUE, measure = config$effect_measure,
                         rve_primary = config$use_rve_as_primary, cluster_vec = d$study_id)
      res[[type]] <- fit
    } else { cat(sprintf("%-8s: analysis failed\n", type)); res[[type]] <- NULL }
  }
  res
}

#' Run Pooled Analysis with RVE
#'
#' @param data Data frame
#' @param config Configuration object
#' @param features Feature availability
#'
#' @return List of pooled results
#' @keywords internal
run_pooled_and_rve <- function(data, config, features) {
  cat("\n=== ALL-STUDIES POOLED (Transport & GRADE) ===\n")
  out <- list()
  fit_t <- robust_rma(data$yi, data$se, data = data, method = "REML", weights = data$analysis_weights, use_hksj = config$use_hksj)
  report_meta_result(fit_t, "Transport only       ", include_pi = TRUE, measure = config$effect_measure,
                       rve_primary = config$use_rve_as_primary, cluster_vec = data$study_id)
  out$transport <- fit_t

  if ("analysis_weights_grade" %in% names(data)) {
    fit_g <- robust_rma(data$yi, data$se, data = data, method = "REML", weights = data$analysis_weights_grade, use_hksj = config$use_hksj)
    report_meta_result(fit_g, "Transport + GRADE    ", include_pi = TRUE, measure = config$effect_measure,
                         rve_primary = config$use_rve_as_primary, cluster_vec = data$study_id)
    out$grade <- fit_g
  }

  if (isTRUE(features$rve)) {
    cat("\n[RVE-CR2] Robust tests on pooled fits:\n")
    rve_print(fit_t, cluster_vec = data$study_id, label = "  Transport")
    if (!is.null(out$grade)) rve_print(out$grade, cluster_vec = data$study_id, label = "  Transport+GRADE")
  } else cat("\n[RVE-CR2] Skipped (clubSandwich not available)\n")
  out
}

#' Run Multiverse Analysis
#'
#' Test robustness across specifications
#'
#' @param data Data frame
#' @param config Configuration object
#'
#' @return Data frame with multiverse results
#' @keywords internal
run_multiverse_analysis <- function(data, config) {
  cat("\n=== MULTIVERSE (τ² estimator × subset × weighting) ===\n")
  grid <- tidyr::expand_grid(estimator = config$tau_estimators, subset = c("RCT_only", "RCT_OBS", "All_types"), weighting = c("standard", "grade_adjusted"))
  rows <- seq_len(nrow(grid)); mm <- .cbamm_measure_meta(config$effect_measure)
  out <- purrr::map_dfr(rows, function(i) {
    spec <- grid[i,]
    dd <- switch(spec$subset, "RCT_only"  = dplyr::filter(data, study_type=="RCT"),
                               "RCT_OBS"   = dplyr::filter(data, study_type %in% c("RCT","OBS")),
                               "All_types" = data)
    if (nrow(dd) < 3) return(tibble::tibble(specification=i, success=FALSE, eff=NA_real_, ci_lb=NA_real_, ci_ub=NA_real_, tau2=NA_real_, i2=NA_real_))
    w <- if (spec$weighting == "grade_adjusted" && "analysis_weights_grade" %in% names(dd)) dd$analysis_weights_grade else dd$analysis_weights
    fit <- try(robust_rma(dd$yi, dd$se, data=dd, method = spec$estimator, weights=w, use_hksj=config$use_hksj), silent=TRUE)
    if (inherits(fit, "try-error")) return(tibble::tibble(specification=i, success=FALSE, eff=NA_real_, ci_lb=NA_real_, ci_ub=NA_real_, tau2=NA_real_, i2=NA_real_))
    pr <- try(metafor::predict(fit, transf=mm$transf), silent=TRUE)
    if (inherits(pr, "try-error")) tibble::tibble(specification=i, success=TRUE, eff=as.numeric(mm$transf(as.numeric(coef(fit)))), ci_lb=NA_real_, ci_ub=NA_real_, tau2=as.numeric(fit$tau2), i2=as.numeric(fit$I2))
    else tibble::tibble(specification=i, success=TRUE, eff=as.numeric(pr$pred), ci_lb=as.numeric(pr$ci.lb), ci_ub=as.numeric(pr$ci.ub), tau2=as.numeric(fit$tau2), i2=as.numeric(fit$I2))
  })
  out <- dplyr::left_join(out, dplyr::mutate(grid, specification=dplyr::row_number()), by="specification")
  ok <- dplyr::filter(out, success)
  if (nrow(ok)>0) { ref <- if (mm$is_ratio) 1 else 0
    cat(sprintf("Successful specs: %d/%d | %s range: %.3f–%.3f | %s<ref: %.1f%%\n", nrow(ok), nrow(out), mm$effect_label, min(ok$eff, na.rm=TRUE), max(ok$eff, na.rm=TRUE), if (mm$is_ratio) "Ratio " else "Effect ", 100*mean(ok$eff < ref, na.rm=TRUE)))
  } else cat("No successful specifications.\n")
  out
}
