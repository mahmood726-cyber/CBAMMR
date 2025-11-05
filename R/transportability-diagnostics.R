#' Transportability Diagnostic Functions
#'
#' Helper functions to assess whether transportability adjustment is appropriate
#' and to diagnose potential issues with transportability weighting

#' Check if Transportability is Appropriate
#'
#' Assesses whether transportability adjustment is likely to be beneficial
#' for a given meta-analysis and target population.
#'
#' @param data Data frame with study-level covariates
#' @param target_population List with target population characteristics
#' @param min_studies Minimum number of studies required (default: 10)
#' @param max_extrapolation Maximum allowable extrapolation in SDs (default: 2)
#'
#' @return List with recommendation and diagnostic information
#' @export
#'
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   study = 1:15,
#'   age_mean = rnorm(15, 55, 5),
#'   female_pct = runif(15, 0.4, 0.6),
#'   bmi_mean = rnorm(15, 27, 3),
#'   charlson = rpois(15, 2)
#' )
#'
#' target <- list(age_mean = 70, female_pct = 0.65, bmi_mean = 30, charlson = 4)
#'
#' diagnostics <- check_transportability(data, target)
#' print(diagnostics$recommendation)
#' }
check_transportability <- function(data,
                                   target_population,
                                   min_studies = 10,
                                   max_extrapolation = 2) {

  # Check 1: Sufficient sample size
  n_studies <- nrow(data)
  sufficient_n <- n_studies >= min_studies

  # Check 2: Required covariates present
  required_covs <- c("age_mean", "female_pct", "bmi_mean", "charlson")
  available_covs <- required_covs %in% names(data)
  all_covs_present <- all(available_covs)
  missing_covs <- required_covs[!available_covs]

  # Check 3: Target population differs from sample
  if (all_covs_present) {
    # Calculate standardized differences
    std_diffs <- sapply(required_covs, function(cov) {
      sample_mean <- mean(data[[cov]], na.rm = TRUE)
      sample_sd <- sd(data[[cov]], na.rm = TRUE)
      target_val <- target_population[[cov]]

      if (sample_sd > 0) {
        abs(target_val - sample_mean) / sample_sd
      } else {
        0
      }
    })

    max_std_diff <- max(std_diffs)
    target_differs <- max_std_diff > 0.5  # Cohen's medium effect
    extreme_extrapolation <- max_std_diff > max_extrapolation
  } else {
    std_diffs <- NULL
    max_std_diff <- NA
    target_differs <- FALSE
    extreme_extrapolation <- FALSE
  }

  # Check 4: Effect heterogeneity exists (if yi, vi provided)
  if (all(c("yi", "vi") %in% names(data))) {
    tryCatch({
      fit <- metafor::rma(yi, vi, data = data, method = "REML")
      i2 <- fit$I2
      heterogeneity_present <- i2 > 50
    }, error = function(e) {
      i2 <- NA
      heterogeneity_present <- FALSE
    })
  } else {
    i2 <- NA
    heterogeneity_present <- NA
  }

  # Overall recommendation
  issues <- character(0)
  warnings <- character(0)

  if (!sufficient_n) {
    issues <- c(issues, sprintf("Small sample size (n=%d, recommend ≥%d)",
                               n_studies, min_studies))
  }

  if (!all_covs_present) {
    issues <- c(issues, sprintf("Missing covariates: %s",
                               paste(missing_covs, collapse = ", ")))
  }

  if (!target_differs) {
    warnings <- c(warnings, "Target population similar to sample (transportability may not be needed)")
  }

  if (extreme_extrapolation) {
    issues <- c(issues, sprintf("Extreme extrapolation (%.2f SDs, max recommended: %.1f)",
                               max_std_diff, max_extrapolation))
  }

  if (!is.na(heterogeneity_present) && !heterogeneity_present) {
    warnings <- c(warnings, sprintf("Low heterogeneity (I²=%.1f%%, transportability may not help)",
                                   i2))
  }

  # Final recommendation
  if (length(issues) > 0) {
    recommendation <- "NOT RECOMMENDED"
    reason <- paste(issues, collapse="; ")
  } else if (length(warnings) > 0 && !target_differs) {
    recommendation <- "OPTIONAL (may not improve estimates)"
    reason <- paste(warnings, collapse = "; ")
  } else {
    recommendation <- "RECOMMENDED"
    reason <- "All criteria met for transportability adjustment"
  }

  # Return diagnostic information
  list(
    recommendation = recommendation,
    reason = reason,
    checks = list(
      sufficient_sample = sufficient_n,
      all_covariates = all_covs_present,
      target_differs = target_differs,
      heterogeneity_present = heterogeneity_present,
      extreme_extrapolation = extreme_extrapolation
    ),
    metrics = list(
      n_studies = n_studies,
      missing_covariates = missing_covs,
      standardized_differences = std_diffs,
      max_std_diff = max_std_diff,
      i2 = i2
    ),
    issues = issues,
    warnings = warnings
  )
}


#' Plot Sample vs Target Population
#'
#' Visualize how target population compares to study sample distributions
#'
#' @param data Data frame with study-level covariates
#' @param target_population List with target population characteristics
#' @param weights Optional transportability weights to show
#'
#' @return ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' plot_sample_vs_target(data, target)
#' }
plot_sample_vs_target <- function(data, target_population, weights = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' required for plotting")
  }

  required_covs <- c("age_mean", "female_pct", "bmi_mean", "charlson")
  available <- required_covs[required_covs %in% names(data)]

  if (length(available) == 0) {
    stop("No transportability covariates found in data")
  }

  # Prepare data for plotting
  plot_data <- lapply(available, function(cov) {
    target_val <- target_population[[cov]]

    data.frame(
      covariate = cov,
      value = data[[cov]],
      weight = if (!is.null(weights)) weights else rep(1/nrow(data), nrow(data)),
      target = target_val
    )
  })

  plot_data <- do.call(rbind, plot_data)

  # Covariate labels
  cov_labels <- c(
    age_mean = "Age (years)",
    female_pct = "Female (%)",
    bmi_mean = "BMI (kg/m²)",
    charlson = "Charlson Index"
  )

  plot_data$covariate_label <- cov_labels[plot_data$covariate]

  # Create plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = value)) +
    ggplot2::geom_histogram(ggplot2::aes(weight = weight), bins = 15,
                           fill = "steelblue", alpha = 0.7) +
    ggplot2::geom_vline(ggplot2::aes(xintercept = target),
                       color = "red", linetype = "dashed", size = 1) +
    ggplot2::facet_wrap(~covariate_label, scales = "free") +
    ggplot2::labs(
      title = "Study Sample vs Target Population",
      subtitle = "Red line = Target population | Blue = Study sample distribution",
      x = "Covariate Value",
      y = if (!is.null(weights)) "Weighted Frequency" else "Frequency"
    ) +
    ggplot2::theme_minimal()

  p
}


#' Assess Covariate Balance After Weighting
#'
#' Calculate and display covariate balance achieved by transportability weights
#'
#' @param data Data frame with study-level covariates
#' @param target_population List with target population characteristics
#' @param weights Transportability weights
#'
#' @return Data frame with balance statistics
#' @export
#'
#' @examples
#' \dontrun{
#' weights <- compute_transport_weights(data, target)
#' balance <- assess_covariate_balance(data, target, weights)
#' print(balance)
#' }
assess_covariate_balance <- function(data, target_population, weights) {
  required_covs <- c("age_mean", "female_pct", "bmi_mean", "charlson")
  available <- required_covs[required_covs %in% names(data)]

  balance <- lapply(available, function(cov) {
    # Unweighted statistics
    unweighted_mean <- mean(data[[cov]], na.rm = TRUE)
    unweighted_sd <- sd(data[[cov]], na.rm = TRUE)

    # Weighted statistics
    weighted_mean <- sum(weights * data[[cov]]) / sum(weights)

    # Target
    target_val <- target_population[[cov]]

    # Standardized differences
    std_diff_unweighted <- if (unweighted_sd > 0) {
      abs(unweighted_mean - target_val) / unweighted_sd
    } else {
      0
    }

    std_diff_weighted <- if (unweighted_sd > 0) {
      abs(weighted_mean - target_val) / unweighted_sd
    } else {
      0
    }

    # Percent error
    pct_error_unweighted <- abs(unweighted_mean - target_val) / target_val * 100
    pct_error_weighted <- abs(weighted_mean - target_val) / target_val * 100

    data.frame(
      covariate = cov,
      target = target_val,
      unweighted_mean = unweighted_mean,
      weighted_mean = weighted_mean,
      std_diff_unweighted = std_diff_unweighted,
      std_diff_weighted = std_diff_weighted,
      pct_error_unweighted = pct_error_unweighted,
      pct_error_weighted = pct_error_weighted,
      balance_achieved = std_diff_weighted < 0.1  # <0.1 SD is good balance
    )
  })

  balance_df <- do.call(rbind, balance)

  # Add summary
  attr(balance_df, "summary") <- list(
    all_balanced = all(balance_df$balance_achieved),
    mean_std_diff_unweighted = mean(balance_df$std_diff_unweighted),
    mean_std_diff_weighted = mean(balance_df$std_diff_weighted),
    improvement = mean(balance_df$std_diff_unweighted - balance_df$std_diff_weighted)
  )

  balance_df
}


#' Diagnose Transportability Weight Issues
#'
#' Identify potential problems with transportability weights
#'
#' @param weights Vector of transportability weights
#' @param data Data frame (for sample size context)
#'
#' @return List with diagnostic information
#' @export
#'
#' @examples
#' \dontrun{
#' weights <- compute_transport_weights(data, target)
#' diagnostics <- diagnose_weights(weights, data)
#' print(diagnostics$issues)
#' }
diagnose_weights <- function(weights, data = NULL) {
  n <- length(weights)

  # Calculate effective sample size
  ess <- sum(weights)^2 / sum(weights^2)
  ess_pct <- ess / n * 100

  # Weight distribution
  min_weight <- min(weights)
  max_weight <- max(weights)
  weight_ratio <- max_weight / min_weight
  cv <- sd(weights) / mean(weights) * 100  # Coefficient of variation

  # Identify issues
  issues <- character(0)
  warnings <- character(0)

  # Check 1: Extreme weights
  if (weight_ratio > 100) {
    issues <- c(issues, sprintf("Very extreme weight ratio (%.1fx)", weight_ratio))
  } else if (weight_ratio > 20) {
    warnings <- c(warnings, sprintf("High weight ratio (%.1fx)", weight_ratio))
  }

  # Check 2: Effective sample size
  if (ess_pct < 50) {
    issues <- c(issues, sprintf("Low effective sample size (%.1f%% of original)",
                               ess_pct))
  } else if (ess_pct < 70) {
    warnings <- c(warnings, sprintf("Moderate effective sample size (%.1f%%)",
                                   ess_pct))
  }

  # Check 3: High variability
  if (cv > 100) {
    issues <- c(issues, "High weight variability (CV > 100%)")
  }

  # Check 4: Truncation may be needed
  if (weight_ratio > 50 && ess_pct < 60) {
    warnings <- c(warnings, "Consider increasing truncation parameter")
  }

  # Overall assessment
  if (length(issues) > 0) {
    assessment <- "PROBLEMATIC WEIGHTS"
  } else if (length(warnings) > 0) {
    assessment <- "ACCEPTABLE WITH CAUTION"
  } else {
    assessment <- "GOOD WEIGHTS"
  }

  list(
    assessment = assessment,
    metrics = list(
      n = n,
      effective_sample_size = ess,
      ess_percentage = ess_pct,
      min_weight = min_weight,
      max_weight = max_weight,
      weight_ratio = weight_ratio,
      coefficient_of_variation = cv
    ),
    issues = issues,
    warnings = warnings
  )
}


#' Print Transportability Report
#'
#' Generate comprehensive diagnostic report for transportability analysis
#'
#' @param data Data frame with study-level covariates and effect sizes
#' @param target_population List with target population characteristics
#' @param weights Optional pre-computed weights
#'
#' @return Invisibly returns list with all diagnostic information
#' @export
#'
#' @examples
#' \dontrun{
#' transportability_report(data, target)
#' }
transportability_report <- function(data, target_population, weights = NULL) {
  cat("\n")
  cat("================================================================\n")
  cat("TRANSPORTABILITY DIAGNOSTIC REPORT\n")
  cat("================================================================\n\n")

  # Check 1: Is transportability appropriate?
  cat("1. APPROPRIATENESS ASSESSMENT\n")
  cat("----------------------------------------------------------------\n")
  check <- check_transportability(data, target_population)
  cat(sprintf("Recommendation: %s\n", check$recommendation))
  cat(sprintf("Reason: %s\n\n", check$reason))

  if (length(check$issues) > 0) {
    cat("Issues:\n")
    for (issue in check$issues) {
      cat(sprintf("  ✗ %s\n", issue))
    }
    cat("\n")
  }

  if (length(check$warnings) > 0) {
    cat("Warnings:\n")
    for (warning in check$warnings) {
      cat(sprintf("  ⚠ %s\n", warning))
    }
    cat("\n")
  }

  cat("Metrics:\n")
  cat(sprintf("  Studies: %d\n", check$metrics$n_studies))
  if (!is.na(check$metrics$i2)) {
    cat(sprintf("  I² heterogeneity: %.1f%%\n", check$metrics$i2))
  }
  if (!is.null(check$metrics$standardized_differences)) {
    cat("  Standardized differences (target vs sample):\n")
    for (cov in names(check$metrics$standardized_differences)) {
      cat(sprintf("    %s: %.2f SD\n", cov,
                 check$metrics$standardized_differences[[cov]]))
    }
  }
  cat("\n")

  # Check 2: Weight quality (if weights provided)
  if (!is.null(weights)) {
    cat("2. WEIGHT QUALITY ASSESSMENT\n")
    cat("----------------------------------------------------------------\n")
    weight_diag <- diagnose_weights(weights, data)
    cat(sprintf("Assessment: %s\n\n", weight_diag$assessment))

    cat("Metrics:\n")
    cat(sprintf("  Effective sample size: %.1f (%.1f%% of n=%d)\n",
               weight_diag$metrics$effective_sample_size,
               weight_diag$metrics$ess_percentage,
               weight_diag$metrics$n))
    cat(sprintf("  Weight range: %.4f to %.4f\n",
               weight_diag$metrics$min_weight,
               weight_diag$metrics$max_weight))
    cat(sprintf("  Weight ratio: %.1fx\n",
               weight_diag$metrics$weight_ratio))
    cat(sprintf("  Coefficient of variation: %.1f%%\n\n",
               weight_diag$metrics$coefficient_of_variation))

    if (length(weight_diag$issues) > 0) {
      cat("Issues:\n")
      for (issue in weight_diag$issues) {
        cat(sprintf("  ✗ %s\n", issue))
      }
      cat("\n")
    }

    if (length(weight_diag$warnings) > 0) {
      cat("Warnings:\n")
      for (warning in weight_diag$warnings) {
        cat(sprintf("  ⚠ %s\n", warning))
      }
      cat("\n")
    }

    # Check 3: Covariate balance
    cat("3. COVARIATE BALANCE\n")
    cat("----------------------------------------------------------------\n")
    balance <- assess_covariate_balance(data, target_population, weights)
    balance_summary <- attr(balance, "summary")

    cat(sprintf("Overall balance: %s\n\n",
               if (balance_summary$all_balanced) "ACHIEVED" else "NOT FULLY ACHIEVED"))

    cat("Standardized differences:\n")
    cat(sprintf("  Before weighting: %.3f (average)\n",
               balance_summary$mean_std_diff_unweighted))
    cat(sprintf("  After weighting:  %.3f (average)\n",
               balance_summary$mean_std_diff_weighted))
    cat(sprintf("  Improvement:      %.3f SD\n\n",
               balance_summary$improvement))

    cat("Per covariate:\n")
    for (i in 1:nrow(balance)) {
      cat(sprintf("  %s: %.3f → %.3f %s\n",
                 balance$covariate[i],
                 balance$std_diff_unweighted[i],
                 balance$std_diff_weighted[i],
                 if (balance$balance_achieved[i]) "✓" else "✗"))
    }
    cat("\n")
  }

  cat("================================================================\n")
  cat("END OF REPORT\n")
  cat("================================================================\n\n")

  # Return all diagnostic info invisibly
  invisible(list(
    appropriateness = check,
    weight_quality = if (!is.null(weights)) weight_diag else NULL,
    covariate_balance = if (!is.null(weights)) balance else NULL
  ))
}
