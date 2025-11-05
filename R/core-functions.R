# Core Meta-Analysis Functions for CBAMMR
# This file contains the main analysis functions including weighting, meta-analysis,
# multivariate methods, diagnostics, publication bias, and Bayesian approaches

# ========================================
# WEIGHTING FUNCTIONS
# ========================================

#' Compute Transportability Weights
#'
#' Calculate weights to transport study results to a target population
#'
#' @param data Data frame with study characteristics
#' @param target_population List with target population characteristics
#' @param truncation Truncation level for extreme weights
#'
#' @return Numeric vector of weights
#' @export
compute_transport_weights <- function(data, target_population, truncation = 0.02) {
  # Input validation
  validate_meta_data(data, required_cols = NULL)

  req <- c("age_mean", "female_pct", "bmi_mean", "charlson")
  miss <- setdiff(req, names(data))
  if (length(miss)) {
    warning("Missing transportability variables: ", paste(miss, collapse = ", "), ". Using uniform weights.")
    return(rep(1 / nrow(data), nrow(data)))
  }
  X <- data |> dplyr::select(dplyr::all_of(req)) |>
    dplyr::mutate(intercept = 1) |>
    dplyr::select(intercept, dplyr::everything()) |> as.data.frame()
  target_moments <- c(1, target_population$age_mean, target_population$female_pct,
                      target_population$bmi_mean, target_population$charlson)
  if (requireNamespace("WeightIt", quietly = TRUE)) {
    set.seed(123); M <- 1000
    tgt <- data.frame(intercept=1,
      age_mean=rnorm(M, target_population$age_mean, 3),
      female_pct=pmin(pmax(rnorm(M, target_population$female_pct, 0.05), 0), 1),
      bmi_mean=rnorm(M, target_population$bmi_mean, 1.2),
      charlson=pmax(rnorm(M, target_population$charlson, 0.4), 0))
    pool <- dplyr::bind_rows(X |> dplyr::mutate(treat = 0L), tgt |> dplyr::mutate(treat = 1L))
    fml <- as.formula("treat ~ age_mean + female_pct + bmi_mean + charlson")
    wobj <- safe_try(
      WeightIt::weightit(fml, data = pool, method = "ebal"),
      context = "entropy balancing for transportability weights",
      return_on_error = NULL
    )
    if (!is.null(wobj)) {
      w <- as.numeric(wobj$weights[pool$treat == 0]); w <- w / sum(w)
      if (truncation > 0) {
        lo <- stats::quantile(w, truncation)
        hi <- stats::quantile(w, 1 - truncation)
        w <- pmax(pmin(w, hi), lo); w <- w / sum(w)
      }
      if (requireNamespace("cobalt", quietly = TRUE))
        suppressMessages(safe_try(print(cobalt::bal.tab(wobj)), context = "printing balance table", warn = FALSE))
      return(w)
    }
  }
  # fallback optimizer
  init <- rep(1 / nrow(X), nrow(X))
  obj <- function(lambda) {
    eta <- as.numeric(as.matrix(X) %*% lambda); eta <- pmin(eta, 700)
    w <- init * exp(eta); w <- as.numeric(w / sum(w))
    sum((colSums(as.matrix(X) * w) - target_moments)^2)
  }
  opt <- safe_try(
    stats::optim(par = rep(0, ncol(X)), fn = obj, control = list(maxit = 2000, reltol = 1e-10)),
    context = "optimizing transportability weights",
    return_on_error = NULL
  )
  if (!is.null(opt)) {
    w <- init * exp(as.matrix(X) %*% opt$par); w <- as.numeric(w / sum(w))
    if (truncation > 0) {
      lo <- stats::quantile(w, truncation)
      hi <- stats::quantile(w, 1 - truncation)
      w <- pmax(pmin(w, hi), lo); w <- w / sum(w)
    }
    return(w)
  }
  warning("Transport optimization failed; using uniform weights.")
  rep(1 / nrow(data), nrow(data))
}

#' @keywords internal
compute_analysis_weights <- function(data, transport_weights = NULL) {
  w <- if (is.null(transport_weights)) rep(1, nrow(data)) else as.numeric(transport_weights)
  w <- ifelse(is.finite(w) & w > 0, w, 0); w / mean(w)
}

#' @keywords internal
apply_grade_weighting <- function(weights, grade_scores) {
  grade_multiplier <- dplyr::case_when(
    grade_scores == "High" ~ 1.0, grade_scores == "Moderate" ~ 0.8,
    grade_scores == "Low" ~ 0.6, grade_scores == "Very low" ~ 0.4, TRUE ~ 0.8)
  z <- as.numeric(weights) * as.numeric(grade_multiplier); z / mean(z)
}

# ========================================
# CORE META-ANALYSIS
# ========================================

#' Robust Random-Effects Meta-Analysis
#'
#' Fit random-effects model with robust error handling
#'
#' @param yi Effect sizes
#' @param sei Standard errors
#' @param data Optional data frame
#' @param method Tau² estimator
#' @param weights Optional weights
#' @param mods Optional moderators
#' @param use_hksj Use Hartung-Knapp-Sidik-Jonkman adjustment
#'
#' @return rma.uni object from metafor
#' @export
robust_rma <- function(yi, sei, data = NULL, method = "REML",
                       weights = NULL, mods = NULL, use_hksj = TRUE) {
  stopifnot(length(yi) == length(sei))
  if (any(!is.finite(yi)) || any(!is.finite(sei)) || any(sei <= 0))
    stop("Non-finite or non-positive inputs in yi/sei")
  if (length(yi) < 3) stop("Need at least 3 studies for meta-analysis")

  build_args <- function(use_vi = FALSE) {
    a <- list(yi = yi, method = method)
    if (use_vi) a$vi <- sei^2 else a$sei <- sei
    if (!is.null(data))    a$data    <- data
    if (!is.null(weights)) a$weights <- weights
    if (!is.null(mods))    a$mods    <- mods
    if (use_hksj)          a$test    <- "knha"
    a
  }
  args <- build_args(FALSE)
  fit <- safe_try(
    do.call(metafor::rma.uni, args),
    context = "fitting meta-analysis model with sei",
    return_on_error = NULL,
    warn = FALSE
  )
  if (is.null(fit)) {
    args$test <- NULL
    fit <- safe_try(
      do.call(metafor::rma.uni, args),
      context = "fitting meta-analysis model without HKSJ",
      return_on_error = NULL,
      warn = FALSE
    )
  }
  if (is.null(fit)) {
    args2 <- build_args(TRUE)
    fit <- safe_try(
      do.call(metafor::rma.uni, args2),
      context = "fitting meta-analysis model with vi",
      return_on_error = NULL,
      warn = FALSE
    )
    if (is.null(fit) && use_hksj) {
      args2$test <- NULL
      fit <- safe_try(
        do.call(metafor::rma.uni, args2),
        context = "fitting meta-analysis model with vi without HKSJ",
        return_on_error = NULL,
        warn = FALSE
      )
    }
  }
  if (is.null(fit)) stop("Meta-analysis failed after trying multiple fallback strategies")
  fit
}

#' @keywords internal
report_meta_result <- function(result, label = "", include_pi = TRUE,
                               measure = "HR", rve_primary = FALSE,
                               cluster_vec = NULL) {
  if (inherits(result, "try-error")) { cat(label, ": failed\n"); return(invisible(NULL)) }
  mm <- .cbamm_measure_meta(measure); tf <- mm$transf
  pr <- safe_predict(result, transf = tf, context = label)
  if (!is.null(pr)) {
    have_pi <- include_pi && !any(is.na(c(pr$pi.lb, pr$pi.ub)))
    if (have_pi) {
      cat(sprintf("%s: %s=%.3f (95%% CI %.3f–%.3f, PI %.3f–%.3f) | k=%d, τ²=%.4f, I²=%.1f%%\n",
                  label, mm$effect_label, pr$pred, pr$ci.lb, pr$ci.ub,
                  pr$pi.lb, pr$pi.ub, result$k, result$tau2, result$I2))
    } else {
      cat(sprintf("%s: %s=%.3f (95%% CI %.3f–%.3f) | k=%d, τ²=%.4f, I²=%.1f%%\n",
                  label, mm$effect_label, pr$pred, pr$ci.lb, pr$ci.ub,
                  result$k, result$tau2, result$I2))
    }
  } else {
    cat(sprintf("%s: %s=%.3f (CI unavailable) | k=%d, τ²=%.4f, I²=%.1f%%\n",
                label, mm$effect_label, mm$transf(coef(result)),
                result$k, result$tau2, result$I2))
  }

  if (rve_primary && requireNamespace("clubSandwich", quietly = TRUE) && !is.null(cluster_vec)) {
    vc <- safe_try(
      clubSandwich::vcovCR(result, cluster = cluster_vec, type = "CR2"),
      context = "computing CR2 robust variance",
      return_on_error = NULL
    )
    rob <- safe_try(
      clubSandwich::coef_test(result, vcov = vc, test = "Satterthwaite"),
      context = "computing robust coefficient test",
      return_on_error = NULL
    )
    if (!is.null(rob)) {
      est <- tf(as.numeric(rob$beta)); lo <- tf(as.numeric(rob$conf.low)); hi <- tf(as.numeric(rob$conf.high)); df <- as.numeric(rob$df)
      cat(sprintf("    ↳ CR2 (primary): %s=%.3f (95%% CI %.3f–%.3f), df≈%.1f\n", mm$effect_label, est, lo, hi, df))
    }
  }
  invisible(NULL)
}

# ========================================
# PUBLICATION BIAS
# ========================================

#' PET-PEESE Analysis
#'
#' Precision-Effect Test and Precision-Effect Estimate with Standard Error
#'
#' @param yi Effect sizes
#' @param sei Standard errors
#'
#' @return Named vector with PET and PEESE intercepts
#' @export
pet_peese <- function(yi, sei) {
  # Input validation
  validate_meta_inputs(yi, vi = NULL, sei = sei)
  validate_sample_size(length(yi), "meta-analysis", warning_only = TRUE)

  w <- 1 / (sei^2); df <- data.frame(yi = yi, sei = sei, w = w)
  fit_pet    <- lm(yi ~ sei, data = df, weights = w)
  fit_peese <- lm(yi ~ I(sei^2), data = df, weights = w)
  c(PET = unname(coef(fit_pet)[1]), PEESE = unname(coef(fit_peese)[1]))
}

#' @keywords internal
rve_print <- function(res, cluster_vec, label="[RVE-CR2]") {
  if (!requireNamespace("clubSandwich", quietly = TRUE)) return(invisible(NULL))
  vc <- safe_try(
    clubSandwich::vcovCR(res, cluster = cluster_vec, type = "CR2"),
    context = "computing CR2 robust variance for RVE",
    return_on_error = NULL
  )
  if (is.null(vc)) return(invisible(NULL))
  rob <- safe_try(
    clubSandwich::coef_test(res, vcov = vc),
    context = "computing robust coefficient test for RVE",
    return_on_error = NULL
  )
  if (!is.null(rob)) { cat(label, " robust test for ", deparse(substitute(res)), ":\n", sep=""); print(rob) }
  invisible(rob)
}

# Additional functions are included in separate module files
# to keep this file manageable. See:
# - simulation.R for data simulation functions
# - analysis.R for main analysis runner
# - visualization.R for plotting functions
# - multivariate.R for MV meta-analysis
# - rare-events.R for rare events methods
# - diagnostics.R for diagnostic functions
# - bayesian.R for Bayesian methods
