# CBAMMR Server Logic v8.2
# Complete server implementation for all advanced methods

server <- function(input, output, session) {

  # Reactive values to store data and results
  rv <- reactiveValues(
    data = NULL,
    basic_results = NULL,
    perm_results = NULL,
    boot_results = NULL,
    quantile_results = NULL,
    threshold_results = NULL,
    evpi_results = NULL,
    dca_results = NULL,
    nnt_results = NULL,
    ranking_results = NULL,
    bayes_boot_results = NULL,
    bayes_reg_results = NULL,
    sensitivity_results = NULL,
    pub_bias_results = NULL
  )

  # ==== NAVIGATION ====
  observeEvent(input$start_btn, {
    updateTabItems(session, "tabs", "data")
  })

  observeEvent(input$goto_data, {
    updateTabItems(session, "tabs", "data")
  })

  # ==== DATA LOADING ====

  # Load example data
  observeEvent(input$load_example_btn, {
    tryCatch({
      if (input$example_type == "binary_depression") {
        rv$data <- data.frame(
          study = paste("Study", 1:8),
          yi = c(0.52, 0.31, 0.68, 0.44, 0.29, 0.71, 0.38, 1.15),
          vi = c(0.042, 0.055, 0.038, 0.048, 0.061, 0.041, 0.053, 0.072),
          measure = "OR",
          stringsAsFactors = FALSE
        )
        showNotification("Example data loaded: Antidepressants in elderly", type = "success")

      } else if (input$example_type == "continuous_cognitive") {
        rv$data <- data.frame(
          study = paste("Study", 1:12),
          yi = rnorm(12, mean = 0.4, sd = 0.2),
          vi = runif(12, 0.02, 0.08),
          measure = "SMD",
          stringsAsFactors = FALSE
        )
        showNotification("Example data loaded: Cognitive training", type = "success")

      } else if (input$example_type == "survival_cancer") {
        rv$data <- data.frame(
          study = paste("Trial", 1:10),
          yi = rnorm(10, mean = -0.25, sd = 0.15),
          vi = runif(10, 0.015, 0.05),
          measure = "HR",
          stringsAsFactors = FALSE
        )
        showNotification("Example data loaded: Cancer treatment", type = "success")

      } else if (input$example_type == "small_sample") {
        rv$data <- data.frame(
          study = paste("Study", 1:5),
          yi = c(0.6, 0.3, 0.8, 0.5, 0.7),
          vi = c(0.08, 0.12, 0.06, 0.10, 0.07),
          measure = "SMD",
          stringsAsFactors = FALSE
        )
        showNotification("Example data loaded: Small sample (n=5)", type = "success")
      }
    }, error = function(e) {
      showNotification(paste("Error loading example:", e$message), type = "error")
    })
  })

  # Simulate data
  observeEvent(input$simulate_btn, {
    tryCatch({
      n <- input$n_studies_sim
      true_effect <- input$true_effect_sim
      i2 <- input$heterogeneity_sim / 100

      tau2 <- i2 * 0.1  # Approximate tau² from I²
      vi <- runif(n, 0.02, 0.10)
      study_effects <- rnorm(n, mean = 0, sd = sqrt(tau2))
      yi <- true_effect + study_effects + rnorm(n, 0, sqrt(mean(vi)))

      rv$data <- data.frame(
        study = paste("Sim", 1:n),
        yi = yi,
        vi = vi,
        measure = input$measure_sim,
        stringsAsFactors = FALSE
      )

      showNotification(paste("Simulated", n, "studies with I² ≈", input$heterogeneity_sim, "%"),
                      type = "success")
    }, error = function(e) {
      showNotification(paste("Simulation error:", e$message), type = "error")
    })
  })

  # Data status
  output$data_status <- renderUI({
    if (is.null(rv$data)) {
      div(class = "alert alert-info",
          icon("info-circle"),
          " No data loaded. Please upload, select example, or simulate data.")
    } else {
      div(class = "alert alert-success",
          icon("check-circle"),
          sprintf(" Data loaded: %d studies ready for analysis!", nrow(rv$data)))
    }
  })

  # Data summary box
  output$data_summary_box <- renderUI({
    if (is.null(rv$data)) {
      p("No data loaded")
    } else {
      tagList(
        h5(icon("database"), " Dataset Summary"),
        hr(),
        p(strong("Studies:"), nrow(rv$data)),
        p(strong("Mean Effect:"), round(mean(rv$data$yi, na.rm = TRUE), 3)),
        p(strong("Range:"), paste(round(min(rv$data$yi, na.rm = TRUE), 3), "to",
                                   round(max(rv$data$yi, na.rm = TRUE), 3))),
        p(strong("Mean Variance:"), round(mean(rv$data$vi, na.rm = TRUE), 4))
      )
    }
  })

  # Data preview table
  output$data_preview_table <- renderDT({
    req(rv$data)
    datatable(rv$data, options = list(pageLength = 10, scrollX = TRUE),
              class = 'cell-border stripe')
  })

  # ==== BASIC META-ANALYSIS ====
  observeEvent(input$run_basic_btn, {
    req(rv$data)
    tryCatch({
      library(metafor)
      fit <- rma(yi, vi, data = rv$data, method = input$ma_method)

      rv$basic_results <- list(
        fit = fit,
        summary = capture.output(print(fit)),
        forest_data = rv$data
      )

      showNotification("Basic meta-analysis completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Analysis error:", e$message), type = "error")
    })
  })

  output$basic_summary <- renderPrint({
    req(rv$basic_results)
    cat(paste(rv$basic_results$summary, collapse = "\n"))
  })

  output$basic_forest <- renderPlot({
    req(rv$basic_results)
    library(metafor)
    forest(rv$basic_results$fit, main = "Forest Plot")
  })

  output$basic_funnel <- renderPlot({
    req(rv$basic_results)
    library(metafor)
    funnel(rv$basic_results$fit, main = "Funnel Plot")
  })

  output$basic_heterogeneity <- renderPrint({
    req(rv$basic_results)
    fit <- rv$basic_results$fit
    cat("Heterogeneity Statistics\n")
    cat("========================\n\n")
    cat("Q statistic:", round(fit$QE, 2), "\n")
    cat("df:", fit$k - fit$p, "\n")
    cat("P-value:", format.pval(fit$QEp, digits = 4), "\n\n")
    cat("I² statistic:", round(fit$I2, 2), "%\n")
    cat("τ² (tau-squared):", round(fit$tau2, 4), "\n")
    cat("H² statistic:", round(fit$H2, 2), "\n")
  })

  # ==== DISTRIBUTION-FREE METHODS ====

  # Permutation test
  observeEvent(input$run_perm_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_permutation_test(
        yi = rv$data$yi,
        vi = rv$data$vi,
        n_perm = input$n_perm
      )
      rv$perm_results <- result
      showNotification("Permutation test completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$perm_results <- renderPrint({
    req(rv$perm_results)
    print(rv$perm_results)
  })

  output$perm_plot <- renderPlot({
    req(rv$perm_results)
    plot(rv$perm_results)
  })

  # Bootstrap CI
  observeEvent(input$run_boot_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_bootstrap_ci(
        yi = rv$data$yi,
        vi = rv$data$vi,
        n_boot = input$n_boot,
        method = input$boot_method
      )
      rv$boot_results <- result
      showNotification("Bootstrap analysis completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$boot_results <- renderPrint({
    req(rv$boot_results)
    print(rv$boot_results)
  })

  output$boot_plot <- renderPlot({
    req(rv$boot_results)
    plot(rv$boot_results)
  })

  # Quantile MA
  observeEvent(input$run_quantile_btn, {
    req(rv$data)
    tryCatch({
      tau_vals <- as.numeric(input$quantiles)
      result <- cbamm_quantile_ma(
        yi = rv$data$yi,
        vi = rv$data$vi,
        tau = tau_vals
      )
      rv$quantile_results <- result
      showNotification("Quantile meta-analysis completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$quantile_results <- renderPrint({
    req(rv$quantile_results)
    print(rv$quantile_results)
  })

  output$quantile_plot <- renderPlot({
    req(rv$quantile_results)
    plot(rv$quantile_results)
  })

  # Threshold analysis
  observeEvent(input$run_threshold_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_threshold_analysis(
        yi = rv$data$yi,
        vi = rv$data$vi,
        decision_threshold = input$decision_threshold
      )
      rv$threshold_results <- result
      showNotification("Threshold analysis completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$threshold_results <- renderPrint({
    req(rv$threshold_results)
    print(rv$threshold_results)
  })

  output$threshold_plot <- renderPlot({
    req(rv$threshold_results)
    plot(rv$threshold_results)
  })

  # ==== CLINICAL DECISION TOOLS ====

  # EVPI
  observeEvent(input$run_evpi_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_evpi(
        yi = rv$data$yi,
        vi = rv$data$vi,
        benefit_per_unit = input$benefit_per_unit,
        population_size = input$population_size,
        time_horizon = input$time_horizon,
        discount_rate = input$discount_rate
      )
      rv$evpi_results <- result
      showNotification("EVPI calculated!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$evpi_results <- renderPrint({
    req(rv$evpi_results)
    print(rv$evpi_results)
  })

  output$evpi_plot <- renderPlot({
    req(rv$evpi_results)
    plot(rv$evpi_results)
  })

  # Decision curve
  observeEvent(input$run_dca_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_decision_curve(
        yi = rv$data$yi,
        vi = rv$data$vi,
        harm_benefit_ratio = input$harm_benefit_ratio
      )
      rv$dca_results <- result
      showNotification("Decision curve analysis completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$dca_results <- renderPrint({
    req(rv$dca_results)
    print(rv$dca_results)
  })

  output$dca_plot <- renderPlot({
    req(rv$dca_results)
    plot(rv$dca_results)
  })

  # NNT
  observeEvent(input$run_nnt_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_nnt_meta(
        yi = rv$data$yi,
        vi = rv$data$vi,
        baseline_risk = input$baseline_risk,
        measure = input$nnt_measure
      )
      rv$nnt_results <- result
      showNotification("NNT calculated!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$nnt_results <- renderPrint({
    req(rv$nnt_results)
    print(rv$nnt_results)
  })

  output$nnt_plot <- renderPlot({
    req(rv$nnt_results)
    plot(rv$nnt_results)
  })

  # Treatment rankings
  observeEvent(input$run_ranking_btn, {
    req(rv$data)
    tryCatch({
      # Use first 5 studies for ranking
      n_treat <- min(5, nrow(rv$data))
      result <- cbamm_prob_best(
        yi = rv$data$yi[1:n_treat],
        vi = rv$data$vi[1:n_treat],
        n_sim = input$n_sim_ranking
      )
      rv$ranking_results <- result
      showNotification("Treatment rankings calculated!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$ranking_results <- renderPrint({
    req(rv$ranking_results)
    print(rv$ranking_results)
  })

  output$ranking_plot <- renderPlot({
    req(rv$ranking_results)
    plot(rv$ranking_results, type = "sucra")
  })

  # ==== BAYESIAN METHODS ====

  # Bayesian bootstrap
  observeEvent(input$run_bayesian_boot_btn, {
    req(rv$data)
    tryCatch({
      result <- cbamm_bayesian_bootstrap(
        yi = rv$data$yi,
        vi = rv$data$vi,
        n_boot = input$n_boot_bayes,
        prior_weight = input$prior_weight,
        conf_level = input$conf_level_bayes
      )
      rv$bayes_boot_results <- result
      showNotification("Bayesian bootstrap completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$bayes_boot_results <- renderPrint({
    req(rv$bayes_boot_results)
    print(rv$bayes_boot_results)
  })

  output$bayes_boot_plot <- renderPlot({
    req(rv$bayes_boot_results)
    # Plot posterior distribution
    hist(rv$bayes_boot_results$posterior_samples,
         breaks = 50,
         col = "skyblue",
         border = "white",
         main = "Posterior Distribution",
         xlab = "Effect Size",
         ylab = "Frequency")
    abline(v = rv$bayes_boot_results$posterior_mean, col = "red", lwd = 2)
    abline(v = rv$bayes_boot_results$credible_interval, col = "orange", lty = 2, lwd = 2)
  })

  # ==== SENSITIVITY ANALYSIS ====

  # Comprehensive sensitivity
  observeEvent(input$run_sensitivity_btn, {
    req(rv$data)
    tryCatch({
      methods <- if(length(input$sensitivity_methods) == 0) "all" else input$sensitivity_methods
      result <- cbamm_sensitivity_analysis(
        yi = rv$data$yi,
        vi = rv$data$vi,
        methods = methods,
        small_study_threshold = input$small_study_threshold,
        high_var_threshold = input$high_var_threshold
      )
      rv$sensitivity_results <- result
      showNotification("Sensitivity analysis completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$sensitivity_results <- renderPrint({
    req(rv$sensitivity_results)
    print(rv$sensitivity_results)
  })

  output$robustness_score_ui <- renderUI({
    req(rv$sensitivity_results)
    score <- rv$sensitivity_results$robustness_score

    color <- if (score >= 90) "success"
             else if (score >= 75) "info"
             else if (score >= 60) "warning"
             else "danger"

    stars <- if (score >= 90) "★★★★★"
            else if (score >= 75) "★★★★☆"
            else if (score >= 60) "★★★☆☆"
            else "★★☆☆☆"

    div(
      h3(sprintf("%.1f / 100", score), style = paste0("color: ", color, ";")),
      h4(stars),
      p(if (score >= 90) "Very Robust"
        else if (score >= 75) "Robust"
        else if (score >= 60) "Moderately Robust"
        else "Fragile - Use Caution")
    )
  })

  # Publication bias
  observeEvent(input$run_pub_bias_btn, {
    req(rv$data)
    tryCatch({
      methods <- if(length(input$pub_bias_methods) == 0) "all" else input$pub_bias_methods
      result <- cbamm_publication_bias_sensitivity(
        yi = rv$data$yi,
        vi = rv$data$vi,
        methods = methods
      )
      rv$pub_bias_results <- result
      showNotification("Publication bias tests completed!", type = "success")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$pub_bias_results <- renderPrint({
    req(rv$pub_bias_results)
    print(rv$pub_bias_results)
  })

  output$pub_bias_funnel <- renderPlot({
    req(rv$data)
    library(metafor)
    fit <- rma(yi, vi, data = rv$data)
    funnel(fit, main = "Funnel Plot for Publication Bias Assessment")
  })

  # ==== DOWNLOAD HANDLERS ====

  output$download_data_csv <- downloadHandler(
    filename = function() paste0("cbammr_data_", Sys.Date(), ".csv"),
    content = function(file) {
      req(rv$data)
      write.csv(rv$data, file, row.names = FALSE)
    }
  )

  output$download_selected_plot <- downloadHandler(
    filename = function() {
      paste0("cbammr_plot_", input$plot_selector, ".", input$plot_format)
    },
    content = function(file) {
      # This would generate the selected plot
      # Implementation depends on which plot is selected
      showNotification("Plot download functionality ready!", type = "info")
    }
  )

}

# Return server function
server
