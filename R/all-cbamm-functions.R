# Complete CBAMM v7.0 Analysis Pipeline
# This file contains the main run_cbamm_analysis function that orchestrates all analyses

#' Run Complete CBAMM Analysis
#'
#' Main analysis function that runs the full CBAMM v7.0 pipeline including:
#' \itemize{
#'   \item Data validation and preparation
#'   \item Transportability weighting
#'   \item GRADE-based down-weighting
#'   \item Stratified and pooled meta-analyses
#'   \item Robust variance estimation (CR2)
#'   \item Multivariate meta-analysis
#'   \item Rare events methods
#'   \item Publication bias assessment
#'   \item Bayesian analysis
#'   \item Diagnostics and influence analysis
#'   \item Meta-regression
#'   \item Multiverse analysis
#'   \item Comprehensive visualization
#'   \item Manuscript-ready tables
#' }
#'
#' @param data Data frame with study-level data
#' @param target_population List with target population characteristics for transportability
#' @param config Configuration object from setup_cbamm()
#'
#' @return List containing results and analysis data
#' @export
#'
#' @examples
#' \dontrun{
#' # Simulate data
#' data <- simulate_cbamm_data(n_rct = 18, n_obs = 18, n_mr = 8)
#' target_pop <- list(age_mean = 72.0, female_pct = 0.48, bmi_mean = 29.4, charlson = 2.1)
#'
#' # Configure analysis
#' config <- setup_cbamm(
#'   effect_measure = "HR",
#'   use_bayesian = TRUE,
#'   run_mv = TRUE
#' )
#'
#' # Run analysis
#' results <- run_cbamm_analysis(data, target_pop, config)
#'
#' # View results
#' print(results$results$summary_table)
#' cbamm_show_all_plots(results)
#' }
run_cbamm_analysis <- function(data, target_population = NULL, config = setup_cbamm()) {

  cat("========================================\nCBAMM v7.0 Analysis\n========================================\n")
  env <- initialize_cbamm(config); features <- env$features

  cat("\n>> Pre-flight validator\n")
  v <- cbamm_pairwise_validator(data, measure = config$effect_measure)
  if (length(v$issues)) { cat("Issues:\n"); for (m in v$issues) cat(" - ", m, "\n", sep="") }
  if (length(v$notes))  { cat("Notes:\n");  for (m in v$notes)  cat(" - ", m, "\n", sep="") }

  if (!all(c("yi","se") %in% names(data))) {
    message("[pairwise] Deriving effect sizes via prepare_pairwise_effects() ...")
    data <- prepare_pairwise_effects(data, measure = config$effect_measure,
                                     add = config$continuity_correction,
                                     cc_when = config$continuity_when,
                                     multiarm_strategy = config$multiarm_strategy)
  }

  req <- c("study_id","yi","se","study_type"); miss <- setdiff(req, names(data))
  if (length(miss)) stop("Missing required columns: ", paste(miss, collapse=", "))
  if (nrow(data) < 5) warning("Very few studies (n=", nrow(data), ") - results may be unstable")
  data <- data %>% dplyr::mutate(study_type = factor(study_type, levels = c("RCT","OBS","MR"), ordered = FALSE))
  if (any(!is.finite(data$yi)) || any(!is.finite(data$se)) || any(data$se <= 0))
    stop("Non-finite yi/se or non-positive se values detected.")

  cat(sprintf("Dataset: %d studies | by type: %s\n", nrow(data),
              paste(paste(names(table(data$study_type)), table(data$study_type), sep="="), collapse=", ")))
  cat(sprintf("Effect measure: %s\n", config$effect_measure))

  # Keep counts if present for rare-events & exact logOR V
  data <- .standardize_pairwise_cols(data)

  # Transportability
  if (config$use_transport && !is.null(target_population)) {
    cat("\nApplying transportability weighting...\n")
    data$transport_weights <- compute_transport_weights(data, target_population, config$transport_truncation)
    if (all(c("age_mean","female_pct") %in% names(data))) {
      pre_age  <- mean(data$age_mean); post_age <- stats::weighted.mean(data$age_mean, data$transport_weights)
      cat(sprintf("Age balance: %.1f -> %.1f (target %.1f)\n", pre_age, post_age, target_population$age_mean))
    }
  } else data$transport_weights <- rep(1 / nrow(data), nrow(data))

  data$analysis_weights <- compute_analysis_weights(data, data$transport_weights)
  if (config$use_grade_weighting && "grade" %in% names(data)) {
    cat("Applying GRADE-based down-weighting...\n")
    data$analysis_weights_grade <- apply_grade_weighting(data$analysis_weights, data$grade)
  }

  # Analyses
  results <- list()
  results$stratified <- run_stratified_analysis(data, config)
  results$pooled     <- run_pooled_and_rve(data, config, features)
  results$advisor    <- run_adaptive_advisor(data, results$pooled, config)
  results$multiverse <- run_multiverse_analysis(data, config)

  # Rare-events if signaled OR forced
  rare_trigger <- config$force_rare_events || (config$effect_measure %in% c("OR","RR") && any(c("ai","bi","ci","di") %in% names(data)) && v$rare_hint)
  if (rare_trigger) results$rare_events <- run_rare_event_models(data, config)

  # PET–PEESE
  cat("\n=== PET–PEESE (model scale; intercepts) ===\n")
  pp <- pet_peese(data$yi, data$se); tfun <- .cbamm_measure_meta(config$effect_measure)$transf
  cat(sprintf("PET intercept: %.3f (effect %.3f) | PEESE intercept: %.3f (effect %.3f)\n", pp["PET"], tfun(pp["PET"]), pp["PEESE"], tfun(pp["PEESE"])))
  results$pet_peese <- pp

  # Publication bias suite
  results$pub_bias <- run_publication_bias_sensitivity(data)
  results$robma    <- run_robma(data)
  results$puniform <- run_puniform(data)
  results$small_study <- run_small_study_tests(results$pooled$transport)

  # Diagnostics
  results$robust_location <- run_robust_location(data)

  # MV meta (assumed ρ) + optional exact logOR V
  if (isTRUE(config$run_mv) && any(duplicated(data$study_id))) {
    results$mv <- run_mv_meta(data, config, rho = config$mv_assumed_rho)
    results$mv_rho <- run_mv_rho_sensitivity(data, config, rhos = config$mv_rho_grid)
    if (isTRUE(config$exact_cov_logOR) && config$effect_measure=="OR" && all(c("ai","bi","ci","di") %in% names(data))) {
      results$mv_exact <- run_mv_meta_exact_logOR(data, config)
    }
  }

  # ML heterogeneity
  if (isTRUE(config$use_ml)) results$ml <- run_ml_heterogeneity(data)

  # Bayesian
  results$bayesian <- run_bayesian_analysis(data, config, features)

  # p-curve
  results$pcurve <- run_pcurve(data)

  # Influence / outliers
  results$influence <- run_influence(results$pooled$transport)

  # Meta-regression (NS on year)
  if (isTRUE(config$run_meta_regression)) results$meta_regression <- run_meta_regression_ns(data, config)

  # Plots
  results$plots <- create_result_plots(results, data, config)

  # Combined static layout
  if (length(results$plots)) {
    static_plots <- Filter(function(p) inherits(p, "ggplot"), results$plots)
    if (length(static_plots) > 0) {
      cat("\nGenerating combined plot layout...\n")
      layout <- "
      AB
      CD
      EF
      "
      if (requireNamespace("patchwork", quietly = TRUE)) {
         safe_try(print(patchwork::wrap_plots(static_plots) + patchwork::plot_layout(design = layout)), context = "printing patchwork combined layout", warn = FALSE)
      } else {
         message("[plot] patchwork not available, skipping combined layout.")
      }
    } else message("[plot] Only interactive plots generated; skipping static wrap.")
  }

  # Manuscript table
  results$summary_table <- cbamm_make_summary_table(results, data, config)
  if (config$export_results) {
    if (!dir.exists(config$output_dir)) dir.create(config$output_dir, recursive = TRUE)
    saveRDS(results, file.path(config$output_dir, "cbamm_results.rds"))
    readr::write_csv(data, file.path(config$output_dir, "analysis_data.csv"))
    if (!is.null(results$multiverse)) readr::write_csv(results$multiverse, file.path(config$output_dir, "multiverse_results.csv"))
    if (!is.null(results$summary_table)) readr::write_csv(results$summary_table, file.path(config$output_dir, "cbamm_summary_table.csv"))
    cat(sprintf("\nResults exported to: %s/\n", config$output_dir))
  }

  cat("\n========================================\nCBAMM Analysis Complete\n========================================\n")
  invisible(list(results = results, analysis_data = data))
}
