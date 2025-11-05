#' Model Selection and Comparison
#'
#' Comprehensive tools for selecting between meta-analytic models and
#' comparing model fit.
#'
#' @name model-selection
#' @keywords internal
NULL

#' Model Selection with Information Criteria
#'
#' Compare different meta-analytic models using AIC, BIC, and AICc.
#' Helps select between fixed-effect vs random-effects, different tau²
#' estimators, and meta-regression models.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param moderators Optional matrix/data frame of moderators
#' @param methods Vector of estimation methods to compare
#' @param include_fe Include fixed-effect model?
#'
#' @return Object of class "cbamm_model_selection" with model comparison results
#' @export
#'
#' @examples
#' \dontrun{
#' data(teacher_expectancy)
#' result <- cbamm_model_selection(
#'   yi = teacher_expectancy$yi,
#'   vi = teacher_expectancy$vi,
#'   methods = c("REML", "DL", "ML", "EB")
#' )
#' print(result)
#' }
cbamm_model_selection <- function(yi, vi,
                                   moderators = NULL,
                                   methods = c("REML", "DL", "ML", "EB", "HS", "SJ", "HE"),
                                   include_fe = TRUE) {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  results <- list()

  # Fixed-effect model
  if (include_fe) {
    res_fe <- metafor::rma(yi = yi, vi = vi, method = "FE")

    results[["FE"]] <- list(
      method = "FE",
      k = res_fe$k,
      estimate = res_fe$beta[1],
      se = res_fe$se,
      tau2 = 0,
      logLik = logLik(res_fe)[1],
      AIC = AIC(res_fe),
      BIC = BIC(res_fe),
      AICc = .calc_aicc(res_fe),
      df = res_fe$parms
    )
  }

  # Random-effects models with different estimators
  for (method in methods) {
    tryCatch({
      if (is.null(moderators)) {
        res <- metafor::rma(yi = yi, vi = vi, method = method)
      } else {
        res <- metafor::rma(yi = yi, vi = vi, mods = moderators, method = method)
      }

      results[[method]] <- list(
        method = method,
        k = res$k,
        estimate = res$beta[1],
        se = res$se[1],
        tau2 = res$tau2,
        logLik = logLik(res)[1],
        AIC = AIC(res),
        BIC = BIC(res),
        AICc = .calc_aicc(res),
        df = res$parms,
        converged = res$fit.stats$converged
      )
    }, error = function(e) {
      warning(sprintf("Method %s failed: %s", method, e$message))
    })
  }

  # Convert to data frame
  results_df <- do.call(rbind, lapply(names(results), function(m) {
    r <- results[[m]]
    data.frame(
      Method = m,
      k = r$k,
      Estimate = r$estimate,
      SE = r$se,
      Tau2 = r$tau2,
      logLik = r$logLik,
      AIC = r$AIC,
      BIC = r$BIC,
      AICc = r$AICc,
      df = r$df,
      stringsAsFactors = FALSE
    )
  }))

  # Calculate delta AIC, BIC, AICc
  results_df$deltaAIC <- results_df$AIC - min(results_df$AIC)
  results_df$deltaBIC <- results_df$BIC - min(results_df$BIC)
  results_df$deltaAICc <- results_df$AICc - min(results_df$AICc)

  # Calculate Akaike weights
  results_df$AIC_weight <- exp(-0.5 * results_df$deltaAIC) /
                           sum(exp(-0.5 * results_df$deltaAIC))

  # Order by AICc (best for small samples)
  results_df <- results_df[order(results_df$AICc), ]

  # Best model
  best_model <- results_df$Method[1]

  # Model selection summary
  summary_text <- sprintf(
    "Best model: %s (AICc = %.2f, weight = %.3f)",
    best_model,
    results_df$AICc[1],
    results_df$AIC_weight[1]
  )

  result <- list(
    results = results_df,
    best_model = best_model,
    summary = summary_text,
    yi = yi,
    vi = vi,
    moderators = moderators
  )

  class(result) <- "cbamm_model_selection"
  return(result)
}


#' Calculate AICc
#' @keywords internal
.calc_aicc <- function(res) {
  k <- res$k
  aic <- AIC(res)
  df <- res$parms
  aicc <- aic + (2 * df * (df + 1)) / (k - df - 1)
  return(aicc)
}


#' @export
print.cbamm_model_selection <- function(x, digits = 3, ...) {
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Model Selection with Information Criteria\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(x$summary, "\n\n")

  cat("Model Comparison:\n")
  print(x$results, digits = digits, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  Δ < 2: Substantial support\n")
  cat("  Δ 2-6: Considerably less support\n")
  cat("  Δ > 10: Essentially no support\n\n")

  # Strong competitors
  strong <- x$results[x$results$deltaAICc < 2, ]
  if (nrow(strong) > 1) {
    cat(sprintf("Models with substantial support (ΔAICc < 2): %d\n",
                nrow(strong)))
    cat("  ", paste(strong$Method, collapse = ", "), "\n")
  }

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}


#' @export
plot.cbamm_model_selection <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required")
  }

  # Create comparison plot
  plot_data <- x$results
  plot_data$Method <- factor(plot_data$Method, levels = plot_data$Method)

  p1 <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Method, y = deltaAICc)) +
    ggplot2::geom_bar(stat = "identity", fill = "#3498db", alpha = 0.7) +
    ggplot2::geom_hline(yintercept = 2, linetype = "dashed", color = "red") +
    ggplot2::geom_hline(yintercept = 10, linetype = "dashed", color = "darkred") +
    ggplot2::labs(
      title = "Model Comparison (ΔAICc)",
      subtitle = "Lower is better (dashed lines at 2 and 10)",
      y = "ΔAICc",
      x = "Method"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  p2 <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Method, y = AIC_weight)) +
    ggplot2::geom_bar(stat = "identity", fill = "#2ecc71", alpha = 0.7) +
    ggplot2::labs(
      title = "Akaike Weights",
      subtitle = "Probability that model is best",
      y = "Weight",
      x = "Method"
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  if (requireNamespace("patchwork", quietly = TRUE)) {
    print(p1 / p2)
  } else {
    print(p1)
    print(p2)
  }

  invisible(x)
}


#' Cross-Validation for Model Selection
#'
#' Use leave-one-out cross-validation to compare predictive performance
#' of different meta-analytic models.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param moderators Optional moderators
#' @param methods Methods to compare
#'
#' @return Object of class "cbamm_cv" with cross-validation results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_cv_model_selection(yi, vi,
#'                                    methods = c("REML", "DL", "ML"))
#' print(result)
#' }
cbamm_cv_model_selection <- function(yi, vi,
                                      moderators = NULL,
                                      methods = c("REML", "DL", "ML")) {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  k <- length(yi)
  cv_results <- list()

  for (method in methods) {
    pred_errors <- numeric(k)

    for (i in 1:k) {
      # Leave one out
      yi_loo <- yi[-i]
      vi_loo <- vi[-i]

      # Fit model
      if (is.null(moderators)) {
        res <- metafor::rma(yi = yi_loo, vi = vi_loo, method = method)
        pred <- predict(res)$pred
      } else {
        mods_loo <- as.matrix(moderators)[-i, , drop = FALSE]
        mods_new <- as.matrix(moderators)[i, , drop = FALSE]
        res <- metafor::rma(yi = yi_loo, vi = vi_loo, mods = mods_loo, method = method)
        pred <- predict(res, newmods = mods_new)$pred
      }

      # Prediction error
      pred_errors[i] <- (yi[i] - pred)^2
    }

    # Summary statistics
    cv_results[[method]] <- list(
      method = method,
      MSPE = mean(pred_errors),
      RMSPE = sqrt(mean(pred_errors)),
      MAE = mean(abs(sqrt(pred_errors)))
    )
  }

  # Convert to data frame
  results_df <- do.call(rbind, lapply(names(cv_results), function(m) {
    r <- cv_results[[m]]
    data.frame(
      Method = m,
      MSPE = r$MSPE,
      RMSPE = r$RMSPE,
      MAE = r$MAE,
      stringsAsFactors = FALSE
    )
  }))

  # Order by RMSPE (lower is better)
  results_df <- results_df[order(results_df$RMSPE), ]

  best_model <- results_df$Method[1]

  result <- list(
    results = results_df,
    best_model = best_model,
    k = k
  )

  class(result) <- "cbamm_cv"
  return(result)
}


#' @export
print.cbamm_cv <- function(x, ...) {
  cat("\nCross-Validation Model Selection\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Leave-One-Out Cross-Validation (k =", x$k, ")\n\n")
  cat("Best model:", x$best_model, "\n\n")

  cat("Prediction Performance:\n")
  print(x$results, row.names = FALSE)

  cat("\nMSPE = Mean Squared Prediction Error\n")
  cat("RMSPE = Root Mean Squared Prediction Error\n")
  cat("MAE = Mean Absolute Error\n")

  invisible(x)
}


#' Likelihood Ratio Test for Model Comparison
#'
#' Compare nested models using likelihood ratio test.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param mods1 Moderators for model 1 (full model)
#' @param mods2 Moderators for model 2 (reduced model) or NULL for intercept-only
#' @param method Estimation method (must be ML for valid LRT)
#'
#' @return Object of class "cbamm_lrt" with test results
#' @export
#'
#' @examples
#' \dontrun{
#' # Test if moderator significantly improves fit
#' result <- cbamm_lrt(yi, vi, mods1 = moderators, mods2 = NULL)
#' print(result)
#' }
cbamm_lrt <- function(yi, vi, mods1, mods2 = NULL, method = "ML") {

  # Input validation
  validate_meta_inputs(yi, vi)
  validate_sample_size(length(yi), "meta-analysis", warning_only = TRUE)

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  if (method != "ML") {
    warning("Likelihood ratio test requires method='ML' for valid inference")
  }

  # Fit models
  if (is.null(mods2)) {
    # Compare with intercept-only model
    res_full <- metafor::rma(yi = yi, vi = vi, mods = mods1, method = method)
    res_reduced <- metafor::rma(yi = yi, vi = vi, method = method)
  } else {
    # Compare two models with moderators
    res_full <- metafor::rma(yi = yi, vi = vi, mods = mods1, method = method)
    res_reduced <- metafor::rma(yi = yi, vi = vi, mods = mods2, method = method)
  }

  # Likelihood ratio statistic
  LR <- -2 * (logLik(res_reduced)[1] - logLik(res_full)[1])

  # Degrees of freedom
  df <- res_full$parms - res_reduced$parms

  # P-value
  p_value <- pchisq(LR, df = df, lower.tail = FALSE)

  result <- list(
    LR = LR,
    df = df,
    p_value = p_value,
    logLik_full = logLik(res_full)[1],
    logLik_reduced = logLik(res_reduced)[1],
    AIC_full = AIC(res_full),
    AIC_reduced = AIC(res_reduced),
    model_full = res_full,
    model_reduced = res_reduced
  )

  class(result) <- "cbamm_lrt"
  return(result)
}


#' @export
print.cbamm_lrt <- function(x, ...) {
  cat("\nLikelihood Ratio Test\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Model Comparison:\n")
  cat(sprintf("  Full model: logLik = %.2f, AIC = %.2f\n",
              x$logLik_full, x$AIC_full))
  cat(sprintf("  Reduced model: logLik = %.2f, AIC = %.2f\n\n",
              x$logLik_reduced, x$AIC_reduced))

  cat("Likelihood Ratio Test:\n")
  cat(sprintf("  LR = %.2f, df = %d, p = %.4f\n\n",
              x$LR, x$df, x$p_value))

  if (x$p_value < 0.001) {
    cat("*** p < 0.001: Strong evidence that full model is better\n")
  } else if (x$p_value < 0.01) {
    cat("**  p < 0.01: Full model significantly better\n")
  } else if (x$p_value < 0.05) {
    cat("*   p < 0.05: Full model better\n")
  } else {
    cat("    p >= 0.05: No significant improvement with full model\n")
  }

  invisible(x)
}


#' Compare Fixed vs Random Effects Models
#'
#' Statistical test and practical comparison of fixed-effect vs
#' random-effects assumptions.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#'
#' @return Object of class "cbamm_fe_vs_re" with comparison results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_compare_fe_re(yi, vi)
#' print(result)
#' }
cbamm_compare_fe_re <- function(yi, vi) {

  # Input validation
  validate_meta_inputs(yi, vi)
  validate_sample_size(length(yi), "meta-analysis", warning_only = TRUE)

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Fit both models
  res_fe <- metafor::rma(yi = yi, vi = vi, method = "FE")
  res_re <- metafor::rma(yi = yi, vi = vi, method = "REML")

  # Test for heterogeneity
  Q <- res_fe$QE
  df <- res_fe$k - 1
  p_het <- pchisq(Q, df = df, lower.tail = FALSE)

  # I²
  I2 <- max(0, 100 * (Q - df) / Q)

  # Estimates
  est_fe <- res_fe$beta[1]
  se_fe <- res_fe$se
  ci_fe <- c(res_fe$ci.lb, res_fe$ci.ub)

  est_re <- res_re$beta[1]
  se_re <- res_re$se[1]
  ci_re <- c(res_re$ci.lb, res_re$ci.ub)

  # Difference in estimates
  diff_est <- abs(est_fe - est_re)

  # Information criteria
  aic_fe <- AIC(res_fe)
  bic_fe <- BIC(res_fe)
  aic_re <- AIC(res_re)
  bic_re <- BIC(res_re)

  # Recommendation
  if (p_het > 0.10 && I2 < 25) {
    recommendation <- "Fixed-effect model: Low heterogeneity"
  } else if (I2 < 50) {
    recommendation <- "Random-effects model: Moderate heterogeneity"
  } else {
    recommendation <- "Random-effects model: Substantial heterogeneity"
  }

  result <- list(
    # Heterogeneity
    Q = Q,
    p_het = p_het,
    I2 = I2,
    tau2 = res_re$tau2,

    # Fixed effect
    est_fe = est_fe,
    se_fe = se_fe,
    ci_fe = ci_fe,

    # Random effects
    est_re = est_re,
    se_re = se_re,
    ci_re = ci_re,

    # Comparison
    diff_est = diff_est,
    aic_fe = aic_fe,
    bic_fe = bic_fe,
    aic_re = aic_re,
    bic_re = bic_re,

    # Recommendation
    recommendation = recommendation
  )

  class(result) <- "cbamm_fe_vs_re"
  return(result)
}


#' @export
print.cbamm_fe_vs_re <- function(x, ...) {
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Fixed-Effect vs Random-Effects Model Comparison\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat("Heterogeneity Assessment:\n")
  cat(sprintf("  Q = %.2f, p %s\n",
              x$Q,
              if (x$p_het < 0.001) "< 0.001" else sprintf("= %.3f", x$p_het)))
  cat(sprintf("  I² = %.1f%%\n", x$I2))
  cat(sprintf("  Tau² = %.4f\n\n", x$tau2))

  cat("Model Estimates:\n")
  cat("  Fixed-Effect:\n")
  cat(sprintf("    Estimate: %.4f [%.4f, %.4f]\n",
              x$est_fe, x$ci_fe[1], x$ci_fe[2]))
  cat(sprintf("    SE: %.4f\n", x$se_fe))
  cat(sprintf("    AIC: %.2f, BIC: %.2f\n\n", x$aic_fe, x$bic_fe))

  cat("  Random-Effects:\n")
  cat(sprintf("    Estimate: %.4f [%.4f, %.4f]\n",
              x$est_re, x$ci_re[1], x$ci_re[2]))
  cat(sprintf("    SE: %.4f\n", x$se_re))
  cat(sprintf("    AIC: %.2f, BIC: %.2f\n\n", x$aic_re, x$bic_re))

  cat(sprintf("Difference in estimates: %.4f\n\n", x$diff_est))

  cat("Recommendation:\n")
  cat(sprintf("  %s\n", x$recommendation))

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}
