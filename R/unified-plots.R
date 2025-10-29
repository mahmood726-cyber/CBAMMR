#' Unified Plotting Interface
#'
#' Single interface to access all meta-analysis plotting capabilities from
#' CBAMMR, metafor, and meta packages.
#'
#' @name unified-plots
#' @keywords internal
NULL

#' Unified Meta-Analysis Plot
#'
#' Universal plotting function that provides access to all meta-analysis
#' plotting capabilities through a single, unified interface. Automatically
#' routes to the appropriate plotting function based on the plot type and
#' package preference.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors (alternative to vi)
#' @param plot_type Type of plot to create. Options:
#'   \itemize{
#'     \item "forest" - Forest plot
#'     \item "funnel" - Funnel plot
#'     \item "radial" - Radial/Galbraith plot
#'     \item "baujat" - Baujat plot
#'     \item "labbe" - L'Abbé plot (requires ai, bi, ci, di)
#'     \item "bubble" - Bubble plot for meta-regression (requires x)
#'     \item "drapery" - Drapery plot (meta only)
#'     \item "gosh" - GOSH plot (metafor only)
#'   }
#' @param package Which package to use ("cbammr", "metafor", "meta", "auto").
#'   Default "auto" intelligently selects based on plot type and data.
#' @param ... Additional arguments passed to the specific plotting function
#'
#' @return Returns plot invisibly, varies by plot type
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#'
#' # Forest plot using metafor
#' cbamm_plot(yi, vi, plot_type = "forest", package = "metafor")
#'
#' # Funnel plot with auto-selection
#' cbamm_plot(yi, vi, plot_type = "funnel")
#'
#' # Baujat plot using meta
#' cbamm_plot(yi, vi, plot_type = "baujat", package = "meta")
#' }
cbamm_plot <- function(yi, vi = NULL, sei = NULL,
                       plot_type = c("forest", "funnel", "radial", "baujat",
                                     "labbe", "bubble", "drapery", "gosh"),
                       package = c("auto", "cbammr", "metafor", "meta"),
                       ...) {

  # Match arguments
  plot_type <- match.arg(plot_type)
  package <- match.arg(package)

  # Handle sei vs vi
  if (is.null(vi) && is.null(sei)) {
    stop("Either vi or sei must be provided")
  }
  if (is.null(sei) && !is.null(vi)) {
    sei <- sqrt(vi)
  }
  if (is.null(vi) && !is.null(sei)) {
    vi <- sei^2
  }

  # Auto-select package if requested
  if (package == "auto") {
    package <- .auto_select_package(plot_type, yi, vi)
  }

  # Route to appropriate function
  result <- switch(paste(plot_type, package, sep = "_"),

    # Forest plots
    "forest_metafor" = cbamm_forest_metafor(yi, vi, ...),
    "forest_meta" = cbamm_forest_meta(yi, sei = sei, ...),
    "forest_cbammr" = stop("CBAMMR forest plots use specific result objects"),

    # Funnel plots
    "funnel_metafor" = cbamm_funnel_metafor(yi, vi, ...),
    "funnel_meta" = cbamm_funnel_meta(yi, sei = sei, ...),
    "funnel_cbammr" = stop("CBAMMR funnel plots use specific result objects"),

    # Radial plots
    "radial_metafor" = cbamm_radial_metafor(yi, vi, ...),
    "radial_meta" = cbamm_radial_meta(yi, sei = sei, ...),
    "radial_cbammr" = stop("Radial plots not available in CBAMMR core"),

    # Baujat plots
    "baujat_metafor" = cbamm_baujat_metafor(yi, vi, ...),
    "baujat_meta" = cbamm_baujat_meta(yi, sei = sei, ...),
    "baujat_cbammr" = stop("Baujat plots not available in CBAMMR core"),

    # Drapery plot (meta only)
    "drapery_meta" = cbamm_drapery_meta(yi, sei = sei, ...),
    "drapery_metafor" = stop("Drapery plots only available in meta package"),
    "drapery_cbammr" = stop("Drapery plots only available in meta package"),

    # GOSH plot (metafor only)
    "gosh_metafor" = cbamm_gosh_metafor(yi, vi, ...),
    "gosh_meta" = stop("GOSH plots only available in metafor package"),
    "gosh_cbammr" = stop("GOSH plots only available in metafor package"),

    # Default
    stop("Plot type '", plot_type, "' with package '", package, "' not supported")
  )

  invisible(result)
}


#' Auto-select plotting package
#'
#' Internal function to intelligently select the best package for a given plot type.
#'
#' @param plot_type Type of plot
#' @param yi Effect sizes
#' @param vi Variances
#'
#' @return Character; selected package name
#' @keywords internal
.auto_select_package <- function(plot_type, yi, vi) {

  # Check which packages are available
  has_metafor <- requireNamespace("metafor", quietly = TRUE)
  has_meta <- requireNamespace("meta", quietly = TRUE)

  # Package-specific plots
  if (plot_type == "drapery") {
    if (!has_meta) {
      stop("meta package required for drapery plots. Install with: install.packages('meta')")
    }
    return("meta")
  }

  if (plot_type == "gosh") {
    if (!has_metafor) {
      stop("metafor package required for GOSH plots. Install with: install.packages('metafor')")
    }
    return("metafor")
  }

  # For other plots, prefer metafor if available (more customizable)
  # Otherwise use meta
  if (has_metafor) {
    return("metafor")
  } else if (has_meta) {
    return("meta")
  } else {
    stop("Either metafor or meta package required. Install with: install.packages('metafor')")
  }
}


#' Get Available Plot Types
#'
#' Returns information about all available plot types and which packages
#' provide them.
#'
#' @return A data frame with plot types, descriptions, and available packages
#' @export
#'
#' @examples
#' \dontrun{
#' # See all available plot types
#' cbamm_available_plots()
#' }
cbamm_available_plots <- function() {

  # Check package availability
  has_metafor <- requireNamespace("metafor", quietly = TRUE)
  has_meta <- requireNamespace("meta", quietly = TRUE)

  plots <- data.frame(
    plot_type = c("forest", "funnel", "radial", "baujat", "labbe",
                  "bubble", "drapery", "gosh", "influence", "cumulative"),
    description = c(
      "Forest plot showing effect sizes and confidence intervals",
      "Funnel plot for publication bias assessment",
      "Radial (Galbraith) plot for outlier detection",
      "Baujat plot identifying heterogeneity contributors",
      "L'Abbé plot for binary outcomes (event rates)",
      "Bubble plot for meta-regression",
      "Drapery plot showing p-value functions",
      "GOSH plot for heterogeneity patterns",
      "Influence diagnostics (Cook's distance, hat values)",
      "Cumulative meta-analysis over time"
    ),
    metafor = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE),
    meta = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE),
    cbammr = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
  )

  # Add availability status
  plots$metafor_available <- plots$metafor & has_metafor
  plots$meta_available <- plots$meta & has_meta

  return(plots)
}


#' Batch Plot Generation
#'
#' Generate multiple plot types at once for comprehensive visualization.
#' Useful for creating complete diagnostic plot sets.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param plots Vector of plot types to generate. Default is c("forest", "funnel", "baujat")
#' @param package Which package to use ("auto", "metafor", "meta")
#' @param output_dir Optional directory to save plots. If NULL, plots to screen.
#' @param file_prefix Prefix for saved plot files
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Resolution for saved plots
#' @param ... Additional arguments passed to plotting functions
#'
#' @return Invisibly returns a list of plot results
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#'
#' # Generate standard diagnostic plots
#' cbamm_batch_plots(yi, vi)
#'
#' # Generate and save plots
#' cbamm_batch_plots(yi, vi, output_dir = "plots", file_prefix = "myanalysis")
#' }
cbamm_batch_plots <- function(yi, vi = NULL, sei = NULL,
                               plots = c("forest", "funnel", "baujat"),
                               package = "auto",
                               output_dir = NULL,
                               file_prefix = "cbamm",
                               width = 8,
                               height = 6,
                               dpi = 300,
                               ...) {

  # Handle sei vs vi
  if (is.null(vi) && is.null(sei)) {
    stop("Either vi or sei must be provided")
  }
  if (is.null(sei) && !is.null(vi)) {
    sei <- sqrt(vi)
  }
  if (is.null(vi) && !is.null(sei)) {
    vi <- sei^2
  }

  # Create output directory if specified
  if (!is.null(output_dir)) {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
  }

  # Generate plots
  results <- list()

  for (plot_type in plots) {

    message(sprintf("Generating %s plot...", plot_type))

    # Open graphics device if saving
    if (!is.null(output_dir)) {
      filename <- file.path(output_dir, paste0(file_prefix, "_", plot_type, ".png"))
      png(filename, width = width, height = height, units = "in", res = dpi)
    }

    # Generate plot
    tryCatch({
      result <- cbamm_plot(yi = yi, vi = vi, sei = sei,
                          plot_type = plot_type,
                          package = package,
                          ...)
      results[[plot_type]] <- result

      if (!is.null(output_dir)) {
        dev.off()
        message(sprintf("  Saved to: %s", filename))
      }

    }, error = function(e) {
      if (!is.null(output_dir) && dev.cur() > 1) {
        dev.off()
      }
      warning(sprintf("Failed to generate %s plot: %s", plot_type, e$message))
      results[[plot_type]] <- NULL
    })
  }

  message("\nBatch plotting complete!")
  invisible(results)
}


#' Compare Package Implementations
#'
#' Generate the same plot type using different packages side-by-side
#' for comparison.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param sei Optional vector of standard errors
#' @param plot_type Type of plot to compare
#' @param packages Vector of packages to compare (e.g., c("metafor", "meta"))
#' @param ... Additional arguments passed to plotting functions
#'
#' @return Invisibly returns results from all packages
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#'
#' # Compare forest plots from metafor and meta
#' cbamm_compare_plots(yi, vi, plot_type = "forest",
#'                     packages = c("metafor", "meta"))
#' }
cbamm_compare_plots <- function(yi, vi = NULL, sei = NULL,
                                 plot_type = "forest",
                                 packages = c("metafor", "meta"),
                                 ...) {

  # Handle sei vs vi
  if (is.null(vi) && is.null(sei)) {
    stop("Either vi or sei must be provided")
  }
  if (is.null(sei) && !is.null(vi)) {
    sei <- sqrt(vi)
  }
  if (is.null(vi) && !is.null(sei)) {
    vi <- sei^2
  }

  # Set up multi-panel plot
  n_packages <- length(packages)
  old_par <- par(mfrow = c(1, n_packages))
  on.exit(par(old_par))

  # Generate plots
  results <- list()

  for (pkg in packages) {
    message(sprintf("Generating %s plot using %s...", plot_type, pkg))

    tryCatch({
      result <- cbamm_plot(yi = yi, vi = vi, sei = sei,
                          plot_type = plot_type,
                          package = pkg,
                          ...)
      results[[pkg]] <- result
      title(main = paste(plot_type, "-", pkg), line = -1, outer = FALSE)

    }, error = function(e) {
      warning(sprintf("Failed with %s: %s", pkg, e$message))
      plot.new()
      text(0.5, 0.5, paste("Error:", pkg, "\n", e$message), cex = 0.8)
      results[[pkg]] <- NULL
    })
  }

  invisible(results)
}


#' Plot Capabilities Summary
#'
#' Prints a comprehensive summary of all available plotting capabilities
#' across CBAMMR, metafor, and meta packages.
#'
#' @return Invisibly returns the capabilities data frame
#' @export
#'
#' @examples
#' \dontrun{
#' cbamm_plot_capabilities()
#' }
cbamm_plot_capabilities <- function() {

  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Unified Plotting Capabilities\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  # Get available plots
  plots_df <- cbamm_available_plots()

  cat("Available Plot Types:\n\n")

  for (i in 1:nrow(plots_df)) {
    row <- plots_df[i, ]

    # Format availability
    avail <- c()
    if (row$metafor_available) avail <- c(avail, "metafor")
    if (row$meta_available) avail <- c(avail, "meta")
    if (row$cbammr) avail <- c(avail, "cbammr")

    avail_str <- if (length(avail) > 0) paste(avail, collapse = ", ") else "None installed"

    cat(sprintf("%d. %s\n", i, toupper(row$plot_type)))
    cat(sprintf("   %s\n", row$description))
    cat(sprintf("   Available in: %s\n\n", avail_str))
  }

  # Package availability
  has_metafor <- requireNamespace("metafor", quietly = TRUE)
  has_meta <- requireNamespace("meta", quietly = TRUE)

  cat("Package Status:\n")
  cat(sprintf("  metafor: %s\n", if (has_metafor) "✓ Installed" else "✗ Not installed"))
  cat(sprintf("  meta:    %s\n", if (has_meta) "✓ Installed" else "✗ Not installed"))

  cat("\n")
  cat("Usage:\n")
  cat("  cbamm_plot(yi, vi, plot_type = 'forest', package = 'auto')\n")
  cat("  cbamm_batch_plots(yi, vi, plots = c('forest', 'funnel', 'baujat'))\n")
  cat("  cbamm_compare_plots(yi, vi, plot_type = 'forest', packages = c('metafor', 'meta'))\n")
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  invisible(plots_df)
}
