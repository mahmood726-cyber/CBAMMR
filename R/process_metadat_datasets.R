#!/usr/bin/env Rscript
#' Process metadat Package Datasets for Meta-Learning
#'
#' This script extracts meta-analysis statistics (I², τ², Q) from all
#' datasets in the metadat package for training meta-learning models.
#'
#' @author CBAMMR Development Team
#' @date 2025-10-28

# Note: This is a standalone script for data processing
# It's not part of the package's exported functions
# Using library() is acceptable here since it's a script
# For use in package development/data preparation only
suppressPackageStartupMessages({
  library(metafor)
  library(metadat)
  library(dplyr)
  library(purrr)
  library(jsonlite)
})

#' Detect outcome measure type from dataset
#'
#' @param dat Dataset
#' @return Character string: "OR", "RR", "SMD", "MD", "COR", "HR", "UNKNOWN"
detect_outcome_type <- function(dat) {
  cols <- tolower(names(dat))

  # Check for different outcome measures
  if (any(grepl("^yi$|^logor$|^logit", cols))) {
    return("OR")
  } else if (any(grepl("^smd$|^d$|^g$", cols))) {
    return("SMD")
  } else if (any(grepl("^md$|mean.*diff", cols))) {
    return("MD")
  } else if (any(grepl("^cor$|^r$|fisher", cols))) {
    return("COR")
  } else if (any(grepl("^hr$|hazard", cols))) {
    return("HR")
  } else if (any(grepl("^rr$|log.*rr", cols))) {
    return("RR")
  } else if (any(grepl("^yi$", cols)) && any(grepl("^vi$", cols))) {
    return("GENERIC")
  } else {
    return("UNKNOWN")
  }
}

#' Detect moderators in dataset
#'
#' @param dat Dataset
#' @return Character vector of moderator names
detect_moderators <- function(dat) {
  # Exclude standard meta-analysis columns
  exclude_cols <- c("yi", "vi", "sei", "ci.lb", "ci.ub", "ni", "n",
                   "author", "year", "study", "id", "weights",
                   "logor", "logit", "smd", "md", "cor", "rr", "hr")

  cols <- names(dat)
  moderators <- cols[!tolower(cols) %in% exclude_cols]

  # Filter to columns with reasonable variation
  moderators <- moderators[sapply(dat[moderators], function(x) {
    if (is.numeric(x)) {
      length(unique(na.omit(x))) > 1 && sd(x, na.rm = TRUE) > 0
    } else {
      length(unique(na.omit(x))) > 1 && length(unique(na.omit(x))) < nrow(dat)
    }
  })]

  return(moderators)
}

#' Run meta-analysis and extract statistics
#'
#' @param dat Dataset with yi and vi columns
#' @return List with heterogeneity statistics
run_meta_analysis <- function(dat) {
  tryCatch({
    # Ensure yi and vi exist
    if (!"yi" %in% names(dat) || !"vi" %in% names(dat)) {
      return(NULL)
    }

    # Remove missing data
    dat <- dat[!is.na(dat$yi) & !is.na(dat$vi) & dat$vi > 0, ]

    if (nrow(dat) < 3) {
      return(NULL)  # Need at least 3 studies
    }

    # Fit random-effects model
    fit <- rma(yi = yi, vi = vi, data = dat, method = "REML")

    # Extract statistics
    result <- list(
      k = fit$k,
      pooled_effect = as.numeric(fit$beta),
      ci_lower = as.numeric(fit$ci.lb),
      ci_upper = as.numeric(fit$ci.ub),
      se = as.numeric(fit$se),
      pval = as.numeric(fit$pval),
      tau2 = as.numeric(fit$tau2),
      I2 = as.numeric(fit$I2),
      H2 = as.numeric(fit$H2),
      Q = as.numeric(fit$QE),
      Q_pval = as.numeric(fit$QEp)
    )

    return(result)

  }, error = function(e) {
    return(NULL)
  })
}

#' Test moderator importance
#'
#' @param dat Dataset
#' @param moderator Moderator variable name
#' @return List with moderator test statistics
test_moderator <- function(dat, moderator) {
  tryCatch({
    # Remove missing
    dat_complete <- dat[!is.na(dat[[moderator]]) &
                       !is.na(dat$yi) &
                       !is.na(dat$vi) &
                       dat$vi > 0, ]

    if (nrow(dat_complete) < 4) {
      return(NULL)  # Need at least 4 studies for moderation
    }

    # Check if moderator has variation
    if (is.numeric(dat_complete[[moderator]])) {
      if (sd(dat_complete[[moderator]], na.rm = TRUE) == 0) {
        return(NULL)
      }
    } else if (length(unique(dat_complete[[moderator]])) < 2) {
      return(NULL)
    }

    # Build formula
    formula_str <- paste0("yi ~ ", moderator)

    # Fit model with moderator
    fit <- rma(as.formula(formula_str), vi = vi,
              data = dat_complete, method = "REML")

    result <- list(
      moderator = moderator,
      QM = as.numeric(fit$QM),
      QM_pval = as.numeric(fit$QMp),
      R2 = max(0, as.numeric(fit$R2)),
      significant = as.numeric(fit$QMp) < 0.05
    )

    return(result)

  }, error = function(e) {
    return(NULL)
  })
}

#' Process a single metadat dataset
#'
#' @param dataset_name Name of dataset
#' @return List with all extracted information
process_dataset <- function(dataset_name) {
  cat(sprintf("Processing: %s\n", dataset_name))

  tryCatch({
    # Load dataset
    dat <- get(dataset_name, envir = asNamespace("metadat"))

    if (!is.data.frame(dat) || nrow(dat) < 3) {
      return(NULL)
    }

    # Detect outcome type
    outcome_type <- detect_outcome_type(dat)

    # Detect moderators
    moderators <- detect_moderators(dat)

    # Extract year if available
    year_cols <- names(dat)[grepl("year", names(dat), ignore.case = TRUE)]
    year_value <- if (length(year_cols) > 0) {
      years <- dat[[year_cols[1]]]
      if (is.numeric(years)) {
        median(years, na.rm = TRUE)
      } else {
        NA
      }
    } else {
      NA
    }

    # Run meta-analysis
    ma_stats <- run_meta_analysis(dat)

    if (is.null(ma_stats)) {
      return(NULL)
    }

    # Test moderators
    moderator_results <- list()
    if (length(moderators) > 0 && length(moderators) <= 10) {
      for (mod in moderators) {
        mod_result <- test_moderator(dat, mod)
        if (!is.null(mod_result)) {
          moderator_results[[mod]] <- mod_result
        }
      }
    }

    # Find most important moderator
    important_moderator <- NULL
    if (length(moderator_results) > 0) {
      pvals <- sapply(moderator_results, function(x) x$QM_pval)
      if (any(pvals < 0.05)) {
        important_moderator <- names(which.min(pvals))
      }
    }

    # Compile result
    result <- list(
      dataset_id = dataset_name,
      source = "metadat",
      outcome_measure = outcome_type,
      n_studies = ma_stats$k,
      year = year_value,

      # Heterogeneity statistics (KEY FOR ML)
      I2 = ma_stats$I2,
      tau2 = ma_stats$tau2,
      Q = ma_stats$Q,
      Q_pval = ma_stats$Q_pval,

      # Pooled effect
      pooled_effect = ma_stats$pooled_effect,
      ci_lower = ma_stats$ci_lower,
      ci_upper = ma_stats$ci_upper,
      pval = ma_stats$pval,

      # Moderators
      n_moderators = length(moderators),
      moderators = moderators,
      important_moderator = important_moderator,
      moderator_results = moderator_results
    )

    return(result)

  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
    return(NULL)
  })
}

#' Main function to process all metadat datasets
#'
#' @param output_dir Output directory for results
process_all_metadat <- function(output_dir = "data/metalearning/processed") {
  cat(paste0("=", strrep("=", 79)), "\n")
  cat("Processing metadat Package Datasets\n")
  cat(paste0("=", strrep("=", 79)), "\n\n")

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Get all datasets from metadat
  metadat_data <- data(package = "metadat")
  dataset_names <- metadat_data$results[, "Item"]

  cat(sprintf("Found %d datasets in metadat package\n\n", length(dataset_names)))

  # Process each dataset
  results <- list()
  successes <- 0
  failures <- 0

  for (i in seq_along(dataset_names)) {
    dataset_name <- dataset_names[i]
    result <- process_dataset(dataset_name)

    if (!is.null(result)) {
      results[[dataset_name]] <- result
      successes <- successes + 1
    } else {
      failures <- failures + 1
    }

    # Progress update every 20 datasets
    if (i %% 20 == 0) {
      cat(sprintf("\nProgress: %d/%d (%.1f%%) - Success: %d, Failed: %d\n\n",
                  i, length(dataset_names),
                  100 * i / length(dataset_names),
                  successes, failures))
    }
  }

  cat("\n", strrep("=", 80), "\n")
  cat(sprintf("Processing complete!\n"))
  cat(sprintf("Successful: %d\n", successes))
  cat(sprintf("Failed: %d\n", failures))
  cat(strrep("=", 80), "\n\n")

  # Save results as JSON
  output_file <- file.path(output_dir, "metadat_processed.json")
  write_json(results, output_file, pretty = TRUE, auto_unbox = TRUE)
  cat(sprintf("Saved results to: %s\n", output_file))

  # Generate summary
  summary <- generate_summary(results)
  summary_file <- file.path(output_dir, "metadat_summary.json")
  write_json(summary, summary_file, pretty = TRUE, auto_unbox = TRUE)
  cat(sprintf("Saved summary to: %s\n", summary_file))

  # Generate markdown report
  report_file <- file.path(output_dir, "METADAT_REPORT.md")
  generate_report(results, summary, report_file)
  cat(sprintf("Saved report to: %s\n", report_file))

  return(results)
}

#' Generate summary statistics
#'
#' @param results List of processed datasets
#' @return Summary list
generate_summary <- function(results) {
  # Extract statistics
  I2_values <- sapply(results, function(x) x$I2)
  tau2_values <- sapply(results, function(x) x$tau2)
  k_values <- sapply(results, function(x) x$n_studies)
  outcome_types <- sapply(results, function(x) x$outcome_measure)

  # Count by outcome type
  outcome_counts <- table(outcome_types)

  # Heterogeneity categories
  I2_low <- sum(I2_values < 25, na.rm = TRUE)
  I2_moderate <- sum(I2_values >= 25 & I2_values < 50, na.rm = TRUE)
  I2_substantial <- sum(I2_values >= 50 & I2_values < 75, na.rm = TRUE)
  I2_considerable <- sum(I2_values >= 75, na.rm = TRUE)

  summary <- list(
    total_datasets = length(results),
    outcome_types = as.list(outcome_counts),

    # Study counts
    median_studies = median(k_values, na.rm = TRUE),
    mean_studies = mean(k_values, na.rm = TRUE),
    min_studies = min(k_values, na.rm = TRUE),
    max_studies = max(k_values, na.rm = TRUE),

    # Heterogeneity
    median_I2 = median(I2_values, na.rm = TRUE),
    mean_I2 = mean(I2_values, na.rm = TRUE),
    median_tau2 = median(tau2_values, na.rm = TRUE),
    mean_tau2 = mean(tau2_values, na.rm = TRUE),

    # I² categories
    I2_low = I2_low,
    I2_moderate = I2_moderate,
    I2_substantial = I2_substantial,
    I2_considerable = I2_considerable,

    # Moderators
    with_moderators = sum(sapply(results, function(x) x$n_moderators) > 0),
    with_important_moderators = sum(sapply(results, function(x)
      !is.null(x$important_moderator)))
  )

  return(summary)
}

#' Generate markdown report
#'
#' @param results Processed results
#' @param summary Summary statistics
#' @param output_file Output file path
generate_report <- function(results, summary, output_file) {
  sink(output_file)

  cat("# Metadat Package Processing Report\n\n")
  cat(sprintf("**Generated:** %s\n\n", Sys.time()))
  cat(sprintf("**Total Datasets Processed:** %d\n\n", summary$total_datasets))

  cat("## Summary Statistics\n\n")
  cat(sprintf("- **Median Studies per Dataset:** %.1f\n", summary$median_studies))
  cat(sprintf("- **Mean Studies per Dataset:** %.1f\n", summary$mean_studies))
  cat(sprintf("- **Range:** %d - %d studies\n\n", summary$min_studies, summary$max_studies))

  cat("## Heterogeneity Statistics\n\n")
  cat(sprintf("- **Median I²:** %.1f%%\n", summary$median_I2))
  cat(sprintf("- **Mean I²:** %.1f%%\n", summary$mean_I2))
  cat(sprintf("- **Median τ²:** %.4f\n", summary$median_tau2))
  cat(sprintf("- **Mean τ²:** %.4f\n\n", summary$mean_tau2))

  cat("### I² Categories (Cochrane Handbook)\n\n")
  cat(sprintf("- **Low (0-25%%):** %d datasets\n", summary$I2_low))
  cat(sprintf("- **Moderate (25-50%%):** %d datasets\n", summary$I2_moderate))
  cat(sprintf("- **Substantial (50-75%%):** %d datasets\n", summary$I2_substantial))
  cat(sprintf("- **Considerable (75-100%%):** %d datasets\n\n", summary$I2_considerable))

  cat("## Outcome Measure Types\n\n")
  for (name in names(summary$outcome_types)) {
    cat(sprintf("- **%s:** %d\n", name, summary$outcome_types[[name]]))
  }
  cat("\n")

  cat("## Moderator Analysis\n\n")
  cat(sprintf("- **Datasets with Moderators:** %d\n", summary$with_moderators))
  cat(sprintf("- **Datasets with Significant Moderators:** %d\n\n",
              summary$with_important_moderators))

  cat("## Top 20 Datasets by Heterogeneity (I²)\n\n")
  I2_sorted <- results[order(sapply(results, function(x) x$I2), decreasing = TRUE)]
  for (i in 1:min(20, length(I2_sorted))) {
    ds <- I2_sorted[[i]]
    cat(sprintf("%d. **%s** (I²=%.1f%%, k=%d, %s)\n",
                i, ds$dataset_id, ds$I2, ds$n_studies, ds$outcome_measure))
  }
  cat("\n")

  cat("## Next Steps: Meta-Learning Training\n\n")
  cat("### Features Available:\n")
  cat("- ✅ **I²** (heterogeneity percentage) - PRIMARY TARGET\n")
  cat("- ✅ **τ²** (between-study variance) - PRIMARY TARGET\n")
  cat("- ✅ Number of studies (k)\n")
  cat("- ✅ Outcome measure type\n")
  cat("- ✅ Pooled effect size\n")
  cat("- ✅ Number of moderators\n")
  cat("- ✅ Important moderator (if exists)\n\n")

  cat("### Ready for Machine Learning:\n")
  cat(sprintf("- **Training samples:** %d datasets\n", summary$total_datasets))
  cat("- **Target variable 1:** I² (continuous, 0-100%)\n")
  cat("- **Target variable 2:** τ² (continuous, ≥0)\n")
  cat("- **Features:** outcome_type, n_studies, pooled_effect, n_moderators, etc.\n\n")

  cat("### Recommended Models:\n")
  cat("- Random Forest regression (handles non-linearity, feature interactions)\n")
  cat("- XGBoost (gradient boosting, excellent performance)\n")
  cat("- Neural network (if >200 datasets)\n")
  cat("- Ensemble (stack multiple models)\n\n")

  sink()
}

# Run if called directly
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  output_dir <- if (length(args) > 0) args[1] else "data/metalearning/processed"

  results <- process_all_metadat(output_dir)
}
