#' Meta-Learning Predictions for Heterogeneity
#'
#' These functions use trained machine learning models to predict
#' heterogeneity (I² and τ²) before conducting meta-analysis.
#'
#' @name metalearning
NULL

#' Predict Heterogeneity for a Meta-Analysis
#'
#' Uses trained ML models to predict expected I² and τ² based on
#' dataset characteristics.
#'
#' @param n_studies Number of studies to be included
#' @param outcome_measure Outcome measure type: "OR", "RR", "SMD", "MD", "HR", "COR"
#' @param domain Research domain (e.g., "cardiology", "psychiatry", "oncology")
#' @param year_median Median publication year of studies
#' @param year_range Range of publication years
#' @param pooled_effect Expected pooled effect size (from pilot data)
#' @param ci_width Expected confidence interval width
#' @param total_n Total sample size across all studies
#' @param Q Cochran's Q statistic (optional, will be estimated if not provided)
#' @param model_type Model to use: "rf" (Random Forest) or "xgb" (XGBoost). Default "rf".
#'
#' @return List with predicted I², τ², uncertainty estimates, and recommendations
#'
#' @examples
#' \dontrun{
#' # Predict heterogeneity for planned cardiology meta-analysis
#' pred <- cbamm_predict_heterogeneity(
#'   n_studies = 15,
#'   outcome_measure = "OR",
#'   domain = "cardiology",
#'   year_median = 2020,
#'   year_range = 10,
#'   pooled_effect = 0.75,
#'   ci_width = 0.15,
#'   total_n = 5000
#' )
#'
#' cat("Predicted I²:", pred$predicted_I2, "%\n")
#' cat("Predicted τ²:", pred$predicted_tau2, "\n")
#' cat("Category:", pred$I2_category, "\n")
#' cat("Recommendation:", pred$recommendation, "\n")
#' }
#'
#' @export
cbamm_predict_heterogeneity <- function(n_studies,
                                        outcome_measure,
                                        domain = "cardiology",
                                        year_median = 2020,
                                        year_range = 10,
                                        pooled_effect = 0.5,
                                        ci_width = 0.2,
                                        total_n = n_studies * 100,
                                        Q = n_studies * 2,
                                        model_type = c("rf", "xgb")) {

  # Validate inputs
  model_type <- match.arg(model_type)

  valid_outcomes <- c("OR", "RR", "SMD", "MD", "HR", "COR")
  if (!outcome_measure %in% valid_outcomes) {
    stop("outcome_measure must be one of: ", paste(valid_outcomes, collapse = ", "))
  }

  if (n_studies < 3) {
    stop("n_studies must be at least 3")
  }

  # Build input JSON
  input_data <- list(
    n_studies = as.integer(n_studies),
    outcome_measure = outcome_measure,
    domain = domain,
    year_median = as.integer(year_median),
    year_range = as.integer(year_range),
    pooled_effect = as.numeric(pooled_effect),
    ci_width = as.numeric(ci_width),
    total_n = as.integer(total_n),
    Q = as.numeric(Q),
    model_type = model_type
  )

  input_json <- jsonlite::toJSON(input_data, auto_unbox = TRUE)

  # Find Python script
  package_root <- system.file(package = "CBAMMR")
  if (package_root == "") {
    # Development mode - use current directory
    python_script <- file.path(getwd(), "python", "predict_heterogeneity.py")
  } else {
    python_script <- file.path(package_root, "python", "predict_heterogeneity.py")
  }

  if (!file.exists(python_script)) {
    stop("Python prediction script not found: ", python_script)
  }

  # Call Python script with system2 (more secure than system)
  result_json <- safe_try(
    system2("python3", args = c(python_script, input_json), stdout = TRUE, stderr = TRUE),
    context = "calling Python heterogeneity prediction script",
    return_on_error = NULL
  )

  if (is.null(result_json)) {
    stop("Failed to execute Python prediction script")
  }

  # Parse result
  result <- jsonlite::fromJSON(result_json)

  if (!is.null(result$error)) {
    stop("Prediction error: ", result$error)
  }

  # Add class for printing
  class(result) <- c("cbamm_heterogeneity_prediction", "list")

  return(result)
}


#' Predict Heterogeneity from Pilot Data
#'
#' Convenience function to predict heterogeneity from a pilot meta-analysis
#' dataset using CBAMMR format.
#'
#' @param pilot_data Data frame with pilot studies (minimum 3 studies)
#' @param outcome_measure Outcome measure type
#' @param domain Research domain
#' @param model_type Model to use: "rf" or "xgb"
#'
#' @return List with predictions and recommendations
#'
#' @examples
#' \dontrun{
#' # Create pilot data
#' pilot <- data.frame(
#'   study = c("Study1", "Study2", "Study3"),
#'   effect = c(0.7, 0.8, 0.6),
#'   se = c(0.1, 0.12, 0.11),
#'   n = c(200, 150, 180),
#'   year = c(2018, 2019, 2020)
#' )
#'
#' pred <- cbamm_predict_from_pilot(
#'   pilot_data = pilot,
#'   outcome_measure = "OR",
#'   domain = "cardiology"
#' )
#' }
#'
#' @export
cbamm_predict_from_pilot <- function(pilot_data,
                                     outcome_measure,
                                     domain = "cardiology",
                                     model_type = c("rf", "xgb")) {

  model_type <- match.arg(model_type)

  # Extract characteristics from pilot data
  n_studies <- nrow(pilot_data)

  if (n_studies < 3) {
    stop("Need at least 3 pilot studies for prediction")
  }

  # Get year characteristics
  if ("year" %in% names(pilot_data)) {
    year_median <- median(pilot_data$year, na.rm = TRUE)
    year_range <- diff(range(pilot_data$year, na.rm = TRUE))
  } else {
    year_median <- 2020
    year_range <- 10
  }

  # Get sample size
  if ("n" %in% names(pilot_data)) {
    total_n <- sum(pilot_data$n, na.rm = TRUE)
  } else {
    total_n <- n_studies * 100
  }

  # Compute pooled effect and CI width (simple inverse-variance)
  if (all(c("effect", "se") %in% names(pilot_data))) {
    weights <- 1 / pilot_data$se^2
    pooled_effect <- sum(pilot_data$effect * weights) / sum(weights)

    se_pooled <- sqrt(1 / sum(weights))
    ci_width <- 2 * 1.96 * se_pooled

    # Compute Q
    Q <- sum(weights * (pilot_data$effect - pooled_effect)^2)
  } else {
    pooled_effect <- 0.5
    ci_width <- 0.2
    Q <- n_studies * 2
  }

  # Call main prediction function
  pred <- cbamm_predict_heterogeneity(
    n_studies = n_studies,
    outcome_measure = outcome_measure,
    domain = domain,
    year_median = year_median,
    year_range = max(year_range, 1),
    pooled_effect = pooled_effect,
    ci_width = ci_width,
    total_n = total_n,
    Q = Q,
    model_type = model_type
  )

  return(pred)
}


#' Recommend Sample Size for Meta-Analysis
#'
#' Estimate the number of studies needed to achieve adequate power
#' based on predicted heterogeneity.
#'
#' @param predicted_I2 Predicted I² (from cbamm_predict_heterogeneity)
#' @param effect_size Expected effect size
#' @param power Desired power (default 0.80)
#' @param alpha Significance level (default 0.05)
#'
#' @return Recommended minimum number of studies
#'
#' @examples
#' \dontrun{
#' # After predicting heterogeneity
#' pred <- cbamm_predict_heterogeneity(n_studies = 10, outcome_measure = "OR")
#' n_needed <- cbamm_recommend_sample_size(pred$predicted_I2, effect_size = 0.3)
#' cat("Recommended minimum studies:", n_needed, "\n")
#' }
#'
#' @export
cbamm_recommend_sample_size <- function(predicted_I2,
                                        effect_size = 0.3,
                                        power = 0.80,
                                        alpha = 0.05) {

  # Convert I² to τ² (approximate)
  # Using: τ² ≈ I² / (100 - I²) * typical within-study variance
  typical_var <- 0.05  # Typical within-study variance

  if (predicted_I2 >= 99) {
    tau2 <- 2.0  # Large τ² for very high I²
  } else {
    tau2 <- (predicted_I2 / (100 - predicted_I2)) * typical_var
  }

  # Z-scores for power and alpha
  z_alpha <- qnorm(1 - alpha/2)
  z_beta <- qnorm(power)

  # Sample size calculation accounting for heterogeneity
  # Formula from Borenstein et al. (2009)
  # n = (z_alpha + z_beta)² * (τ² + typical_var) / effect_size²

  n_required <- ((z_alpha + z_beta)^2 * (tau2 + typical_var)) / (effect_size^2)

  # Round up and ensure minimum
  n_required <- ceiling(n_required)
  n_required <- max(n_required, 5)  # Minimum 5 studies

  # Add buffer for high heterogeneity
  if (predicted_I2 > 75) {
    n_required <- ceiling(n_required * 1.5)
  }

  return(as.integer(n_required))
}


#' Print Method for Heterogeneity Predictions
#'
#' @param x Object of class cbamm_heterogeneity_prediction
#' @param ... Additional arguments (ignored)
#'
#' @export
print.cbamm_heterogeneity_prediction <- function(x, ...) {
  cat("\n")
  cat("CBAMMR Meta-Learning Prediction\n")
  cat("=================================\n\n")

  cat(sprintf("Predicted I²:  %.1f%% (± %.1f%%)\n",
              x$predicted_I2, x$I2_uncertainty))
  cat(sprintf("Category:      %s\n", toupper(x$I2_category)))
  cat(sprintf("Predicted τ²:  %.4f (± %.4f)\n\n",
              x$predicted_tau2, x$tau2_uncertainty))

  cat("Interpretation:\n")
  cat(strwrap(x$interpretation, width = 70, prefix = "  "), sep = "\n")
  cat("\n\n")

  cat("Recommendations:\n")
  cat(strwrap(x$recommendation, width = 70, prefix = "  "), sep = "\n")
  cat("\n\n")

  cat(sprintf("Model used: %s\n", toupper(x$model_used)))
  cat("=================================\n")

  invisible(x)
}


#' Summary of Meta-Learning Models
#'
#' Display information about the trained meta-learning models.
#'
#' @return Data frame with model performance metrics
#'
#' @examples
#' \dontrun{
#' model_info <- cbamm_metalearning_info()
#' print(model_info)
#' }
#'
#' @export
cbamm_metalearning_info <- function() {
  # Load evaluation results
  package_root <- system.file(package = "CBAMMR")
  if (package_root == "") {
    results_file <- file.path(getwd(), "data/metalearning/models/evaluation_results.json")
  } else {
    results_file <- file.path(package_root, "data/metalearning/models/evaluation_results.json")
  }

  if (!file.exists(results_file)) {
    stop("Model evaluation results not found")
  }

  results <- jsonlite::fromJSON(results_file)

  # Create summary table
  summary_df <- data.frame(
    Model = c("Random Forest", "XGBoost"),
    Target = c("I²", "I²"),
    MAE = c(results$rf_i2$mae, results$xgb_i2$mae),
    RMSE = c(results$rf_i2$rmse, results$xgb_i2$rmse),
    R2 = c(results$rf_i2$r2, results$xgb_i2$r2)
  )

  tau2_df <- data.frame(
    Model = c("Random Forest", "XGBoost"),
    Target = c("τ²", "τ²"),
    MAE = c(results$rf_tau2$mae, results$xgb_tau2$mae),
    RMSE = c(results$rf_tau2$rmse, results$xgb_tau2$rmse),
    R2 = c(results$rf_tau2$r2, results$xgb_tau2$r2)
  )

  summary_df <- rbind(summary_df, tau2_df)

  cat("\n")
  cat("CBAMMR Meta-Learning Models\n")
  cat("=============================\n\n")
  cat("Training samples: 508 meta-analyses\n")
  cat("Test samples: 77 meta-analyses\n\n")
  print(summary_df, row.names = FALSE)
  cat("\n")
  cat(sprintf("Best I² model: %s (MAE: %.2f%%)\n",
              toupper(results$best_models$i2),
              if (results$best_models$i2 == "rf") results$rf_i2$mae else results$xgb_i2$mae))
  cat(sprintf("Best τ² model: %s (MAE: %.4f)\n",
              toupper(results$best_models$tau2),
              if (results$best_models$tau2 == "rf") results$rf_tau2$mae else results$xgb_tau2$mae))
  cat("\n")

  invisible(summary_df)
}
