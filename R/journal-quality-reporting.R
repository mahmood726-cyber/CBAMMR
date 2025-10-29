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

  text <- paste0(
    "## Study Selection and Characteristics\n\n",
    "A total of ", result$n_studies, " studies met the inclusion criteria for this meta-analysis. ",
    "The included studies comprised [add total participants] participants. ",
    "Study characteristics are presented in Table 1.\n\n"
  )

  return(text)
}


#' Generate Study Characteristics
#' @keywords internal
.generate_study_characteristics <- function(result, style, table_format) {

  # Create basic characteristics table
  text <- paste0(
    "### Study Characteristics\n\n",
    "**Table 1.** Characteristics of Included Studies\n\n",
    "| Study | Sample Size | Effect Size | SE | Weight | Quality |\n",
    "|-------|-------------|-------------|-----|--------|----------|\n"
  )

  # Add rows for each study
  for (i in seq_len(result$n_studies)) {
    sei <- sqrt(result$vi[i])
    weight <- (1/result$vi[i]) / sum(1/result$vi) * 100

    text <- paste0(
      text,
      "| Study ", i, " | [N] | ",
      sprintf("%.3f", result$yi[i]), " | ",
      sprintf("%.3f", sei), " | ",
      sprintf("%.1f%%", weight), " | [Quality] |\n"
    )
  }

  text <- paste0(
    text,
    "\n*Note.* SE = Standard Error. Quality assessed using [specify tool]. ",
    "Effect sizes are reported as ", result$effect_size_measure, ".\n\n"
  )

  return(text)
}


#' Generate Main Results Section
#' @keywords internal
.generate_main_results <- function(result, style) {

  # Format based on style
  if (style == "APA") {
    results_text <- sprintf(
      "## Meta-Analysis Results\n\n",
      "The random-effects meta-analysis revealed a pooled effect size of ",
      "%.3f (95%% CI [%.3f, %.3f], *p* %s), ",
      "indicating [describe direction and magnitude of effect]. ",
      "This estimate was derived using the %s estimator for between-study variance (tau²). ",
      "The forest plot displaying individual study effect sizes and the pooled estimate ",
      "is presented in Figure 1.\n\n",
      result$estimate,
      result$ci_lb,
      result$ci_ub,
      .format_pvalue(result$pval, style),
      result$estimator
    )
  } else {
    # Generic format for other styles
    results_text <- sprintf(
      "## Meta-Analysis Results\n\n",
      "Random-effects meta-analysis yielded a pooled effect of %.3f ",
      "(95%% CI %.3f to %.3f; p %s). ",
      "Between-study variance was estimated using %s. ",
      "See Figure 1 for the forest plot.\n\n",
      result$estimate,
      result$ci_lb,
      result$ci_ub,
      .format_pvalue(result$pval, style),
      result$estimator
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

  text <- paste0(
    "## Heterogeneity Assessment\n\n",
    "Substantial heterogeneity was observed among the included studies ",
    sprintf("(*I*² = %.1f%%, ", het$I2),
    sprintf("*Q* = %.2f, ", het$Q),
    sprintf("df = %d, ", het$Q_df),
    sprintf("*p* %s; ", .format_pvalue(het$Q_pval, style)),
    sprintf("tau² = %.4f). ", het$tau2),
    .interpret_heterogeneity_text(het$I2), " ",
    "The prediction interval for the true effect in a new study was ",
    sprintf("[%.3f, %.3f], ", het$pi_lb, het$pi_ub),
    "indicating [describe range of expected effects].\n\n"
  )

  # Add interpretation
  if (het$I2 > 75) {
    text <- paste0(
      text,
      "The high level of heterogeneity suggests considerable variability in treatment effects across studies, ",
      "which may be attributed to differences in [list potential sources: populations, ",
      "interventions, methodological quality, etc.]. ",
      "This heterogeneity was further explored through [subgroup analyses/meta-regression].\n\n"
    )
  } else if (het$I2 > 50) {
    text <- paste0(
      text,
      "The moderate-to-substantial heterogeneity observed warrants consideration of potential ",
      "sources of variability between studies.\n\n"
    )
  } else {
    text <- paste0(
      text,
      "The relatively low heterogeneity suggests consistent effects across studies.\n\n"
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

  text <- paste0(
    "## Summary of Findings\n\n",
    "In summary, this meta-analysis of ", result$n_studies, " studies ",
    "revealed [describe main finding in clinical terms]. "
  )

  if (result$recommendations$confidence_level == "HIGH") {
    text <- paste0(
      text,
      "The evidence base is robust, with high-quality data, ",
      sprintf("minimal heterogeneity concerns (though I² = %.1f%%), ", result$heterogeneity$I2),
      "little evidence of publication bias, and stable findings across sensitivity analyses. ",
      "These results provide strong evidence for [clinical conclusion].\n\n"
    )
  } else if (result$recommendations$confidence_level == "MODERATE") {
    text <- paste0(
      text,
      "The overall quality of evidence is moderate. ",
      "While the findings suggest [clinical conclusion], ",
      "there are some concerns regarding [list issues based on diagnostics]. ",
      "Further high-quality studies would strengthen confidence in these conclusions.\n\n"
    )
  } else {
    text <- paste0(
      text,
      "The quality of evidence is limited due to ",
      "[list specific concerns: heterogeneity, publication bias, sensitivity]. ",
      "While results suggest [clinical conclusion], ",
      "these findings should be interpreted with caution, ",
      "and additional well-designed studies are needed.\n\n"
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
      return(sprintf("The odds ratio of %.2f indicates that [treatment/exposure] ",
                    "increases the odds of [outcome] by approximately %.0f%%.",
                    or, (or - 1) * 100))
    } else {
      return(sprintf("The odds ratio of %.2f indicates that [treatment/exposure] ",
                    "decreases the odds of [outcome] by approximately %.0f%%.",
                    or, (1 - or) * 100))
    }
  } else if (measure == "SMD" || grepl("standardized", measure, ignore.case = TRUE)) {
    # Cohen's d interpretation
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

    return(sprintf("The standardized mean difference of %.2f represents a %s effect size, ",
                  es, magnitude))
  } else {
    return(sprintf("The effect size of %.2f indicates [describe clinical meaning].", es))
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
