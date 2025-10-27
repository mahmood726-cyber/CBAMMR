#' Display CBAMM Novelty Notes
#'
#' Print a summary of the key methodological innovations in CBAMM v7.0
#'
#' @return Invisibly returns NULL after printing novelty notes
#' @export
#'
#' @examples
#' cbamm_novelty_notes()
cbamm_novelty_notes <- function() {
  cat("
CBAMM v7.0 novelty (concise):
• Pairwise-first + validator: escalc-based builder for RR/OR/RD/MD/SMD; HR via logHR+SE, HR CIs, or O–E+V.
• Rare-events suite (counts): Peto OR, Mantel–Haenszel OR/RR, GLMM OR/RR (binomial).
• Multivariate: rma.mv with block V (assumed ρ) + exact within-study covariance V for log OR (shared control).
• Publication-bias MA: RoBMA model-averaging* + selection models (weightr) + p-uniform*.
• Measure-aware: printing/PI/plots for ratio vs difference scales, PET–PEESE on model scale with back-transform.
• Extras: Influence/outliers, Begg/Egger, robust M-location, simple p-curve, E-values, spline meta-regression.
• Pipeline maintained: transport weighting, GRADE down-weighting, multiverse, Bayesian stacking — hardened.
(* requires package availability)
")
  invisible(NULL)
}

#' Setup CBAMM Configuration
#'
#' Create a configuration object for CBAMM analysis with all methodological options
#'
#' @param use_transport Logical; enable transportability weighting (default TRUE)
#' @param use_hksj Logical; use Hartung-Knapp-Sidik-Jonkman adjustment (default TRUE)
#' @param use_grade_weighting Logical; apply GRADE-based down-weighting (default TRUE)
#' @param use_bayesian Logical; run Bayesian analysis (default TRUE)
#' @param tau_estimators Character vector of tau² estimators to try (default c("REML", "DL", "PM", "HE", "ML", "EB"))
#' @param export_results Logical; export results to files (default FALSE)
#' @param output_dir Character; directory for exported results (default "cbamm_results")
#' @param transport_truncation Numeric; truncation level for transport weights (default 0.02)
#' @param use_interactive Logical; create interactive plots (default FALSE)
#' @param use_ml Logical; run ML heterogeneity analysis (default FALSE)
#' @param kmeans_k_candidates Integer vector; k candidates for conflict detection (default 2:4)
#' @param effect_measure Character; effect measure - one of "HR", "RR", "OR", "RD", "MD", "SMD" (default "HR")
#' @param continuity_correction Numeric; continuity correction for zero cells (default 0.5)
#' @param continuity_when Character; when to apply CC - "only0" or "all" (default "only0")
#' @param multiarm_strategy Character; multi-arm handling - "keep_cr2" or "split_shared_control" (default "keep_cr2")
#' @param use_rve_as_primary Logical; use RVE-CR2 as primary inference (default FALSE)
#' @param force_rare_events Logical; force rare-events models even if not detected (default FALSE)
#' @param rare_event_models Character vector; which rare-event models to fit (default c("Peto","MH","GLMM"))
#' @param glmm_model Character; GLMM model specification for rma.glmm (default "CM.EL")
#' @param run_mv Logical; run multivariate meta-analysis (default TRUE)
#' @param mv_assumed_rho Numeric; assumed within-study correlation for MV (default 0.50)
#' @param mv_tau_estimator Character; tau² estimator for MV (default "REML")
#' @param mv_rho_grid Numeric vector; rho values for sensitivity analysis (default seq(0, 0.9, by = 0.1))
#' @param exact_cov_logOR Logical; use exact covariance for log OR in MV (default TRUE)
#' @param run_meta_regression Logical; run meta-regression on year (default TRUE)
#' @param meta_regression_df Integer; degrees of freedom for spline (default 3)
#' @param bayes_chains Integer; number of MCMC chains (default 2)
#' @param bayes_iter Integer; total MCMC iterations (default 2000)
#' @param bayes_warmup Integer; warmup iterations (default 1000)
#' @param bayes_priors List or NULL; custom priors for primary Bayesian model (default NULL)
#' @param bayes_priors_alt List or NULL; custom priors for alternative Bayesian model (default NULL)
#'
#' @return A list containing all configuration parameters
#' @export
#'
#' @examples
#' # Default configuration
#' config <- setup_cbamm()
#'
#' # Custom configuration for odds ratio meta-analysis
#' config <- setup_cbamm(
#'   effect_measure = "OR",
#'   force_rare_events = TRUE,
#'   use_bayesian = FALSE
#' )
setup_cbamm <- function(
  use_transport = TRUE,
  use_hksj = TRUE,
  use_grade_weighting = TRUE,
  use_bayesian = TRUE,
  tau_estimators = c("REML", "DL", "PM", "HE", "ML", "EB"),
  export_results = FALSE,
  output_dir = "cbamm_results",
  transport_truncation = 0.02,
  use_interactive = FALSE,
  use_ml = FALSE,
  kmeans_k_candidates = 2:4,
  effect_measure = c("HR","RR","OR","RD","MD","SMD"),
  continuity_correction = 0.5,
  continuity_when = c("only0","all"),
  multiarm_strategy = c("keep_cr2","split_shared_control"),
  use_rve_as_primary = FALSE,
  force_rare_events = FALSE,
  rare_event_models = c("Peto","MH","GLMM"),
  glmm_model = "CM.EL",
  run_mv = TRUE,
  mv_assumed_rho = 0.50,
  mv_tau_estimator = "REML",
  mv_rho_grid = seq(0, 0.9, by = 0.1),
  exact_cov_logOR = TRUE,
  run_meta_regression = TRUE,
  meta_regression_df = 3,
  bayes_chains = 2,
  bayes_iter = 2000,
  bayes_warmup = 1000,
  bayes_priors = NULL,
  bayes_priors_alt = NULL
) {
  effect_measure <- match.arg(effect_measure)
  continuity_when <- match.arg(continuity_when)
  multiarm_strategy <- match.arg(multiarm_strategy)
  list(
    use_transport = use_transport,
    use_hksj = use_hksj,
    use_grade_weighting = use_grade_weighting,
    use_bayesian = use_bayesian,
    tau_estimators = tau_estimators,
    transport_truncation = transport_truncation,
    export_results = export_results,
    output_dir = output_dir,
    use_interactive = use_interactive,
    use_ml = use_ml,
    kmeans_k_candidates = kmeans_k_candidates,
    effect_measure = effect_measure,
    continuity_correction = continuity_correction,
    continuity_when = continuity_when,
    multiarm_strategy = multiarm_strategy,
    use_rve_as_primary = use_rve_as_primary,
    force_rare_events = force_rare_events,
    rare_event_models = rare_event_models,
    glmm_model = glmm_model,
    run_mv = run_mv,
    mv_assumed_rho = mv_assumed_rho,
    mv_tau_estimator = mv_tau_estimator,
    mv_rho_grid = mv_rho_grid,
    exact_cov_logOR = exact_cov_logOR,
    run_meta_regression = run_meta_regression,
    meta_regression_df = meta_regression_df,
    bayes_chains = bayes_chains,
    bayes_iter = bayes_iter,
    bayes_warmup = bayes_warmup,
    bayes_priors = bayes_priors,
    bayes_priors_alt = bayes_priors_alt,
    n_cores = max(1, min(4, parallel::detectCores() - 1)),
    seed = 42
  )
}

#' Install and Check CBAMM Package Dependencies
#'
#' Check which optional features are available based on installed packages
#'
#' @return A list indicating which optional features are available
#' @export
#'
#' @examples
#' \dontrun{
#' features <- install_cbamm_packages()
#' }
install_cbamm_packages <- function() {
  required <- c("metafor","tidyverse","ggplot2","patchwork","coda","splines")
  optional <- list(
    transport = c("WeightIt","cobalt"),
    bayesian  = c("brms","posterior","loo"),
    bayes_alt = c("rjags"),
    rve       = c("clubSandwich"),
    extras    = c("plotly","cluster","weightr","ranger","MASS","puniform","RoBMA")
  )
  missing_required <- setdiff(required, rownames(installed.packages()))
  if (length(missing_required) > 0) {
    message("Required packages missing: ", paste(missing_required, collapse = ", "),
            "\nPlease install them first: install.packages(c(",
            paste(sprintf('"%s"', missing_required), collapse=", "), "))")
    stop("Missing required packages. Aborting.")
  }
  available_features <- list()
  for (feature in names(optional)) {
    pkgs <- optional[[feature]]
    available_features[[feature]] <- all(pkgs %in% rownames(installed.packages()))
    if (available_features[[feature]]) {
      message("✓ ", feature, " feature available")
    } else {
      message("✗ ", feature, " feature disabled (missing: ",
              paste(setdiff(pkgs, rownames(installed.packages())), collapse = ", "), ")")
    }
  }
  available_features
}

#' Initialize CBAMM Environment
#'
#' Load required packages and set up the analysis environment
#'
#' @param config Configuration object from setup_cbamm()
#'
#' @return A list containing config and features availability
#' @export
#'
#' @examples
#' \dontrun{
#' config <- setup_cbamm()
#' env <- initialize_cbamm(config)
#' }
initialize_cbamm <- function(config = setup_cbamm()) {
  suppressPackageStartupMessages({
    requireNamespace("metafor", quietly = TRUE)
    requireNamespace("dplyr", quietly = TRUE)
    requireNamespace("ggplot2", quietly = TRUE)
    requireNamespace("patchwork", quietly = TRUE)
    requireNamespace("coda", quietly = TRUE)
    requireNamespace("splines", quietly = TRUE)
  })
  features <- install_cbamm_packages()
  if (isTRUE(features$transport)) suppressPackageStartupMessages(requireNamespace("WeightIt", quietly = TRUE))
  if (isTRUE(features$bayesian))  suppressPackageStartupMessages({
    requireNamespace("brms", quietly = TRUE)
    requireNamespace("posterior", quietly = TRUE)
    requireNamespace("loo", quietly = TRUE)
  })
  if (isTRUE(features$rve)) suppressPackageStartupMessages(requireNamespace("clubSandwich", quietly = TRUE))
  if (isTRUE(features$extras) && "MASS" %in% rownames(installed.packages()))
    suppressPackageStartupMessages(requireNamespace("MASS", quietly = TRUE))
  if (isTRUE(features$extras) && "RoBMA" %in% rownames(installed.packages()))
    suppressPackageStartupMessages(requireNamespace("RoBMA", quietly = TRUE))
  if (isTRUE(features$extras) && "puniform" %in% rownames(installed.packages()))
    suppressPackageStartupMessages(requireNamespace("puniform", quietly = TRUE))

  set.seed(config$seed)
  suppressWarnings(try(RNGkind(sample.kind = "Rounding"), silent = TRUE))
  list(config = config, features = features)
}
