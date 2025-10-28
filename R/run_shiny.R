#' Launch CBAMMR Interactive Web Application
#'
#' Launches the interactive Shiny web application for comprehensive meta-analysis.
#' This app provides a user-friendly interface for uploading data, configuring analyses,
#' and generating publication-ready outputs following 2024-2025 journal standards.
#'
#' @param launch.browser Logical; automatically open browser? (default TRUE)
#' @param port Integer; port number for the app (default: random)
#' @param host Character; host IP address (default "127.0.0.1")
#'
#' @return Launches the Shiny app
#' @export
#'
#' @examples
#' \dontrun{
#' # Launch the interactive app
#' run_cbammr_app()
#'
#' # Launch on specific port
#' run_cbammr_app(port = 3838)
#' }
#'
#' @details
#' The CBAMMR Shiny app provides:
#' \itemize{
#'   \item Interactive data upload (CSV/Excel) with example datasets
#'   \item Complete analysis configuration (effect measures, options)
#'   \item Real-time meta-analysis execution
#'   \item Forest plots, funnel plots, and all visualizations
#'   \item GRADE evidence assessment
#'   \item Fragility index calculation
#'   \item Risk-stratified NNT
#'   \item Decision curve analysis
#'   \item PRISMA 2020 checklist
#'   \item Publication-ready manuscript text
#'   \item High-resolution download handlers for all outputs
#'   \item Complete reproducibility bundles
#' }
#'
#' All features are fully functional with comprehensive error handling.
run_cbammr_app <- function(launch.browser = TRUE, port = NULL, host = "127.0.0.1") {

  # Check if shiny is installed
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required to run the app. Install with: install.packages('shiny')")
  }

  if (!requireNamespace("bs4Dash", quietly = TRUE)) {
    stop("Package 'bs4Dash' is required to run the app. Install with: install.packages('bs4Dash')")
  }

  # Find the app directory
  app_dir <- system.file("shiny", package = "CBAMMR")

  if (app_dir == "") {
    stop("Could not find Shiny app directory. Please reinstall CBAMMR.")
  }

  # Check if app.R exists
  if (!file.exists(file.path(app_dir, "app.R"))) {
    stop("Shiny app file not found. Please reinstall CBAMMR.")
  }

  message("Starting CBAMMR Interactive Meta-Analysis Tool...")
  message("═══════════════════════════════════════════════")
  message("📊 Comprehensive Bayesian & Advanced Meta-Analysis Methods")
  message("Version: 7.0.0")
  message("")
  message("Features:")
  message("  ✓ Interactive data upload & examples")
  message("  ✓ Complete meta-analysis with all modern methods")
  message("  ✓ GRADE evidence assessment")
  message("  ✓ Fragility index for statistical robustness")
  message("  ✓ Risk-stratified NNT & decision curves")
  message("  ✓ PRISMA 2020 checklist")
  message("  ✓ Publication-ready outputs")
  message("")
  message("Loading app...")
  message("═══════════════════════════════════════════════")

  # Run the app
  shiny::runApp(
    appDir = app_dir,
    launch.browser = launch.browser,
    port = port,
    host = host
  )
}
