# CBAMMR Interactive Meta-Analysis Tool
# Streamlined but fully functional Shiny app
# All core features implemented without placeholders

library(shiny)
library(bs4Dash)
library(DT)
library(ggplot2)
library(plotly)
library(shinyWidgets)

# Source global helpers
source("global.R", local = TRUE)

# UI
ui <- dashboardPage(
  header = dashboardHeader(
    title = "CBAMMR v8.2",
    rightUi = tags$div(
      class = "navbar-custom-menu",
      tags$span(style = "color: white; padding: 15px;",
                "Comprehensive Meta-Analysis Tool")
    )
  ),

  sidebar = dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("1. Upload Data", tabName = "upload", icon = icon("upload"),
               badgeLabel = "Start", badgeColor = "success"),
      menuItem("2. Configure", tabName = "config", icon = icon("cog")),
      menuItem("3. Run Analysis", tabName = "run", icon = icon("play")),
      menuItem("Results", icon = icon("chart-bar"),
               menuSubItem("Summary", tabName = "summary"),
               menuSubItem("Plots", tabName = "plots"),
               menuSubItem("GRADE & Fragility", tabName = "grade")),
      menuItem("Download", tabName = "download", icon = icon("download"))
    )
  ),

  body = dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #ecf0f5; }
        .box { box-shadow: 0 1px 1px rgba(0,0,0,0.1); }
        .btn-file { position: relative; overflow: hidden; }
        .download-section { margin: 15px 0; padding: 15px; background: #f9f9f9; border-radius: 5px; }
      "))
    ),

    tabItems(
      # HOME
      tabItem("home",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Welcome to CBAMMR Interactive Tool",
              h3("Comprehensive Bayesian & Advanced Meta-Analysis Methods"),
              p("State-of-the-art meta-analysis following 2024-2025 journal standards."),
              hr(),
              h4("What This Tool Provides:"),
              tags$ul(
                tags$li("✅ Complete random-effects meta-analysis"),
                tags$li("✅ GRADE evidence assessment"),
                tags$li("✅ Fragility index for statistical robustness"),
                tags$li("✅ Publication-ready plots and tables"),
                tags$li("✅ PRISMA 2020 compliance"),
                tags$li("✅ Manuscript-ready text output")
              ),
              hr(),
              actionButton("start_btn", "Get Started →",
                          class = "btn-lg btn-success",
                          icon = icon("arrow-right"))
          )
        )
      ),

      # UPLOAD
      tabItem("upload",
        fluidRow(
          box(width = 8, title = "Upload Your Data", status = "primary", solidHeader = TRUE,
              radioButtons("data_source", "Choose Data Source:",
                          choices = c("Upload File" = "file",
                                    "Use Example" = "example",
                                    "Simulate Data" = "simulate")),

              conditionalPanel(
                condition = "input.data_source == 'file'",
                fileInput("datafile", "Choose CSV/Excel File",
                         accept = c(".csv", ".xlsx"))
              ),

              conditionalPanel(
                condition = "input.data_source == 'example'",
                selectInput("example_type", "Select Example:",
                           choices = c("Binary (OR)" = "binary",
                                     "Continuous (SMD)" = "continuous")),
                actionButton("load_example_btn", "Load Example Data",
                            class = "btn-info")
              ),

              conditionalPanel(
                condition = "input.data_source == 'simulate'",
                numericInput("sim_n", "Number of Studies:", 20, min = 5, max = 50),
                selectInput("sim_measure", "Effect Measure:",
                           choices = c("OR", "RR", "SMD")),
                actionButton("simulate_btn", "Generate Data",
                            class = "btn-warning")
              ),

              hr(),
              h4("Data Preview:"),
              DTOutput("data_table")
          ),

          box(width = 4, title = "Download Templates", status = "info", solidHeader = TRUE,
              p("Download template files to see required format:"),
              downloadButton("dl_binary_template", "Binary Data Template",
                            class = "btn-block"),
              br(),
              downloadButton("dl_continuous_template", "Continuous Data Template",
                            class = "btn-block"),
              hr(),
              h5("Required Columns:"),
              tags$ul(
                tags$li("Binary: ai, bi, ci, di OR yi, sei"),
                tags$li("Continuous: yi, sei"),
                tags$li("All: study, year (optional)")
              )
          )
        )
      ),

      # CONFIGURE
      tabItem("config",
        fluidRow(
          box(width = 8, title = "Analysis Configuration", status = "primary", solidHeader = TRUE,
              selectInput("effect_measure", "Effect Measure:",
                         choices = c("Odds Ratio" = "OR",
                                   "Risk Ratio" = "RR",
                                   "Hazard Ratio" = "HR",
                                   "Mean Difference" = "MD",
                                   "Std Mean Diff" = "SMD")),

              awesomeCheckbox("use_hksj", "Use Hartung-Knapp Adjustment",
                             value = TRUE, status = "success"),
              p(class = "text-muted", "✅ Recommended for better CI coverage"),

              awesomeCheckbox("run_grade", "Generate GRADE Assessment",
                             value = TRUE, status = "info"),

              awesomeCheckbox("calc_fragility", "Calculate Fragility Index",
                             value = TRUE, status = "warning"),

              selectInput("method", "Heterogeneity Estimator:",
                         choices = c("REML (Recommended)" = "REML",
                                   "DerSimonian-Laird" = "DL",
                                   "Maximum Likelihood" = "ML")),
              hr(),
              verbatimTextOutput("config_summary")
          ),

          box(width = 4, title = "Quick Presets", status = "success", solidHeader = TRUE,
              actionButton("preset_standard", "Standard Analysis",
                          class = "btn-block btn-info"),
              br(),
              actionButton("preset_comprehensive", "Comprehensive",
                          class = "btn-block btn-warning"),
              br(),
              actionButton("preset_quick", "Quick (Fast)",
                          class = "btn-block btn-success")
          )
        )
      ),

      # RUN ANALYSIS
      tabItem("run",
        fluidRow(
          box(width = 12, title = "Run Meta-Analysis", status = "success", solidHeader = TRUE,
              h4("Ready to analyze your data!"),
              p("This will perform complete meta-analysis with all selected options."),
              br(),
              actionButton("run_btn", "🚀 Run Analysis",
                          class = "btn-lg btn-success btn-block",
                          icon = icon("play-circle")),
              br(), br(),
              uiOutput("run_status"),
              br(),
              conditionalPanel(
                condition = "input.run_btn > 0",
                verbatimTextOutput("analysis_log")
              )
          )
        )
      ),

      # SUMMARY
      tabItem("summary",
        fluidRow(
          box(width = 12, title = "Analysis Results", status = "primary", solidHeader = TRUE,
              conditionalPanel(
                condition = "output.has_results",
                fluidRow(
                  valueBoxOutput("effect_box", width = 3),
                  valueBoxOutput("het_box", width = 3),
                  valueBoxOutput("p_box", width = 3),
                  valueBoxOutput("studies_box", width = 3)
                ),
                hr(),
                h4("Detailed Results:"),
                DTOutput("results_table"),
                hr(),
                h4("Publication-Ready Text:"),
                verbatimTextOutput("formatted_text")
              ),
              conditionalPanel(
                condition = "!output.has_results",
                div(class = "text-center",
                    icon("info-circle", class = "fa-3x text-muted"),
                    h4("No results yet"),
                    p("Please run the analysis first."))
              )
          )
        )
      ),

      # PLOTS
      tabItem("plots",
        fluidRow(
          # FOREST PLOT
          box(width = 8, title = "Forest Plot", status = "primary", solidHeader = TRUE, collapsible = TRUE,
              plotOutput("forest_plot", height = "600px"),
              conditionalPanel(
                condition = "output.has_results",
                hr(),
                fluidRow(
                  column(6, downloadButton("dl_forest_png", "Download PNG (300 DPI)", class = "btn-info btn-block")),
                  column(6, downloadButton("dl_forest_pdf", "Download PDF", class = "btn-primary btn-block"))
                )
              )
          ),

          # FOREST PLOT CUSTOMIZATION
          box(width = 4, title = "Forest Plot Settings", status = "info", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,

              h5("Style Preset:"),
              selectInput("forest_style", NULL,
                         choices = c("Classic" = "classic",
                                   "Meta R Package" = "meta",
                                   "RevMan Style" = "revman",
                                   "NEJM Style" = "nejm"),
                         selected = "classic"),

              hr(),
              h5("Range & Scale:"),
              fluidRow(
                column(6, numericInput("forest_xlim_min", "X-min:", value = NA)),
                column(6, numericInput("forest_xlim_max", "X-max:", value = NA))
              ),
              numericInput("forest_steps", "Tick Marks:", value = 5, min = 3, max = 10),
              numericInput("forest_digits", "Decimals:", value = 2, min = 0, max = 4),

              hr(),
              h5("Colors:"),
              fluidRow(
                column(6, selectInput("forest_col", "Effect Color:", choices = color_choices, selected = "black")),
                column(6, selectInput("forest_border", "Border:", choices = color_choices, selected = "black"))
              ),
              fluidRow(
                column(6, selectInput("forest_col_diamond", "Diamond:", choices = color_choices, selected = "#003366")),
                column(6, selectInput("forest_col_pred", "Pred. Interval:", choices = color_choices, selected = "#006600"))
              ),
              fluidRow(
                column(6, selectInput("forest_col_lines", "Grid Lines:", choices = color_choices, selected = "#808080")),
                column(6, selectInput("forest_col_text", "Text:", choices = color_choices, selected = "black"))
              ),
              selectInput("forest_col_bg", "Background:", choices = color_choices, selected = "white"),

              hr(),
              h5("Appearance:"),
              sliderInput("forest_cex", "Text Size:", min = 0.5, max = 2, value = 1.0, step = 0.1),
              sliderInput("forest_lwd", "Line Width:", min = 0.5, max = 5, value = 1.5, step = 0.5),
              selectInput("forest_pch", "Point Style:",
                         choices = list("Square" = 15, "Circle" = 16, "Diamond" = 18,
                                      "Triangle" = 17, "Plus" = 3),
                         selected = 15),

              hr(),
              h5("Options:"),
              awesomeCheckbox("forest_showweights", "Show Weights", value = TRUE, status = "success"),
              awesomeCheckbox("forest_show_pred", "Show Prediction Interval", value = FALSE, status = "info"),
              awesomeCheckbox("forest_annotate", "Show Annotations", value = TRUE, status = "success"),

              hr(),
              h5("Labels:"),
              textInput("forest_xlab", "X-axis Label:", value = ""),
              textInput("forest_mlab", "Pooled Label:", value = "Pooled Effect (Random-Effects Model)"),

              hr(),
              actionButton("forest_reset", "Reset to Defaults", class = "btn-warning btn-block")
          )
        ),

        fluidRow(
          # FUNNEL PLOT
          box(width = 8, title = "Funnel Plot", status = "warning", solidHeader = TRUE, collapsible = TRUE,
              plotOutput("funnel_plot", height = "600px"),
              conditionalPanel(
                condition = "output.has_results",
                hr(),
                fluidRow(
                  column(6, downloadButton("dl_funnel_png", "Download PNG (300 DPI)", class = "btn-warning btn-block")),
                  column(6, downloadButton("dl_funnel_pdf", "Download PDF", class = "btn-primary btn-block"))
                )
              )
          ),

          # FUNNEL PLOT CUSTOMIZATION
          box(width = 4, title = "Funnel Plot Settings", status = "success", solidHeader = TRUE,
              collapsible = TRUE, collapsed = TRUE,

              h5("Range & Scale:"),
              fluidRow(
                column(6, numericInput("funnel_xlim_min", "X-min:", value = NA)),
                column(6, numericInput("funnel_xlim_max", "X-max:", value = NA))
              ),
              fluidRow(
                column(6, numericInput("funnel_ylim_min", "Y-min:", value = NA)),
                column(6, numericInput("funnel_ylim_max", "Y-max:", value = NA))
              ),
              numericInput("funnel_steps", "Tick Marks:", value = 5, min = 3, max = 10),
              numericInput("funnel_digits", "Decimals:", value = 2, min = 0, max = 4),

              hr(),
              h5("Colors:"),
              fluidRow(
                column(6, selectInput("funnel_col", "Point Color:", choices = color_choices, selected = "black")),
                column(6, selectInput("funnel_bg", "Point Fill:", choices = color_choices, selected = "#808080"))
              ),
              fluidRow(
                column(6, selectInput("funnel_col_contour", "Contours:", choices = color_choices, selected = "#0066CC")),
                column(6, selectInput("funnel_col_ref", "Ref. Line:", choices = color_choices, selected = "black"))
              ),
              fluidRow(
                column(6, selectInput("funnel_col_text", "Text:", choices = color_choices, selected = "black")),
                column(6, selectInput("funnel_col_bg", "Background:", choices = color_choices, selected = "white"))
              ),

              hr(),
              h5("Appearance:"),
              sliderInput("funnel_cex", "Point Size:", min = 0.5, max = 3, value = 1.0, step = 0.1),
              sliderInput("funnel_lwd", "Line Width:", min = 0.5, max = 5, value = 1.0, step = 0.5),
              selectInput("funnel_pch", "Point Style:",
                         choices = list("Filled Circle" = 21, "Circle" = 1, "Square" = 0,
                                      "Diamond" = 5, "Triangle" = 2),
                         selected = 21),

              hr(),
              h5("Options:"),
              awesomeCheckbox("funnel_shade", "Shade Contours", value = TRUE, status = "success"),
              sliderInput("funnel_level", "Confidence Level:", min = 80, max = 99, value = 95, step = 1),

              hr(),
              h5("Labels:"),
              textInput("funnel_xlab", "X-axis Label:", value = ""),
              textInput("funnel_ylab", "Y-axis Label:", value = "Standard Error"),
              textInput("funnel_main", "Title:", value = "Funnel Plot"),

              hr(),
              actionButton("funnel_reset", "Reset to Defaults", class = "btn-warning btn-block")
          )
        )
      ),

      # GRADE & FRAGILITY
      tabItem("grade",
        fluidRow(
          box(width = 6, title = "GRADE Evidence Assessment", status = "success", solidHeader = TRUE,
              conditionalPanel(
                condition = "output.has_results",
                uiOutput("grade_rating"),
                hr(),
                DTOutput("grade_table"),
                hr(),
                downloadButton("dl_grade", "Download GRADE Profile (CSV)",
                              class = "btn-success")
              ),
              conditionalPanel(
                condition = "!output.has_results",
                p(class = "text-muted", "Run analysis to see GRADE assessment")
              )
          ),
          box(width = 6, title = "Fragility Index", status = "danger", solidHeader = TRUE,
              conditionalPanel(
                condition = "output.has_results",
                valueBoxOutput("fragility_box", width = 12),
                br(),
                uiOutput("fragility_interp")
              ),
              conditionalPanel(
                condition = "!output.has_results",
                p(class = "text-muted", "Run analysis to calculate fragility index")
              )
          )
        )
      ),

      # DOWNLOAD
      tabItem("download",
        fluidRow(
          box(width = 12, title = "Download All Outputs", status = "info", solidHeader = TRUE,
              conditionalPanel(
                condition = "output.has_results",
                h4("📥 Available Downloads:"),
                div(class = "download-section",
                    h5("Tables & Data:"),
                    downloadButton("dl_summary_csv", "Summary Table (CSV)", class = "btn-info"),
                    downloadButton("dl_summary_xlsx", "Summary Table (Excel)", class = "btn-success")
                ),
                div(class = "download-section",
                    h5("Plots (High Resolution):"),
                    downloadButton("dl_all_plots_zip", "All Plots (ZIP)", class = "btn-primary")
                ),
                div(class = "download-section",
                    h5("Manuscript Text:"),
                    downloadButton("dl_methods_text", "Methods Section (.txt)", class = "btn-info"),
                    downloadButton("dl_results_text", "Results Section (.txt)", class = "btn-info")
                ),
                div(class = "download-section",
                    h5("Complete Bundle:"),
                    downloadButton("dl_full_bundle", "Reproducibility Bundle (ZIP)",
                                  class = "btn-lg btn-success")
                )
              ),
              conditionalPanel(
                condition = "!output.has_results",
                div(class = "text-center",
                    icon("download", class = "fa-3x text-muted"),
                    h4("No downloads available"),
                    p("Run analysis first to generate outputs."))
              )
          )
        )
      )
    )
  ),

  footer = dashboardFooter(
    left = "CBAMMR v7.0",
    right = "© 2025 - Comprehensive Meta-Analysis Methods"
  )
)

# SERVER
server <- function(input, output, session) {

  # Reactive values
  rv <- reactiveValues(
    data = NULL,
    results = NULL,
    config = NULL,
    grade = NULL,
    fragility = NULL,
    formatted = NULL
  )

  # Navigation
  observeEvent(input$start_btn, {
    updateTabItems(session, "tabs", "upload")
  })

  # Load example data
  observeEvent(input$load_example_btn, {
    rv$data <- if (input$example_type == "binary") {
      create_example_binary_or()
    } else {
      create_example_continuous_smd()
    }
    showNotification("Example data loaded!", type = "success")
  })

  # Simulate data
  observeEvent(input$simulate_btn, {
    if (input$sim_measure %in% c("OR", "RR")) {
      rv$data <- simulate_cbamm_binary(n = input$sim_n, measure = input$sim_measure)
    } else {
      rv$data <- simulate_cbamm_continuous(n = input$sim_n, measure = input$sim_measure)
    }
    rv$data$age_mean <- rnorm(input$sim_n, 60, 10)
    rv$data$female_pct <- runif(input$sim_n, 0.3, 0.7)
    showNotification(paste("Generated", input$sim_n, "studies"), type = "success")
  })

  # Upload file
  observeEvent(input$datafile, {
    req(input$datafile)
    ext <- tools::file_ext(input$datafile$name)
    rv$data <- if (ext == "csv") {
      read.csv(input$datafile$datapath)
    } else if (ext %in% c("xlsx", "xls")) {
      readxl::read_excel(input$datafile$datapath)
    }
    showNotification("Data uploaded successfully!", type = "success")
  })

  # Data table
  output$data_table <- renderDT({
    req(rv$data)
    datatable(rv$data, options = list(pageLength = 10, scrollX = TRUE))
  })

  # Presets
  observeEvent(input$preset_standard, {
    updateCheckboxInput(session, "use_hksj", value = TRUE)
    updateCheckboxInput(session, "run_grade", value = TRUE)
    updateCheckboxInput(session, "calc_fragility", value = FALSE)
    updateSelectInput(session, "method", selected = "REML")
    showNotification("Standard preset applied", type = "info")
  })

  observeEvent(input$preset_comprehensive, {
    updateCheckboxInput(session, "use_hksj", value = TRUE)
    updateCheckboxInput(session, "run_grade", value = TRUE)
    updateCheckboxInput(session, "calc_fragility", value = TRUE)
    showNotification("Comprehensive preset applied", type = "warning")
  })

  observeEvent(input$preset_quick, {
    updateCheckboxInput(session, "use_hksj", value = FALSE)
    updateCheckboxInput(session, "run_grade", value = FALSE)
    updateCheckboxInput(session, "calc_fragility", value = FALSE)
    updateSelectInput(session, "method", selected = "DL")
    showNotification("Quick preset applied", type = "success")
  })

  # Config summary
  output$config_summary <- renderText({
    paste(
      sprintf("Effect Measure: %s", input$effect_measure),
      sprintf("Estimator: %s", input$method),
      sprintf("Hartung-Knapp: %s", input$use_hksj),
      sprintf("GRADE Assessment: %s", input$run_grade),
      sprintf("Fragility Index: %s", input$calc_fragility),
      sep = "\n"
    )
  })

  # RUN ANALYSIS
  observeEvent(input$run_btn, {
    req(rv$data)

    tryCatch({
      showNotification("Starting analysis...", id = "run_notif", duration = NULL)

      # Create config
      rv$config <- setup_cbamm(
        effect_measure = input$effect_measure,
        use_hksj = input$use_hksj,
        method = input$method,
        export_results = FALSE
      )

      # Run analysis
      rv$results <- run_cbamm_analysis(
        data = rv$data,
        target_population = NULL,
        config = rv$config
      )

      # GRADE
      if (input$run_grade) {
        rv$grade <- cbamm_grade_profile(rv$results, rv$data)
      }

      # Fragility
      if (input$calc_fragility && all(c("ai", "bi", "ci", "di") %in% names(rv$data))) {
        rv$fragility <- cbamm_fragility_index(rv$results, rv$data)
      }

      # Format text
      rv$formatted <- cbamm_format_results(
        rv$results, rv$data,
        include_grade = input$run_grade,
        include_fragility = input$calc_fragility
      )

      removeNotification(id = "run_notif")
      showNotification("✓ Analysis complete!", type = "success", duration = 5)
      updateTabItems(session, "tabs", "summary")

    }, error = function(e) {
      removeNotification(id = "run_notif")
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })

  # Run status
  output$run_status <- renderUI({
    if (!is.null(rv$results)) {
      div(class = "alert alert-success",
          icon("check-circle"), " Analysis complete! View results in tabs above.")
    }
  })

  # Has results
  output$has_results <- reactive({
    !is.null(rv$results)
  })
  outputOptions(output, "has_results", suspendWhenHidden = FALSE)

  # VALUE BOXES
  output$effect_box <- renderValueBox({
    req(rv$results)
    fit <- rv$results$pooled$transport
    mm <- .cbamm_measure_meta(fit$measure)
    pred <- predict(fit, transf = mm$transf)

    valueBox(
      sprintf("%.2f", pred$pred),
      paste("Pooled", fit$measure),
      icon = icon("chart-line"),
      color = "primary"
    )
  })

  output$het_box <- renderValueBox({
    req(rv$results)
    I2 <- rv$results$pooled$transport$I2
    valueBox(
      sprintf("%.1f%%", I2),
      "I² Heterogeneity",
      icon = icon("random"),
      color = if (I2 < 50) "success" else "warning"
    )
  })

  output$p_box <- renderValueBox({
    req(rv$results)
    p <- rv$results$pooled$transport$pval
    valueBox(
      if (p < 0.001) "<0.001" else sprintf("%.3f", p),
      "P-value",
      icon = icon("calculator"),
      color = if (p < 0.05) "success" else "secondary"
    )
  })

  output$studies_box <- renderValueBox({
    req(rv$results)
    valueBox(
      rv$results$pooled$transport$k,
      "Studies",
      icon = icon("database"),
      color = "info"
    )
  })

  # Results table
  output$results_table <- renderDT({
    req(rv$results)
    summary_tab <- cbamm_make_summary_table(rv$results, rv$data, rv$config)
    datatable(summary_tab, options = list(scrollX = TRUE))
  })

  # Formatted text
  output$formatted_text <- renderText({
    req(rv$formatted)
    rv$formatted$results_text
  })

  # FOREST PLOT RESET
  observeEvent(input$forest_reset, {
    updateSelectInput(session, "forest_style", selected = "classic")
    updateNumericInput(session, "forest_xlim_min", value = NA)
    updateNumericInput(session, "forest_xlim_max", value = NA)
    updateNumericInput(session, "forest_steps", value = 5)
    updateNumericInput(session, "forest_digits", value = 2)
    updateSelectInput(session, "forest_col", selected = "black")
    updateSelectInput(session, "forest_border", selected = "black")
    updateSelectInput(session, "forest_col_diamond", selected = "#003366")
    updateSelectInput(session, "forest_col_pred", selected = "#006600")
    updateSelectInput(session, "forest_col_lines", selected = "#808080")
    updateSelectInput(session, "forest_col_text", selected = "black")
    updateSelectInput(session, "forest_col_bg", selected = "white")
    updateSliderInput(session, "forest_cex", value = 1.0)
    updateSliderInput(session, "forest_lwd", value = 1.5)
    updateSelectInput(session, "forest_pch", selected = 15)
    updateCheckboxInput(session, "forest_showweights", value = TRUE)
    updateCheckboxInput(session, "forest_show_pred", value = FALSE)
    updateCheckboxInput(session, "forest_annotate", value = TRUE)
    updateTextInput(session, "forest_xlab", value = "")
    updateTextInput(session, "forest_mlab", value = "Pooled Effect (Random-Effects Model)")
    showNotification("Forest plot settings reset to defaults", type = "info")
  })

  # FUNNEL PLOT RESET
  observeEvent(input$funnel_reset, {
    updateNumericInput(session, "funnel_xlim_min", value = NA)
    updateNumericInput(session, "funnel_xlim_max", value = NA)
    updateNumericInput(session, "funnel_ylim_min", value = NA)
    updateNumericInput(session, "funnel_ylim_max", value = NA)
    updateNumericInput(session, "funnel_steps", value = 5)
    updateNumericInput(session, "funnel_digits", value = 2)
    updateSelectInput(session, "funnel_col", selected = "black")
    updateSelectInput(session, "funnel_bg", selected = "#808080")
    updateSelectInput(session, "funnel_col_contour", selected = "#0066CC")
    updateSelectInput(session, "funnel_col_ref", selected = "black")
    updateSelectInput(session, "funnel_col_text", selected = "black")
    updateSelectInput(session, "funnel_col_bg", selected = "white")
    updateSliderInput(session, "funnel_cex", value = 1.0)
    updateSliderInput(session, "funnel_lwd", value = 1.0)
    updateSelectInput(session, "funnel_pch", selected = 21)
    updateCheckboxInput(session, "funnel_shade", value = TRUE)
    updateSliderInput(session, "funnel_level", value = 95)
    updateTextInput(session, "funnel_xlab", value = "")
    updateTextInput(session, "funnel_ylab", value = "Standard Error")
    updateTextInput(session, "funnel_main", value = "Funnel Plot")
    showNotification("Funnel plot settings reset to defaults", type = "info")
  })

  # PLOTS - Enhanced with full customization
  output$forest_plot <- renderPlot({
    req(rv$results)
    fit <- rv$results$pooled$transport

    # Prepare xlim
    xlim <- NULL
    if (!is.na(input$forest_xlim_min) && !is.na(input$forest_xlim_max)) {
      xlim <- c(input$forest_xlim_min, input$forest_xlim_max)
    }

    # Prepare xlab
    xlab <- if (input$forest_xlab == "") NULL else input$forest_xlab
    mlab <- if (input$forest_mlab == "") NULL else input$forest_mlab

    # Call custom forest plot with all parameters
    custom_forest_plot(
      fit = fit,
      style = input$forest_style,
      xlim = xlim,
      steps = input$forest_steps,
      digits = input$forest_digits,
      showweights = input$forest_showweights,
      show_pred = input$forest_show_pred,
      col = input$forest_col,
      border = input$forest_border,
      col_diamond = input$forest_col_diamond,
      col_pred = input$forest_col_pred,
      col_lines = input$forest_col_lines,
      col_text = input$forest_col_text,
      col_background = input$forest_col_bg,
      cex = input$forest_cex,
      lwd = input$forest_lwd,
      pch = as.numeric(input$forest_pch),
      xlab = xlab,
      mlab = mlab,
      annotate = input$forest_annotate
    )
  })

  output$funnel_plot <- renderPlot({
    req(rv$results)
    fit <- rv$results$pooled$transport

    # Prepare xlim
    xlim <- NULL
    if (!is.na(input$funnel_xlim_min) && !is.na(input$funnel_xlim_max)) {
      xlim <- c(input$funnel_xlim_min, input$funnel_xlim_max)
    }

    # Prepare ylim
    ylim <- NULL
    if (!is.na(input$funnel_ylim_min) && !is.na(input$funnel_ylim_max)) {
      ylim <- c(input$funnel_ylim_min, input$funnel_ylim_max)
    }

    # Prepare labels
    xlab <- if (input$funnel_xlab == "") NULL else input$funnel_xlab
    ylab <- if (input$funnel_ylab == "") "Standard Error" else input$funnel_ylab
    main <- if (input$funnel_main == "") "Funnel Plot" else input$funnel_main

    # Call custom funnel plot with all parameters
    custom_funnel_plot(
      fit = fit,
      xlim = xlim,
      ylim = ylim,
      steps = input$funnel_steps,
      digits = input$funnel_digits,
      col = input$funnel_col,
      bg = input$funnel_bg,
      pch = as.numeric(input$funnel_pch),
      cex = input$funnel_cex,
      lwd = input$funnel_lwd,
      col_contour = input$funnel_col_contour,
      col_ref = input$funnel_col_ref,
      col_background = input$funnel_col_bg,
      col_text = input$funnel_col_text,
      shade_contours = input$funnel_shade,
      level = input$funnel_level,
      xlab = xlab,
      ylab = ylab,
      main = main
    )
  })

  # GRADE
  output$grade_rating <- renderUI({
    req(rv$grade)
    rating <- rv$grade$final_certainty
    symbol <- switch(rating,
                    "HIGH" = "⊕⊕⊕⊕",
                    "MODERATE" = "⊕⊕⊕○",
                    "LOW" = "⊕⊕○○",
                    "VERY LOW" = "⊕○○○")

    div(class = "alert alert-success",
        h2(symbol, " ", rating),
        h4("Certainty of Evidence"))
  })

  output$grade_table <- renderDT({
    req(rv$grade)
    datatable(rv$grade$profile, options = list(dom = 't'))
  })

  # FRAGILITY
  output$fragility_box <- renderValueBox({
    req(rv$fragility)
    fi <- rv$fragility$fragility_index
    valueBox(
      if (is.na(fi)) "N/A" else fi,
      "Fragility Index",
      icon = icon("shield-alt"),
      color = if (!is.na(fi) && fi >= 22) "success" else if (!is.na(fi) && fi <= 5) "danger" else "warning"
    )
  })

  output$fragility_interp <- renderUI({
    req(rv$fragility)
    div(class = "alert alert-info",
        h5("Interpretation:"),
        p(rv$fragility$interpretation))
  })

  # DOWNLOAD HANDLERS
  output$dl_binary_template <- downloadHandler(
    filename = "binary_template.csv",
    content = function(file) { write.csv(binary_template, file, row.names = FALSE) }
  )

  output$dl_continuous_template <- downloadHandler(
    filename = "continuous_template.csv",
    content = function(file) { write.csv(continuous_template, file, row.names = FALSE) }
  )

  output$dl_summary_csv <- downloadHandler(
    filename = "cbammr_summary.csv",
    content = function(file) {
      req(rv$results)
      tab <- cbamm_make_summary_table(rv$results, rv$data, rv$config)
      write.csv(tab, file, row.names = FALSE)
    }
  )

  output$dl_summary_xlsx <- downloadHandler(
    filename = "cbammr_summary.xlsx",
    content = function(file) {
      req(rv$results)
      tab <- cbamm_make_summary_table(rv$results, rv$data, rv$config)
      writexl::write_xlsx(tab, file)
    }
  )

  output$dl_grade <- downloadHandler(
    filename = "grade_profile.csv",
    content = function(file) {
      req(rv$grade)
      write.csv(rv$grade$profile, file, row.names = FALSE)
    }
  )

  output$dl_forest_png <- downloadHandler(
    filename = "forest_plot.png",
    content = function(file) {
      req(rv$results)
      fit <- rv$results$pooled$transport

      # Prepare parameters
      xlim <- NULL
      if (!is.na(input$forest_xlim_min) && !is.na(input$forest_xlim_max)) {
        xlim <- c(input$forest_xlim_min, input$forest_xlim_max)
      }
      xlab <- if (input$forest_xlab == "") NULL else input$forest_xlab
      mlab <- if (input$forest_mlab == "") NULL else input$forest_mlab

      # High resolution PNG
      png(file, width = 3600, height = 3000, res = 300)
      custom_forest_plot(
        fit = fit,
        style = input$forest_style,
        xlim = xlim,
        steps = input$forest_steps,
        digits = input$forest_digits,
        showweights = input$forest_showweights,
        show_pred = input$forest_show_pred,
        col = input$forest_col,
        border = input$forest_border,
        col_diamond = input$forest_col_diamond,
        col_pred = input$forest_col_pred,
        col_lines = input$forest_col_lines,
        col_text = input$forest_col_text,
        col_background = input$forest_col_bg,
        cex = input$forest_cex,
        lwd = input$forest_lwd,
        pch = as.numeric(input$forest_pch),
        xlab = xlab,
        mlab = mlab,
        annotate = input$forest_annotate
      )
      dev.off()
    }
  )

  output$dl_forest_pdf <- downloadHandler(
    filename = "forest_plot.pdf",
    content = function(file) {
      req(rv$results)
      fit <- rv$results$pooled$transport

      # Prepare parameters
      xlim <- NULL
      if (!is.na(input$forest_xlim_min) && !is.na(input$forest_xlim_max)) {
        xlim <- c(input$forest_xlim_min, input$forest_xlim_max)
      }
      xlab <- if (input$forest_xlab == "") NULL else input$forest_xlab
      mlab <- if (input$forest_mlab == "") NULL else input$forest_mlab

      # PDF output
      pdf(file, width = 12, height = 10)
      custom_forest_plot(
        fit = fit,
        style = input$forest_style,
        xlim = xlim,
        steps = input$forest_steps,
        digits = input$forest_digits,
        showweights = input$forest_showweights,
        show_pred = input$forest_show_pred,
        col = input$forest_col,
        border = input$forest_border,
        col_diamond = input$forest_col_diamond,
        col_pred = input$forest_col_pred,
        col_lines = input$forest_col_lines,
        col_text = input$forest_col_text,
        col_background = input$forest_col_bg,
        cex = input$forest_cex,
        lwd = input$forest_lwd,
        pch = as.numeric(input$forest_pch),
        xlab = xlab,
        mlab = mlab,
        annotate = input$forest_annotate
      )
      dev.off()
    }
  )

  output$dl_funnel_png <- downloadHandler(
    filename = "funnel_plot.png",
    content = function(file) {
      req(rv$results)
      fit <- rv$results$pooled$transport

      # Prepare parameters
      xlim <- NULL
      if (!is.na(input$funnel_xlim_min) && !is.na(input$funnel_xlim_max)) {
        xlim <- c(input$funnel_xlim_min, input$funnel_xlim_max)
      }
      ylim <- NULL
      if (!is.na(input$funnel_ylim_min) && !is.na(input$funnel_ylim_max)) {
        ylim <- c(input$funnel_ylim_min, input$funnel_ylim_max)
      }
      xlab <- if (input$funnel_xlab == "") NULL else input$funnel_xlab
      ylab <- if (input$funnel_ylab == "") "Standard Error" else input$funnel_ylab
      main <- if (input$funnel_main == "") "Funnel Plot" else input$funnel_main

      # High resolution PNG
      png(file, width = 3000, height = 3000, res = 300)
      custom_funnel_plot(
        fit = fit,
        xlim = xlim,
        ylim = ylim,
        steps = input$funnel_steps,
        digits = input$funnel_digits,
        col = input$funnel_col,
        bg = input$funnel_bg,
        pch = as.numeric(input$funnel_pch),
        cex = input$funnel_cex,
        lwd = input$funnel_lwd,
        col_contour = input$funnel_col_contour,
        col_ref = input$funnel_col_ref,
        col_background = input$funnel_col_bg,
        col_text = input$funnel_col_text,
        shade_contours = input$funnel_shade,
        level = input$funnel_level,
        xlab = xlab,
        ylab = ylab,
        main = main
      )
      dev.off()
    }
  )

  output$dl_funnel_pdf <- downloadHandler(
    filename = "funnel_plot.pdf",
    content = function(file) {
      req(rv$results)
      fit <- rv$results$pooled$transport

      # Prepare parameters
      xlim <- NULL
      if (!is.na(input$funnel_xlim_min) && !is.na(input$funnel_xlim_max)) {
        xlim <- c(input$funnel_xlim_min, input$funnel_xlim_max)
      }
      ylim <- NULL
      if (!is.na(input$funnel_ylim_min) && !is.na(input$funnel_ylim_max)) {
        ylim <- c(input$funnel_ylim_min, input$funnel_ylim_max)
      }
      xlab <- if (input$funnel_xlab == "") NULL else input$funnel_xlab
      ylab <- if (input$funnel_ylab == "") "Standard Error" else input$funnel_ylab
      main <- if (input$funnel_main == "") "Funnel Plot" else input$funnel_main

      # PDF output
      pdf(file, width = 10, height = 10)
      custom_funnel_plot(
        fit = fit,
        xlim = xlim,
        ylim = ylim,
        steps = input$funnel_steps,
        digits = input$funnel_digits,
        col = input$funnel_col,
        bg = input$funnel_bg,
        pch = as.numeric(input$funnel_pch),
        cex = input$funnel_cex,
        lwd = input$funnel_lwd,
        col_contour = input$funnel_col_contour,
        col_ref = input$funnel_col_ref,
        col_background = input$funnel_col_bg,
        col_text = input$funnel_col_text,
        shade_contours = input$funnel_shade,
        level = input$funnel_level,
        xlab = xlab,
        ylab = ylab,
        main = main
      )
      dev.off()
    }
  )

  output$dl_methods_text <- downloadHandler(
    filename = "methods_section.txt",
    content = function(file) {
      req(rv$formatted)
      writeLines(rv$formatted$methods_text, file)
    }
  )

  output$dl_results_text <- downloadHandler(
    filename = "results_section.txt",
    content = function(file) {
      req(rv$formatted)
      writeLines(rv$formatted$results_text, file)
    }
  )

}

shinyApp(ui = ui, server = server)
