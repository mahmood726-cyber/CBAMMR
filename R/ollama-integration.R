#' CBAMMR Ollama AI Integration
#'
#' Integrate local LLMs via Ollama for intelligent meta-analysis interpretation,
#' methodology recommendations, and natural language explanations.
#'
#' @name cbamm_ollama
#' @rdname cbamm_ollama
NULL

#' AI-Powered Meta-Analysis Interpretation
#'
#' Uses Ollama (local LLM) to provide intelligent interpretation of meta-analysis
#' results, methodology recommendations, and plain-language explanations.
#'
#' @param results CBAMM results object from cbamm_auto() or run_cbamm_analysis()
#' @param data Meta-analysis data frame
#' @param model Ollama model to use. Options: "llama3.2", "mistral", "phi3", "qwen2.5"
#'   Default: "llama3.2" (recommended for medical/scientific analysis)
#' @param tasks Vector of AI tasks. Options:
#'   - "interpret_results": Explain what the results mean
#'   - "assess_quality": Evaluate study quality and risk of bias
#'   - "recommend_methods": Suggest optimal methods
#'   - "identify_biases": Detect potential biases
#'   - "clinical_implications": Explain clinical significance
#'   - "limitations": Identify limitations
#'   - "future_research": Suggest future research directions
#'   - "all": Run all tasks (default)
#' @param temperature Creativity level (0-1). Lower = more conservative. Default: 0.3
#' @param context_length Maximum context length. Default: 4096
#' @param ollama_host Ollama server URL. Default: "http://localhost:11434"
#'
#' @return List containing:
#'   \item{interpretations}{AI-generated interpretations for each task}
#'   \item{recommendations}{Methodology recommendations}
#'   \item{quality_assessment}{Quality and bias assessment}
#'   \item{plain_language_summary}{Non-technical summary}
#'   \item{clinical_insights}{Clinical implications}
#'   \item{metadata}{Model info, timestamp, token usage}
#'
#' @details
#' This function uses Ollama to run local LLMs for intelligent meta-analysis
#' interpretation. Benefits:
#'
#' **Privacy:** All processing happens locally - no data sent to external APIs
#' **Scientific:** Models trained on medical/scientific literature
#' **Contextual:** Understands meta-analysis methodology and statistics
#' **Explanatory:** Provides plain-language explanations for clinicians/patients
#'
#' **Supported Models:**
#' - llama3.2 (3B/8B): Best for medical/scientific (RECOMMENDED)
#' - mistral (7B): Fast, good general knowledge
#' - phi3 (3.8B): Efficient, good reasoning
#' - qwen2.5 (7B): Strong multilingual support
#'
#' **Requirements:**
#' 1. Install Ollama: https://ollama.ai
#' 2. Pull model: `ollama pull llama3.2`
#' 3. Start server: `ollama serve` (runs on port 11434)
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' results <- cbamm_auto(dat.bcg)
#' ai_interp <- cbamm_ollama_interpret(results, dat.bcg)
#' print(ai_interp$plain_language_summary)
#'
#' # Specific tasks
#' ai_interp <- cbamm_ollama_interpret(
#'   results, dat.bcg,
#'   tasks = c("interpret_results", "clinical_implications"),
#'   model = "llama3.2",
#'   temperature = 0.2  # More conservative
#' )
#'
#' # Access specific interpretations
#' cat(ai_interp$interpretations$interpret_results)
#' cat(ai_interp$clinical_insights)
#' }
#'
#' @export
cbamm_ollama_interpret <- function(results,
                                   data = NULL,
                                   model = c("llama3.2", "mistral", "phi3", "qwen2.5"),
                                   tasks = "all",
                                   temperature = 0.3,
                                   context_length = 4096,
                                   ollama_host = "http://localhost:11434") {

  model <- match.arg(model)

  if ("all" %in% tasks) {
    tasks <- c("interpret_results", "assess_quality", "recommend_methods",
               "identify_biases", "clinical_implications", "limitations",
               "future_research")
  }

  # Check Ollama availability
  if (!.check_ollama_available(ollama_host)) {
    stop(
      "Ollama not available. Please:\n",
      "  1. Install Ollama: https://ollama.ai\n",
      "  2. Pull model: ollama pull ", model, "\n",
      "  3. Start server: ollama serve\n",
      "  4. Verify at: ", ollama_host
    )
  }

  # Check model availability
  if (!.check_ollama_model_available(model, ollama_host)) {
    message("Model '", model, "' not found. Pulling...")
    .ollama_pull_model(model, ollama_host)
  }

  message("\n🤖 CBAMMR AI-Powered Interpretation")
  message("Model: ", model)
  message("Tasks: ", paste(tasks, collapse = ", "))
  message("\n")

  interpretations <- list()

  # Extract key results for context
  context <- .build_analysis_context(results, data)

  # Run each AI task
  for (task in tasks) {
    message("Running: ", task, "...")

    prompt <- .build_task_prompt(task, context, results, data)

    ai_response <- .query_ollama(
      prompt = prompt,
      model = model,
      temperature = temperature,
      context_length = context_length,
      host = ollama_host
    )

    interpretations[[task]] <- ai_response$text
  }

  # Generate plain language summary
  message("Generating plain language summary...")
  plain_summary <- .generate_plain_summary(interpretations, results, model, ollama_host)

  # Extract specific insights
  quality_assessment <- if ("assess_quality" %in% tasks) {
    interpretations$assess_quality
  } else NULL

  clinical_insights <- if ("clinical_implications" %in% tasks) {
    interpretations$clinical_implications
  } else NULL

  recommendations <- if ("recommend_methods" %in% tasks) {
    interpretations$recommend_methods
  } else NULL

  structure(
    list(
      interpretations = interpretations,
      recommendations = recommendations,
      quality_assessment = quality_assessment,
      plain_language_summary = plain_summary,
      clinical_insights = clinical_insights,
      metadata = list(
        model = model,
        tasks = tasks,
        temperature = temperature,
        timestamp = Sys.time(),
        ollama_version = .get_ollama_version(ollama_host)
      )
    ),
    class = "cbamm_ai_interpretation"
  )
}


#' Check Ollama Availability
#' @keywords internal
.check_ollama_available <- function(host) {
  tryCatch({
    response <- httr::GET(paste0(host, "/api/tags"), httr::timeout(5))
    httr::status_code(response) == 200
  }, error = function(e) FALSE)
}


#' Check Model Availability
#' @keywords internal
.check_ollama_model_available <- function(model, host) {
  tryCatch({
    response <- httr::GET(paste0(host, "/api/tags"))
    models_data <- httr::content(response, "parsed")
    model_names <- sapply(models_data$models, function(m) m$name)
    any(grepl(model, model_names))
  }, error = function(e) FALSE)
}


#' Pull Ollama Model
#' @keywords internal
.ollama_pull_model <- function(model, host) {
  tryCatch({
    # Use system2 to call ollama CLI
    result <- system2("ollama", args = c("pull", model), stdout = TRUE, stderr = TRUE)
    TRUE
  }, error = function(e) {
    warning("Failed to pull model: ", e$message)
    FALSE
  })
}


#' Build Analysis Context
#' @keywords internal
.build_analysis_context <- function(results, data) {
  fit <- results$pooled$transport
  mm <- .cbamm_measure_meta(fit$measure)
  pred <- metafor::predict(fit, transf = mm$transf)

  context <- list(
    n_studies = fit$k,
    effect_measure = fit$measure,
    pooled_effect = pred$pred,
    ci_lower = pred$ci.lb,
    ci_upper = pred$ci.ub,
    p_value = fit$pval,
    I2 = fit$I2,
    tau2 = fit$tau2,
    Q = fit$QE,
    Q_pval = fit$QEp,
    heterogeneity_level = if (fit$I2 < 25) "low" else if (fit$I2 < 50) "moderate" else if (fit$I2 < 75) "substantial" else "considerable"
  )

  # Add GRADE if available
  if (!is.null(results$grade)) {
    context$grade_certainty <- results$grade$final_certainty
  }

  # Add fragility if available
  if (!is.null(results$fragility)) {
    context$fragility_index <- results$fragility$fragility_index
  }

  context
}


#' Build Task Prompt
#' @keywords internal
.build_task_prompt <- function(task, context, results, data) {
  base_context <- sprintf(
    "You are an expert meta-analysis statistician and clinical epidemiologist analyzing a %s meta-analysis of %d studies.\n\n",
    context$effect_measure,
    context$n_studies
  )

  base_context <- paste0(
    base_context,
    sprintf("Results:\n"),
    sprintf("- Pooled effect: %.3f (95%% CI: %.3f to %.3f)\n", context$pooled_effect, context$ci_lower, context$ci_upper),
    sprintf("- P-value: %.4f\n", context$p_value),
    sprintf("- I² heterogeneity: %.1f%% (%s)\n", context$I2, context$heterogeneity_level),
    sprintf("- τ²: %.4f\n", context$tau2),
    sprintf("- Cochran's Q: %.2f (p = %.4f)\n\n", context$Q, context$Q_pval)
  )

  if (!is.null(context$grade_certainty)) {
    base_context <- paste0(base_context, sprintf("- GRADE certainty: %s\n\n", context$grade_certainty))
  }

  task_prompts <- list(
    interpret_results = paste0(
      base_context,
      "Task: Provide a comprehensive interpretation of these results.\n",
      "Include:\n",
      "1. What the pooled effect means clinically\n",
      "2. Statistical significance and clinical significance\n",
      "3. Interpretation of heterogeneity\n",
      "4. Strength of evidence\n",
      "5. Key takeaways\n\n",
      "Provide a clear, scientific interpretation suitable for a journal manuscript."
    ),

    assess_quality = paste0(
      base_context,
      "Task: Assess the quality and potential biases in this meta-analysis.\n",
      "Consider:\n",
      "1. Number of studies (adequacy)\n",
      "2. Heterogeneity level (consistency)\n",
      "3. Potential publication bias\n",
      "4. Risk of bias concerns\n",
      "5. Overall quality rating\n\n",
      "Provide a structured quality assessment."
    ),

    recommend_methods = paste0(
      base_context,
      "Task: Recommend optimal methodological approaches for this meta-analysis.\n",
      "Based on the I² of ", context$I2, "% and ", context$n_studies, " studies, recommend:\n",
      "1. Best effect model (fixed vs random-effects)\n",
      "2. Heterogeneity exploration methods\n",
      "3. Publication bias assessment methods\n",
      "4. Sensitivity analyses to conduct\n",
      "5. Additional analyses that would strengthen findings\n\n",
      "Provide evidence-based methodological recommendations."
    ),

    identify_biases = paste0(
      base_context,
      "Task: Identify potential biases and limitations.\n",
      "Analyze:\n",
      "1. Publication bias risk\n",
      "2. Selection bias\n",
      "3. Reporting bias\n",
      "4. Heterogeneity-related concerns\n",
      "5. Other methodological limitations\n\n",
      "Provide a critical appraisal of potential biases."
    ),

    clinical_implications = paste0(
      base_context,
      "Task: Explain the clinical implications and significance.\n",
      "Address:\n",
      "1. Clinical meaningfulness of the effect size\n",
      "2. Patient-relevant outcomes\n",
      "3. Applicability to clinical practice\n",
      "4. Practical recommendations for clinicians\n",
      "5. Implications for treatment decisions\n\n",
      "Write for a clinical audience (doctors, nurses)."
    ),

    limitations = paste0(
      base_context,
      "Task: Identify and discuss limitations of this meta-analysis.\n",
      "Consider:\n",
      "1. Statistical limitations\n",
      "2. Data availability limitations\n",
      "3. Generalizability concerns\n",
      "4. Methodological constraints\n",
      "5. Potential confounders not addressed\n\n",
      "Provide an honest, balanced discussion of limitations."
    ),

    future_research = paste0(
      base_context,
      "Task: Suggest directions for future research.\n",
      "Based on current findings, recommend:\n",
      "1. Key research questions still unanswered\n",
      "2. Study designs needed\n",
      "3. Outcomes to measure\n",
      "4. Populations to study\n",
      "5. Methodological improvements needed\n\n",
      "Provide actionable future research recommendations."
    )
  )

  task_prompts[[task]]
}


#' Query Ollama API
#' @keywords internal
.query_ollama <- function(prompt, model, temperature, context_length, host) {
  url <- paste0(host, "/api/generate")

  body <- list(
    model = model,
    prompt = prompt,
    stream = FALSE,
    options = list(
      temperature = temperature,
      num_ctx = context_length
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(300)  # 5 minute timeout
  )

  if (httr::status_code(response) != 200) {
    stop("Ollama API error: ", httr::status_code(response))
  }

  content <- httr::content(response, "parsed")

  list(
    text = content$response,
    model = content$model,
    tokens = content$total_duration %||% NA
  )
}


#' Generate Plain Language Summary
#' @keywords internal
.generate_plain_summary <- function(interpretations, results, model, host) {
  # Combine all interpretations into one plain-language summary
  combined_text <- paste(
    "Based on the following expert analysis:",
    paste(names(interpretations), interpretations, sep = ":\n", collapse = "\n\n"),
    sep = "\n\n"
  )

  prompt <- paste0(
    combined_text,
    "\n\nTask: Write a plain-language summary that a patient or non-expert could understand.\n",
    "Requirements:\n",
    "- Use simple language (8th grade reading level)\n",
    "- Avoid jargon and statistical terms\n",
    "- Explain what the results mean in everyday terms\n",
    "- Keep it under 250 words\n",
    "- Be accurate but accessible\n\n",
    "Plain language summary:"
  )

  response <- .query_ollama(
    prompt = prompt,
    model = model,
    temperature = 0.3,
    context_length = 8192,
    host = host
  )

  response$text
}


#' Get Ollama Version
#' @keywords internal
.get_ollama_version <- function(host) {
  tryCatch({
    response <- httr::GET(paste0(host, "/api/version"))
    content <- httr::content(response, "parsed")
    content$version %||% "unknown"
  }, error = function(e) "unknown")
}


#' Print method for AI interpretation
#' @export
print.cbamm_ai_interpretation <- function(x, ...) {
  cat("\n")
  cat("========================================\n")
  cat("🤖 CBAMMR AI-POWERED INTERPRETATION\n")
  cat("========================================\n\n")

  cat("Model:", x$metadata$model, "\n")
  cat("Tasks:", paste(x$metadata$tasks, collapse = ", "), "\n")
  cat("Generated:", format(x$metadata$timestamp, "%Y-%m-%d %H:%M:%S"), "\n\n")

  cat("========================================\n")
  cat("PLAIN LANGUAGE SUMMARY\n")
  cat("========================================\n\n")
  cat(strwrap(x$plain_language_summary, width = 70), sep = "\n")
  cat("\n\n")

  if (!is.null(x$clinical_insights)) {
    cat("========================================\n")
    cat("CLINICAL IMPLICATIONS\n")
    cat("========================================\n\n")
    cat(strwrap(x$clinical_insights, width = 70), sep = "\n")
    cat("\n\n")
  }

  if (!is.null(x$recommendations)) {
    cat("========================================\n")
    cat("METHODOLOGICAL RECOMMENDATIONS\n")
    cat("========================================\n\n")
    cat(strwrap(x$recommendations, width = 70), sep = "\n")
    cat("\n\n")
  }

  cat("Use summary(x) to see all interpretations.\n\n")

  invisible(x)
}


#' Summary method for AI interpretation
#' @export
summary.cbamm_ai_interpretation <- function(object, ...) {
  cat("\n🤖 CBAMMR AI INTERPRETATION - FULL REPORT\n\n")

  for (task in names(object$interpretations)) {
    cat("========================================\n")
    cat(toupper(gsub("_", " ", task)), "\n")
    cat("========================================\n\n")
    cat(strwrap(object$interpretations[[task]], width = 70), sep = "\n")
    cat("\n\n")
  }

  invisible(object)
}


#' AI-Powered Automated Recommendations
#'
#' Uses Ollama to automatically recommend optimal meta-analysis methods
#' based on data characteristics and research question.
#'
#' @param data Meta-analysis data frame
#' @param research_question Research question (optional but recommended)
#' @param model Ollama model. Default: "llama3.2"
#'
#' @return List of AI-recommended methods
#' @export
cbamm_ollama_recommend <- function(data, research_question = NULL, model = "llama3.2") {
  # Analyze data characteristics
  chars <- .analyze_data_characteristics(data)

  # Build recommendation prompt
  prompt <- .build_recommendation_prompt(chars, research_question)

  # Query Ollama
  response <- .query_ollama(
    prompt = prompt,
    model = model,
    temperature = 0.2,  # More conservative for recommendations
    context_length = 4096,
    host = "http://localhost:11434"
  )

  # Parse recommendations
  .parse_recommendations(response$text)
}


#' Analyze Data Characteristics
#' @keywords internal
.analyze_data_characteristics <- function(data) {
  list(
    n_studies = nrow(data),
    has_binary = all(c("ai", "bi", "ci", "di") %in% names(data)),
    has_continuous = all(c("yi", "vi") %in% names(data)) || all(c("yi", "sei") %in% names(data)),
    has_moderators = any(sapply(data, is.factor)) || any(sapply(data, is.character)),
    n_moderators = sum(sapply(data, is.factor)) + sum(sapply(data, is.character)) - 1,
    sample_size_range = if ("n" %in% names(data)) range(data$n, na.rm = TRUE) else c(NA, NA),
    has_year = "year" %in% names(data),
    has_quality = any(grepl("quality|rob|bias", names(data), ignore.case = TRUE))
  )
}


#' Build Recommendation Prompt
#' @keywords internal
.build_recommendation_prompt <- function(chars, research_question) {
  prompt <- "You are an expert meta-analysis methodologist. Based on the following data characteristics, recommend optimal methods:\n\n"

  prompt <- paste0(
    prompt,
    sprintf("- Number of studies: %d\n", chars$n_studies),
    sprintf("- Data type: %s\n", if (chars$has_binary) "Binary" else "Continuous"),
    sprintf("- Moderators available: %s (%d variables)\n", if (chars$has_moderators) "Yes" else "No", chars$n_moderators),
    sprintf("- Year information: %s\n", if (chars$has_year) "Yes" else "No"),
    sprintf("- Quality assessment: %s\n", if (chars$has_quality) "Yes" else "No")
  )

  if (!is.null(research_question)) {
    prompt <- paste0(prompt, "\nResearch question: ", research_question, "\n")
  }

  prompt <- paste0(
    prompt,
    "\nRecommend:\n",
    "1. Best effect model (fixed vs random)\n",
    "2. Heterogeneity estimator (REML, DL, ML, etc.)\n",
    "3. Publication bias methods to use\n",
    "4. Moderator analysis approach\n",
    "5. Sensitivity analyses\n",
    "6. Any concerns or limitations\n\n",
    "Provide evidence-based recommendations with brief justification."
  )

  prompt
}


#' Parse AI Recommendations
#' @keywords internal
.parse_recommendations <- function(text) {
  # Parse the AI response into structured recommendations
  list(
    full_text = text,
    effect_model = .extract_recommendation(text, "effect model"),
    estimator = .extract_recommendation(text, "estimator"),
    pub_bias_methods = .extract_recommendation(text, "publication bias"),
    moderator_approach = .extract_recommendation(text, "moderator"),
    sensitivity = .extract_recommendation(text, "sensitivity"),
    concerns = .extract_recommendation(text, "concern")
  )
}


#' Extract Recommendation
#' @keywords internal
.extract_recommendation <- function(text, keyword) {
  # Simple extraction - can be improved with more sophisticated parsing
  lines <- strsplit(text, "\n")[[1]]
  relevant <- grep(keyword, lines, ignore.case = TRUE, value = TRUE)
  if (length(relevant) > 0) paste(relevant, collapse = " ") else "Not specified"
}
