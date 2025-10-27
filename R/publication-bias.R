# Publication Bias Assessment Functions for CBAMMR

#' Build Weightr Breaks for Selection Models
#'
#' @param pvals Vector of p-values
#'
#' @return Vector of break points
#' @keywords internal
.cbamm_build_weightr_breaks <- function(pvals) {
  cand <- list(c(0, .025, .05, 1), c(0, quantile(pvals, .025, na.rm = TRUE), .05, 1), c(0, .01, .05, 1), c(0, quantile(pvals, .10, na.rm = TRUE), .25, 1))
  for (br in cand) { idx <- cut(pvals, breaks = br, include.lowest = TRUE, right = TRUE); if (all(table(idx) > 0)) return(br) }
  br <- unique(c(0, quantile(pvals, probs = seq(.1,.9,.1), na.rm = TRUE), 1)); if (length(br) < 3) br <- c(0, .05, 1); br
}

#' Run Publication Bias Sensitivity Analysis
#'
#' Run trim-and-fill and selection models
#'
#' @param data Data frame with yi and se
#'
#' @return List with publication bias results
#' @keywords internal
run_publication_bias_sensitivity <- function(data) {
  cat("\n=== PUBLICATION-BIAS SENSITIVITY ===\n")
  out <- list()
  tf <- try(metafor::trimfill(metafor::rma(yi = data$yi, sei = data$se, method = "REML")), silent = TRUE)
  if (!inherits(tf, "try-error")) { cat("Trim-and-fill estimated missing studies: ", tf$k0, "\n", sep = ""); out$trimfill <- tf } else cat("Trim-and-fill unavailable or failed.\n")

  if (requireNamespace("weightr", quietly = TRUE)) {
    pvals <- 2 * pnorm(-abs(data$yi / data$se)); br <- .cbamm_build_weightr_breaks(pvals)
    sm <- try(weightr::weightfunct(effect = data$yi, v = data$se^2, steps = br, table = FALSE), silent = TRUE)
    if (!inherits(sm, "try-error")) { cat("Selection model (weightr) fitted with breaks: ", paste(br, collapse = ", "), "\n", sep = ""); out$selection_model <- sm }
    else cat("Selection model failed. Proceeding.\n")
  } else cat("Selection model skipped (weightr not available).\n")
  invisible(out)
}

#' Run RoBMA Publication Bias Model Averaging
#'
#' @param data Data frame with yi and se
#'
#' @return List with RoBMA results
#' @keywords internal
run_robma <- function(data) {
  if (!requireNamespace("RoBMA", quietly = TRUE)) { cat("\n=== RoBMA ===\nSkipped (RoBMA not available)\n"); return(NULL) }
  cat("\n=== RoBMA (Robust Bayesian Model Averaging for pub-bias) ===\n")
  fit <- try(RoBMA::RoBMA(y = data$yi, se = data$se), silent = TRUE)
  if (inherits(fit, "try-error")) { cat("RoBMA failed.\n"); return(NULL) }
  summ <- try(capture.output(summary(fit)), silent = TRUE)
  if (!inherits(summ, "try-error")) cat(paste0(summ, collapse = "\n"), "\n")
  eff <- try(RoBMA::coef(fit), silent = TRUE)
  res <- list(fit = fit, coef = eff)
  if (!inherits(eff, "try-error")) {
    if ("mu" %in% rownames(eff)) {
      mu <- eff["mu", , drop=FALSE]
      if (all(c("Median","2.5%","97.5%") %in% colnames(mu))) {
        cat(sprintf("RoBMA MA (back-transformed): %.3f (95%% CrI %.3f–%.3f)\n", exp(mu[1,"Median"]), exp(mu[1,"2.5%"]), exp(mu[1,"97.5%"])))
        res$summary <- list(median = exp(mu[1,"Median"]), cri = c(exp(mu[1,"2.5%"]), exp(mu[1,"97.5%"])))
      }
    }
  }
  invisible(res)
}

#' Run p-uniform* Analysis
#'
#' @param data Data frame with yi and se
#'
#' @return p-uniform* fit or NULL
#' @keywords internal
run_puniform <- function(data) {
  if (!requireNamespace("puniform", quietly = TRUE)) { cat("\n=== p-uniform* ===\nSkipped (package not available)\n"); return(NULL) }
  cat("\n=== p-uniform* ===\n")
  z <- data$yi / data$se
  p2 <- 2 * pnorm(-abs(z))
  sig <- p2[p2 < 0.05 & is.finite(p2)]
  if (length(sig) < 5) { cat("Too few significant p-values (<5); skipping p-uniform*.\n"); return(NULL) }
  fit <- try(puniform::puniform(yi = data$yi, vi = data$se^2, side = "two.sided", method = "P"), silent = TRUE)
  if (inherits(fit, "try-error")) { cat("p-uniform* failed.\n"); return(NULL) }
  print(fit); invisible(fit)
}
