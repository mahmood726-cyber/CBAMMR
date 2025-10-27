# Multivariate Meta-Analysis Functions for CBAMMR

#' @keywords internal
.build_V_block <- function(vi, study_id, rho = 0.5) {
  stopifnot(length(vi) == length(study_id))
  N <- length(vi); V <- matrix(0, nrow = N, ncol = N)
  idx <- split(seq_len(N), factor(study_id))
  for (g in idx) {
    V[g, g] <- diag(vi[g])
    if (length(g) > 1 && rho != 0) {
      for (i in 1:(length(g)-1)) for (j in (i+1):length(g)) {
        V[g[i], g[j]] <- rho * sqrt(vi[g[i]] * vi[g[j]])
        V[g[j], g[i]] <- V[g[i], g[j]]
      }
    }
  }
  V
}

#' @keywords internal
.build_V_exact_logOR <- function(d) {
  stopifnot(all(c("ai","bi","ci","di","study_id") %in% names(d)))
  N <- nrow(d); V <- matrix(0, nrow = N, ncol = N)
  var_i <- with(d, 1/ai + 1/bi + 1/ci + 1/di)
  if (any(!is.finite(var_i))) stop("Non-finite variance components for log OR.")
  diag(V) <- var_i
  idx <- split(seq_len(N), factor(d$study_id))
  for (g in idx) {
    if (length(g) < 2) next
    for (i in 1:(length(g)-1)) for (j in (i+1):length(g)) {
      same_control <- d$ci[g[i]] == d$ci[g[j]] && d$di[g[i]] == d$di[g[j]]
      if (same_control) {
        cov_cd <- (1/d$ci[g[i]] + 1/d$di[g[i]])
        V[g[i], g[j]] <- cov_cd; V[g[j], g[i]] <- cov_cd
      }
    }
  }
  V
}

#' Run Multivariate Meta-Analysis
#'
#' Fit multivariate random-effects model with assumed within-study correlation
#'
#' @param data Data frame with yi, se, study_id
#' @param config Configuration object
#' @param rho Assumed within-study correlation (default from config)
#'
#' @return rma.mv object or NULL if fails
#' @keywords internal
run_mv_meta <- function(data, config, rho = NULL) {
  if (is.null(rho)) rho <- config$mv_assumed_rho
  dup <- any(duplicated(data$study_id))
  if (!dup) { cat("\n=== MV META ===\nSkipped (no multi-arm).\n"); return(NULL) }
  cat("\n=== MV META (rma.mv; ρ=", sprintf("%.2f", rho), ") ===\n", sep = "")
  V <- .build_V_block(vi = data$se^2, study_id = data$study_id, rho = rho)
  mm <- .cbamm_measure_meta(config$effect_measure)
  args <- list(yi = data$yi, V = V, random = ~ 1 | study_id, test = if (config$use_hksj) "knha" else "z", method = config$mv_tau_estimator)
  fit <- try(do.call(metafor::rma.mv, c(args, list(weights = data$analysis_weights))), silent = TRUE)
  if (inherits(fit, "try-error")) fit <- try(do.call(metafor::rma.mv, args), silent = TRUE)
  if (inherits(fit, "try-error")) { cat("rma.mv failed.\n"); return(NULL) }
  pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
  if (!inherits(pr, "try-error")) cat(sprintf("MV pooled: %s=%.3f (95%% CI %.3f–%.3f) | τ²=%.4f\n", mm$effect_label, pr$pred, pr$ci.lb, pr$ci.ub, fit$sigma2))
  else cat(sprintf("MV pooled: %s=%.3f (CI unavailable) | τ²=%.4f\n", mm$effect_label, mm$transf(coef(fit)), fit$sigma2))
  if (requireNamespace("clubSandwich", quietly = TRUE)) {
    vc <- try(clubSandwich::vcovCR(fit, type = "CR2", cluster = data$study_id), silent = TRUE)
    rob <- try(clubSandwich::coef_test(fit, vcov = vc, test = "Satterthwaite"), silent = TRUE)
    if (!inherits(rob, "try-error")) {
      est <- mm$transf(as.numeric(rob$beta)); lo <- mm$transf(as.numeric(rob$conf.low)); hi <- mm$transf(as.numeric(rob$conf.high))
      cat(sprintf("    ↳ MV-CR2: %s=%.3f (95%% CI %.3f–%.3f)\n", mm$effect_label, est, lo, hi))
    }
  } else cat("    ↳ MV-CR2 skipped (clubSandwich not available)\n")
  invisible(fit)
}

#' Run Multivariate Meta-Analysis with Exact Log OR Covariance
#'
#' @param data Data frame with arm-level counts
#' @param config Configuration object
#'
#' @return rma.mv object or NULL
#' @keywords internal
run_mv_meta_exact_logOR <- function(data, config) {
  if (config$effect_measure != "OR") { cat("\n=== MV Exact logOR ===\nSkipped (measure != OR)\n"); return(NULL) }
  need <- c("ai","bi","ci","di","study_id")
  if (!all(need %in% names(data))) { cat("\n=== MV Exact logOR ===\nSkipped (counts not present)\n"); return(NULL) }
  if (!any(duplicated(data$study_id))) { cat("\n=== MV Exact logOR ===\nSkipped (no multi-arm)\n"); return(NULL) }
  cat("\n=== MV META (Exact within-study V for log OR) ===\n")
  V <- .build_V_exact_logOR(data)
  mm <- .cbamm_measure_meta("OR")
  args <- list(yi = data$yi, V = V, random = ~ 1 | study_id, test = if (config$use_hksj) "knha" else "z", method = config$mv_tau_estimator)
  fit <- try(do.call(metafor::rma.mv, args), silent = TRUE)
  if (inherits(fit, "try-error")) { cat("rma.mv exact-V failed.\n"); return(NULL) }
  pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
  if (!inherits(pr, "try-error")) cat(sprintf("MV exact-V pooled: %s=%.3f (95%% CI %.3f–%.3f) | τ²=%.4f\n", mm$effect_label, pr$pred, pr$ci.lb, pr$ci.ub, fit$sigma2))
  else cat(sprintf("MV exact-V pooled: %s=%.3f (CI unavailable) | τ²=%.4f\n", mm$effect_label, mm$transf(coef(fit)), fit$sigma2))
  invisible(fit)
}

#' Run Multivariate Rho Sensitivity Analysis
#'
#' @param data Data frame
#' @param config Configuration object
#' @param rhos Vector of rho values to test
#'
#' @return Data frame with results
#' @keywords internal
run_mv_rho_sensitivity <- function(data, config, rhos = NULL) {
  dup <- any(duplicated(data$study_id))
  if (!dup) { cat("\n=== MV ρ-SENSITIVITY ===\nSkipped (no multi-arm).\n"); return(NULL) }
  if (is.null(rhos)) rhos <- config$mv_rho_grid
  mm <- .cbamm_measure_meta(config$effect_measure)
  out <- purrr::map_dfr(rhos, function(rho) {
    fit <- try(run_mv_meta(data, config, rho = rho), silent = TRUE)
    if (inherits(fit, "try-error") || is.null(fit)) return(tibble::tibble(rho = rho, eff = NA_real_, lo = NA_real_, hi = NA_real_))
    pr <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
    if (inherits(pr, "try-error")) tibble::tibble(rho = rho, eff = mm$transf(as.numeric(coef(fit))), lo = NA_real_, hi = NA_real_)
    else tibble::tibble(rho = rho, eff = pr$pred, lo = pr$ci.lb, hi = pr$ci.ub)
  })
  print(out)
  invisible(out)
}
