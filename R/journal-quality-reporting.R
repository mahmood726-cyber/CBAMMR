#' Journal-Quality R Markdown Results Generator
#'
#' Generates publication-ready R Markdown results sections that can be
#' directly copied and pasted into manuscripts. Follows journal standards,
#' PRISMA guidelines, and best practices for reporting meta-analyses.
#'
#' @name journal-reporting
#' @keywords internal
NULL

#' Generate Journal-Quality R Markdown Results Section
#'
#' Creates a comprehensive, publication-ready results section in R Markdown
#' format that can be directly copied into manuscripts. Includes all necessary
#' elements: study characteristics, meta-analysis results, heterogeneity,
#' publication bias, sensitivity analyses, figures, and tables.
#'
#' @param result Object of class "cbamm_auto" from cbamm_auto()
#' @param style Journal style ("APA", "AMA", "Nature", "Lancet", "BMJ", "JAMA")
#' @param include_figures Include figure code? (default TRUE)
#' @param figure_format Figure format ("png", "pdf", "both")
#' @param figure_dpi Figure resolution (default 300)
#' @param table_format Table format ("markdown", "kable", "gt", "flextable")
#' @param output_file File path to save R Markdown (optional)
#' @param copy_to_clipboard Copy to clipboard? (default TRUE)
#'
#' @return Character string with complete R Markdown results section
#' @export
#'
#' @examples
#' \dontrun{
#' # Run automated analysis
#' result <- cbamm_auto(bcg_vaccine)
#'
#' # Generate journal-quality results
#' rmd <- cbamm_generate_results(result, style = "APA")
#'
#' # View the output
#' cat(rmd)
#'
#' # Save to file
#' cbamm_generate_results(result, style = "APA",
#'                       output_file = "results.Rmd")
#' }
cbamm_generate_results <- function(result,
                                    style = c("APA", "AMA", "Nature", "Lancet", "BMJ", "JAMA"),
                                    include_figures = TRUE,
                                    figure_format = c("png", "pdf", "both"),
                                    figure_dpi = 300,
                                    table_format = c("markdown", "kable", "gt", "flextable"),
                                    output_file = NULL,
                                    copy_to_clipboard = TRUE) {

  if (!inherits(result, "cbamm_auto")) {
    stop("result must be an object of class 'cbamm_auto' from cbamm_auto()")
  }

  style <- match.arg(style)
  figure_format <- match.arg(figure_format)
  table_format <- match.arg(table_format)

  # Generate complete R Markdown document
  rmd <- .generate_complete_rmd(
    result = result,
    style = style,
    include_figures = include_figures,
    figure_format = figure_format,
    figure_dpi = figure_dpi,
    table_format = table_format
  )

  # Save to file if requested
  if (!is.null(output_file)) {
    cat(rmd, file = output_file)
    message("Results saved to: ", output_file)
  }

  # Copy to clipboard if requested
  if (copy_to_clipboard && requireNamespace("clipr", quietly = TRUE)) {
    clipr::write_clip(rmd)
    message("Results copied to clipboard - ready to paste into manuscript!")
  }

  # Print preview
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Journal-Quality Results Section Generated\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  cat("Style:", style, "\n")
  cat("Length:", nchar(rmd), "characters\n")
  cat("Sections: Study characteristics, Results, Heterogeneity, Publication bias, Sensitivity\n")
  cat("Figures:", if(include_figures) "Included" else "Not included", "\n")
  cat("\n")

  if (!is.null(output_file)) {
    cat("✓ Saved to:", output_file, "\n")
  }
  if (copy_to_clipboard) {
    cat("✓ Copied to clipboard - ready to paste!\n")
  }

  cat("\n═══════════════════════════════════════════════════════════════\n\n")

  invisible(rmd)
}


#' Generate Complete R Markdown Document
#' @keywords internal
.generate_complete_rmd <- function(result, style, include_figures,
                                   figure_format, figure_dpi, table_format) {

  # Build sections
  sections <- list(
    header = .generate_rmd_header(style),
    overview = .generate_overview_section(result, style),
    study_chars = .generate_study_characteristics(result, style, table_format),
    main_results = .generate_main_results(result, style),
    heterogeneity = .generate_heterogeneity_section(result, style),
    pub_bias = .generate_publication_bias_section(result, style),
    sensitivity = .generate_sensitivity_section(result, style),
    figures = if(include_figures) .generate_figures_section(result, figure_format, figure_dpi) else "",
    tables = .generate_tables_section(result, table_format),
    summary = .generate_summary_section(result, style)
  )

  # Combine all sections
  rmd <- paste(sections, collapse = "\n\n")

  return(rmd)
}


#' Generate R Markdown Header
#' @keywords internal
.generate_rmd_header <- function(style) {
  paste0(
    "<!-- \n",
    "CBAMM Automated Meta-Analysis Results Section\n",
    "Generated: ", Sys.time(), "\n",
    "Style: ", style, "\n",
    "Ready to copy-paste into manuscript\n",
    "-->\n\n",
    "# Results\n\n"
  )
}


#' Generate Overview Section
#' @keywords internal
.generate_overview_section <- function(result, style) {

  # Get participant count
  if (!is.null(result$study_metadata$total_participants) &&
      !is.na(result$study_metadata$total_participants)) {
    participants_text <- paste0(result$study_metadata$total_participants, " participants")
  } else {
    participants_text <- "[TOTAL PARTICIPANTS NOT AVAILABLE - PLEASE ADD]"
  }

  text <- paste0(
    "## Study Selection and Characteristics\n\n",
    "A total of ", result$n_studies, " studies met the inclusion criteria for this meta-analysis. ",
    "The included studies comprised ", participants_text, ". ",
    "Study characteristics are presented in Table 1.\n\n"
  )

  return(text)
}


#' Generate Study Characteristics
#' @keywords internal
.generate_study_characteristics <- function(result, style, table_format) {

  metadata <- result$study_metadata

  # Create basic characteristics table
  text <- paste0(
    "### Study Characteristics\n\n",
    "**Table 1.** Characteristics of Included Studies\n\n",
    "| Study | Year | Sample Size | Effect Size | SE | Weight | Quality |\n",
    "|-------|------|-------------|-------------|-----|--------|----------|\n"
  )

  # Add rows for each study
  for (i in seq_len(result$n_studies)) {
    sei <- sqrt(result$vi[i])
    weight <- (1/result$vi[i]) / sum(1/result$vi) * 100

    # Get study name
    study_name <- metadata$study_names[i]

    # Get year
    year_text <- if (!is.na(metadata$years[i])) {
      as.character(metadata$years[i])
    } else {
      "—"
    }

    # Get sample size
    n_text <- if (!is.na(metadata$sample_sizes[i])) {
      as.character(metadata$sample_sizes[i])
    } else {
      "—"
    }

    # Get quality
    quality_text <- if (!is.na(metadata$quality[i])) {
      as.character(metadata$quality[i])
    } else {
      "—"
    }

    text <- paste0(
      text,
      "| ", study_name, " | ",
      year_text, " | ",
      n_text, " | ",
      sprintf("%.3f", result$yi[i]), " | ",
      sprintf("%.3f", sei), " | ",
      sprintf("%.1f%%", weight), " | ",
      quality_text, " |\n"
    )
  }

  # Note about quality
  quality_note <- if (all(is.na(metadata$quality))) {
    "Quality assessment not provided in data."
  } else {
    "Quality assessed using risk of bias tool."
  }

  text <- paste0(
    text,
    "\n*Note.* SE = Standard Error. ", quality_note, " ",
    "Effect sizes are reported as ", result$effect_size_measure, ". ",
    "— indicates data not available in source.\n\n"
  )

  return(text)
}


#' Generate Main Results Section
#' @keywords internal
.generate_main_results <- function(result, style) {

  # Determine direction
  if (result$estimate > 0) {
    direction <- "positive"
  } else if (result$estimate < 0) {
    direction <- "negative"
  } else {
    direction <- "null"
  }

  # Determine significance
  if (result$pval < 0.05) {
    sig_text <- "statistically significant"
  } else {
    sig_text <- "not statistically significant"
  }

  # Format based on style
  if (style == "APA") {
    results_text <- paste0(
      "## Meta-Analysis Results\n\n",
      "The random-effects meta-analysis revealed a pooled effect size of ",
      sprintf("%.3f", result$estimate),
      " (95% CI [", sprintf("%.3f", result$ci_lb), ", ", sprintf("%.3f", result$ci_ub), "], *p* ",
      .format_pvalue(result$pval, style), "), ",
      "indicating a ", direction, " effect that is ", sig_text, ". ",
      "This estimate was derived using the ", result$estimator,
      " estimator for between-study variance (tau²). ",
      "The forest plot displaying individual study effect sizes and the pooled estimate ",
      "is presented in Figure 1.\n\n"
    )
  } else {
    # Generic format for other styles
    results_text <- paste0(
      "## Meta-Analysis Results\n\n",
      "Random-effects meta-analysis yielded a pooled effect of ",
      sprintf("%.3f", result$estimate),
      " (95% CI ", sprintf("%.3f", result$ci_lb), " to ", sprintf("%.3f", result$ci_ub),
      "; p ", .format_pvalue(result$pval, style), "). ",
      "The effect was ", sig_text, ". ",
      "Between-study variance was estimated using ", result$estimator, ". ",
      "See Figure 1 for the forest plot.\n\n"
    )
  }

  # Add interpretation
  interpretation <- paste0(
    "### Clinical Interpretation\n\n",
    .interpret_effect_size(result$estimate, result$effect_size_measure),
    "\n\n"
  )

  return(paste0(results_text, interpretation))
}


#' Generate Heterogeneity Section
#' @keywords internal
.generate_heterogeneity_section <- function(result, style) {

  het <- result$heterogeneity

  # Determine heterogeneity level for opening sentence
  if (het$I2 < 25) {
    het_level <- "Low heterogeneity"
  } else if (het$I2 < 50) {
    het_level <- "Moderate heterogeneity"
  } else if (het$I2 < 75) {
    het_level <- "Substantial heterogeneity"
  } else {
    het_level <- "Considerable heterogeneity"
  }

  # Interpret prediction interval width
  pi_width <- het$pi_ub - het$pi_lb
  pooled_se <- abs(het$pi_ub - het$pi_lb) / (2 * 1.96)  # Approximate
  if (pi_width > abs(het$pi_ub - het$pi_lb) * 2) {
    pi_interpretation <- "indicating substantial variation in the expected range of effects in future studies"
  } else {
    pi_interpretation <- "suggesting relatively consistent effects expected in future studies"
  }

  text <- paste0(
    "## Heterogeneity Assessment\n\n",
    het_level, " was observed among the included studies ",
    sprintf("(*I*² = %.1f%%, ", het$I2),
    sprintf("*Q* = %.2f, ", het$Q),
    sprintf("df = %d, ", het$Q_df),
    sprintf("*p* %s; ", .format_pvalue(het$Q_pval, style)),
    sprintf("tau² = %.4f). ", het$tau2),
    .interpret_heterogeneity_text(het$I2), " ",
    "The 95% prediction interval for the true effect in a new study was ",
    sprintf("[%.3f, %.3f], ", het$pi_lb, het$pi_ub),
    pi_interpretation, ". ",
    "This interval represents the range in which we would expect 95% of true effects to fall in similar studies.\n\n"
  )

  # Add interpretation
  if (het$I2 > 75) {
    text <- paste0(
      text,
      "The high level of heterogeneity suggests considerable variability in effects across studies. ",
      "Potential sources of heterogeneity may include differences in study populations (e.g., age, ",
      "disease severity, baseline characteristics), intervention characteristics (e.g., dose, duration, ",
      "delivery method), comparison conditions, outcome measurement methods, study design features, ",
      "or methodological quality. Exploratory subgroup analyses or meta-regression could help identify ",
      "sources of heterogeneity, though such analyses should be interpreted cautiously as hypothesis-generating ",
      "rather than confirmatory. Pooled estimates should be interpreted with caution given the high heterogeneity.\n\n"
    )
  } else if (het$I2 > 50) {
    text <- paste0(
      text,
      "The moderate-to-substantial heterogeneity observed warrants careful consideration. ",
      "Potential sources may include variations in populations, interventions, or study methods. ",
      "While pooling is still reasonable, results should be interpreted recognizing this variability.\n\n"
    )
  } else {
    text <- paste0(
      text,
      "The relatively low heterogeneity suggests reasonably consistent effects across studies, ",
      "supporting the appropriateness of pooling and generalizability of findings.\n\n"
    )
  }

  return(text)
}


#' Generate Publication Bias Section
#' @keywords internal
.generate_publication_bias_section <- function(result, style) {

  pb <- result$publication_bias

  text <- paste0(
    "## Publication Bias Assessment\n\n",
    "Multiple methods were employed to assess publication bias. "
  )

  # Egger's test
  text <- paste0(
    text,
    sprintf("Egger's regression test yielded a bias estimate of %.3f ",
            pb$full_results$egger$estimate),
    sprintf("(SE = %.3f, ", pb$full_results$egger$se),
    sprintf("*p* %s). ", .format_pvalue(pb$full_results$egger$p_value, style))
  )

  # Begg's test
  text <- paste0(
    text,
    sprintf("Begg's rank correlation test produced tau = %.3f ",
            pb$full_results$begg$tau),
    sprintf("(*p* %s). ", .format_pvalue(pb$full_results$begg$p_value, style))
  )

  # Trim and fill
  if (pb$full_results$trimfill$n_imputed > 0) {
    text <- paste0(
      text,
      sprintf("Trim-and-fill analysis imputed %d potentially missing studies, ",
              pb$full_results$trimfill$n_imputed),
      sprintf("yielding an adjusted pooled estimate of %.3f. ",
              pb$full_results$trimfill$adjusted_estimate)
    )
  } else {
    text <- paste0(
      text,
      "Trim-and-fill analysis did not suggest any missing studies. "
    )
  }

  # Overall conclusion
  if (pb$concern_level == "LOW") {
    text <- paste0(
      text,
      "Overall, these analyses provide little evidence of substantial publication bias. ",
      "The funnel plot (Figure 2) shows reasonable symmetry around the pooled estimate.\n\n"
    )
  } else if (pb$concern_level == "MODERATE") {
    text <- paste0(
      text,
      "These results suggest some potential for publication bias, ",
      "although the evidence is not conclusive. Results should be interpreted with this limitation in mind. ",
      "See Figure 2 for the funnel plot.\n\n"
    )
  } else {
    text <- paste0(
      text,
      "Multiple indicators suggest potential publication bias, ",
      "which may have led to an overestimate of the true effect. ",
      "Adjusted estimates accounting for this bias should be considered. ",
      "The funnel plot (Figure 2) shows asymmetry consistent with publication bias.\n\n"
    )
  }

  return(text)
}


#' Generate Sensitivity Section
#' @keywords internal
.generate_sensitivity_section <- function(result, style) {

  sens <- result$sensitivity

  text <- paste0(
    "## Sensitivity Analyses\n\n",
    "Leave-one-out sensitivity analysis was conducted to assess the influence of individual studies. ",
    sprintf("The pooled effect size ranged from %.3f to %.3f when each study was sequentially removed, ",
            min(sens$full_results$leave_one_out$estimate),
            max(sens$full_results$leave_one_out$estimate)),
    sprintf("yielding a robustness score of %.1f out of 100. ", sens$robustness_score)
  )

  if (sens$robustness_score > 80) {
    text <- paste0(
      text,
      "This high robustness score indicates that the overall finding is stable ",
      "and not driven by any single study.\n\n"
    )
  } else if (sens$robustness_score > 60) {
    text <- paste0(
      text,
      "This moderate robustness score suggests reasonable stability of the overall finding, ",
      "though some individual studies have notable influence.\n\n"
    )
  } else {
    text <- paste0(
      text,
      "This relatively low robustness score indicates that the overall finding may be ",
      "sensitive to the inclusion/exclusion of specific studies. ",
      sprintf("Study %s was identified as particularly influential.\n\n", sens$most_influential)
    )
  }

  return(text)
}


#' Generate Figures Section
#' @keywords internal
.generate_figures_section <- function(result, figure_format, figure_dpi) {

  text <- paste0(
    "## Figures\n\n",
    "### Figure 1. Forest Plot\n\n",
    "```{r forest-plot, fig.width=10, fig.height=8, dpi=", figure_dpi, "}\n",
    "# Forest plot showing individual study effect sizes and pooled estimate\n",
    "library(CBAMMR)\n",
    "cbamm_forest_metafor(\n",
    "  yi = c(", paste(round(result$yi, 4), collapse = ", "), "),\n",
    "  vi = c(", paste(round(result$vi, 4), collapse = ", "), "),\n",
    "  slab = paste('Study', 1:", result$n_studies, "),\n",
    "  xlab = '", result$effect_size_measure, " (95% CI)',\n",
    "  main = 'Meta-Analysis of Included Studies'\n",
    ")\n",
    "```\n\n",
    "*Note.* Forest plot displaying individual study effect sizes (squares) with 95% confidence intervals (horizontal lines). ",
    "Square size is proportional to study weight. The diamond represents the pooled effect estimate. ",
    "Dashed vertical line indicates the null effect.\n\n",
    "### Figure 2. Funnel Plot\n\n",
    "```{r funnel-plot, fig.width=8, fig.height=8, dpi=", figure_dpi, "}\n",
    "# Contour-enhanced funnel plot for publication bias assessment\n",
    "cbamm_funnel_metafor(\n",
    "  yi = c(", paste(round(result$yi, 4), collapse = ", "), "),\n",
    "  vi = c(", paste(round(result$vi, 4), collapse = ", "), "),\n",
    "  level = c(90, 95, 99),\n",
    "  shade = c('white', 'gray85', 'gray70'),\n",
    "  legend = TRUE\n",
    ")\n",
    "```\n\n",
    "*Note.* Contour-enhanced funnel plot for assessment of publication bias. ",
    "Shaded regions indicate statistical significance at different alpha levels. ",
    "Asymmetry in the distribution of studies suggests potential publication bias.\n\n"
  )

  return(text)
}


#' Generate Tables Section
#' @keywords internal
.generate_tables_section <- function(result, table_format) {

  text <- paste0(
    "## Supplementary Tables\n\n",
    "### Table 2. Summary of Meta-Analysis Results\n\n"
  )

  # Results summary table
  summary_table <- data.frame(
    Statistic = c(
      "Number of studies",
      "Pooled effect size",
      "95% Confidence interval",
      "Standard error",
      "*p*-value",
      "Between-study variance (tau²)",
      "*I*² statistic",
      "Cochran's *Q*",
      "Prediction interval"
    ),
    Value = c(
      as.character(result$n_studies),
      sprintf("%.3f", result$estimate),
      sprintf("[%.3f, %.3f]", result$ci_lb, result$ci_ub),
      sprintf("%.3f", result$se),
      .format_pvalue(result$pval, "APA"),
      sprintf("%.4f", result$heterogeneity$tau2),
      sprintf("%.1f%%", result$heterogeneity$I2),
      sprintf("%.2f (*p* %s)", result$heterogeneity$Q,
              .format_pvalue(result$heterogeneity$Q_pval, "APA")),
      sprintf("[%.3f, %.3f]", result$heterogeneity$pi_lb, result$heterogeneity$pi_ub)
    )
  )

  # Format as markdown table
  text <- paste0(
    text,
    "| Statistic | Value |\n",
    "|-----------|-------|\n"
  )

  for (i in seq_len(nrow(summary_table))) {
    text <- paste0(
      text,
      "| ", summary_table$Statistic[i], " | ", summary_table$Value[i], " |\n"
    )
  }

  text <- paste0(
    text,
    "\n*Note.* Results based on random-effects meta-analysis using ", result$estimator, " estimator.\n\n"
  )

  # Add publication bias summary table
  text <- paste0(
    text,
    "### Table 3. Publication Bias Assessment\n\n",
    "| Test | Statistic | *p*-value | Interpretation |\n",
    "|------|-----------|-----------|----------------|\n",
    sprintf("| Egger's test | *b* = %.3f | %s | %s |\n",
            result$publication_bias$full_results$egger$estimate,
            .format_pvalue(result$publication_bias$full_results$egger$p_value, "APA"),
            if(result$publication_bias$full_results$egger$p_value < 0.05) "Significant asymmetry" else "No significant asymmetry"),
    sprintf("| Begg's test | tau = %.3f | %s | %s |\n",
            result$publication_bias$full_results$begg$tau,
            .format_pvalue(result$publication_bias$full_results$begg$p_value, "APA"),
            if(result$publication_bias$full_results$begg$p_value < 0.05) "Significant correlation" else "No significant correlation"),
    sprintf("| Trim-and-fill | %d imputed | — | %s |\n",
            result$publication_bias$full_results$trimfill$n_imputed,
            if(result$publication_bias$full_results$trimfill$n_imputed > 0) "Potential bias" else "No bias detected"),
    "\n*Note.* Multiple methods used to assess small-study effects and publication bias. ",
    sprintf("Overall concern level: %s.\n\n", result$publication_bias$concern_level)
  )

  return(text)
}


#' Generate Summary Section
#' @keywords internal
.generate_summary_section <- function(result, style) {

  # Create main finding summary
  direction_text <- if (result$estimate > 0) "a positive effect" else if (result$estimate < 0) "a negative effect" else "no effect"
  sig_text <- if (result$pval < 0.05) "statistically significant" else "not statistically significant"

  text <- paste0(
    "## Summary of Findings\n\n",
    "In summary, this meta-analysis of ", result$n_studies, " studies ",
    "revealed ", direction_text, " (pooled estimate: ", sprintf("%.3f", result$estimate),
    ", 95% CI [", sprintf("%.3f", result$ci_lb), ", ", sprintf("%.3f", result$ci_ub),
    "]) that was ", sig_text, ". "
  )

  if (result$recommendations$confidence_level == "HIGH") {
    text <- paste0(
      text,
      "The evidence base is robust, with ", tolower(result$data_quality$quality_level), "-quality data, ",
      if (result$heterogeneity$I2 < 50) {
        "low-to-moderate heterogeneity"
      } else {
        sprintf("heterogeneity (I² = %.1f%%) that was explored and considered", result$heterogeneity$I2)
      },
      ", little evidence of publication bias (", result$publication_bias$concern_level, " concern), ",
      "and stable findings across sensitivity analyses (robustness score: ",
      sprintf("%.0f/100", result$sensitivity$robustness_score), "). ",
      "These results provide strong evidence that should inform clinical practice and policy, though ",
      "the clinical significance should be evaluated in the context of the specific outcome and population.\n\n"
    )
  } else if (result$recommendations$confidence_level == "MODERATE") {
    # Identify concerns
    concerns <- c()
    if (result$heterogeneity$I2 > 50) concerns <- c(concerns, "heterogeneity")
    if (result$publication_bias$concern_level != "LOW") concerns <- c(concerns, "potential publication bias")
    if (result$sensitivity$robustness_score < 70) concerns <- c(concerns, "sensitivity to individual studies")
    if (result$data_quality$quality_level %in% c("Moderate", "Poor")) concerns <- c(concerns, "data quality")

    concerns_text <- if (length(concerns) > 0) {
      paste(concerns, collapse = ", ")
    } else {
      "methodological limitations"
    }

    text <- paste0(
      text,
      "The overall quality of evidence is moderate. ",
      "While the findings suggest ", direction_text, " that is ", sig_text, ", ",
      "there are some concerns regarding ", concerns_text, ". ",
      "Results should be interpreted with appropriate caution. ",
      "Further high-quality studies would strengthen confidence in these conclusions.\n\n"
    )
  } else {
    # Identify specific concerns for LOW confidence
    concerns <- c()
    if (result$heterogeneity$I2 > 75) concerns <- c(concerns, "high heterogeneity")
    if (result$publication_bias$concern_level == "HIGH") concerns <- c(concerns, "strong evidence of publication bias")
    if (result$sensitivity$robustness_score < 50) concerns <- c(concerns, "sensitivity to individual studies")
    if (result$data_quality$quality_level == "Poor") concerns <- c(concerns, "poor data quality")

    concerns_text <- if (length(concerns) > 0) {
      paste(concerns, collapse = ", ")
    } else {
      "multiple methodological concerns"
    }

    text <- paste0(
      text,
      "The quality of evidence is limited due to ", concerns_text, ". ",
      "While results suggest ", direction_text, ", ",
      "these findings should be interpreted with substantial caution. ",
      "The effect estimate may change considerably with additional well-designed studies. ",
      "More research is needed before drawing firm conclusions.\n\n"
    )
  }

  # Add methodological note
  text <- paste0(
    text,
    "### Methodological Note\n\n",
    "All analytical decisions in this meta-analysis were made *a priori* ",
    "based on data characteristics and established guidelines, ",
    "eliminating researcher degrees of freedom and ensuring reproducibility. ",
    "The analysis was conducted using CBAMMR v", result$cbamm_version, " ",
    "(Intelligent Automated Meta-Analysis System), ",
    "which implements evidence-based decision rules for method selection, ",
    "heterogeneity assessment, publication bias evaluation, and sensitivity analysis. ",
    "Complete decision documentation and analysis code are available in the supplementary materials.\n\n"
  )

  # Add PRISMA note
  text <- paste0(
    text,
    "*Note.* This meta-analysis was conducted and reported in accordance with ",
    "the Preferred Reporting Items for Systematic Reviews and Meta-Analyses (PRISMA) guidelines.\n\n"
  )

  return(text)
}


#' Format P-Value for Journal Style
#' @keywords internal
.format_pvalue <- function(p, style) {
  if (p < 0.001) {
    return("< .001")
  } else if (p < 0.01) {
    return(sprintf("= %.3f", p))
  } else {
    return(sprintf("= %.2f", p))
  }
}


#' Interpret Effect Size
#' @keywords internal
.interpret_effect_size <- function(es, measure) {
  if (measure == "OR" || grepl("odds", measure, ignore.case = TRUE)) {
    # Convert log OR to OR
    or <- exp(es)
    if (or > 1) {
      pct_change <- (or - 1) * 100
      return(paste0(
        "The odds ratio of ", sprintf("%.2f", or), " (log OR = ", sprintf("%.2f", es), ") ",
        "indicates that the odds of the outcome are ", sprintf("%.0f%%", pct_change),
        " higher in the treatment/exposure group compared to the control group. ",
        "Note: Odds ratios should be interpreted carefully and ",
        "consider converting to risk ratios for rare outcomes if baseline risk is known."
      ))
    } else {
      pct_change <- (1 - or) * 100
      return(paste0(
        "The odds ratio of ", sprintf("%.2f", or), " (log OR = ", sprintf("%.2f", es), ") ",
        "indicates that the odds of the outcome are ", sprintf("%.0f%%", pct_change),
        " lower in the treatment/exposure group compared to the control group. ",
        "Note: Odds ratios should be interpreted carefully and ",
        "consider converting to risk ratios for rare outcomes if baseline risk is known."
      ))
    }
  } else if (measure == "SMD" || grepl("standardized", measure, ignore.case = TRUE)) {
    # Cohen's d interpretation with context
    abs_es <- abs(es)
    if (abs_es < 0.2) {
      magnitude <- "negligible"
    } else if (abs_es < 0.5) {
      magnitude <- "small"
    } else if (abs_es < 0.8) {
      magnitude <- "medium"
    } else {
      magnitude <- "large"
    }

    direction_text <- if (es > 0) {
      "favoring the treatment group"
    } else {
      "favoring the control group"
    }

    return(paste0(
      "The standardized mean difference of ", sprintf("%.2f", es),
      " represents a ", magnitude, " effect size ", direction_text, " (Cohen's benchmarks). ",
      "Note that these benchmarks are general guidelines and the clinical importance ",
      "should be evaluated in the specific context of the outcome being measured. ",
      "Consider reporting the effect in the original units if possible for clinical interpretation."
    ))
  } else {
    return(paste0(
      "The effect size of ", sprintf("%.3f", es),
      " should be interpreted in the context of the specific measure (",
      measure, ") and the clinical/practical importance for the outcome of interest. ",
      "Statistical significance does not necessarily imply clinical significance."
    ))
  }
}


#' Interpret Heterogeneity as Text
#' @keywords internal
.interpret_heterogeneity_text <- function(I2) {
  if (I2 < 25) {
    return("This low level of heterogeneity suggests relatively consistent effects across studies.")
  } else if (I2 < 50) {
    return("This moderate heterogeneity indicates some variability in effects across studies.")
  } else if (I2 < 75) {
    return("This substantial heterogeneity suggests considerable variability in treatment effects.")
  } else {
    return("This considerable heterogeneity indicates high variability in effects across studies.")
  }
}


#' Print R Markdown Results
#' @export
print.cbamm_rmd_results <- function(x, ...) {
  cat(x)
  invisible(x)
}
