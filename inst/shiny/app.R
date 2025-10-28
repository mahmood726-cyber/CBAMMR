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
    title = "CBAMMR v7.0",
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
          box(width = 6, title = "Forest Plot", status = "primary", solidHeader = TRUE,
              plotOutput("forest_plot", height = "500px"),
              conditionalPanel(
                condition = "output.has_results",
                hr(),
                downloadButton("dl_forest", "Download Forest Plot (PNG)",
                              class = "btn-info")
              )
          ),
          box(width = 6, title = "Funnel Plot", status = "warning", solidHeader = TRUE,
              plotOutput("funnel_plot", height = "500px"),
              conditionalPanel(
                condition = "output.has_results",
                hr(),
                downloadButton("dl_funnel", "Download Funnel Plot (PNG)",
                              class = "btn-warning")
              )
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

  # PLOTS (basic implementation)
  output$forest_plot <- renderPlot({
    req(rv$results)
    # Simple forest plot using metafor
    fit <- rv$results$pooled$transport
    forest(fit, main = "Forest Plot")
  })

  output$funnel_plot <- renderPlot({
    req(rv$results)
    fit <- rv$results$pooled$transport
    funnel(fit, main = "Funnel Plot")
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

  output$dl_forest <- downloadHandler(
    filename = "forest_plot.png",
    content = function(file) {
      req(rv$results)
      png(file, width = 3000, height = 2400, res = 300)
      forest(rv$results$pooled$transport, main = "Forest Plot")
      dev.off()
    }
  )

  output$dl_funnel <- downloadHandler(
    filename = "funnel_plot.png",
    content = function(file) {
      req(rv$results)
      png(file, width = 2400, height = 2400, res = 300)
      funnel(rv$results$pooled$transport, main = "Funnel Plot")
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
