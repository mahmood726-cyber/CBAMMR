#' Plot Method for cbamm_auto Objects
#'
#' Creates a forest plot from a cbamm_auto analysis result using the specified style
#'
#' @param x Object of class "cbamm_auto"
#' @param type Type of plot: "forest" (default), "funnel", "all"
#' @param style Forest plot style: "auto" (use style from analysis), "metafor", "meta", or "ggplot"
#' @param ... Additional arguments passed to plotting functions
#'
#' @return Forest plot or list of plots
#' @export
#'
#' @examples
#' \dontrun{
#' data <- read.csv("my_data.csv")
#' result <- cbamm_auto(data, forest_style = "metafor")
#' plot(result)  # Uses metafor style from analysis
#' plot(result, style = "meta")  # Override to use meta style
#' plot(result, type = "funnel")  # Funnel plot instead
#' }
plot.cbamm_auto <- function(x, type = c("forest", "funnel", "all"),
                            style = "auto", ...) {

  type <- match.arg(type)

  if (type == "forest" || type == "all") {
    # Determine style
    if (style == "auto") {
      style <- x$forest_style
      if (is.null(style)) style <- "metafor"  # Default if not set
    }

    # Create forest plot using enhanced function
    if (requireNamespace("cbamm", quietly = TRUE) || exists("cbamm_forest_auto")) {
      forest_plot <- cbamm_forest_auto(x, style = style, ...)
    } else {
      # Fallback: basic forest plot
      forest_plot <- .basic_forest_plot(x, ...)
    }

    if (type == "forest") {
      return(forest_plot)
    }
  }

  if (type == "funnel" || type == "all") {
    funnel_plot <- .cbamm_funnel_plot(x, ...)

    if (type == "funnel") {
      return(funnel_plot)
    }
  }

  if (type == "all") {
    return(list(forest = forest_plot, funnel = funnel_plot))
  }
}


#' Basic Forest Plot (fallback)
#' @keywords internal
.basic_forest_plot <- function(x, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' required for forest plots")
  }

  fit <- metafor::rma(yi = x$yi, vi = x$vi, method = x$estimator)
  metafor::forest(fit, ...)
  invisible(fit)
}


#' Funnel Plot for cbamm_auto
#' @keywords internal
.cbamm_funnel_plot <- function(x, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop("Package 'metafor' required for funnel plots")
  }

  fit <- metafor::rma(yi = x$yi, vi = x$vi, method = x$estimator)
  metafor::funnel(fit, ...)
  invisible(fit)
}


#' Print Method for cbamm_auto Objects
#'
#' Prints a summary of the automated meta-analysis results
#'
#' @param x Object of class "cbamm_auto"
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#' @export
#'
#' @examples
#' \dontrun{
#' data <- read.csv("my_data.csv")
#' result <- cbamm_auto(data)
#' print(result)
#' }
print.cbamm_auto <- function(x, ...) {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMM Automated Meta-Analysis Results\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  # Pathway
  cat("Pathway:        ", toupper(x$pathway), "\n")

  # Data info
  cat("Data type:      ", x$data_type, "\n")
  cat("Studies:        ", x$n_studies, "\n")
  cat("Effect measure: ", x$effect_size_measure, "\n")
  cat("Estimator:      ", x$estimator, "\n")
  cat("Forest style:   ", x$forest_style, "\n\n")

  # Main results
  cat("───────────────────────────────────────────────────────────────\n")
  cat("Primary Results:\n")
  cat("───────────────────────────────────────────────────────────────\n")
  cat(sprintf("Estimate:       %.4f\n", x$estimate))
  cat(sprintf("95%% CI:         [%.4f, %.4f]\n", x$ci_lb, x$ci_ub))
  cat(sprintf("SE:             %.4f\n", x$se))
  cat(sprintf("p-value:        %.4f %s\n", x$pval,
              if(x$pval < 0.001) "***" else if(x$pval < 0.01) "**" else if(x$pval < 0.05) "*" else ""))
  cat("\n")

  # Heterogeneity
  if (!is.null(x$heterogeneity)) {
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Heterogeneity:\n")
    cat("───────────────────────────────────────────────────────────────\n")
    cat(sprintf("I²:             %.1f%%\n", x$heterogeneity$I2))
    cat(sprintf("Q:              %.2f (p = %.4f)\n", x$heterogeneity$Q, x$heterogeneity$QEp))
    cat(sprintf("τ²:             %.4f\n", x$heterogeneity$tau2))
    cat("\n")
  }

  # Publication bias
  if (!is.null(x$publication_bias)) {
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Publication Bias:\n")
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Concern level:  ", x$publication_bias$concern_level, "\n")
    cat("Decision:       ", x$publication_bias$decision, "\n")
    cat("\n")
  }

  # Advanced/Custom results
  if (!is.null(x$advanced_results)) {
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Advanced Results Available:\n")
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Methods run:    ", paste(names(x$advanced_results), collapse = ", "), "\n")
    cat("Access via:      result$advanced_results\n\n")
  }

  if (!is.null(x$custom_results)) {
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Custom Results Available:\n")
    cat("───────────────────────────────────────────────────────────────\n")
    cat("Methods run:    ", paste(names(x$custom_results), collapse = ", "), "\n")
    cat("Access via:      result$custom_results\n\n")
  }

  # Footer
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("Use plot(result) to create forest plot\n")
  cat("Use plot(result, type='funnel') for funnel plot\n")
  cat("Use plot(result, style='meta') to change forest plot style\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  invisible(x)
}


#' Summary Method for cbamm_auto Objects
#'
#' Provides a detailed summary of the automated meta-analysis
#'
#' @param object Object of class "cbamm_auto"
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns the input object
#' @export
#'
#' @examples
#' \dontrun{
#' data <- read.csv("my_data.csv")
#' result <- cbamm_auto(data)
#' summary(result)
#' }
summary.cbamm_auto <- function(object, ...) {
  print(object, ...)

  # Additional detailed information
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  Detailed Information\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  # Justification
  if (!is.null(object$justification)) {
    cat("Method justification:\n")
    cat(object$justification, "\n\n")
  }

  # Study metadata
  if (!is.null(object$study_metadata)) {
    cat("Study characteristics:\n")
    cat(sprintf("  Total participants: %d\n", object$study_metadata$total_participants))
    if (!is.null(object$study_metadata$years)) {
      years <- object$study_metadata$years[!is.na(object$study_metadata$years)]
      if (length(years) > 0) {
        cat(sprintf("  Year range: %d - %d\n", min(years), max(years)))
      }
    }
    cat("\n")
  }

  # Recommendations
  if (!is.null(object$recommendations)) {
    cat("Recommendations:\n")
    cat(object$recommendations$conclusion, "\n")
    cat("\n")
  }

  # Analysis info
  cat("Analysis information:\n")
  cat(sprintf("  Date: %s\n", format(object$analysis_date, "%Y-%m-%d %H:%M:%S")))
  cat(sprintf("  Time elapsed: %.2f %s\n",
              as.numeric(object$elapsed_time),
              attr(object$elapsed_time, "units")))
  cat(sprintf("  CBAMMR version: %s\n", object$cbamm_version))
  cat("\n")

  cat("═══════════════════════════════════════════════════════════════\n\n")

  invisible(object)
}
