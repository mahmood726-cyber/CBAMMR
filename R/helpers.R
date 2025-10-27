# Helper Functions for User-Friendly Output and Integration

#' Format Meta-Analysis Results for Publication
#'
#' Creates publication-ready text output of meta-analysis results following
#' 2025 journal standards including proper CI notation, GRADE symbols, and
#' standardized reporting.
#'
#' @param results Results object from run_cbamm_analysis()
#' @param data Original analysis data
#' @param include_grade Logical; include GRADE assessment?
#' @param include_fragility Logical; include fragility index?
#' @param include_nnt Logical; include NNT analysis?
#' @param outcome_name Character; name of the outcome for reporting
#'
#' @return List with formatted text strings ready for manuscript
#' @export
#'
#' @examples
#' \dontrun{
#' results <- run_cbamm_analysis(data, target_pop, config)
#' formatted <- cbamm_format_results(results, data,
#'   include_grade = TRUE, outcome_name = "All-cause mortality")
#' cat(formatted$results_text)
#' }
cbamm_format_results <- function(results,
                                 data,
                                 include_grade = TRUE,
                                 include_fragility = TRUE,
                                 include_nnt = TRUE,
                                 outcome_name = "the outcome") {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("dplyr required")
  }

  # Extract main pooled result
  fit <- results$pooled$transport
  if (is.null(fit)) fit <- results$pooled$overall

  measure <- fit$measure
  mm <- .cbamm_measure_meta(measure)
  pred <- metafor::predict(fit, transf = mm$transf)

  # Format effect estimate with proper brackets
  # Parentheses () = conventional CI
  # Square brackets [] = Hartung-Knapp CI
  # Braces {} = other methods
  ci_symbol <- if (!is.null(fit$test) && grepl("knha", fit$test, ignore.case = TRUE)) {
    "["  # Square brackets for HKSJ
  } else {
    "("  # Parentheses for conventional
  }
  ci_symbol_close <- if (ci_symbol == "[") "]" else ")"

  effect_text <- sprintf("%s = %.2f (95%% CI: %s%.2f, %.2f%s)",
                        measure,
                        pred$pred,
                        ci_symbol,
                        pred$ci.lb,
                        pred$ci.ub,
                        ci_symbol_close)

  # Heterogeneity
  i2_text <- sprintf("I² = %.1f%%", fit$I2)
  tau2_text <- sprintf("τ² = %.3f", fit$tau2)

  # Prediction interval
  if (!is.null(pred$pi.lb) && !is.null(pred$pi.ub)) {
    pi_text <- sprintf("95%% prediction interval: %.2f-%.2f", pred$pi.lb, pred$pi.ub)
  } else {
    pi_text <- NULL
  }

  # Sample size
  n_studies <- fit$k
  if ("n1i" %in% names(data) && "n2i" %in% names(data)) {
    n_participants <- sum(data$n1i, na.rm = TRUE) + sum(data$n2i, na.rm = TRUE)
    sample_text <- sprintf("%d studies (n = %s participants)", n_studies, format(n_participants, big.mark = ","))
  } else {
    sample_text <- sprintf("%d studies", n_studies)
  }

  # Build main results paragraph
  main_results <- sprintf(
    "%s were included. The pooled %s, indicating %s heterogeneity.%s",
    sample_text,
    effect_text,
    if (fit$I2 < 25) "low" else if (fit$I2 < 50) "moderate" else if (fit$I2 < 75) "substantial" else "considerable",
    if (!is.null(pi_text)) paste0(" The ", tolower(pi_text), ".") else ""
  )

  # GRADE assessment
  grade_text <- NULL
  if (include_grade) {
    grade <- tryCatch({
      cbamm_grade_profile(results, data, outcome_name = outcome_name)
    }, error = function(e) NULL)

    if (!is.null(grade)) {
      # Convert GRADE rating to symbol notation
      grade_symbol <- switch(grade$final_certainty,
                            "HIGH" = "++++",
                            "MODERATE" = "+++−",
                            "LOW" = "++−−",
                            "VERY LOW" = "+−−−",
                            grade$final_certainty)

      grade_text <- sprintf(
        "GRADE assessment yielded %s (%s) certainty evidence.",
        grade$final_certainty,
        grade_symbol
      )

      # Add downgrade reasons if available
      downgrades <- grade$profile %>%
        dplyr::filter(Assessment %in% c("serious", "very serious"))

      if (nrow(downgrades) > 0) {
        reasons <- paste(tolower(downgrades$Domain), collapse = ", ")
        grade_text <- paste(grade_text,
                           sprintf("Evidence was downgraded for: %s.", reasons))
      }
    }
  }

  # Fragility index
  fragility_text <- NULL
  if (include_fragility && all(c("ai", "bi", "ci", "di") %in% names(data))) {
    fragility <- tryCatch({
      cbamm_fragility_index(results, data)
    }, error = function(e) NULL)

    if (!is.null(fragility) && !is.na(fragility$fragility_index)) {
      interpretation <- if (fragility$fragility_index >= 22) {
        "indicating highly robust findings"
      } else if (fragility$fragility_index >= 10) {
        "indicating moderately robust findings"
      } else if (fragility$fragility_index <= 5) {
        "suggesting fragile findings susceptible to small changes"
      } else {
        "indicating acceptable robustness"
      }

      fragility_text <- sprintf(
        "The fragility index was %d, %s.",
        fragility$fragility_index,
        interpretation
      )
    }
  }

  # NNT analysis
  nnt_text <- NULL
  if (include_nnt && mm$is_ratio) {
    nnt_table <- tryCatch({
      cbamm_nnt_by_baseline_risk(
        results,
        baseline_risks = c(0.01, 0.05, 0.10, 0.20, 0.40),
        measure = measure
      )
    }, error = function(e) NULL)

    if (!is.null(nnt_table)) {
      # Extract min and max NNT for interpretability
      valid_nnt <- nnt_table %>% dplyr::filter(!is.na(nnt), nnt < 1000)

      if (nrow(valid_nnt) > 0) {
        nnt_text <- sprintf(
          "Number needed to treat varied from %d in low-risk patients (%.0f%% baseline risk) to %d in high-risk patients (%.0f%% baseline risk).",
          round(max(valid_nnt$nnt)),
          min(valid_nnt$baseline_risk_pct),
          round(min(valid_nnt$nnt)),
          max(valid_nnt$baseline_risk_pct)
        )
      }
    }
  }

  # Methods text
  methods_text <- sprintf(
    "Meta-analysis was conducted using CBAMMR v%s in R version %s. We used random-effects meta-analysis with %s estimation%s. Heterogeneity was quantified using I² and τ². %s%s%s",
    utils::packageVersion("CBAMMR"),
    paste0(R.version$major, ".", R.version$minor),
    if (!is.null(fit$method)) fit$method else "REML",
    if (!is.null(fit$test) && grepl("knha", fit$test, ignore.case = TRUE)) {
      " and Hartung-Knapp-Sidik-Jonkman adjustments"
    } else {
      ""
    },
    if (!is.null(results$transport_weights)) {
      "Transportability weights were applied using entropy balancing to adjust estimates for the target population. "
    } else {
      ""
    },
    if (include_grade) {
      "Certainty of evidence was assessed using GRADE. "
    } else {
      ""
    },
    if (include_fragility) {
      "Statistical robustness was evaluated using the fragility index. "
    } else {
      ""
    }
  )

  # Statistical reporting text
  statistical_text <- sprintf(
    "Statistical significance was defined as p < 0.05. Results are reported as %s with 95%% confidence intervals%s. Prediction intervals are reported to indicate the range of true effects in future studies.",
    measure,
    if (ci_symbol == "[") " using square brackets to indicate Hartung-Knapp adjustments" else ""
  )

  # Combine all text elements
  results_paragraph <- paste(
    c(main_results, grade_text, fragility_text, nnt_text),
    collapse = " "
  )

  # Return structured output
  list(
    # For Results section
    results_text = results_paragraph,

    # For Methods section
    methods_text = methods_text,
    statistical_methods_text = statistical_text,

    # Individual components
    effect_estimate = effect_text,
    heterogeneity = paste(i2_text, tau2_text, sep = ", "),
    prediction_interval = pi_text,
    grade_assessment = grade_text,
    fragility_index = fragility_text,
    nnt_analysis = nnt_text,

    # For copying to clipboard/Word
    complete_results_section = paste(
      "Results",
      "-------",
      results_paragraph,
      "",
      sep = "\n"
    ),

    complete_methods_section = paste(
      "Statistical Analysis",
      "-------------------",
      methods_text,
      statistical_text,
      "",
      sep = "\n"
    )
  )
}


#' Complete Publication-Ready Workflow
#'
#' Runs a complete meta-analysis with all 2025 reporting standards and
#' generates publication-ready outputs. This is a convenience wrapper that
#' combines run_cbamm_analysis with all reporting and clinical decision functions.
#'
#' @param data Analysis data frame
#' @param target_population Optional target population for transportability
#' @param config Configuration from setup_cbamm()
#' @param outcome_name Character; name of the outcome
#' @param output_dir Directory for all outputs (default: "cbamm_publication_outputs")
#' @param mid Minimal important difference for clinical significance (optional)
#' @param baseline_risk Baseline risk for decision curve analysis (optional)
#'
#' @return List with complete results and all publication outputs
#' @export
#'
#' @examples
#' \dontrun{
#' config <- setup_cbamm(effect_measure = "OR")
#' publication <- cbamm_complete_workflow(
#'   data = my_data,
#'   target_population = list(age_mean = 65, female_pct = 0.52),
#'   config = config,
#'   outcome_name = "All-cause mortality",
#'   mid = 0.10,
#'   baseline_risk = 0.15
#' )
#'
#' # All outputs saved to cbamm_publication_outputs/
#' # Access formatted text:
#' cat(publication$formatted$results_text)
#' }
cbamm_complete_workflow <- function(data,
                                    target_population = NULL,
                                    config,
                                    outcome_name = "the outcome",
                                    output_dir = "cbamm_publication_outputs",
                                    mid = NULL,
                                    baseline_risk = NULL) {

  cat("\n========================================\n")
  cat("CBAMMR Complete Publication Workflow\n")
  cat("========================================\n\n")

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Step 1: Run main analysis
  cat("Step 1/7: Running comprehensive meta-analysis...\n")
  results <- run_cbamm_analysis(
    data = data,
    target_population = target_population,
    config = config
  )

  # Step 2: PRISMA checklist
  cat("Step 2/7: Generating PRISMA 2020 checklist...\n")
  prisma <- cbamm_prisma_checklist(populated = TRUE, results = results)
  readr::write_csv(prisma, file.path(output_dir, "prisma_checklist.csv"))

  # Step 3: GRADE assessment
  cat("Step 3/7: Conducting GRADE evidence assessment...\n")
  grade <- cbamm_grade_profile(results, data, outcome_name = outcome_name)
  readr::write_csv(grade$profile, file.path(output_dir, "grade_profile.csv"))

  # Step 4: Clinical decision-making analyses
  cat("Step 4/7: Running clinical decision analyses...\n")

  # Fragility index
  fragility <- if (all(c("ai", "bi", "ci", "di") %in% names(data))) {
    cbamm_fragility_index(results, data)
  } else {
    NULL
  }

  # NNT by risk
  nnt_table <- if (!is.null(results$pooled$transport$measure) &&
                   results$pooled$transport$measure %in% c("OR", "RR", "HR")) {
    cbamm_nnt_by_baseline_risk(results, c(0.01, 0.05, 0.10, 0.20, 0.40))
  } else {
    NULL
  }
  if (!is.null(nnt_table)) {
    readr::write_csv(nnt_table, file.path(output_dir, "nnt_by_baseline_risk.csv"))
  }

  # Clinical significance
  clinical_sig <- if (!is.null(mid)) {
    cbamm_clinical_significance(results, mid = mid)
  } else {
    NULL
  }

  # Prediction interval threshold
  pi_threshold <- cbamm_prediction_interval_threshold(results)

  # Net clinical benefit
  net_benefit <- if (!is.null(baseline_risk) && !is.null(fragility)) {
    cbamm_net_clinical_benefit(results, data, baseline_risk = baseline_risk)
  } else {
    NULL
  }

  # Step 5: Power analysis
  cat("Step 5/7: Calculating power...\n")
  power <- cbamm_power_analysis(
    effect_size = if (!is.null(results$pooled$transport)) {
      abs(results$pooled$transport$beta[1])
    } else {
      0.3
    },
    tau2 = if (!is.null(results$pooled$transport)) {
      results$pooled$transport$tau2
    } else {
      0.04
    },
    n_studies = nrow(data)
  )

  # Step 6: Format for publication
  cat("Step 6/7: Formatting publication-ready text...\n")
  formatted <- cbamm_format_results(
    results = results,
    data = data,
    include_grade = TRUE,
    include_fragility = !is.null(fragility),
    include_nnt = !is.null(nnt_table),
    outcome_name = outcome_name
  )

  # Save formatted text
  writeLines(
    c(formatted$complete_methods_section,
      "",
      formatted$complete_results_section),
    file.path(output_dir, "manuscript_text.txt")
  )

  # Step 7: Create reproducibility bundle
  cat("Step 7/7: Creating reproducibility bundle...\n")
  bundle_dir <- file.path(output_dir, "reproducibility_bundle")
  cbamm_export_bundle(
    results = results,
    data = data,
    config = config,
    output_dir = bundle_dir,
    include_data = TRUE
  )

  # Summary report
  cat("\n========================================\n")
  cat("WORKFLOW COMPLETE\n")
  cat("========================================\n\n")

  cat(sprintf("All outputs saved to: %s/\n\n", output_dir))
  cat("Files created:\n")
  cat("  ✓ prisma_checklist.csv - PRISMA 2020 compliance\n")
  cat("  ✓ grade_profile.csv - GRADE evidence assessment\n")
  if (!is.null(nnt_table)) {
    cat("  ✓ nnt_by_baseline_risk.csv - Risk-stratified NNT\n")
  }
  cat("  ✓ manuscript_text.txt - Ready-to-use Methods & Results text\n")
  cat("  ✓ reproducibility_bundle/ - Complete OSF/Zenodo bundle\n")
  cat("  ✓ Plots in cbamm_outputs/\n\n")

  cat("Next steps:\n")
  cat("  1. Review manuscript_text.txt for Methods/Results sections\n")
  cat("  2. Upload reproducibility_bundle/ to OSF/Zenodo for DOI\n")
  cat("  3. Include DOI in manuscript supplementary materials\n\n")

  cat("Quick summary:\n")
  cat(sprintf("  • %s\n", formatted$effect_estimate))
  cat(sprintf("  • %s\n", formatted$heterogeneity))
  if (!is.null(grade)) {
    cat(sprintf("  • GRADE: %s certainty\n", grade$final_certainty))
  }
  if (!is.null(fragility)) {
    cat(sprintf("  • Fragility index: %d\n", fragility$fragility_index))
  }
  cat(sprintf("  • Statistical power: %.1f%%\n", power$power * 100))
  cat("\n")

  # Return everything
  invisible(list(
    results = results,
    prisma = prisma,
    grade = grade,
    fragility = fragility,
    nnt_table = nnt_table,
    clinical_significance = clinical_sig,
    pi_threshold = pi_threshold,
    net_benefit = net_benefit,
    power = power,
    formatted = formatted,
    output_directory = output_dir
  ))
}
