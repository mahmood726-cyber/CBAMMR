# Rare Events Methods for CBAMMR

#' Run Rare Events Models Suite
#'
#' Fit rare events meta-analysis models (Peto OR, Mantel-Haenszel, GLMM)
#'
#' @param data Data frame with ai, bi, ci, di columns
#' @param config Configuration object
#'
#' @return List of fitted models
#' @keywords internal
run_rare_event_models <- function(data, config) {
  if (!(config$effect_measure %in% c("OR","RR"))) { cat("\n=== RARE EVENTS ===\nSkipped (measure not OR/RR)\n"); return(NULL) }
  need <- c("ai","bi","ci","di")
  if (!all(need %in% names(data))) { cat("\n=== RARE EVENTS ===\nSkipped (counts ai,bi,ci,di not present)\n"); return(NULL) }
  out <- list(); mset <- unique(config$rare_event_models)
  cat("\n=== RARE EVENTS (", paste(mset, collapse=", "), ") ===\n", sep="")

  # Peto (OR only)
  if ("Peto" %in% mset && config$effect_measure == "OR") {
    fit_p <- safe_try(
      metafor::rma.peto(ai= data$ai, bi= data$bi, ci= data$ci, di= data$di),
      context = "Peto odds ratio for rare events",
      return_on_error = NULL
    )
    if (!is.null(fit_p)) {
      pr <- safe_predict(fit_p, transf = exp, context = "Peto OR")
      if (!is.null(pr)) cat(sprintf("Peto OR: OR=%.3f (95%% CI %.3f–%.3f)\n", pr$pred, pr$ci.lb, pr$ci.ub))
      out$peto <- fit_p
    } else cat("Peto OR failed.\n")
  }

  # Mantel–Haenszel (fixed)
  if ("MH" %in% mset) {
    meas <- config$effect_measure
    fit_mh <- safe_try(
      metafor::rma.mh(ai=data$ai, bi=data$bi, ci=data$ci, di=data$di, measure = meas),
      context = paste("Mantel-Haenszel", meas, "for rare events"),
      return_on_error = NULL
    )
    if (!is.null(fit_mh)) {
      pr <- safe_predict(fit_mh, transf = if (meas=="RR"||meas=="OR") exp else identity, context = paste("MH", meas))
      if (!is.null(pr)) cat(sprintf("MH %s: %s=%.3f (95%% CI %.3f–%.3f)\n",
        meas, .cbamm_measure_meta(meas)$effect_label, pr$pred, pr$ci.lb, pr$ci.ub))
      out$mh <- fit_mh
    } else cat("MH failed.\n")
  }

  # GLMM (binomial likelihood)
  if ("GLMM" %in% mset) {
    meas <- config$effect_measure
    fit_g <- safe_try(
      metafor::rma.glmm(measure = meas, ai=data$ai, bi=data$bi, ci=data$ci, di=data$di, model = config$glmm_model),
      context = paste("GLMM", meas, "for rare events with model", config$glmm_model),
      return_on_error = NULL
    )
    if (!is.null(fit_g)) {
      pr <- safe_predict(fit_g, transf = if (meas=="RR"||meas=="OR") exp else identity, context = paste("GLMM", meas))
      if (!is.null(pr)) cat(sprintf("GLMM %s: %s=%.3f (95%% CI %.3f–%.3f)\n",
        meas, .cbamm_measure_meta(meas)$effect_label, pr$pred, pr$ci.lb, pr$ci.ub))
      out$glmm <- fit_g
    } else cat("GLMM failed.\n")
  }
  invisible(out)
}
