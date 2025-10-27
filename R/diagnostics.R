# Diagnostic Functions for CBAMMR

#' Run Influence Analysis
#'
#' Identify influential studies and outliers
#'
#' @param fit Fitted rma object
#'
#' @return List with influence results
#' @keywords internal
run_influence <- function(fit) {
  inf <- try(metafor::influence(fit), silent = TRUE)
  if (inherits(inf, "try-error")) return(NULL)
  s <- summary(inf)
  cat("\n=== INFLUENCE / OUTLIERS ===\n"); print(s)
  invisible(list(inf = inf, summary = s))
}

#' Run Small Study Effect Tests
#'
#' Egger's test and Begg's rank test for small-study effects
#'
#' @param fit Fitted rma object
#'
#' @return List with test results
#' @keywords internal
run_small_study_tests <- function(fit) {
  out <- list()
  eg <- try(metafor::regtest(fit, model = "lm"), silent = TRUE)
  if (!inherits(eg, "try-error")) { cat(sprintf("\nEgger test (lm): z=%.3f, p=%.3f\n", eg$zval, eg$pval)); out$egger <- eg }
  bg <- try(metafor::ranktest(fit), silent = TRUE)
  if (!inherits(bg, "try-error")) { cat(sprintf("Begg rank test: Kendall τ=%.3f, p=%.3f\n", bg$tau, bg$pval)); out$begg <- bg }
  invisible(out)
}

#' Run Robust Location Estimation
#'
#' Fit robust M-estimator for central tendency
#'
#' @param data Data frame with yi and se
#'
#' @return List with robust fit results
#' @keywords internal
run_robust_location <- function(data) {
  if (!requireNamespace("MASS", quietly = TRUE)) { cat("\n=== ROBUST LOCATION ===\nSkipped (MASS not available)\n"); return(NULL) }
  cat("\n=== ROBUST LOCATION (M-estimator; weights=1/vi) ===\n")
  w <- 1/(data$se^2)
  fit <- try(MASS::rlm(yi ~ 1, weights = w, psi = MASS::psi.huber, data = data), silent = TRUE)
  if (inherits(fit, "try-error")) { cat("rlm failed.\n"); return(NULL) }
  est <- coef(fit)[1]; se <- summary(fit)$coefficients[1,2]
  cat(sprintf("rlm intercept (model scale): %.3f (SE %.3f)\n", est, se))
  invisible(list(fit = fit, est = est, se = se))
}

#' Compute E-value for Unmeasured Confounding
#'
#' Calculate E-value for effect estimate and confidence interval
#'
#' @param effect Effect estimate (on ratio scale)
#' @param lo_ci Lower confidence limit
#' @param measure Effect measure ("HR", "RR", or "OR")
#'
#' @return List with point and lower E-values
#' @keywords internal
compute_evalue <- function(effect, lo_ci, measure = "HR") {
  if (!(measure %in% c("HR","RR","OR"))) return(NULL)
  rr <- effect; if (is.na(rr) || !is.finite(rr) || rr <= 0) return(NULL)
  E <- function(r) if (r < 1) 1/E(1/r) else r + sqrt(r*(r-1))
  list(point = E(rr), lower = if (is.finite(lo_ci) && lo_ci > 0) E(lo_ci) else NA_real_)
}

#' Run Simple P-Curve Analysis
#'
#' Examine distribution of significant p-values
#'
#' @param data Data frame with yi and se
#'
#' @return List with p-curve results
#' @keywords internal
run_pcurve <- function(data) {
  cat("\n=== P-CURVE (simple) ===\n")
  z <- data$yi / data$se
  p2 <- 2 * pnorm(-abs(z))
  sig <- p2[p2 < 0.05 & is.finite(p2)]
  if (length(sig) < 5) { cat("Too few significant p-values (<5); skipping.\n"); return(NULL) }
  bins <- cut(sig, breaks = seq(0, 0.05, by = 0.01), include.lowest = TRUE)
  tab <- table(bins)
  print(tab)
  invisible(list(p_sig = sig, table = tab))
}
