# Automated Reporting and GRADE Assessment Module
# Based on GRADE Working Group and PRISMA guidelines
# Part of CBAMMR v8.14.0 - Final Comprehensive Release
#
# References:
# - Guyatt et al. (2011) Journal of Clinical Epidemiology - GRADE series
# - Balshem et al. (2011) Journal of Clinical Epidemiology - GRADE certainty
# - Page et al. (2021) BMJ - PRISMA 2020 statement
# - Sch��nemann et al. (2013) Journal of Clinical Epidemiology - GRADE handbook

#' Automated GRADE Assessment
#'
#' Performs automated GRADE (Grading of Recommendations Assessment,
#' Development and Evaluation) assessment for certainty of evidence.
#'
#' @param ma_result Meta-analysis result object (from rma or similar)
#' @param study_design Design of included studies: "RCT" or "observational"
#' @param risk_of_bias Overall risk of bias: "low", "some_concerns", "high"
#' @param inconsistency I² value or assessment: numeric or "low"/"moderate"/"high"
#' @param indirectness Assessment: "no", "some", "serious"
#' @param imprecision Assessment based on CI width: "no", "some", "serious"
#' @param publication_bias Assessment: "undetected", "suspected", "strongly_suspected"
#' @param large_effect Optional: "yes" if effect size is large (RR >2 or <0.5)
#' @param dose_response Optional: "yes" if dose-response gradient observed
#' @param confounding Optional: "reduces" if confounding likely reduces effect
#'
#' @return Object of class "cbamm_grade" containing:
#'   \item{starting_certainty}{Starting level based on study design}
#'   \item{downgrades}{Reasons for downgrading}
#'   \item{upgrades}{Reasons for upgrading}
#'   \item{final_certainty}{Final GRADE certainty: "high", "moderate", "low", "very low"}
#'   \item{summary_of_findings}{Summary table}
#'
#' @references
#' Guyatt, G. H., Oxman, A. D., Vist, G. E., Kunz, R., Falck-Ytter, Y., Alonso-Coello, P., & Schünemann, H. J. (2008).
#' GRADE: an emerging consensus on rating quality of evidence and strength of recommendations.
#' BMJ, 336(7650), 924-926.
#'
#' Balshem, H., Helfand, M., Schünemann, H. J., Oxman, A. D., Kunz, R., Brozek, J., ... & Guyatt, G. H. (2011).
#' GRADE guidelines: 3. Rating the quality of evidence.
#' Journal of clinical epidemiology, 64(4), 401-406.
#'
#' @examples
#' \dontrun{
#' # After meta-analysis
#' ma_fit <- rma(yi = yi, vi = vi, data = dat)
#'
#' grade <- cbamm_grade_assessment(
#'   ma_result = ma_fit,
#'   study_design = "RCT",
#'   risk_of_bias = "some_concerns",
#'   inconsistency = ma_fit$I2,
#'   indirectness = "no",
#'   imprecision = "some",
#'   publication_bias = "undetected"
#' )
#' print(grade)
#' }
#'
#' @export
cbamm_grade_assessment <- function(ma_result, study_design = "RCT",
                                   risk_of_bias = "low",
                                   inconsistency = NULL,
                                   indirectness = "no",
                                   imprecision = NULL,
                                   publication_bias = "undetected",
                                   large_effect = NULL,
                                   dose_response = NULL,
                                   confounding = NULL) {

  # Starting certainty based on study design
  if (tolower(study_design) %in% c("rct", "randomized", "randomised")) {
    starting_certainty <- 4  # High
    starting_label <- "High (RCTs)"
  } else {
    starting_certainty <- 2  # Low
    starting_label <- "Low (Observational studies)"
  }

  downgrades <- list()
  downgrade_reasons <- c()
  total_downgrades <- 0

  # DOWNGRADE 1: Risk of Bias
  if (risk_of_bias == "high" || risk_of_bias == "serious") {
    downgrades$risk_of_bias <- -2
    downgrade_reasons <- c(downgrade_reasons, "Serious risk of bias (-2)")
    total_downgrades <- total_downgrades + 2
  } else if (risk_of_bias == "some_concerns" || risk_of_bias == "moderate") {
    downgrades$risk_of_bias <- -1
    downgrade_reasons <- c(downgrade_reasons, "Some concerns about risk of bias (-1)")
    total_downgrades <- total_downgrades + 1
  } else {
    downgrades$risk_of_bias <- 0
  }

  # DOWNGRADE 2: Inconsistency (Heterogeneity)
  if (!is.null(inconsistency)) {
    if (is.numeric(inconsistency)) {
      # I² value provided
      if (inconsistency > 75) {
        downgrades$inconsistency <- -2
        downgrade_reasons <- c(downgrade_reasons, sprintf("Serious inconsistency (I²=%.1f%%) (-2)", inconsistency))
        total_downgrades <- total_downgrades + 2
      } else if (inconsistency > 50) {
        downgrades$inconsistency <- -1
        downgrade_reasons <- c(downgrade_reasons, sprintf("Moderate inconsistency (I²=%.1f%%) (-1)", inconsistency))
        total_downgrades <- total_downgrades + 1
      } else {
        downgrades$inconsistency <- 0
      }
    } else {
      # Qualitative assessment
      if (inconsistency == "high" || inconsistency == "serious") {
        downgrades$inconsistency <- -2
        downgrade_reasons <- c(downgrade_reasons, "Serious inconsistency (-2)")
        total_downgrades <- total_downgrades + 2
      } else if (inconsistency == "moderate" || inconsistency == "some") {
        downgrades$inconsistency <- -1
        downgrade_reasons <- c(downgrade_reasons, "Moderate inconsistency (-1)")
        total_downgrades <- total_downgrades + 1
      } else {
        downgrades$inconsistency <- 0
      }
    }
  } else {
    downgrades$inconsistency <- 0
  }

  # DOWNGRADE 3: Indirectness
  if (indirectness == "serious" || indirectness == "high") {
    downgrades$indirectness <- -2
    downgrade_reasons <- c(downgrade_reasons, "Serious indirectness (-2)")
    total_downgrades <- total_downgrades + 2
  } else if (indirectness == "some" || indirectness == "moderate") {
    downgrades$indirectness <- -1
    downgrade_reasons <- c(downgrade_reasons, "Some indirectness (-1)")
    total_downgrades <- total_downgrades + 1
  } else {
    downgrades$indirectness <- 0
  }

  # DOWNGRADE 4: Imprecision
  if (!is.null(imprecision)) {
    if (imprecision == "serious" || imprecision == "high") {
      downgrades$imprecision <- -2
      downgrade_reasons <- c(downgrade_reasons, "Serious imprecision (-2)")
      total_downgrades <- total_downgrades + 2
    } else if (imprecision == "some" || imprecision == "moderate") {
      downgrades$imprecision <- -1
      downgrade_reasons <- c(downgrade_reasons, "Some imprecision (-1)")
      total_downgrades <- total_downgrades + 1
    } else {
      downgrades$imprecision <- 0
    }
  } else {
    # Auto-assess based on CI width if ma_result provided
    if (!is.null(ma_result) && inherits(ma_result, "rma")) {
      ci_width <- ma_result$ci.ub - ma_result$ci.lb
      # Wide CI suggests imprecision
      if (ci_width > 1.5) {  # Arbitrary threshold, adjust based on measure
        downgrades$imprecision <- -1
        downgrade_reasons <- c(downgrade_reasons, "Imprecision (wide CI) (-1)")
        total_downgrades <- total_downgrades + 1
      } else {
        downgrades$imprecision <- 0
      }
    } else {
      downgrades$imprecision <- 0
    }
  }

  # DOWNGRADE 5: Publication Bias
  if (publication_bias == "strongly_suspected" || publication_bias == "high") {
    downgrades$publication_bias <- -1
    downgrade_reasons <- c(downgrade_reasons, "Strongly suspected publication bias (-1)")
    total_downgrades <- total_downgrades + 1
  } else if (publication_bias == "suspected" || publication_bias == "some") {
    downgrades$publication_bias <- -1
    downgrade_reasons <- c(downgrade_reasons, "Suspected publication bias (-1)")
    total_downgrades <- total_downgrades + 1
  } else {
    downgrades$publication_bias <- 0
  }

  # UPGRADES (for observational studies only)
  upgrades <- list()
  upgrade_reasons <- c()
  total_upgrades <- 0

  if (tolower(study_design) != "rct") {
    # UPGRADE 1: Large magnitude of effect
    if (!is.null(large_effect) && large_effect == "yes") {
      if (!is.null(ma_result) && inherits(ma_result, "rma")) {
        effect_size <- exp(ma_result$beta[1])  # Assume log scale
        if (effect_size > 5 || effect_size < 0.2) {
          upgrades$large_effect <- 2
          upgrade_reasons <- c(upgrade_reasons, "Very large effect (RR >5 or <0.2) (+2)")
          total_upgrades <- total_upgrades + 2
        } else if (effect_size > 2 || effect_size < 0.5) {
          upgrades$large_effect <- 1
          upgrade_reasons <- c(upgrade_reasons, "Large effect (RR >2 or <0.5) (+1)")
          total_upgrades <- total_upgrades + 1
        } else {
          upgrades$large_effect <- 0
        }
      } else {
        upgrades$large_effect <- 1
        upgrade_reasons <- c(upgrade_reasons, "Large effect (+1)")
        total_upgrades <- total_upgrades + 1
      }
    } else {
      upgrades$large_effect <- 0
    }

    # UPGRADE 2: Dose-response gradient
    if (!is.null(dose_response) && dose_response == "yes") {
      upgrades$dose_response <- 1
      upgrade_reasons <- c(upgrade_reasons, "Dose-response gradient (+1)")
      total_upgrades <- total_upgrades + 1
    } else {
      upgrades$dose_response <- 0
    }

    # UPGRADE 3: All plausible confounding would reduce effect
    if (!is.null(confounding) && confounding == "reduces") {
      upgrades$confounding <- 1
      upgrade_reasons <- c(upgrade_reasons, "Plausible confounding would reduce effect (+1)")
      total_upgrades <- total_upgrades + 1
    } else {
      upgrades$confounding <- 0
    }
  }

  # Calculate final certainty
  final_certainty_score <- starting_certainty - total_downgrades + total_upgrades
  final_certainty_score <- max(1, min(4, final_certainty_score))  # Clamp to 1-4

  final_certainty_label <- switch(as.character(final_certainty_score),
    "4" = "High",
    "3" = "Moderate",
    "2" = "Low",
    "1" = "Very Low"
  )

  # Symbol for GRADE
  grade_symbol <- switch(final_certainty_label,
    "High" = "⊕⊕⊕⊕",
    "Moderate" = "⊕⊕⊕⊖",
    "Low" = "⊕⊕⊖⊖",
    "Very Low" = "⊕⊖⊖⊖"
  )

  result <- list(
    starting_certainty = starting_label,
    downgrades = downgrades,
    downgrade_reasons = downgrade_reasons,
    total_downgrades = total_downgrades,
    upgrades = upgrades,
    upgrade_reasons = upgrade_reasons,
    total_upgrades = total_upgrades,
    final_certainty = final_certainty_label,
    final_certainty_score = final_certainty_score,
    grade_symbol = grade_symbol
  )

  class(result) <- "cbamm_grade"
  return(result)
}


#' Generate Summary of Findings Table
#'
#' Creates GRADE Summary of Findings (SoF) table in multiple formats.
#'
#' @param outcome_name Name of the outcome
#' @param ma_result Meta-analysis result object
#' @param grade_result GRADE assessment result
#' @param comparison Comparison description (e.g., "Drug A vs Placebo")
#' @param n_participants Total number of participants
#' @param n_studies Number of studies
#' @param format Output format: "markdown", "html", "latex", "dataframe"
#'
#' @return Summary of Findings table in specified format
#'
#' @export
cbamm_summary_of_findings <- function(outcome_name, ma_result, grade_result,
                                     comparison, n_participants, n_studies,
                                     format = "markdown") {

  # Extract effect estimate
  if (inherits(ma_result, "rma")) {
    estimate <- ma_result$beta[1]
    ci_lower <- ma_result$ci.lb
    ci_upper <- ma_result$ci.ub
    pval <- ma_result$pval
  } else {
    stop("ma_result must be a metafor rma object")
  }

  # Create data frame
  sof_df <- data.frame(
    Outcome = outcome_name,
    Comparison = comparison,
    `N Participants` = n_participants,
    `N Studies` = n_studies,
    Estimate = sprintf("%.2f", estimate),
    `95% CI` = sprintf("[%.2f, %.2f]", ci_lower, ci_upper),
    `P-value` = sprintf("%.4f", pval),
    Certainty = paste(grade_result$grade_symbol, grade_result$final_certainty),
    check.names = FALSE
  )

  # Add reasons for downgrading/upgrading
  if (length(grade_result$downgrade_reasons) > 0) {
    sof_df$`Reasons` <- paste(c(grade_result$downgrade_reasons, grade_result$upgrade_reasons), collapse = "; ")
  } else {
    sof_df$`Reasons` <- "No concerns"
  }

  # Format output
  if (format == "dataframe") {
    return(sof_df)
  } else if (format == "markdown") {
    # Markdown table
    output <- paste0("## Summary of Findings\n\n")
    output <- paste0(output, "|", paste(names(sof_df), collapse = " | "), "|\n")
    output <- paste0(output, "|", paste(rep("---", ncol(sof_df)), collapse = "|"), "|\n")
    output <- paste0(output, "|", paste(sof_df[1,], collapse = " | "), "|\n")
    return(cat(output))
  } else if (format == "html") {
    # HTML table
    output <- "<table border='1'>\n<tr>\n"
    output <- paste0(output, paste0("<th>", names(sof_df), "</th>", collapse = "\n"), "\n</tr>\n<tr>\n")
    output <- paste0(output, paste0("<td>", sof_df[1,], "</td>", collapse = "\n"), "\n</tr>\n</table>")
    return(cat(output))
  } else if (format == "latex") {
    # LaTeX table
    output <- "\\begin{table}[h]\n\\centering\n\\begin{tabular}{|"
    output <- paste0(output, paste(rep("l|", ncol(sof_df)), collapse = ""), "}\n\\hline\n")
    output <- paste0(output, paste(names(sof_df), collapse = " & "), " \\\\\n\\hline\n")
    output <- paste0(output, paste(sof_df[1,], collapse = " & "), " \\\\\n\\hline\n\\end{tabular}\n\\end{table}")
    return(cat(output))
  }
}


#' Generate PRISMA 2020 Checklist
#'
#' Creates automated PRISMA 2020 checklist showing which items are addressed.
#'
#' @param title Study title
#' @param abstract_structured Is abstract structured? (TRUE/FALSE)
#' @param registration_prospero PROSPERO registration number
#' @param search_date Date of last search
#' @param databases_searched Vector of databases searched
#' @param n_identified Number of records identified
#' @param n_screened Number screened
#' @param n_included Number included
#' @param n_excluded Number excluded (with reasons)
#' @param rob_tool Risk of bias tool used
#' @param synthesis_method Synthesis method used
#' @param reporting_bias_assessed Publication bias assessed? (TRUE/FALSE)
#' @param certainty_method GRADE or other certainty assessment
#'
#' @return PRISMA checklist data frame
#'
#' @references
#' Page, M. J., McKenzie, J. E., Bossuyt, P. M., Boutron, I., Hoffmann, T. C., Mulrow, C. D., ... & Moher, D. (2021).
#' The PRISMA 2020 statement: an updated guideline for reporting systematic reviews.
#' BMJ, 372, n71.
#'
#' @export
cbamm_prisma_checklist <- function(title = NULL,
                                   abstract_structured = FALSE,
                                   registration_prospero = NULL,
                                   search_date = NULL,
                                   databases_searched = NULL,
                                   n_identified = NULL,
                                   n_screened = NULL,
                                   n_included = NULL,
                                   n_excluded = NULL,
                                   rob_tool = NULL,
                                   synthesis_method = NULL,
                                   reporting_bias_assessed = FALSE,
                                   certainty_method = NULL) {

  # PRISMA 2020 items
  prisma_items <- data.frame(
    Section = c(
      "Title", "Abstract", "Introduction", "Introduction",
      "Methods", "Methods", "Methods", "Methods", "Methods", "Methods", "Methods",
      "Methods", "Methods", "Methods", "Methods", "Methods", "Methods",
      "Results", "Results", "Results", "Results", "Results", "Results", "Results",
      "Discussion", "Discussion", "Other"
    ),
    Item = c(
      "1. Title", "2. Abstract", "3. Rationale", "4. Objectives",
      "5. Eligibility criteria", "6. Information sources", "7. Search strategy",
      "8. Selection process", "9. Data collection process", "10. Data items",
      "11. Study risk of bias assessment", "12. Effect measures", "13. Synthesis methods",
      "14. Reporting bias assessment", "15. Certainty assessment", "16. Study characteristics",
      "17. Study results",
      "18. Study selection", "19. Study characteristics", "20. Risk of bias",
      "21. Results of individual studies", "22. Results of syntheses",
      "23. Reporting biases", "24. Certainty of evidence",
      "25. Discussion", "26. Limitations", "27. Registration and protocol"
    ),
    Status = c(
      ifelse(!is.null(title), "✓ Complete", "☐ Not provided"),
      ifelse(abstract_structured, "✓ Complete", "☐ Not provided"),
      "☐ Manual completion required",
      "☐ Manual completion required",
      "☐ Manual completion required",
      ifelse(!is.null(databases_searched), "✓ Complete", "☐ Not provided"),
      "☐ Manual completion required",
      ifelse(!is.null(n_screened), "✓ Complete", "☐ Not provided"),
      "☐ Manual completion required",
      "☐ Manual completion required",
      ifelse(!is.null(rob_tool), paste("✓ Complete -", rob_tool), "☐ Not provided"),
      ifelse(!is.null(synthesis_method), paste("✓ Complete -", synthesis_method), "☐ Not provided"),
      ifelse(!is.null(synthesis_method), "✓ Complete", "☐ Not provided"),
      ifelse(reporting_bias_assessed, "✓ Complete", "☐ Not provided"),
      ifelse(!is.null(certainty_method), paste("✓ Complete -", certainty_method), "☐ Not provided"),
      "☐ Manual completion required",
      "☐ Manual completion required",
      ifelse(!is.null(n_included), paste("✓ Complete - n =", n_included), "☐ Not provided"),
      "☐ Manual completion required",
      ifelse(!is.null(rob_tool), "✓ Complete", "☐ Not provided"),
      "☐ Manual completion required",
      "✓ Complete via CBAMMR",
      ifelse(reporting_bias_assessed, "✓ Complete", "☐ Not provided"),
      ifelse(!is.null(certainty_method), "✓ Complete", "☐ Not provided"),
      "☐ Manual completion required",
      "☐ Manual completion required",
      ifelse(!is.null(registration_prospero), paste("✓ Complete -", registration_prospero), "☐ Not provided")
    )
  )

  return(prisma_items)
}


#' Generate Automated Meta-Analysis Report
#'
#' Creates complete publication-ready report with methods, results, GRADE, and PRISMA.
#'
#' @param ma_result Meta-analysis result
#' @param study_data Data frame with study characteristics
#' @param outcome_name Outcome name
#' @param comparison Comparison description
#' @param grade_assessment GRADE assessment result
#' @param format Output format: "markdown", "html", "word"
#' @param output_file Output file path
#'
#' @return Writes report to file
#'
#' @export
cbamm_generate_report <- function(ma_result, study_data, outcome_name, comparison,
                                  grade_assessment = NULL, format = "markdown",
                                  output_file = "meta_analysis_report.md") {

  # Extract key information
  n_studies <- ma_result$k
  n_participants <- sum(study_data$n, na.rm = TRUE)
  estimate <- ma_result$beta[1]
  ci_lower <- ma_result$ci.lb
  ci_upper <- ma_result$ci.ub
  pval <- ma_result$pval
  I2 <- ma_result$I2
  tau2 <- ma_result$tau2

  # Start report
  report <- c()

  # Title
  report <- c(report, paste0("# Meta-Analysis Report: ", outcome_name))
  report <- c(report, "")
  report <- c(report, paste0("**Comparison:** ", comparison))
  report <- c(report, paste0("**Date:** ", Sys.Date()))
  report <- c(report, "")

  # Abstract
  report <- c(report, "## Abstract")
  report <- c(report, "")
  report <- c(report, paste0("**Objective:** To assess the effect of ", comparison, " on ", outcome_name, "."))
  report <- c(report, "")
  report <- c(report, paste0("**Methods:** Systematic review and meta-analysis of ", n_studies, " studies (N = ", n_participants, " participants). Random-effects meta-analysis was performed using the CBAMMR package."))
  report <- c(report, "")
  report <- c(report, paste0("**Results:** Pooled estimate: ", sprintf("%.2f", estimate), " (95% CI: ", sprintf("[%.2f, %.2f]", ci_lower, ci_upper), ", p = ", sprintf("%.4f", pval), "). Heterogeneity: I² = ", sprintf("%.1f%%", I2), ", τ² = ", sprintf("%.3f", tau2), "."))
  report <- c(report, "")

  if (!is.null(grade_assessment)) {
    report <- c(report, paste0("**Certainty of Evidence:** ", grade_assessment$grade_symbol, " ", grade_assessment$final_certainty))
  }

  report <- c(report, "")

  # Methods
  report <- c(report, "## Methods")
  report <- c(report, "")
  report <- c(report, "### Search Strategy")
  report <- c(report, "A comprehensive search was conducted across multiple databases.")
  report <- c(report, "")
  report <- c(report, "### Inclusion Criteria")
  report <- c(report, "[To be completed manually]")
  report <- c(report, "")
  report <- c(report, "### Statistical Analysis")
  report <- c(report, paste0("Random-effects meta-analysis was performed using the restricted maximum likelihood (REML) estimator. Effect sizes were pooled using the ", class(ma_result)[1], " framework. Heterogeneity was assessed using I² and τ². Publication bias was evaluated using [methods to be specified]."))
  report <- c(report, "")

  # Results
  report <- c(report, "## Results")
  report <- c(report, "")
  report <- c(report, paste0("### Study Characteristics"))
  report <- c(report, paste0("A total of ", n_studies, " studies with ", n_participants, " participants were included."))
  report <- c(report, "")
  report <- c(report, "### Meta-Analysis Results")
  report <- c(report, paste0("The pooled estimate was ", sprintf("%.2f", estimate), " (95% CI: ", sprintf("[%.2f, %.2f]", ci_lower, ci_upper), ", p = ", sprintf("%.4f", pval), ")."))
  report <- c(report, "")
  report <- c(report, "### Heterogeneity")
  report <- c(report, paste0("Substantial heterogeneity was ", ifelse(I2 > 50, "detected", "not detected"), " (I² = ", sprintf("%.1f%%", I2), ", τ² = ", sprintf("%.3f", tau2), ")."))
  report <- c(report, "")

  # GRADE Summary of Findings
  if (!is.null(grade_assessment)) {
    report <- c(report, "## Summary of Findings")
    report <- c(report, "")
    report <- c(report, cbamm_summary_of_findings(
      outcome_name = outcome_name,
      ma_result = ma_result,
      grade_result = grade_assessment,
      comparison = comparison,
      n_participants = n_participants,
      n_studies = n_studies,
      format = "markdown"
    ))
    report <- c(report, "")
  }

  # Discussion
  report <- c(report, "## Discussion")
  report <- c(report, "[To be completed manually]")
  report <- c(report, "")

  # Conclusion
  report <- c(report, "## Conclusion")
  report <- c(report, "[To be completed manually]")
  report <- c(report, "")

  # Write to file
  writeLines(report, con = output_file)

  message(paste0("Report generated: ", output_file))

  return(invisible(report))
}


# S3 Methods ----

#' @export
print.cbamm_grade <- function(x, ...) {
  cat("\n=== GRADE Certainty of Evidence Assessment ===\n\n")

  cat(sprintf("Starting certainty: %s\n\n", x$starting_certainty))

  if (length(x$downgrade_reasons) > 0) {
    cat("Downgrades:\n")
    for (reason in x$downgrade_reasons) {
      cat(paste0("  - ", reason, "\n"))
    }
    cat("\n")
  }

  if (length(x$upgrade_reasons) > 0) {
    cat("Upgrades:\n")
    for (reason in x$upgrade_reasons) {
      cat(paste0("  + ", reason, "\n"))
    }
    cat("\n")
  }

  cat(sprintf("Final Certainty: %s %s\n", x$grade_symbol, x$final_certainty))

  cat("\nInterpretation:\n")
  cat(switch(x$final_certainty,
    "High" = "  We are very confident that the true effect lies close to the estimate.\n",
    "Moderate" = "  We are moderately confident in the effect estimate.\n",
    "Low" = "  Our confidence in the effect estimate is limited.\n",
    "Very Low" = "  We have very little confidence in the effect estimate.\n"
  ))

  cat("\n")
  invisible(x)
}
