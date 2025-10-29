#' Comprehensive Heterogeneity Assessment
#'
#' Complete set of methods for assessing, explaining, and quantifying
#' heterogeneity in meta-analyses.
#'
#' @name heterogeneity-methods
#' @keywords internal
NULL

#' Comprehensive Heterogeneity Analysis
#'
#' All-in-one function providing complete heterogeneity assessment including
#' Q-statistic, I², H², tau², prediction intervals, and subgroup analyses.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param method Method for tau² estimation ("REML", "DL", "ML", "EB", "HS", "SJ", "HE", "GENQ")
#' @param moderators Optional matrix or data frame of moderators
#' @param subgroups Optional vector of subgroup indicators
#' @param conf_level Confidence level (default 0.95)
#'
#' @return Object of class "cbamm_heterogeneity" with comprehensive diagnostics
#' @export
#'
#' @examples
#' \dontrun{
#' data(bcg_vaccine)
#' library(metafor)
#' dat <- escalc(measure="OR", ai=tpos, bi=tneg, ci=cpos, di=cneg,
#'               data=bcg_vaccine)
#'
#' # Comprehensive heterogeneity analysis
#' result <- cbamm_heterogeneity(dat$yi, dat$vi)
#' print(result)
#' plot(result)
#' }
cbamm_heterogeneity <- function(yi, vi,
                                method = "REML",
                                moderators = NULL,
                                subgroups = NULL,
                                conf_level = 0.95) {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required. Install with: install.packages('metafor')")
  }

  # Basic meta-analysis
  res <- metafor::rma(yi = yi, vi = vi, method = method)

  # Q-statistic and heterogeneity tests
  Q <- res$QE
  df <- res$k - 1
  Q_pval <- pchisq(Q, df = df, lower.tail = FALSE)

  # I² and H²
  I2 <- max(0, 100 * (Q - df) / Q)
  H2 <- Q / df

  # Tau² and confidence interval
  tau2 <- res$tau2
  tau2_se <- res$se.tau2

  if (!is.null(tau2_se) && tau2_se > 0) {
    tau2_ci <- c(
      max(0, tau2 - qnorm((1 + conf_level)/2) * tau2_se),
      tau2 + qnorm((1 + conf_level)/2) * tau2_se
    )
  } else {
    tau2_ci <- c(NA, NA)
  }

  # R² (proportion of heterogeneity explained) if moderators provided
  R2 <- NULL
  if (!is.null(moderators)) {
    res_mod <- metafor::rma(yi = yi, vi = vi, mods = moderators, method = method)
    R2 <- max(0, 100 * (res$tau2 - res_mod$tau2) / res$tau2)
  }

  # Prediction interval
  pred_int <- predict(res, digits = 5)
  pi_lb <- pred_int$pi.lb
  pi_ub <- pred_int$pi.ub

  # Subgroup analysis if provided
  subgroup_results <- NULL
  if (!is.null(subgroups)) {
    subgroup_results <- .analyze_subgroups(yi, vi, subgroups, method)
  }

  # Heterogeneity interpretation
  interpretation <- .interpret_heterogeneity(I2, tau2, H2)

  # Compile results
  result <- list(
    # Basic stats
    k = res$k,
    estimate = res$beta[1],
    ci_lb = res$ci.lb,
    ci_ub = res$ci.ub,

    # Heterogeneity measures
    Q = Q,
    Q_df = df,
    Q_pval = Q_pval,
    I2 = I2,
    H2 = H2,
    tau2 = tau2,
    tau = sqrt(tau2),
    tau2_ci = tau2_ci,

    # Prediction interval
    pi_lb = pi_lb,
    pi_ub = pi_ub,

    # Model fit
    R2 = R2,

    # Subgroup results
    subgroups = subgroup_results,

    # Interpretation
    interpretation = interpretation,

    # Method
    method = method,
    conf_level = conf_level
  )

  class(result) <- "cbamm_heterogeneity"
  return(result)
}


#' @export
print.cbamm_heterogeneity <- function(x, ...) {
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Comprehensive Heterogeneity Analysis\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat("Studies: ", x$k, "\n")
  cat("Estimation method: ", x$method, "\n\n")

  cat("Overall Effect:\n")
  cat(sprintf("  Estimate: %.4f [%.4f, %.4f]\n", x$estimate, x$ci_lb, x$ci_ub))
  cat(sprintf("  Prediction interval: [%.4f, %.4f]\n\n", x$pi_lb, x$pi_ub))

  cat("Heterogeneity Statistics:\n")
  cat(sprintf("  Q = %.2f, df = %d, p %s\n",
              x$Q, x$Q_df,
              if (x$Q_pval < 0.001) "< 0.001" else sprintf("= %.3f", x$Q_pval)))
  cat(sprintf("  I² = %.1f%% [%s]\n", x$I2, x$interpretation$I2_class))
  cat(sprintf("  H² = %.2f\n", x$H2))
  cat(sprintf("  Tau² = %.4f [%.4f, %.4f]\n", x$tau2, x$tau2_ci[1], x$tau2_ci[2]))
  cat(sprintf("  Tau = %.4f\n\n", x$tau))

  if (!is.null(x$R2)) {
    cat(sprintf("Heterogeneity Explained (R²): %.1f%%\n\n", x$R2))
  }

  cat("Interpretation:\n")
  cat(sprintf("  Heterogeneity level: %s\n", x$interpretation$level))
  cat(sprintf("  Recommendation: %s\n", x$interpretation$recommendation))

  if (!is.null(x$subgroups)) {
    cat("\nSubgroup Analysis:\n")
    cat(sprintf("  Q_between = %.2f, df = %d, p = %.4f\n",
                x$subgroups$Q_between,
                x$subgroups$df_between,
                x$subgroups$p_between))
  }

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}


#' @export
plot.cbamm_heterogeneity <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required")
  }

  # Create heterogeneity breakdown plot
  measures <- data.frame(
    Measure = c("I²", "H²", "Tau²"),
    Value = c(x$I2/100, x$H2/10, x$tau2*10),  # Scaled for visibility
    Label = c(
      sprintf("I² = %.1f%%", x$I2),
      sprintf("H² = %.2f", x$H2),
      sprintf("Tau² = %.4f", x$tau2)
    )
  )

  p <- ggplot2::ggplot(measures, ggplot2::aes(x = Measure, y = Value, fill = Measure)) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = Label), vjust = -0.5) +
    ggplot2::labs(
      title = "Heterogeneity Measures",
      subtitle = sprintf("Q = %.2f, df = %d, p %s",
                        x$Q, x$Q_df,
                        if (x$Q_pval < 0.001) "< 0.001" else sprintf("= %.3f", x$Q_pval)),
      y = "Scaled Value"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")

  print(p)
  invisible(x)
}


#' Interpret Heterogeneity
#'
#' @keywords internal
.interpret_heterogeneity <- function(I2, tau2, H2) {

  # I² classification (Higgins et al., 2003)
  I2_class <- if (I2 < 25) {
    "Low"
  } else if (I2 < 50) {
    "Moderate"
  } else if (I2 < 75) {
    "Substantial"
  } else {
    "Considerable"
  }

  # Overall level
  level <- if (I2 < 40) {
    "Low - Homogeneous"
  } else if (I2 < 60) {
    "Moderate - Some heterogeneity"
  } else if (I2 < 75) {
    "Substantial - Important heterogeneity"
  } else {
    "High - Considerable heterogeneity"
  }

  # Recommendations
  recommendation <- if (I2 < 40) {
    "Fixed-effect model may be appropriate"
  } else if (I2 < 75) {
    "Random-effects model recommended; explore sources of heterogeneity"
  } else {
    "Important heterogeneity detected; thoroughly investigate sources; consider not pooling"
  }

  list(
    I2_class = I2_class,
    level = level,
    recommendation = recommendation
  )
}


#' Analyze Subgroups
#'
#' @keywords internal
.analyze_subgroups <- function(yi, vi, subgroups, method) {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Overall model
  res_overall <- metafor::rma(yi = yi, vi = vi, method = method)

  # Subgroup models
  unique_groups <- unique(subgroups)
  subgroup_results <- list()

  for (g in unique_groups) {
    idx <- subgroups == g
    if (sum(idx) >= 2) {
      res_g <- metafor::rma(yi = yi[idx], vi = vi[idx], method = method)
      subgroup_results[[as.character(g)]] <- list(
        k = res_g$k,
        estimate = res_g$beta[1],
        ci_lb = res_g$ci.lb,
        ci_ub = res_g$ci.ub,
        tau2 = res_g$tau2,
        I2 = max(0, 100 * (res_g$QE - (res_g$k - 1)) / res_g$QE)
      )
    }
  }

  # Test for subgroup differences
  # Fit model with subgroup as moderator
  subgroup_factor <- as.factor(subgroups)
  res_mod <- metafor::rma(yi = yi, vi = vi, mods = ~ subgroup_factor - 1, method = method)

  Q_between <- res_mod$QM
  df_between <- res_mod$m
  p_between <- res_mod$QMp

  list(
    results = subgroup_results,
    Q_between = Q_between,
    df_between = df_between,
    p_between = p_between
  )
}


#' Bayes Factor for Heterogeneity
#'
#' Calculate Bayes Factor comparing heterogeneous vs homogeneous models.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param prior_tau Prior SD for tau (default 0.5)
#'
#' @return Bayes Factor (BF10) favoring heterogeneous model
#' @export
#'
#' @examples
#' \dontrun{
#' data(teacher_expectancy)
#' bf <- cbamm_heterogeneity_bf(teacher_expectancy$yi,
#'                              teacher_expectancy$vi)
#' print(bf)
#' }
cbamm_heterogeneity_bf <- function(yi, vi, prior_tau = 0.5) {

  # Fit homogeneous model (fixed effect)
  weights_fe <- 1 / vi
  estimate_fe <- sum(weights_fe * yi) / sum(weights_fe)
  se_fe <- sqrt(1 / sum(weights_fe))

  # Log-likelihood for homogeneous model
  ll_fe <- sum(dnorm(yi, mean = estimate_fe, sd = sqrt(vi), log = TRUE))

  # Fit heterogeneous model (random effects with REML)
  if (requireNamespace("metafor", quietly = TRUE)) {
    res_re <- metafor::rma(yi = yi, vi = vi, method = "REML")
    tau2 <- res_re$tau2
    estimate_re <- res_re$beta[1]

    # Log-likelihood for heterogeneous model
    vi_star <- vi + tau2
    ll_re <- sum(dnorm(yi, mean = estimate_re, sd = sqrt(vi_star), log = TRUE))

    # Prior probability
    prior_ll <- dnorm(sqrt(tau2), mean = 0, sd = prior_tau, log = TRUE)

    # Bayes Factor (BF10 = heterogeneous / homogeneous)
    BF10 <- exp(ll_re + prior_ll - ll_fe)

  } else {
    stop("Package 'metafor' required for heterogeneity Bayes Factor")
  }

  # Interpretation
  interpretation <- if (BF10 > 100) {
    "Extreme evidence for heterogeneity"
  } else if (BF10 > 30) {
    "Very strong evidence for heterogeneity"
  } else if (BF10 > 10) {
    "Strong evidence for heterogeneity"
  } else if (BF10 > 3) {
    "Moderate evidence for heterogeneity"
  } else if (BF10 > 1) {
    "Weak evidence for heterogeneity"
  } else if (BF10 > 0.33) {
    "Inconclusive"
  } else if (BF10 > 0.1) {
    "Moderate evidence for homogeneity"
  } else {
    "Strong evidence for homogeneity"
  }

  result <- list(
    BF10 = BF10,
    log_BF10 = log(BF10),
    interpretation = interpretation,
    tau2 = tau2,
    ll_fe = ll_fe,
    ll_re = ll_re
  )

  class(result) <- "cbamm_heterogeneity_bf"
  return(result)
}


#' @export
print.cbamm_heterogeneity_bf <- function(x, ...) {
  cat("\nBayes Factor for Heterogeneity\n")
  cat("═══════════════════════════════════════\n\n")

  cat("BF₁₀ (heterogeneous / homogeneous):\n")
  if (x$BF10 > 1000) {
    cat(sprintf("  %.2e\n", x$BF10))
  } else {
    cat(sprintf("  %.2f\n", x$BF10))
  }

  cat(sprintf("  log(BF₁₀) = %.2f\n\n", x$log_BF10))

  cat("Interpretation:\n")
  cat(sprintf("  %s\n", x$interpretation))

  cat(sprintf("\nEstimated Tau² = %.4f\n", x$tau2))

  invisible(x)
}


#' Meta-Regression R² Calculation
#'
#' Calculate proportion of heterogeneity explained by moderators.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param moderators Matrix or data frame of moderators
#' @param method Estimation method
#'
#' @return List with R² and related statistics
#' @export
#'
#' @examples
#' \dontrun{
#' data(teacher_expectancy)
#' moderators <- matrix(teacher_expectancy$weeks, ncol = 1)
#' r2 <- cbamm_metareg_r2(teacher_expectancy$yi,
#'                        teacher_expectancy$vi,
#'                        moderators)
#' print(r2)
#' }
cbamm_metareg_r2 <- function(yi, vi, moderators, method = "REML") {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Model without moderators
  res0 <- metafor::rma(yi = yi, vi = vi, method = method)
  tau2_0 <- res0$tau2

  # Model with moderators
  res1 <- metafor::rma(yi = yi, vi = vi, mods = moderators, method = method)
  tau2_1 <- res1$tau2

  # R²
  R2 <- max(0, 100 * (tau2_0 - tau2_1) / tau2_0)

  # Adjusted R² (accounting for number of moderators)
  k <- length(yi)
  p <- ncol(as.matrix(moderators))
  R2_adj <- max(0, 100 * (1 - (1 - R2/100) * ((k - 1) / (k - p - 1))))

  result <- list(
    R2 = R2,
    R2_adj = R2_adj,
    tau2_without_mods = tau2_0,
    tau2_with_mods = tau2_1,
    tau2_reduction = tau2_0 - tau2_1,
    k = k,
    n_moderators = p
  )

  class(result) <- "cbamm_metareg_r2"
  return(result)
}


#' @export
print.cbamm_metareg_r2 <- function(x, ...) {
  cat("\nMeta-Regression R²\n")
  cat("═══════════════════════════════════════\n\n")

  cat(sprintf("R² = %.1f%%\n", x$R2))
  cat(sprintf("Adjusted R² = %.1f%%\n\n", x$R2_adj))

  cat("Tau² Statistics:\n")
  cat(sprintf("  Without moderators: %.4f\n", x$tau2_without_mods))
  cat(sprintf("  With moderators: %.4f\n", x$tau2_with_mods))
  cat(sprintf("  Reduction: %.4f\n\n", x$tau2_reduction))

  cat(sprintf("Moderators: %d\n", x$n_moderators))
  cat(sprintf("Studies: %d\n", x$k))

  interpretation <- if (x$R2 < 25) {
    "Low - Moderators explain little heterogeneity"
  } else if (x$R2 < 50) {
    "Moderate - Moderators explain some heterogeneity"
  } else if (x$R2 < 75) {
    "Substantial - Moderators explain much heterogeneity"
  } else {
    "High - Moderators explain most heterogeneity"
  }

  cat(sprintf("\nInterpretation: %s\n", interpretation))

  invisible(x)
}


#' Heterogeneity Decomposition
#'
#' Decompose total heterogeneity into within-subgroup and between-subgroup components.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param subgroups Subgroup indicators
#' @param method Estimation method
#'
#' @return List with decomposition results
#' @export
#'
#' @examples
#' \dontrun{
#' # Decompose by study quality
#' decomp <- cbamm_heterogeneity_decomp(yi, vi, subgroups = quality)
#' print(decomp)
#' }
cbamm_heterogeneity_decomp <- function(yi, vi, subgroups, method = "REML") {

  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' is required")
  }

  # Overall heterogeneity
  res_overall <- metafor::rma(yi = yi, vi = vi, method = method)
  Q_total <- res_overall$QE

  # Within-subgroup heterogeneity
  unique_groups <- unique(subgroups)
  Q_within <- 0
  df_within <- 0

  subgroup_stats <- list()

  for (g in unique_groups) {
    idx <- subgroups == g
    if (sum(idx) >= 2) {
      res_g <- metafor::rma(yi = yi[idx], vi = vi[idx], method = method)
      Q_within <- Q_within + res_g$QE
      df_within <- df_within + (res_g$k - 1)

      subgroup_stats[[as.character(g)]] <- list(
        k = res_g$k,
        Q = res_g$QE,
        df = res_g$k - 1,
        tau2 = res_g$tau2
      )
    }
  }

  # Between-subgroup heterogeneity
  Q_between <- Q_total - Q_within
  df_between <- length(unique_groups) - 1

  # P-values
  p_within <- pchisq(Q_within, df = df_within, lower.tail = FALSE)
  p_between <- pchisq(Q_between, df = df_between, lower.tail = FALSE)

  # Proportion of heterogeneity between subgroups
  prop_between <- Q_between / Q_total * 100

  result <- list(
    Q_total = Q_total,
    Q_within = Q_within,
    Q_between = Q_between,
    df_within = df_within,
    df_between = df_between,
    p_within = p_within,
    p_between = p_between,
    prop_between = prop_between,
    subgroup_stats = subgroup_stats
  )

  class(result) <- "cbamm_heterogeneity_decomp"
  return(result)
}


#' @export
print.cbamm_heterogeneity_decomp <- function(x, ...) {
  cat("\nHeterogeneity Decomposition\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Total Heterogeneity:\n")
  cat(sprintf("  Q_total = %.2f\n\n", x$Q_total))

  cat("Decomposition:\n")
  cat(sprintf("  Q_within = %.2f, df = %d, p = %.4f\n",
              x$Q_within, x$df_within, x$p_within))
  cat(sprintf("  Q_between = %.2f, df = %d, p = %.4f\n\n",
              x$Q_between, x$df_between, x$p_between))

  cat(sprintf("Between-subgroup heterogeneity: %.1f%% of total\n\n",
              x$prop_between))

  cat("Subgroup Statistics:\n")
  for (name in names(x$subgroup_stats)) {
    stats <- x$subgroup_stats[[name]]
    cat(sprintf("  %s: k=%d, Q=%.2f, df=%d, tau²=%.4f\n",
                name, stats$k, stats$Q, stats$df, stats$tau2))
  }

  invisible(x)
}
