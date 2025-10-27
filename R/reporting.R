# Reporting and Reproducibility Functions for CBAMMR
# Implements PRISMA 2020, GRADE, and reproducibility standards

#' Generate PRISMA 2020 Checklist
#'
#' Creates a PRISMA 2020 compliant checklist to guide systematic review reporting.
#' Returns a data frame with 27 items covering title, abstract, introduction,
#' methods, results, discussion, and funding.
#'
#' @param populated Logical; if TRUE, attempts to auto-populate from results
#' @param results Optional results object from run_cbamm_analysis()
#'
#' @return Data frame with PRISMA checklist items
#' @export
#'
#' @examples
#' \dontrun{
#' checklist <- cbamm_prisma_checklist(populated = FALSE)
#' # Or auto-populate from analysis:
#' checklist <- cbamm_prisma_checklist(populated = TRUE, results = my_results)
#' }
cbamm_prisma_checklist <- function(populated = FALSE, results = NULL) {

  sections <- c(
    "Title", "Abstract", "Abstract", "Abstract", "Abstract", "Abstract",
    "Introduction", "Introduction",
    "Methods", "Methods", "Methods", "Methods", "Methods", "Methods", "Methods",
    "Methods", "Methods", "Methods", "Methods",
    "Results", "Results", "Results", "Results", "Results",
    "Discussion", "Discussion", "Discussion",
    "Other"
  )

  items <- c(
    "Title: Identify report as systematic review",
    "Structured summary: Objectives, eligibility, sources, methods, results",
    "Abstract: Background/rationale",
    "Abstract: Objectives with PICO",
    "Abstract: Data sources",
    "Abstract: Main results with certainty",
    "Rationale for review",
    "Explicit objectives/questions with PICO",
    "Eligibility criteria",
    "Information sources",
    "Search strategy for at least one database",
    "Selection process",
    "Data collection process",
    "Data items sought",
    "Risk of bias assessment methods",
    "Effect measures",
    "Synthesis methods",
    "Reporting bias assessment",
    "Certainty assessment (e.g., GRADE)",
    "Study selection results with reasons",
    "Study characteristics",
    "Risk of bias results",
    "Results of syntheses",
    "Results of reporting bias assessment",
    "Discussion of limitations",
    "Interpretation considering certainty",
    "Registration and protocol",
    "Support/funding sources"
  )

  df <- tibble::tibble(
    Section = sections,
    Item = 1:27,
    Description = items,
    Completed = if (populated && !is.null(results)) {
      # Auto-detect completion based on results object
      rep("Partial", 27)  # Could be enhanced with actual detection
    } else {
      rep("", 27)
    },
    Page_Number = "",
    Notes = ""
  )

  message("PRISMA 2020 checklist generated. Mark 'Completed' and 'Page_Number' for your manuscript.")
  message("See https://www.prisma-statement.org/ for full guidance.")

  return(df)
}


#' Generate GRADE Evidence Profile
#'
#' Creates a GRADE (Grading of Recommendations Assessment, Development and
#' Evaluation) evidence profile table assessing certainty of evidence across
#' five domains: risk of bias, inconsistency, indirectness, imprecision, and
#' publication bias.
#'
#' @param results Results object from run_cbamm_analysis()
#' @param data Analysis data frame
#' @param outcome_name Character; name of the outcome
#' @param risk_of_bias Character; "serious", "not serious", "very serious", or NULL (auto-assess)
#' @param inconsistency Character; assessment or NULL (auto-assess from I²)
#' @param indirectness Character; assessment or NULL
#' @param imprecision Character; assessment or NULL (auto-assess from CI width)
#' @param publication_bias Character; assessment or NULL (auto-assess from tests)
#'
#' @return List with evidence profile table and overall certainty rating
#' @export
cbamm_grade_profile <- function(results, data, outcome_name = "Primary outcome",
                                 risk_of_bias = NULL,
                                 inconsistency = NULL,
                                 indirectness = NULL,
                                 imprecision = NULL,
                                 publication_bias = NULL) {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("dplyr package required for GRADE profile")
  }

  # Auto-assess inconsistency from I²
  if (is.null(inconsistency) && !is.null(results$pooled$transport)) {
    I2 <- results$pooled$transport$I2
    inconsistency <- if (I2 < 40) {
      "not serious"
    } else if (I2 < 75) {
      "serious"
    } else {
      "very serious"
    }
    message(sprintf("Auto-assessed inconsistency as '%s' based on I² = %.1f%%",
                    inconsistency, I2))
  }

  # Auto-assess publication bias
  if (is.null(publication_bias) && !is.null(results$small_study)) {
    egger_p <- try(results$small_study$egger$p.value, silent = TRUE)
    if (!inherits(egger_p, "try-error") && is.numeric(egger_p)) {
      publication_bias <- if (egger_p < 0.05) "serious" else "not serious"
      message(sprintf("Auto-assessed publication bias as '%s' based on Egger p = %.3f",
                      publication_bias, egger_p))
    }
  }

  # Auto-assess imprecision from CI width
  if (is.null(imprecision) && !is.null(results$pooled$transport)) {
    fit <- results$pooled$transport
    mm <- .cbamm_measure_meta(results$pooled$transport$measure)
    pred <- try(metafor::predict(fit, transf = mm$transf), silent = TRUE)
    if (!inherits(pred, "try-error")) {
      ci_width <- pred$ci.ub - pred$ci.lb
      # Rough heuristic: ratio measures with CI crossing 1.0 or width > threshold
      if (mm$is_ratio) {
        imprecision <- if (pred$ci.lb < 1.0 && pred$ci.ub > 1.0) {
          "serious"
        } else if (ci_width > 1.0) {
          "serious"
        } else {
          "not serious"
        }
      } else {
        imprecision <- if (ci_width > 0.5) "serious" else "not serious"
      }
      message(sprintf("Auto-assessed imprecision as '%s' based on CI width = %.3f",
                      imprecision, ci_width))
    }
  }

  # Default assessments if still NULL
  if (is.null(risk_of_bias)) risk_of_bias <- "not assessed"
  if (is.null(inconsistency)) inconsistency <- "not assessed"
  if (is.null(indirectness)) indirectness <- "not assessed"
  if (is.null(imprecision)) imprecision <- "not assessed"
  if (is.null(publication_bias)) publication_bias <- "not assessed"

  # Count downgrades
  downgrades <- sum(c(risk_of_bias, inconsistency, indirectness,
                      imprecision, publication_bias) %in% c("serious", "very serious"))
  very_serious_count <- sum(c(risk_of_bias, inconsistency, indirectness,
                               imprecision, publication_bias) == "very serious")

  # Starting certainty (RCT = high, observational = low)
  study_types <- table(data$study_type)
  starting_certainty <- if ("RCT" %in% names(study_types) &&
                            study_types["RCT"] >= nrow(data)/2) {
    "HIGH"
  } else {
    "LOW"
  }

  # Calculate final certainty
  final_certainty <- starting_certainty
  if (starting_certainty == "HIGH") {
    final_certainty <- c("HIGH", "MODERATE", "LOW", "VERY LOW")[min(downgrades + very_serious_count + 1, 4)]
  } else if (starting_certainty == "LOW") {
    final_certainty <- c("LOW", "VERY LOW")[min(downgrades + 1, 2)]
  }

  # Create profile table
  profile <- tibble::tibble(
    Domain = c("Risk of Bias", "Inconsistency", "Indirectness",
               "Imprecision", "Publication Bias"),
    Assessment = c(risk_of_bias, inconsistency, indirectness,
                   imprecision, publication_bias),
    Explanation = c(
      "Based on study design and execution",
      sprintf("I² = %.1f%%", if (!is.null(results$pooled$transport)) results$pooled$transport$I2 else NA),
      "Population, intervention, comparison, outcome alignment",
      "Width of confidence interval and sample size",
      if (!is.null(results$small_study)) sprintf("Egger p = %.3f", results$small_study$egger$p.value) else "Statistical tests"
    )
  )

  message("\n=== GRADE Evidence Profile ===")
  message(sprintf("Starting certainty: %s (based on study design)", starting_certainty))
  message(sprintf("Downgrades: %d", downgrades))
  message(sprintf("FINAL CERTAINTY: %s\n", final_certainty))

  return(list(
    profile = profile,
    starting_certainty = starting_certainty,
    final_certainty = final_certainty,
    outcome = outcome_name,
    n_studies = nrow(data)
  ))
}


#' Capture Complete Reproducibility Information
#'
#' Records comprehensive environment information including package versions,
#' R version, system details, and analysis configuration to ensure full
#' reproducibility of results.
#'
#' @param results Results object from run_cbamm_analysis()
#' @param config Configuration object
#' @param save_rds Logical; save to RDS file?
#' @param output_dir Directory for output
#'
#' @return List with reproducibility information
#' @export
cbamm_reproducibility_report <- function(results = NULL, config = NULL,
                                         save_rds = TRUE,
                                         output_dir = "cbamm_outputs") {

  repro_info <- list(
    timestamp = Sys.time(),
    r_version = R.version.string,
    platform = R.version$platform,
    os = Sys.info()["sysname"],
    locale = Sys.getlocale(),
    session_info = utils::sessionInfo(),
    installed_packages = as.data.frame(utils::installed.packages()[, c("Package", "Version", "Built")]),
    cbamm_config = config,
    random_seed = if (exists(".Random.seed", envir = .GlobalEnv)) {
      get(".Random.seed", envir = .GlobalEnv)
    } else {
      NULL
    },
    working_directory = getwd(),
    cbamm_version = utils::packageVersion("CBAMMR")
  )

  # Add git info if available
  if (dir.exists(".git")) {
    git_info <- try({
      list(
        commit = system("git rev-parse HEAD", intern = TRUE),
        branch = system("git rev-parse --abbrev-ref HEAD", intern = TRUE)
      )
    }, silent = TRUE)
    if (!inherits(git_info, "try-error")) {
      repro_info$git_info <- git_info
    }
  }

  if (save_rds) {
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
    output_file <- file.path(output_dir,
                             paste0("cbamm_reproducibility_",
                                    format(Sys.time(), "%Y%m%d_%H%M%S"),
                                    ".rds"))
    saveRDS(repro_info, output_file)
    message(sprintf("Reproducibility report saved to: %s", output_file))
  }

  # Print summary
  message("\n=== Reproducibility Information ===")
  message(sprintf("R version: %s", repro_info$r_version))
  message(sprintf("Platform: %s", repro_info$platform))
  message(sprintf("CBAMMR version: %s", repro_info$cbamm_version))
  message(sprintf("Timestamp: %s", repro_info$timestamp))
  message(sprintf("Key packages: metafor %s, dplyr %s, ggplot2 %s",
                  utils::packageVersion("metafor"),
                  utils::packageVersion("dplyr"),
                  utils::packageVersion("ggplot2")))

  invisible(repro_info)
}


#' Export Complete Reproducibility Bundle
#'
#' Creates a folder structure with data, code, results, and documentation
#' ready for sharing on OSF, Zenodo, or as supplementary materials.
#'
#' @param results Results object from run_cbamm_analysis()
#' @param data Analysis data frame
#' @param config Configuration object
#' @param output_dir Directory for bundle
#' @param include_data Logical; include raw data?
#' @param anonymize Logical; remove identifying information?
#' @param create_readme Logical; generate README?
#'
#' @return Path to created bundle
#' @export
cbamm_export_bundle <- function(results, data, config,
                                output_dir = "cbamm_reproducibility_bundle",
                                include_data = TRUE,
                                anonymize = FALSE,
                                create_readme = TRUE) {

  # Create directory structure
  dirs <- file.path(output_dir, c("data", "code", "results", "documentation"))
  for (d in dirs) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }

  message(sprintf("Creating reproducibility bundle in: %s", output_dir))

  # 1. Data
  if (include_data) {
    data_export <- if (anonymize) {
      data %>% dplyr::select(-dplyr::any_of(c("author", "first_author", "doi")))
    } else {
      data
    }
    readr::write_csv(data_export, file.path(output_dir, "data", "analysis_data.csv"))
    message("  ✓ Data exported")
  }

  # 2. Results
  saveRDS(results, file.path(output_dir, "results", "cbamm_results.rds"))
  if (!is.null(results$summary_table)) {
    readr::write_csv(results$summary_table,
                     file.path(output_dir, "results", "summary_table.csv"))
  }
  if (!is.null(results$multiverse)) {
    readr::write_csv(results$multiverse,
                     file.path(output_dir, "results", "multiverse_results.csv"))
  }
  message("  ✓ Results exported")

  # 3. Code - Create reproducible R script
  code_script <- sprintf('# CBAMM Analysis Reproducibility Script
# Generated: %s
# R version: %s

# Load package
library(CBAMMR)

# Load data
data <- readr::read_csv("../data/analysis_data.csv")

# Configuration
config <- setup_cbamm(
  effect_measure = "%s",
  use_transport = %s,
  use_hksj = %s,
  use_bayesian = %s,
  run_mv = %s
)

# Define target population (if used)
target_pop <- list(
  age_mean = %s,
  female_pct = %s
)

# Run analysis
results <- run_cbamm_analysis(data, target_pop, config)

# View results
print(results$results$summary_table)

# Display plots
cbamm_show_all_plots(results)

# Session info for reproducibility
sessionInfo()
',
    Sys.time(),
    R.version.string,
    config$effect_measure,
    config$use_transport,
    config$use_hksj,
    if (!is.null(config$use_bayesian)) config$use_bayesian else FALSE,
    if (!is.null(config$run_mv)) config$run_mv else FALSE,
    if ("age_mean" %in% names(data)) mean(data$age_mean, na.rm = TRUE) else "NULL",
    if ("female_pct" %in% names(data)) mean(data$female_pct, na.rm = TRUE) else "NULL"
  )

  writeLines(code_script, file.path(output_dir, "code", "reproduce_analysis.R"))
  message("  ✓ Reproducible code script created")

  # 4. Documentation
  # Save reproducibility report
  repro <- cbamm_reproducibility_report(results, config, save_rds = FALSE)
  saveRDS(repro, file.path(output_dir, "documentation", "reproducibility_info.rds"))

  # Create data codebook
  codebook <- tibble::tibble(
    Variable = names(data),
    Type = sapply(data, class),
    N_Missing = sapply(data, function(x) sum(is.na(x))),
    Description = "" # User can fill in
  )
  readr::write_csv(codebook, file.path(output_dir, "documentation", "codebook.csv"))
  message("  ✓ Documentation created")

  # 5. README
  if (create_readme) {
    readme_content <- sprintf('# CBAMM Meta-Analysis Reproducibility Bundle

## Overview

This bundle contains all materials needed to reproduce the meta-analysis conducted using CBAMM v%s.

**Date Created**: %s
**R Version**: %s
**CBAMM Version**: %s

## Contents

- `data/` - Analysis dataset in CSV format
- `code/` - R script to reproduce all analyses
- `results/` - Complete results object and summary tables
- `documentation/` - Codebook, reproducibility information

## Reproducing the Analysis

1. Install R (version %s or later recommended)
2. Install CBAMMR package:
   ```r
   devtools::install_github("mahmood726-cyber/CBAMMR")
   ```
3. Install required dependencies (see reproducibility_info.rds)
4. Run the analysis script:
   ```r
   source("code/reproduce_analysis.R")
   ```

## Package Versions

Key packages used:
- metafor: %s
- dplyr: %s
- ggplot2: %s

See `documentation/reproducibility_info.rds` for complete package list.

## Citation

Please cite:
- CBAMMR package: [Add citation]
- This analysis: [Add DOI after depositing on OSF/Zenodo]

## Contact

[Your contact information]

## License

[Specify data/code license, e.g., CC-BY 4.0]
',
      utils::packageVersion("CBAMMR"),
      format(Sys.time(), "%Y-%m-%d"),
      R.version.string,
      utils::packageVersion("CBAMMR"),
      paste0(R.version$major, ".", R.version$minor),
      utils::packageVersion("metafor"),
      utils::packageVersion("dplyr"),
      utils::packageVersion("ggplot2")
    )

    writeLines(readme_content, file.path(output_dir, "README.md"))
    message("  ✓ README created")
  }

  message(sprintf("\n✅ Reproducibility bundle complete: %s/", output_dir))
  message("\nNext steps:")
  message("  1. Review and complete documentation/codebook.csv")
  message("  2. Add citation and contact info to README.md")
  message("  3. Upload to OSF (osf.io) or Zenodo (zenodo.org)")
  message("  4. Include DOI in manuscript supplementary materials")

  invisible(output_dir)
}


#' Generate Power Analysis for Meta-Analysis
#'
#' Calculate statistical power for detecting overall effect or required
#' number of studies given power constraints.
#'
#' @param effect_size Expected or observed effect size
#' @param tau2 Expected or observed between-study variance
#' @param n_studies Number of studies (NULL to calculate required k)
#' @param avg_n_per_study Average sample size per study
#' @param alpha Significance level (default 0.05)
#' @param power Desired power (NULL to calculate achieved power)
#' @param measure Effect measure type (for interpretation)
#'
#' @return List with power analysis results
#' @export
cbamm_power_analysis <- function(effect_size, tau2,
                                 n_studies = NULL,
                                 avg_n_per_study = 100,
                                 alpha = 0.05,
                                 power = NULL,
                                 measure = "HR") {

  # Simple approximation for random-effects MA power
  # Based on Hedges & Pigott (2004) and Valentine et al. (2010)

  if (is.null(n_studies) && is.null(power)) {
    stop("Must specify either n_studies (to compute power) or power (to compute required n_studies)")
  }

  # Within-study variance (approximate)
  v_within <- 4 / avg_n_per_study  # Rough approximation

  # Total variance per study
  v_total <- v_within + tau2

  # Critical value
  z_alpha <- stats::qnorm(1 - alpha/2)

  if (!is.null(n_studies)) {
    # Calculate power
    se_pooled <- sqrt(v_total / n_studies)
    ncp <- effect_size / se_pooled  # Non-centrality parameter
    z_beta <- ncp - z_alpha
    power_achieved <- stats::pnorm(z_beta)

    result <- list(
      power = power_achieved,
      n_studies = n_studies,
      effect_size = effect_size,
      tau2 = tau2,
      alpha = alpha,
      avg_n = avg_n_per_study,
      interpretation = if (power_achieved >= 0.80) {
        "Adequate power (≥80%)"
      } else if (power_achieved >= 0.50) {
        "Moderate power (50-80%)"
      } else {
        "Low power (<50%)"
      }
    )
  } else {
    # Calculate required n_studies
    z_power <- stats::qnorm(power)
    z_total <- z_alpha + z_power
    n_required <- ceiling((z_total^2 * v_total) / (effect_size^2))

    result <- list(
      n_studies_required = n_required,
      desired_power = power,
      effect_size = effect_size,
      tau2 = tau2,
      alpha = alpha,
      avg_n = avg_n_per_study,
      interpretation = sprintf("Need %d studies for %.0f%% power", n_required, power*100)
    )
  }

  message("\n=== Power Analysis ===")
  message(sprintf("Effect size: %.3f", effect_size))
  message(sprintf("Tau²: %.3f", tau2))
  if (!is.null(n_studies)) {
    message(sprintf("Number of studies: %d", n_studies))
    message(sprintf("Achieved power: %.1f%%", result$power * 100))
  } else {
    message(sprintf("Desired power: %.1f%%", power * 100))
    message(sprintf("Required studies: %d", result$n_studies_required))
  }
  message(sprintf("Interpretation: %s\n", result$interpretation))

  return(result)
}
