# Table Generation Functions for CBAMMR

#' Create Manuscript-Ready Summary Table
#'
#' Generate comprehensive summary table of all meta-analysis results
#'
#' @param results Results list from CBAMM analysis
#' @param data Data frame
#' @param config Configuration object
#'
#' @return Data frame with summary table
#' @export
cbamm_make_summary_table <- function(results, data, config) {
  mm <- .cbamm_measure_meta(config$effect_measure); rows <- list()
  add_row <- function(model, est, lo, hi, tau2 = NA, I2 = NA, k = nrow(data), notes = "") {
    rows[[length(rows)+1]] <<- tibble::tibble(Model = model, Effect = est, CI_L = lo, CI_U = hi, Tau2 = tau2, I2 = I2, k = k, Notes = notes)
  }
  # Pooled (transport)
  if (!is.null(results$pooled$transport)) {
    fit <- results$pooled$transport; pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
    if (!inherits(pr,"try-error")) add_row("Pooled (transport, HK–SJ)", pr$pred, pr$ci.lb, pr$ci.ub, fit$tau2, fit$I2)
  }
  # Pooled (transport+GRADE)
  if (!is.null(results$pooled$grade)) {
    fit <- results$pooled$grade; pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
    if (!inherits(pr,"try-error")) add_row("Pooled (transport+GRADE, HK–SJ)", pr$pred, pr$ci.lb, pr$ci.ub, fit$tau2, fit$I2)
  }
  # CR2 robust
  if (!is.null(results$pooled$transport) && requireNamespace("clubSandwich", quietly = TRUE)) {
    fit <- results$pooled$transport; vc <- try(clubSandwich::vcovCR(fit, cluster = data$study_id, type = "CR2"), silent = TRUE)
    rob <- try(clubSandwich::coef_test(fit, vcov = vc, test = "Satterthwaite"), silent = TRUE)
    if (!inherits(rob,"try-error")) add_row("CR2 (transport)", mm$transf(as.numeric(rob$beta)), mm$transf(as.numeric(rob$conf.low)), mm$transf(as.numeric(rob$conf.high)), fit$tau2, fit$I2, notes = "CR2 adjusted")
  }
  # Rare-events
  if (!is.null(results$rare_events)) {
    if (!is.null(results$rare_events$peto)) {
      pr <- try(metafor::predict(results$rare_events$peto, transf = exp), silent = TRUE)
      if (!inherits(pr,"try-error")) add_row("Peto OR", pr$pred, pr$ci.lb, pr$ci.ub)
    }
    if (!is.null(results$rare_events$mh)) {
      meas <- config$effect_measure; tf <- if (meas %in% c("RR","OR")) exp else identity
      pr <- try(metafor::predict(results$rare_events$mh, transf = tf), silent = TRUE)
      if (!inherits(pr,"try-error")) add_row(paste0("MH ", meas), pr$pred, pr$ci.lb, pr$ci.ub)
    }
    if (!is.null(results$rare_events$glmm)) {
      meas <- config$effect_measure; tf <- if (meas %in% c("RR","OR")) exp else identity
      pr <- try(metafor::predict(results$rare_events$glmm, transf = tf), silent = TRUE)
      if (!inherits(pr,"try-error")) add_row(paste0("GLMM ", meas), pr$pred, pr$ci.lb, pr$ci.ub)
    }
  }
  # PET/PEESE
  if (!is.null(results$pet_peese)) {
    pp <- results$pet_peese; add_row("PET (intercept)", mm$transf(pp["PET"]), NA, NA, notes = "Model-scale intercept back-transformed")
    add_row("PEESE (intercept)", mm$transf(pp["PEESE"]), NA, NA, notes = "Model-scale intercept back-transformed")
  }
  # Trim & Fill
  if (!is.null(results$pub_bias$trimfill)) {
    tf <- results$pub_bias$trimfill; pr <- try(metafor::predict(tf, transf = mm$transf), silent = TRUE)
    if (!inherits(pr,"try-error")) add_row(sprintf("Trim&Fill (k0=%d)", tf$k0), pr$pred, pr$ci.lb, pr$ci.ub, notes = "REML")
  }
  # Selection model (weightr)
  if (!is.null(results$pub_bias$selection_model)) {
    sm <- results$pub_bias$selection_model; adj <- try(weightr::adj_est(sm), silent = TRUE)
    if (!inherits(adj,"try-error") && is.numeric(adj)) add_row("Selection model (weightr)", mm$transf(adj), NA, NA) else add_row("Selection model (weightr)", NA, NA, NA, notes = "adj_est unavailable")
  }
  # RoBMA
  if (!is.null(results$robma) && !is.null(results$robma$summary)) {
    add_row("RoBMA (MA, model-averaged)", results$robma$summary$median, results$robma$summary$cri[1], results$robma$summary$cri[2])
  }
  # p-uniform*
  if (!is.null(results$puniform)) add_row("p-uniform*", NA, NA, NA, notes = "See p-uniform* output")
  # Bayesian
  if (!is.null(results$bayesian$summary)) {
    b <- results$bayesian$summary; add_row(paste0("Bayesian (", results$bayesian$engine, ", stacked)"), b$median, b$cri[1], b$cri[2])
  }
  # MV (assumed ρ)
  if (!is.null(results$mv)) {
    fit <- results$mv; pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
    if (!inherits(pr,"try-error")) add_row(sprintf("MV (rma.mv, ρ=%.2f)", config$mv_assumed_rho), pr$pred, pr$ci.lb, pr$ci.ub, tau2 = fit$sigma2)
  }
  # MV exact logOR
  if (!is.null(results$mv_exact) && config$effect_measure=="OR") {
    fit <- results$mv_exact; pr <- try(metafor::predict(fit, transf = exp), silent = TRUE)
    if (!inherits(pr,"try-error")) add_row("MV exact-V (log OR)", pr$pred, pr$ci.lb, pr$ci.ub, tau2 = fit$sigma2)
  }
  # Robust location
  if (!is.null(results$robust_location)) {
    rl <- results$robust_location; add_row("Robust location (rlm, intercept)", .cbamm_measure_meta(config$effect_measure)$transf(rl$est), NA, NA, notes = "Sensitivity (not RE)")
  }
  # E-value
  if (!is.null(results$pooled$transport) && .cbamm_measure_meta(config$effect_measure)$is_ratio) {
    fit <- results$pooled$transport; pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
    if (!inherits(pr,"try-error")) { ev <- compute_evalue(pr$pred, pr$ci.lb, measure = config$effect_measure); if (!is.null(ev)) add_row("E-value (pooled)", ev$point, ev$lower, NA, notes = "Point; lower CI") }
  }
  dplyr::bind_rows(rows)
}
