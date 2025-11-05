# Advanced Evidence Synthesis Module
# Based on cutting-edge methods from top journals
# Part of CBAMMR v8.13.0 Massive Improvements
#
# References:
# - Welton et al. (2009) Statistics in Medicine - Evidence synthesis
# - Efthimiou et al. (2020) BMJ - Component network meta-analysis
# - Verde & Ohmann (2015) Research Synthesis Methods - Cross-design synthesis
# - Ioannidis (2009) BMJ - Umbrella reviews
# - Elliott et al. (2017) BMJ - Living systematic reviews

#' Component Network Meta-Analysis (CNMA)
#'
#' Performs component network meta-analysis to assess effects of individual
#' components of complex interventions (e.g., multi-component behavioral interventions).
#'
#' @param data Data frame with study-level data
#' @param studyvar Name of study variable
#' @param treatvar Name of treatment variable
#' @param components Character vector of component names
#' @param yi Name of effect size variable
#' @param vi Name of variance variable
#' @param additive Assume additive component effects (default: TRUE)
#' @param interactions Include interaction terms (default: FALSE)
#'
#' @return Object of class "cbamm_cnma" containing:
#'   \item{component_effects}{Main effects of each component}
#'   \item{interaction_effects}{Interaction effects (if included)}
#'   \item{combination_predictions}{Predicted effects for all combinations}
#'   \item{model}{Fitted model}
#'
#' @references
#' Welton, N. J., Caldwell, D. M., Adamopoulos, E., & Vedhara, K. (2009).
#' Mixed treatment comparison meta-analysis of complex interventions:
#' Psychological interventions in coronary heart disease. American Journal of Epidemiology, 169(9), 1158-1165.
#'
#' Efthimiou, O., Rücker, G., Schwarzer, G., Higgins, J., Egger, M., & Salanti, G. (2020).
#' A Mantel-Haenszel model for network meta-analysis of rare events.
#' Statistics in Medicine, 39(16), 2672-2683.
#'
#' @examples
#' \dontrun{
#' # Component NMA for multi-component behavioral intervention
#' # Components: Exercise, Diet, Counseling
#' cnma_result <- cbamm_component_nma(
#'   data = intervention_data,
#'   studyvar = "study",
#'   treatvar = "intervention",
#'   components = c("exercise", "diet", "counseling"),
#'   yi = "effect",
#'   vi = "variance",
#'   additive = TRUE,
#'   interactions = FALSE
#' )
#' print(cnma_result)
#' }
#'
#' @export
cbamm_component_nma <- function(data, studyvar, treatvar, components,
                                yi, vi, additive = TRUE, interactions = FALSE) {

  # Extract variables
  study <- data[[studyvar]]
  treatment <- data[[treatvar]]
  effect <- data[[yi]]
  variance <- data[[vi]]

  # Check which components are present in each treatment
  # Assumes data has binary indicators for each component
  component_matrix <- as.matrix(data[, components])

  if (!all(component_matrix %in% c(0, 1, NA))) {
    stop("Component indicators must be 0/1")
  }

  # Replace NA with 0
  component_matrix[is.na(component_matrix)] <- 0

  # Create design matrix for component effects
  X <- component_matrix

  # Add interaction terms if requested
  if (interactions && ncol(X) >= 2) {
    # All pairwise interactions
    interact_cols <- combn(ncol(X), 2, function(idx) {
      X[, idx[1]] * X[, idx[2]]
    }, simplify = FALSE)

    interact_matrix <- do.call(cbind, interact_cols)
    interact_names <- combn(components, 2, function(names) {
      paste0(names[1], "_x_", names[2])
    }, simplify = TRUE)

    colnames(interact_matrix) <- interact_names
    X <- cbind(X, interact_matrix)
  }

  # Fit meta-regression with components as moderators
  fit <- metafor::rma(yi = effect, vi = variance, mods = X, method = "REML")

  # Extract component effects
  n_components <- length(components)
  component_effects <- data.frame(
    component = components,
    estimate = fit$beta[2:(n_components + 1)],
    se = fit$se[2:(n_components + 1)],
    ci_lower = fit$ci.lb[2:(n_components + 1)],
    ci_upper = fit$ci.ub[2:(n_components + 1)],
    z = fit$zval[2:(n_components + 1)],
    pval = fit$pval[2:(n_components + 1)]
  )

  # Interaction effects if included
  if (interactions && ncol(X) > n_components) {
    n_interactions <- ncol(X) - n_components
    interaction_effects <- data.frame(
      interaction = colnames(X)[(n_components + 1):ncol(X)],
      estimate = fit$beta[(n_components + 2):length(fit$beta)],
      se = fit$se[(n_components + 2):length(fit$se)],
      ci_lower = fit$ci.lb[(n_components + 2):length(fit$ci.lb)],
      ci_upper = fit$ci.ub[(n_components + 2):length(fit$ci.ub)],
      z = fit$zval[(n_components + 2):length(fit$zval)],
      pval = fit$pval[(n_components + 2):length(fit$pval)]
    )
  } else {
    interaction_effects <- NULL
  }

  # Generate predictions for all possible component combinations
  all_combinations <- expand.grid(lapply(1:n_components, function(i) c(0, 1)))
  colnames(all_combinations) <- components

  # Add interaction terms for predictions
  if (interactions && n_components >= 2) {
    interact_combos <- combn(n_components, 2, function(idx) {
      all_combinations[, idx[1]] * all_combinations[, idx[2]]
    }, simplify = FALSE)

    interact_df <- as.data.frame(do.call(cbind, interact_combos))
    colnames(interact_df) <- interact_names
    pred_matrix <- cbind(all_combinations, interact_df)
  } else {
    pred_matrix <- all_combinations
  }

  # Predictions
  preds <- predict(fit, newmods = as.matrix(pred_matrix))

  combination_predictions <- cbind(
    all_combinations,
    data.frame(
      predicted_effect = preds$pred,
      se = preds$se,
      ci_lower = preds$ci.lb,
      ci_upper = preds$ci.ub
    )
  )

  # Sort by predicted effect
  combination_predictions <- combination_predictions[order(-combination_predictions$predicted_effect), ]

  result <- list(
    component_effects = component_effects,
    interaction_effects = interaction_effects,
    combination_predictions = combination_predictions,
    model = fit,
    additive = additive,
    interactions = interactions,
    data = data
  )

  class(result) <- "cbamm_cnma"
  return(result)
}


#' Cross-Design Synthesis
#'
#' Combines evidence from randomized controlled trials (RCTs) and
#' observational studies, accounting for potential bias in observational data.
#'
#' @param data Data frame with studies
#' @param yi Name of effect size variable
#' @param vi Name of variance variable
#' @param design_var Name of design variable ("RCT" or "observational")
#' @param bias_adjustment Method for bias adjustment: "hierarchical", "downweight", or "none"
#' @param rct_weight Relative weight for RCTs vs observational (default: 1, equal weight)
#'
#' @return Object of class "cbamm_cross_design" containing:
#'   \item{combined_estimate}{Pooled estimate across designs}
#'   \item{rct_estimate}{RCT-only estimate}
#'   \item{obs_estimate}{Observational-only estimate}
#'   \item{design_difference}{Difference between designs}
#'   \item{heterogeneity}{Within and between-design heterogeneity}
#'
#' @references
#' Verde, P. E., & Ohmann, C. (2015). Combining randomized and non-randomized evidence
#' in clinical research: A review of methods and applications.
#' Research Synthesis Methods, 6(1), 45-62.
#'
#' Schmitz, S., Adams, R., & Walsh, C. D. (2013). Incorporating data from various trial
#' designs into a mixed treatment comparison model. Statistics in Medicine, 32(17), 2935-2949.
#'
#' @examples
#' \dontrun{
#' cross_design <- cbamm_cross_design_synthesis(
#'   data = all_studies,
#'   yi = "effect",
#'   vi = "variance",
#'   design_var = "study_design",
#'   bias_adjustment = "hierarchical"
#' )
#' print(cross_design)
#' }
#'
#' @export
cbamm_cross_design_synthesis <- function(data, yi, vi, design_var,
                                        bias_adjustment = "hierarchical",
                                        rct_weight = 1) {

  # Extract variables
  effect <- data[[yi]]
  variance <- data[[vi]]
  design <- data[[design_var]]

  # Standardize design labels
  design <- tolower(as.character(design))
  design[grepl("rct|randomized|randomised", design)] <- "rct"
  design[grepl("obs|observational|cohort|case", design)] <- "observational"

  # Separate by design
  rct_idx <- design == "rct"
  obs_idx <- design == "observational"

  n_rct <- sum(rct_idx)
  n_obs <- sum(obs_idx)

  # RCT-only meta-analysis
  if (n_rct > 0) {
    rct_fit <- metafor::rma(yi = effect[rct_idx], vi = variance[rct_idx], method = "REML")
    rct_estimate <- rct_fit$beta[1]
    rct_se <- rct_fit$se
    rct_ci_lower <- rct_fit$ci.lb
    rct_ci_upper <- rct_fit$ci.ub
    rct_tau2 <- rct_fit$tau2
  } else {
    rct_estimate <- NA
    rct_se <- NA
    rct_ci_lower <- NA
    rct_ci_upper <- NA
    rct_tau2 <- NA
  }

  # Observational-only meta-analysis
  if (n_obs > 0) {
    obs_fit <- metafor::rma(yi = effect[obs_idx], vi = variance[obs_idx], method = "REML")
    obs_estimate <- obs_fit$beta[1]
    obs_se <- obs_fit$se
    obs_ci_lower <- obs_fit$ci.lb
    obs_ci_upper <- obs_fit$ci.ub
    obs_tau2 <- obs_fit$tau2
  } else {
    obs_estimate <- NA
    obs_se <- NA
    obs_ci_lower <- NA
    obs_ci_upper <- NA
    obs_tau2 <- NA
  }

  # Test for design difference
  if (n_rct > 0 && n_obs > 0) {
    design_diff <- rct_estimate - obs_estimate
    design_diff_se <- sqrt(rct_se^2 + obs_se^2)
    design_diff_z <- design_diff / design_diff_se
    design_diff_pval <- 2 * pnorm(-abs(design_diff_z))
  } else {
    design_diff <- NA
    design_diff_se <- NA
    design_diff_z <- NA
    design_diff_pval <- NA
  }

  # Combined estimate with bias adjustment
  if (bias_adjustment == "hierarchical") {
    # Hierarchical model: studies nested within design
    design_factor <- factor(design)
    hier_fit <- metafor::rma.mv(
      yi = effect,
      V = variance,
      random = ~ 1 | design_factor / 1:length(effect),
      method = "REML"
    )

    combined_estimate <- hier_fit$beta[1]
    combined_se <- hier_fit$se
    combined_ci_lower <- hier_fit$ci.lb
    combined_ci_upper <- hier_fit$ci.ub

    # Variance components
    tau2_within <- hier_fit$sigma2[1]  # Within design
    tau2_between <- hier_fit$sigma2[2]  # Between design

  } else if (bias_adjustment == "downweight") {
    # Down-weight observational studies
    weights <- ifelse(rct_idx, rct_weight, 1)

    down_fit <- metafor::rma(yi = effect, vi = variance, weights = weights, method = "REML")

    combined_estimate <- down_fit$beta[1]
    combined_se <- down_fit$se
    combined_ci_lower <- down_fit$ci.lb
    combined_ci_upper <- down_fit$ci.ub
    tau2_within <- down_fit$tau2
    tau2_between <- NA

  } else {
    # No bias adjustment - simple pooling
    simple_fit <- metafor::rma(yi = effect, vi = variance, method = "REML")

    combined_estimate <- simple_fit$beta[1]
    combined_se <- simple_fit$se
    combined_ci_lower <- simple_fit$ci.lb
    combined_ci_upper <- simple_fit$ci.ub
    tau2_within <- simple_fit$tau2
    tau2_between <- NA
  }

  result <- list(
    combined_estimate = data.frame(
      estimate = combined_estimate,
      se = combined_se,
      ci_lower = combined_ci_lower,
      ci_upper = combined_ci_upper
    ),
    rct_estimate = data.frame(
      n = n_rct,
      estimate = rct_estimate,
      se = rct_se,
      ci_lower = rct_ci_lower,
      ci_upper = rct_ci_upper,
      tau2 = rct_tau2
    ),
    obs_estimate = data.frame(
      n = n_obs,
      estimate = obs_estimate,
      se = obs_se,
      ci_lower = obs_ci_lower,
      ci_upper = obs_ci_upper,
      tau2 = obs_tau2
    ),
    design_difference = data.frame(
      difference = design_diff,
      se = design_diff_se,
      z = design_diff_z,
      pval = design_diff_pval
    ),
    heterogeneity = data.frame(
      tau2_within_design = tau2_within,
      tau2_between_design = tau2_between
    ),
    bias_adjustment = bias_adjustment
  )

  class(result) <- "cbamm_cross_design"
  return(result)
}


#' Umbrella Review
#'
#' Performs umbrella review (overview of systematic reviews) by synthesizing
#' results from multiple meta-analyses on related topics.
#'
#' @param data Data frame with meta-analysis results
#' @param topic_var Name of topic/comparison variable
#' @param estimate_var Name of pooled estimate variable from each MA
#' @param se_var Name of standard error variable
#' @param n_studies_var Name of variable containing number of studies in each MA
#' @param quality_var Name of quality assessment variable (optional)
#'
#' @return Object of class "cbamm_umbrella" containing:
#'   \item{summary_table}{Summary of all included meta-analyses}
#'   \item{overall_distribution}{Distribution of effects across topics}
#'   \item{quality_assessment}{Quality ratings if available}
#'   \item{heterogeneity_across_mas}{Between-MA heterogeneity}
#'
#' @references
#' Ioannidis, J. P. (2009). Integration of evidence from multiple meta-analyses:
#' A primer on umbrella reviews, treatment networks and multiple treatments meta-analyses.
#' Canadian Medical Association Journal, 181(8), 488-493.
#'
#' Aromataris, E., Fernandez, R., Godfrey, C. M., Holly, C., Khalil, H., & Tungpunkom, P. (2015).
#' Summarizing systematic reviews: Methodological development, conduct and reporting of an
#' umbrella review approach. International Journal of Evidence-Based Healthcare, 13(3), 132-140.
#'
#' @examples
#' \dontrun{
#' umbrella <- cbamm_umbrella_review(
#'   data = meta_analyses,
#'   topic_var = "comparison",
#'   estimate_var = "pooled_effect",
#'   se_var = "se",
#'   n_studies_var = "k",
#'   quality_var = "amstar_score"
#' )
#' print(umbrella)
#' }
#'
#' @export
cbamm_umbrella_review <- function(data, topic_var, estimate_var, se_var,
                                  n_studies_var, quality_var = NULL) {

  # Extract variables
  topic <- data[[topic_var]]
  estimate <- data[[estimate_var]]
  se <- data[[se_var]]
  n_studies <- data[[n_studies_var]]

  n_mas <- length(estimate)

  # Calculate variance
  variance <- se^2

  # Summary table
  summary_table <- data.frame(
    topic = topic,
    estimate = estimate,
    se = se,
    ci_lower = estimate - qnorm(0.975) * se,
    ci_upper = estimate + qnorm(0.975) * se,
    n_studies = n_studies,
    significant = (estimate - qnorm(0.975) * se > 0) | (estimate + qnorm(0.975) * se < 0)
  )

  # Add quality if available
  if (!is.null(quality_var)) {
    summary_table$quality = data[[quality_var]]
  }

  # Overall distribution of effects
  # Weight by precision (inverse variance)
  weights <- 1 / variance

  overall_mean <- weighted.mean(estimate, weights)
  overall_se <- sqrt(1 / sum(weights))

  # Heterogeneity across meta-analyses
  Q <- sum(weights * (estimate - overall_mean)^2)
  df <- n_mas - 1
  Q_pval <- pchisq(Q, df, lower.tail = FALSE)

  I2 <- max(0, (Q - df) / Q) * 100

  # Calculate prediction interval
  tau2 <- max(0, (Q - df) / sum(weights - sum(weights^2) / sum(weights)))
  pi_se <- sqrt(overall_se^2 + tau2)
  pi_lower <- overall_mean - qnorm(0.975) * pi_se
  pi_upper <- overall_mean + qnorm(0.975) * pi_se

  overall_distribution <- data.frame(
    n_meta_analyses = n_mas,
    mean_effect = overall_mean,
    se = overall_se,
    ci_lower = overall_mean - qnorm(0.975) * overall_se,
    ci_upper = overall_mean + qnorm(0.975) * overall_se,
    pi_lower = pi_lower,
    pi_upper = pi_upper,
    Q = Q,
    Q_pval = Q_pval,
    I2 = I2,
    tau2 = tau2
  )

  # Quality assessment summary if available
  if (!is.null(quality_var)) {
    quality_assessment <- data.frame(
      n_high_quality = sum(data[[quality_var]] >= 8, na.rm = TRUE),  # AMSTAR ≥8
      n_moderate_quality = sum(data[[quality_var]] >= 4 & data[[quality_var]] < 8, na.rm = TRUE),
      n_low_quality = sum(data[[quality_var]] < 4, na.rm = TRUE),
      mean_quality = mean(data[[quality_var]], na.rm = TRUE),
      range_quality = paste(range(data[[quality_var]], na.rm = TRUE), collapse = "-")
    )
  } else {
    quality_assessment <- NULL
  }

  # Proportion of significant results
  prop_significant <- mean(summary_table$significant)

  result <- list(
    summary_table = summary_table,
    overall_distribution = overall_distribution,
    quality_assessment = quality_assessment,
    prop_significant = prop_significant,
    interpretation = if (I2 > 75) {
      "Substantial heterogeneity across meta-analyses - interpret with caution"
    } else if (I2 > 50) {
      "Moderate heterogeneity across meta-analyses"
    } else {
      "Low heterogeneity across meta-analyses"
    }
  )

  class(result) <- "cbamm_umbrella"
  return(result)
}


#' Living Systematic Review Framework
#'
#' Sets up framework for living systematic reviews with continual updating
#' as new studies become available.
#'
#' @param initial_data Initial set of studies
#' @param yi Name of effect size variable
#' @param vi Name of variance variable
#' @param date_var Name of date variable (for tracking updates)
#' @param update_threshold Minimum number of new studies to trigger update
#'
#' @return Object of class "cbamm_living_sr" with update infrastructure
#'
#' @references
#' Elliott, J. H., Turner, T., Clavisi, O., Thomas, J., Higgins, J. P., Mavergames, C., & Gruen, R. L. (2014).
#' Living systematic reviews: An emerging opportunity to narrow the evidence-practice gap.
#' PLoS Medicine, 11(2), e1001603.
#'
#' Elliott, J. H., Synnot, A., Turner, T., Simmonds, M., Akl, E. A., McDonald, S., ... & Thomas, J. (2017).
#' Living systematic review: 1. Introduction—the why, what, when, and how.
#' Journal of Clinical Epidemiology, 91, 23-30.
#'
#' @examples
#' \dontrun{
#' living_sr <- cbamm_living_systematic_review(
#'   initial_data = baseline_studies,
#'   yi = "effect",
#'   vi = "variance",
#'   date_var = "pub_date",
#'   update_threshold = 3
#' )
#' print(living_sr)
#'
#' # Later, add new studies
#' updated_sr <- cbamm_lsr_update(living_sr, new_studies)
#' }
#'
#' @export
cbamm_living_systematic_review <- function(initial_data, yi, vi, date_var,
                                           update_threshold = 3) {

  # Initial meta-analysis
  effect <- initial_data[[yi]]
  variance <- initial_data[[vi]]
  dates <- initial_data[[date_var]]

  initial_ma <- metafor::rma(yi = effect, vi = variance, method = "REML")

  # Calculate information (inverse variance of pooled estimate)
  information <- 1 / initial_ma$se^2

  # Create version history
  version_history <- data.frame(
    version = 1,
    date = Sys.Date(),
    n_studies = length(effect),
    estimate = initial_ma$beta[1],
    ci_lower = initial_ma$ci.lb,
    ci_upper = initial_ma$ci.ub,
    I2 = initial_ma$I2,
    information = information,
    studies_added = length(effect)
  )

  result <- list(
    current_ma = initial_ma,
    current_data = initial_data,
    version_history = version_history,
    current_version = 1,
    update_threshold = update_threshold,
    yi = yi,
    vi = vi,
    date_var = date_var,
    last_update = Sys.Date()
  )

  class(result) <- "cbamm_living_sr"
  return(result)
}


#' Update Living Systematic Review
#'
#' Updates a living systematic review with new studies.
#'
#' @param lsr Living SR object from cbamm_living_systematic_review()
#' @param new_data New studies to add
#'
#' @return Updated living SR object
#'
#' @export
cbamm_lsr_update <- function(lsr, new_data) {

  if (!inherits(lsr, "cbamm_living_sr")) {
    stop("lsr must be a cbamm_living_sr object")
  }

  # Combine old and new data
  combined_data <- rbind(lsr$current_data, new_data)

  n_new <- nrow(new_data)

  # Check if update threshold met
  if (n_new < lsr$update_threshold) {
    message(sprintf("Only %d new studies (threshold: %d). Not updating.", n_new, lsr$update_threshold))
    return(lsr)
  }

  # Updated meta-analysis
  effect <- combined_data[[lsr$yi]]
  variance <- combined_data[[lsr$vi]]

  updated_ma <- metafor::rma(yi = effect, vi = variance, method = "REML")

  # Calculate change from previous version
  prev_estimate <- lsr$current_ma$beta[1]
  change <- updated_ma$beta[1] - prev_estimate

  # Information
  information <- 1 / updated_ma$se^2

  # Add to version history
  new_version <- lsr$current_version + 1

  new_history_row <- data.frame(
    version = new_version,
    date = Sys.Date(),
    n_studies = length(effect),
    estimate = updated_ma$beta[1],
    ci_lower = updated_ma$ci.lb,
    ci_upper = updated_ma$ci.ub,
    I2 = updated_ma$I2,
    information = information,
    studies_added = n_new,
    change_from_previous = change
  )

  updated_history <- rbind(lsr$version_history, new_history_row)

  # Update object
  lsr$current_ma <- updated_ma
  lsr$current_data <- combined_data
  lsr$version_history <- updated_history
  lsr$current_version <- new_version
  lsr$last_update <- Sys.Date()

  message(sprintf("Living SR updated to version %d (+%d studies)", new_version, n_new))

  return(lsr)
}


# S3 Methods ----

#' @export
print.cbamm_cnma <- function(x, ...) {
  cat("\n=== Component Network Meta-Analysis ===\n\n")

  cat(sprintf("Model: %s\n", ifelse(x$additive, "Additive", "Non-additive")))
  cat(sprintf("Interactions: %s\n\n", ifelse(x$interactions, "Included", "Not included")))

  cat("Component Effects:\n")
  print(x$component_effects, digits = 3, row.names = FALSE)

  if (!is.null(x$interaction_effects)) {
    cat("\nInteraction Effects:\n")
    print(x$interaction_effects, digits = 3, row.names = FALSE)
  }

  cat("\n\nTop 5 Predicted Component Combinations:\n")
  print(head(x$combination_predictions, 5), digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_cross_design <- function(x, ...) {
  cat("\n=== Cross-Design Evidence Synthesis ===\n\n")

  cat(sprintf("Bias adjustment method: %s\n\n", x$bias_adjustment))

  cat("RCT Evidence:\n")
  print(x$rct_estimate, digits = 3, row.names = FALSE)

  cat("\nObservational Evidence:\n")
  print(x$obs_estimate, digits = 3, row.names = FALSE)

  cat("\nDesign Difference (RCT - Observational):\n")
  print(x$design_difference, digits = 3, row.names = FALSE)

  cat("\nCombined Estimate (All Studies):\n")
  print(x$combined_estimate, digits = 3, row.names = FALSE)

  cat("\nHeterogeneity:\n")
  print(x$heterogeneity, digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_umbrella <- function(x, ...) {
  cat("\n=== Umbrella Review ===\n\n")

  cat(sprintf("Number of meta-analyses: %d\n", x$overall_distribution$n_meta_analyses))
  cat(sprintf("Proportion with significant results: %.1f%%\n\n", x$prop_significant * 100))

  cat("Overall Distribution of Effects:\n")
  print(x$overall_distribution, digits = 3, row.names = FALSE)

  if (!is.null(x$quality_assessment)) {
    cat("\n\nQuality Assessment:\n")
    print(x$quality_assessment, digits = 1, row.names = FALSE)
  }

  cat("\n\nInterpretation:\n")
  cat(sprintf("  %s\n", x$interpretation))

  cat("\n\nSummary Table (first 10 meta-analyses):\n")
  print(head(x$summary_table, 10), digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_living_sr <- function(x, ...) {
  cat("\n=== Living Systematic Review ===\n\n")

  cat(sprintf("Current version: %d\n", x$current_version))
  cat(sprintf("Last updated: %s\n", x$last_update))
  cat(sprintf("Total studies: %d\n", x$current_ma$k))
  cat(sprintf("Update threshold: %d studies\n\n", x$update_threshold))

  cat("Current Estimate:\n")
  cat(sprintf("  Effect: %.3f (95%% CI: [%.3f, %.3f])\n",
              x$current_ma$beta[1], x$current_ma$ci.lb, x$current_ma$ci.ub))
  cat(sprintf("  I²: %.1f%%, τ²: %.3f\n\n", x$current_ma$I2, x$current_ma$tau2))

  cat("Version History:\n")
  print(x$version_history, digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}
