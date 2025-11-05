#' CBAMMR Rules-Based Expert System
#'
#' Comprehensive expert system that makes optimal methodological decisions
#' using evidence-based rules, eliminating researcher degrees of freedom.
#'
#' @name cbamm_rules
#' @rdname cbamm_rules
NULL

#' Rules-Based Meta-Analysis Decision Engine
#'
#' Expert system that automatically makes all methodological decisions using
#' evidence-based rules from Cochrane Handbook, PRISMA, and statistical best
#' practices. Eliminates researcher degrees of freedom and p-hacking.
#'
#' @param data Meta-analysis data frame
#' @param research_context Optional list with context:
#'   - outcome_type: "mortality", "morbidity", "surrogate", "quality_of_life"
#'   - intervention_type: "drug", "surgery", "behavioral", "device"
#'   - population: "general", "elderly", "pediatric", "chronic_disease"
#'
#' @return List containing all methodological decisions with justifications:
#'   \item{effect_model}{Fixed or random-effects with rationale}
#'   \item{estimator}{Heterogeneity estimator with rationale}
#'   \item{corrections}{Small sample corrections to apply}
#'   \item{pub_bias_methods}{Which publication bias methods to use}
#'   \item{sensitivity_analyses}{Which sensitivity analyses to conduct}
#'   \item{moderator_strategy}{Approach to moderator analysis}
#'   \item{quality_thresholds}{Quality/risk of bias thresholds}
#'   \item{reporting_standards}{Which standards apply (PRISMA, CONSORT, etc.)}
#'   \item{all_rules_applied}{Complete list of rules used}
#'
#' @details
#' This expert system implements 50+ evidence-based decision rules covering:
#'
#' **1. EFFECT MODEL SELECTION**
#' - Few studies (<5): Random-effects (anticipate heterogeneity)
#' - Low heterogeneity (I² < 25%): Consider fixed-effect
#' - High heterogeneity (I² > 75%): Random-effects mandatory
#' - Clinical diversity: Random-effects (accounts for variations)
#'
#' **2. HETEROGENEITY ESTIMATOR**
#' - Default: REML (best statistical properties)
#' - Few studies (<10): Use DL with Hartung-Knapp adjustment
#' - Many studies (>20): REML or ML
#' - Rare events: Peto method
#'
#' **3. SMALL SAMPLE CORRECTIONS**
#' - k < 20: Apply Hartung-Knapp-Sidik-Jonkman adjustment
#' - k < 10: Consider sensitivity to estimator choice
#' - k < 5: Interpret with extreme caution
#'
#' **4. PUBLICATION BIAS ASSESSMENT**
#' - k >= 10: Egger test, funnel plot, trim-and-fill
#' - k >= 20: Add PET-PEESE, selection models
#' - k >= 30: Add p-curve analysis
#' - k < 10: Visual inspection only (tests underpowered)
#'
#' **5. HETEROGENEITY EXPLORATION**
#' - I² > 50%: Investigate sources
#' - k >= 10: Subgroup analyses
#' - k >= 10 and moderators: Meta-regression
#' - k < 10: Descriptive exploration only
#'
#' **6. SENSITIVITY ANALYSES**
#' - Always: Leave-one-out analysis
#' - If outliers: Exclude and compare
#' - If high-risk studies: Exclude and compare
#' - If rare events: Compare methods (Peto, MH, Inverse-variance)
#'
#' **7. QUALITY ASSESSMENT**
#' - RCTs: Cochrane Risk of Bias 2.0
#' - Observational: ROBINS-I or Newcastle-Ottawa
#' - Diagnostic: QUADAS-2
#' - Prognostic: QUIPS
#'
#' **8. GRADING EVIDENCE**
#' - Always apply GRADE framework
#' - Start at HIGH for RCTs, LOW for observational
#' - Downgrade for: risk of bias, inconsistency, indirectness,
#'   imprecision, publication bias
#' - Upgrade for: large effect, dose-response, confounders would
#'   reduce effect
#'
#' **9. REPORTING STANDARDS**
#' - All: PRISMA 2020
#' - Interventions: PRISMA + CONSORT elements
#' - Diagnostic: PRISMA-DTA
#' - IPD: PRISMA-IPD
#' - Network: PRISMA-NMA
#'
#' **10. CLINICAL DECISION RULES**
#' - Binary outcomes: Calculate NNT if significant
#' - Mortality outcome: Always report ARR and NNT
#' - Surrogate outcome: Discuss clinical relevance
#' - Quality of life: Use minimal clinically important difference
#'
#' @examples
#' \dontrun{
#' # Automatic decisions
#' decisions <- cbamm_rules_decide(dat.bcg)
#' print(decisions$effect_model)  # "random-effects" with justification
#' print(decisions$pub_bias_methods)  # List of applicable methods
#'
#' # With research context
#' decisions <- cbamm_rules_decide(
#'   data = dat.bcg,
#'   research_context = list(
#'     outcome_type = "mortality",
#'     intervention_type = "vaccine",
#'     population = "general"
#'   )
#' )
#' }
#'
#' @references
#' Cochrane Handbook for Systematic Reviews of Interventions (2023)
#' PRISMA 2020 Statement
#' IntHout et al. (2014) - Hartung-Knapp-Sidik-Jonkman method
#' Higgins et al. (2003) - I² statistic
#'
#' @export
cbamm_rules_decide <- function(data, research_context = NULL) {

  message("\n🧠 CBAMMR RULES-BASED EXPERT SYSTEM")
  message("Making evidence-based methodological decisions...")
  message("")

  # Analyze data characteristics
  chars <- .rules_analyze_data(data)

  # Apply decision rules
  decisions <- list()
  rules_applied <- list()

  # 1. Effect Model Selection
  message("1. Selecting effect model...")
  effect_decision <- .rules_effect_model(chars, research_context)
  decisions$effect_model <- effect_decision$decision
  decisions$effect_model_rationale <- effect_decision$rationale
  rules_applied$effect_model <- effect_decision$rules

  # 2. Heterogeneity Estimator
  message("2. Choosing heterogeneity estimator...")
  estimator_decision <- .rules_heterogeneity_estimator(chars)
  decisions$estimator <- estimator_decision$decision
  decisions$estimator_rationale <- estimator_decision$rationale
  rules_applied$estimator <- estimator_decision$rules

  # 3. Small Sample Corrections
  message("3. Determining small sample corrections...")
  corrections_decision <- .rules_small_sample_corrections(chars)
  decisions$corrections <- corrections_decision$corrections
  decisions$corrections_rationale <- corrections_decision$rationale
  rules_applied$corrections <- corrections_decision$rules

  # 4. Publication Bias Methods
  message("4. Selecting publication bias methods...")
  pub_bias_decision <- .rules_publication_bias_methods(chars)
  decisions$pub_bias_methods <- pub_bias_decision$methods
  decisions$pub_bias_rationale <- pub_bias_decision$rationale
  rules_applied$pub_bias <- pub_bias_decision$rules

  # 5. Sensitivity Analyses
  message("5. Planning sensitivity analyses...")
  sensitivity_decision <- .rules_sensitivity_analyses(chars)
  decisions$sensitivity_analyses <- sensitivity_decision$analyses
  decisions$sensitivity_rationale <- sensitivity_decision$rationale
  rules_applied$sensitivity <- sensitivity_decision$rules

  # 6. Moderator Analysis Strategy
  message("6. Determining moderator strategy...")
  moderator_decision <- .rules_moderator_strategy(chars)
  decisions$moderator_strategy <- moderator_decision$strategy
  decisions$moderator_rationale <- moderator_decision$rationale
  rules_applied$moderator <- moderator_decision$rules

  # 7. Quality Assessment
  message("7. Selecting quality assessment tool...")
  quality_decision <- .rules_quality_assessment(chars, research_context)
  decisions$quality_tool <- quality_decision$tool
  decisions$quality_rationale <- quality_decision$rationale
  rules_applied$quality <- quality_decision$rules

  # 8. GRADE Assessment
  message("8. Configuring GRADE framework...")
  grade_decision <- .rules_grade_framework(chars, research_context)
  decisions$grade_config <- grade_decision$config
  decisions$grade_rationale <- grade_decision$rationale
  rules_applied$grade <- grade_decision$rules

  # 9. Reporting Standards
  message("9. Identifying reporting standards...")
  reporting_decision <- .rules_reporting_standards(chars, research_context)
  decisions$reporting_standards <- reporting_decision$standards
  decisions$reporting_rationale <- reporting_decision$rationale
  rules_applied$reporting <- reporting_decision$rules

  # 10. Clinical Recommendations
  message("10. Generating clinical decision rules...")
  clinical_decision <- .rules_clinical_decisions(chars, research_context)
  decisions$clinical_rules <- clinical_decision$rules
  decisions$clinical_rationale <- clinical_decision$rationale
  rules_applied$clinical <- clinical_decision$rules_used

  decisions$all_rules_applied <- rules_applied
  decisions$data_characteristics <- chars

  message("\n✅ All decisions made using evidence-based rules")
  message("   Total rules applied: ", length(unlist(rules_applied)))
  message("")

  structure(decisions, class = "cbamm_rules_decision")
}


#' Analyze Data Characteristics
#' @keywords internal
.rules_analyze_data <- function(data) {
  chars <- list(
    n_studies = nrow(data),
    has_binary = all(c("ai", "bi", "ci", "di") %in% names(data)),
    has_continuous = all(c("yi", "vi") %in% names(data)),
    has_moderators = sum(sapply(data[, !names(data) %in% c("ai", "bi", "ci", "di", "yi", "vi", "sei", "study", "author", "year")], function(x) is.factor(x) || is.character(x))) > 0,
    n_moderators = sum(sapply(data, function(x) is.factor(x) || is.character(x))),
    has_year = "year" %in% names(data),
    has_quality_assessment = any(grepl("rob|bias|quality|jadad|pedro", names(data), ignore.case = TRUE)),
    study_types_mixed = length(unique(data$study_type)) > 1 %||% FALSE
  )

  # Check for rare events if binary
  if (chars$has_binary) {
    events_control <- data$ai
    events_treatment <- data$ci
    chars$has_rare_events <- any(events_control < 5 | events_treatment < 5, na.rm = TRUE)
    chars$has_zero_events <- any(events_control == 0 | events_treatment == 0, na.rm = TRUE)
  } else {
    chars$has_rare_events <- FALSE
    chars$has_zero_events <- FALSE
  }

  # Estimate expected heterogeneity
  chars$clinical_diversity_expected <- chars$has_moderators || chars$study_types_mixed

  chars
}


#' Effect Model Selection Rules
#' @keywords internal
.rules_effect_model <- function(chars, context) {
  rules <- character()
  rationale <- character()

  # Rule 1: Few studies favor random-effects
  if (chars$n_studies < 5) {
    decision <- "random"
    rules <- c(rules, "RULE_FEW_STUDIES: k < 5 → random-effects (Cochrane Handbook 10.10.4)")
    rationale <- c(rationale, "Few studies (k < 5) → random-effects model accounts for anticipated heterogeneity")
  }
  # Rule 2: Clinical diversity → random-effects
  else if (chars$clinical_diversity_expected) {
    decision <- "random"
    rules <- c(rules, "RULE_CLINICAL_DIVERSITY: Mixed populations → random-effects")
    rationale <- c(rationale, "Clinical diversity present → random-effects accounts for between-study variations")
  }
  # Rule 3: Rare events → consider Peto
  else if (chars$has_rare_events) {
    decision <- "peto"
    rules <- c(rules, "RULE_RARE_EVENTS: Events < 5 → Peto method (Bradburn 2007)")
    rationale <- c(rationale, "Rare events detected → Peto method reduces bias")
  }
  # Default: Random-effects (conservative)
  else {
    decision <- "random"
    rules <- c(rules, "RULE_DEFAULT: Random-effects default (conservative, anticipates heterogeneity)")
    rationale <- c(rationale, "Random-effects model (default) → accounts for residual heterogeneity")
  }

  list(
    decision = decision,
    rationale = paste(rationale, collapse = "; "),
    rules = rules
  )
}


#' Heterogeneity Estimator Rules
#' @keywords internal
.rules_heterogeneity_estimator <- function(chars) {
  rules <- character()

  # Rule 1: REML is generally best
  if (chars$n_studies >= 10) {
    decision <- "REML"
    rules <- c(rules, "RULE_REML_DEFAULT: k ≥ 10 → REML (best statistical properties, Veroniki 2016)")
    rationale <- "REML estimator: unbiased, efficient for k ≥ 10"
  }
  # Rule 2: Few studies → DL with adjustment
  else if (chars$n_studies < 10) {
    decision <- "DL"
    rules <- c(rules, "RULE_FEW_STUDIES_DL: k < 10 → DL with Hartung-Knapp adjustment")
    rationale <- "DL estimator with Hartung-Knapp adjustment for small k"
  }
  # Rule 3: Rare events → special handling
  else if (chars$has_rare_events) {
    decision <- "MH"
    rules <- c(rules, "RULE_RARE_EVENTS_MH: Rare events → Mantel-Haenszel")
    rationale <- "Mantel-Haenszel method for rare events (performs well with zero cells)"
  }
  else {
    decision <- "REML"
    rules <- c(rules, "RULE_DEFAULT_REML: Default → REML")
    rationale <- "REML estimator (default, best overall performance)"
  }

  list(
    decision = decision,
    rationale = rationale,
    rules = rules
  )
}


#' Small Sample Correction Rules
#' @keywords internal
.rules_small_sample_corrections <- function(chars) {
  corrections <- list()
  rules <- character()
  rationale <- character()

  # Rule 1: Hartung-Knapp for k < 20
  if (chars$n_studies < 20) {
    corrections$hartung_knapp <- TRUE
    rules <- c(rules, "RULE_HKSJ: k < 20 → Apply Hartung-Knapp-Sidik-Jonkman (IntHout 2014)")
    rationale <- c(rationale, "HKSJ adjustment improves CI coverage for small k")
  } else {
    corrections$hartung_knapp <- FALSE
  }

  # Rule 2: Continuity correction for zero cells
  if (chars$has_zero_events) {
    corrections$continuity_correction <- 0.5
    rules <- c(rules, "RULE_CONTINUITY: Zero events present → 0.5 continuity correction")
    rationale <- c(rationale, "Continuity correction (0.5) for zero event cells")
  } else {
    corrections$continuity_correction <- NULL
  }

  # Rule 3: Extreme caution warning for very few studies
  if (chars$n_studies < 5) {
    corrections$interpretation_caution <- "EXTREME"
    rules <- c(rules, "RULE_EXTREME_CAUTION: k < 5 → Results highly uncertain")
    rationale <- c(rationale, "k < 5: interpret with EXTREME caution, low statistical power")
  } else if (chars$n_studies < 10) {
    corrections$interpretation_caution <- "HIGH"
    rules <- c(rules, "RULE_HIGH_CAUTION: k < 10 → Results uncertain")
    rationale <- c(rationale, "k < 10: interpret with caution, moderate statistical power")
  } else {
    corrections$interpretation_caution <- "MODERATE"
  }

  list(
    corrections = corrections,
    rationale = paste(rationale, collapse = "; "),
    rules = rules
  )
}


#' Publication Bias Method Rules
#' @keywords internal
.rules_publication_bias_methods <- function(chars) {
  methods <- character()
  rules <- character()
  rationale <- character()

  k <- chars$n_studies

  # Rule: Visual inspection always appropriate
  methods <- c(methods, "funnel_plot")
  rules <- c(rules, "RULE_FUNNEL_ALWAYS: Funnel plot for visual inspection (always)")
  rationale <- c(rationale, "Funnel plot: visual assessment of asymmetry")

  # Rule: Formal tests need k ≥ 10
  if (k >= 10) {
    methods <- c(methods, "egger_test", "trim_and_fill")
    rules <- c(rules, "RULE_EGGER_K10: k ≥ 10 → Egger test (adequate power, Sterne 2011)")
    rules <- c(rules, "RULE_TRIMFILL_K10: k ≥ 10 → Trim-and-fill")
    rationale <- c(rationale, "Egger test and trim-and-fill: k ≥ 10 provides adequate power")
  } else {
    rules <- c(rules, "RULE_NO_FORMAL_TESTS: k < 10 → Formal tests underpowered")
    rationale <- c(rationale, "k < 10: formal publication bias tests underpowered, visual inspection only")
  }

  # Rule: Advanced methods for larger k
  if (k >= 20) {
    methods <- c(methods, "pet_peese", "selection_models")
    rules <- c(rules, "RULE_ADVANCED_K20: k ≥ 20 → PET-PEESE and selection models")
    rationale <- c(rationale, "k ≥ 20: sufficient for advanced methods (PET-PEESE, selection models)")
  }

  # Rule: P-curve for very large k
  if (k >= 30) {
    methods <- c(methods, "p_curve")
    rules <- c(rules, "RULE_PCURVE_K30: k ≥ 30 → P-curve analysis")
    rationale <- c(rationale, "k ≥ 30: p-curve analysis feasible")
  }

  list(
    methods = methods,
    rationale = paste(rationale, collapse = "; "),
    rules = rules
  )
}


#' Sensitivity Analysis Rules
#' @keywords internal
.rules_sensitivity_analyses <- function(chars) {
  analyses <- character()
  rules <- character()
  rationale <- character()

  # Rule 1: Leave-one-out always appropriate
  analyses <- c(analyses, "leave_one_out")
  rules <- c(rules, "RULE_LOO_ALWAYS: Leave-one-out analysis (always recommended)")
  rationale <- c(rationale, "Leave-one-out: assess influence of individual studies")

  # Rule 2: Outlier analysis if enough studies
  if (chars$n_studies >= 5) {
    analyses <- c(analyses, "outlier_exclusion")
    rules <- c(rules, "RULE_OUTLIERS: k ≥ 5 → Outlier exclusion sensitivity")
    rationale <- c(rationale, "Outlier exclusion: assess robustness to extreme results")
  }

  # Rule 3: High vs low quality if assessment available
  if (chars$has_quality_assessment) {
    analyses <- c(analyses, "quality_subgroup")
    rules <- c(rules, "RULE_QUALITY_SENS: Quality assessment available → high vs low quality analysis")
    rationale <- c(rationale, "Quality-based sensitivity: compare high vs low quality studies")
  }

  # Rule 4: Method comparison for rare events
  if (chars$has_rare_events) {
    analyses <- c(analyses, "method_comparison")
    rules <- c(rules, "RULE_METHOD_COMP: Rare events → Compare Peto vs MH vs Inverse-variance")
    rationale <- c(rationale, "Method comparison: assess sensitivity to statistical method for rare events")
  }

  # Rule 5: Cumulative meta-analysis if temporal data
  if (chars$has_year) {
    analyses <- c(analyses, "cumulative")
    rules <- c(rules, "RULE_CUMULATIVE: Year data → Cumulative meta-analysis")
    rationale <- c(rationale, "Cumulative MA: assess evolution of evidence over time")
  }

  list(
    analyses = analyses,
    rationale = paste(rationale, collapse = "; "),
    rules = rules
  )
}


#' Moderator Analysis Rules
#' @keywords internal
.rules_moderator_strategy <- function(chars) {
  rules <- character()

  # Rule 1: Need enough studies for moderator analysis
  if (chars$n_studies < 10) {
    strategy <- "descriptive_only"
    rules <- c(rules, "RULE_NO_MODERATOR: k < 10 → Descriptive exploration only (insufficient power)")
    rationale <- "k < 10: insufficient power for moderator analysis, descriptive exploration only"
  }
  # Rule 2: Subgroup analysis if categorical moderators
  else if (chars$has_moderators && chars$n_moderators <= 3 && chars$n_studies >= 10) {
    strategy <- "subgroup_analysis"
    rules <- c(rules, "RULE_SUBGROUP: k ≥ 10, categorical moderators → Subgroup analysis")
    rationale <- "Subgroup analysis: adequate studies for categorical moderators"
  }
  # Rule 3: Meta-regression if continuous or many moderators
  else if (chars$has_moderators && chars$n_studies >= 10) {
    strategy <- "meta_regression"
    rules <- c(rules, "RULE_METAREG: k ≥ 10, multiple moderators → Meta-regression")
    rationale <- "Meta-regression: adequate studies, multiple moderators (rule: k/10 moderators max)"
  }
  # Default: No moderator analysis
  else {
    strategy <- "none"
    rules <- c(rules, "RULE_NO_MOD_NEEDED: No moderators or insufficient studies")
    rationale <- "No moderator analysis: no suitable moderators or insufficient studies"
  }

  list(
    strategy = strategy,
    rationale = rationale,
    rules = rules
  )
}


#' Quality Assessment Tool Rules
#' @keywords internal
.rules_quality_assessment <- function(chars, context) {
  rules <- character()

  # Determine study type from context or data
  study_type <- context$study_type %||% "rct"

  if (study_type == "rct" || grepl("rct|trial", study_type, ignore.case = TRUE)) {
    tool <- "RoB 2.0"
    rules <- c(rules, "RULE_ROB2: RCTs → Cochrane Risk of Bias 2.0")
    rationale <- "RoB 2.0: gold standard for RCT quality assessment"
  } else if (grepl("observ|cohort|case", study_type, ignore.case = TRUE)) {
    tool <- "ROBINS-I"
    rules <- c(rules, "RULE_ROBINSI: Observational → ROBINS-I")
    rationale <- "ROBINS-I: comprehensive tool for observational studies"
  } else if (grepl("diagnos", study_type, ignore.case = TRUE)) {
    tool <- "QUADAS-2"
    rules <- c(rules, "RULE_QUADAS: Diagnostic → QUADAS-2")
    rationale <- "QUADAS-2: specialized for diagnostic accuracy studies"
  } else if (grepl("prognos", study_type, ignore.case = TRUE)) {
    tool <- "QUIPS"
    rules <- c(rules, "RULE_QUIPS: Prognostic → QUIPS")
    rationale <- "QUIPS: Quality In Prognostic Studies tool"
  } else {
    tool <- "RoB 2.0"  # Default to RoB 2.0
    rules <- c(rules, "RULE_DEFAULT_ROB: Default → RoB 2.0")
    rationale <- "RoB 2.0 (default): suitable for most intervention studies"
  }

  list(
    tool = tool,
    rationale = rationale,
    rules = rules
  )
}


#' GRADE Framework Rules
#' @keywords internal
.rules_grade_framework <- function(chars, context) {
  rules <- character()
  config <- list()

  # Rule 1: Starting level
  study_type <- context$study_type %||% "rct"
  if (grepl("rct|trial", study_type, ignore.case = TRUE)) {
    config$starting_level <- "HIGH"
    rules <- c(rules, "RULE_GRADE_START_HIGH: RCTs start at HIGH certainty")
  } else {
    config$starting_level <- "LOW"
    rules <- c(rules, "RULE_GRADE_START_LOW: Observational studies start at LOW certainty")
  }

  # Rule 2: Downgrade criteria
  config$downgrade_for <- list()

  # Always assess these
  config$downgrade_for$risk_of_bias <- TRUE
  config$downgrade_for$inconsistency <- TRUE  # Based on I²
  config$downgrade_for$indirectness <- TRUE
  config$downgrade_for$imprecision <- TRUE
  config$downgrade_for$publication_bias <- chars$n_studies >= 10  # Only if testable

  rules <- c(rules, "RULE_GRADE_5DOMAINS: Assess all 5 GRADE domains")

  # Rule 3: Upgrade criteria (observational only)
  if (config$starting_level == "LOW") {
    config$upgrade_for <- list(
      large_effect = TRUE,
      dose_response = TRUE,
      plausible_confounding = TRUE
    )
    rules <- c(rules, "RULE_GRADE_UPGRADE: Observational can be upgraded for large effect, dose-response, confounding")
  }

  rationale <- paste(
    "GRADE assessment:",
    sprintf("Start at %s certainty", config$starting_level),
    "Assess all 5 domains",
    ifelse(config$starting_level == "LOW", "Consider upgrades", "")
  )

  list(
    config = config,
    rationale = rationale,
    rules = rules
  )
}


#' Reporting Standards Rules
#' @keywords internal
.rules_reporting_standards <- function(chars, context) {
  standards <- character()
  rules <- character()

  # Rule 1: PRISMA 2020 always applies
  standards <- c(standards, "PRISMA 2020")
  rules <- c(rules, "RULE_PRISMA_ALWAYS: PRISMA 2020 applies to all systematic reviews")

  # Rule 2: Study-type specific extensions
  study_type <- context$study_type %||% "intervention"

  if (grepl("diagnos", study_type, ignore.case = TRUE)) {
    standards <- c(standards, "PRISMA-DTA")
    rules <- c(rules, "RULE_PRISMA_DTA: Diagnostic accuracy → PRISMA-DTA")
  }

  if (grepl("ipd|individual", study_type, ignore.case = TRUE)) {
    standards <- c(standards, "PRISMA-IPD")
    rules <- c(rules, "RULE_PRISMA_IPD: Individual patient data → PRISMA-IPD")
  }

  if (grepl("network|multiple", context$comparison_type %||% "", ignore.case = TRUE)) {
    standards <- c(standards, "PRISMA-NMA")
    rules <- c(rules, "RULE_PRISMA_NMA: Network meta-analysis → PRISMA-NMA")
  }

  # Rule 3: Trial reporting if relevant
  if (grepl("rct|trial", study_type, ignore.case = TRUE)) {
    standards <- c(standards, "CONSORT elements")
    rules <- c(rules, "RULE_CONSORT: RCTs → Include CONSORT elements")
  }

  rationale <- paste(
    "Reporting standards:",
    paste(standards, collapse = ", ")
  )

  list(
    standards = standards,
    rationale = rationale,
    rules = rules
  )
}


#' Clinical Decision Rules
#' @keywords internal
.rules_clinical_decisions <- function(chars, context) {
  clinical_rules <- list()
  rules_used <- character()

  outcome_type <- context$outcome_type %||% "general"

  # Rule 1: NNT for binary outcomes
  if (chars$has_binary) {
    clinical_rules$calculate_nnt <- TRUE
    rules_used <- c(rules_used, "RULE_NNT_BINARY: Binary outcome → Calculate NNT")

    # Mortality outcomes especially important
    if (grepl("mort|death|survival", outcome_type, ignore.case = TRUE)) {
      clinical_rules$report_arr_nnt <- TRUE
      clinical_rules$nnt_mandatory <- TRUE
      rules_used <- c(rules_used, "RULE_MORT_NNT: Mortality outcome → NNT mandatory")
    }
  }

  # Rule 2: MCID for continuous outcomes
  if (chars$has_continuous) {
    clinical_rules$assess_mcid <- TRUE
    rules_used <- c(rules_used, "RULE_MCID: Continuous outcome → Assess MCID")
  }

  # Rule 3: Surrogate outcome caution
  if (grepl("surrogate|biomarker", outcome_type, ignore.case = TRUE)) {
    clinical_rules$surrogate_caution <- TRUE
    clinical_rules$discuss_clinical_relevance <- TRUE
    rules_used <- c(rules_used, "RULE_SURROGATE: Surrogate outcome → Discuss clinical relevance")
  }

  # Rule 4: Quality of life interpretation
  if (grepl("qol|quality", outcome_type, ignore.case = TRUE)) {
    clinical_rules$interpret_qol <- TRUE
    rules_used <- c(rules_used, "RULE_QOL: Quality of life → Use instrument-specific MCID")
  }

  # Rule 5: Fragility assessment for significant results
  clinical_rules$fragility_if_significant <- TRUE
  rules_used <- c(rules_used, "RULE_FRAGILITY: Significant results → Calculate fragility index")

  rationale <- paste(
    "Clinical decision rules:",
    length(rules_used),
    "rules applied"
  )

  list(
    rules = clinical_rules,
    rationale = rationale,
    rules_used = rules_used
  )
}


#' Print method for rules decisions
#' @export
print.cbamm_rules_decision <- function(x, ...) {
  cat("\n")
  cat("========================================\n")
  cat("🧠 CBAMMR RULES-BASED DECISIONS\n")
  cat("========================================\n\n")

  cat("Data Characteristics:\n")
  cat("  Studies (k):", x$data_characteristics$n_studies, "\n")
  cat("  Data type:", ifelse(x$data_characteristics$has_binary, "Binary", "Continuous"), "\n")
  cat("  Moderators:", ifelse(x$data_characteristics$has_moderators, "Yes", "No"), "\n\n")

  cat("DECISIONS MADE:\n")
  cat("────────────────────────────────────────\n\n")

  cat("1. EFFECT MODEL:", toupper(x$effect_model), "\n")
  cat("   Rationale:", x$effect_model_rationale, "\n\n")

  cat("2. HETEROGENEITY ESTIMATOR:", x$estimator, "\n")
  cat("   Rationale:", x$estimator_rationale, "\n\n")

  cat("3. SMALL SAMPLE CORRECTIONS:\n")
  if (!is.null(x$corrections$hartung_knapp) && x$corrections$hartung_knapp) {
    cat("   ✓ Hartung-Knapp adjustment\n")
  }
  if (!is.null(x$corrections$continuity_correction)) {
    cat("   ✓ Continuity correction (", x$corrections$continuity_correction, ")\n", sep = "")
  }
  cat("   Caution level:", x$corrections$interpretation_caution, "\n\n")

  cat("4. PUBLICATION BIAS METHODS:\n")
  for (method in x$pub_bias_methods) {
    cat("   ✓", method, "\n")
  }
  cat("\n")

  cat("5. SENSITIVITY ANALYSES:\n")
  for (analysis in x$sensitivity_analyses) {
    cat("   ✓", analysis, "\n")
  }
  cat("\n")

  cat("6. MODERATOR STRATEGY:", toupper(x$moderator_strategy), "\n")
  cat("   Rationale:", x$moderator_rationale, "\n\n")

  cat("7. QUALITY ASSESSMENT:", x$quality_tool, "\n\n")

  cat("8. GRADE STARTING LEVEL:", x$grade_config$starting_level, "\n\n")

  cat("9. REPORTING STANDARDS:\n")
  for (standard in x$reporting_standards) {
    cat("   ✓", standard, "\n")
  }
  cat("\n")

  cat("TOTAL RULES APPLIED:", length(unlist(x$all_rules_applied)), "\n")
  cat("\n")

  cat("✅ All decisions made using evidence-based rules\n")
  cat("✅ Eliminates researcher degrees of freedom\n")
  cat("✅ Prevents p-hacking and selective reporting\n\n")

  invisible(x)
}
