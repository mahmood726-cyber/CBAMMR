#!/usr/bin/env Rscript
# Comprehensive Test Suite for CBAMMR Package
# Run this script to test all package functionality

cat("\n")
cat("========================================\n")
cat("CBAMMR v7.0 Comprehensive Test Suite\n")
cat("========================================\n\n")

# Initialize results tracking
test_results <- list()
test_count <- 0
pass_count <- 0
fail_count <- 0

run_test <- function(name, code) {
  test_count <<- test_count + 1
  cat(sprintf("\n[TEST %d] %s\n", test_count, name))
  cat(strrep("-", 60), "\n")

  result <- tryCatch({
    code
    cat("✓ PASS\n")
    pass_count <<- pass_count + 1
    test_results[[name]] <<- "PASS"
    TRUE
  }, error = function(e) {
    cat("✗ FAIL\n")
    cat("Error:", conditionMessage(e), "\n")
    fail_count <<- fail_count + 1
    test_results[[name]] <<- paste("FAIL:", conditionMessage(e))
    FALSE
  }, warning = function(w) {
    cat("⚠ WARNING\n")
    cat("Warning:", conditionMessage(w), "\n")
    test_results[[name]] <<- paste("WARN:", conditionMessage(w))
    TRUE
  })

  return(result)
}

# ============================================================
# SECTION 1: Installation and Loading
# ============================================================

cat("\n" ); cat(strrep("=", 60), "\n")
cat("SECTION 1: Installation and Loading\n")
cat(strrep("=", 60), "\n")

run_test("Install devtools", {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  stopifnot(requireNamespace("devtools", quietly = TRUE))
})

run_test("Install CBAMMR package", {
  devtools::install(".", quiet = TRUE, upgrade = "never", dependencies = TRUE)
})

run_test("Load CBAMMR package", {
  library(CBAMMR)
})

run_test("Check package version", {
  ver <- packageVersion("CBAMMR")
  cat("Package version:", as.character(ver), "\n")
  stopifnot(ver >= "7.0.0")
})

# ============================================================
# SECTION 2: Configuration and Setup
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 2: Configuration and Setup\n")
cat(strrep("=", 60), "\n")

run_test("cbamm_novelty_notes()", {
  cbamm_novelty_notes()
})

run_test("setup_cbamm() - default", {
  config <- setup_cbamm()
  stopifnot(is.list(config))
  stopifnot("effect_measure" %in% names(config))
  stopifnot(config$effect_measure == "HR")
  cat("Default effect measure:", config$effect_measure, "\n")
})

run_test("setup_cbamm() - custom OR", {
  config <- setup_cbamm(
    effect_measure = "OR",
    use_bayesian = FALSE,
    run_mv = TRUE
  )
  stopifnot(config$effect_measure == "OR")
  stopifnot(config$use_bayesian == FALSE)
  cat("Custom config created successfully\n")
})

run_test("install_cbamm_packages()", {
  features <- install_cbamm_packages()
  stopifnot(is.list(features))
  cat("Available features:\n")
  print(features)
})

run_test("initialize_cbamm()", {
  config <- setup_cbamm()
  env <- initialize_cbamm(config)
  stopifnot(is.list(env))
  stopifnot("config" %in% names(env))
  stopifnot("features" %in% names(env))
  cat("Environment initialized successfully\n")
})

# ============================================================
# SECTION 3: Data Simulation
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 3: Data Simulation\n")
cat(strrep("=", 60), "\n")

data_hr <- NULL
run_test("simulate_cbamm_data() - HR", {
  data_hr <<- simulate_cbamm_data(n_rct = 10, n_obs = 10, n_mr = 5, seed = 123)
  stopifnot(nrow(data_hr) == 25)
  stopifnot(all(c("study_id", "yi", "se", "study_type") %in% names(data_hr)))
  cat("Generated", nrow(data_hr), "studies\n")
  cat("Columns:", paste(names(data_hr), collapse = ", "), "\n")
  print(head(data_hr, 3))
})

data_binary <- NULL
run_test("simulate_cbamm_binary() - OR", {
  data_binary <<- simulate_cbamm_binary(n = 20, measure = "OR", seed = 456)
  stopifnot(nrow(data_binary) == 20)
  stopifnot(all(c("event_t", "n_t", "event_c", "n_c") %in% names(data_binary)))
  cat("Generated", nrow(data_binary), "binary studies\n")
  print(head(data_binary, 3))
})

data_continuous <- NULL
run_test("simulate_cbamm_continuous() - SMD", {
  data_continuous <<- simulate_cbamm_continuous(n = 15, measure = "SMD", seed = 789)
  stopifnot(nrow(data_continuous) == 15)
  stopifnot(all(c("mean_t", "sd_t", "n_t", "mean_c", "sd_c", "n_c") %in% names(data_continuous)))
  cat("Generated", nrow(data_continuous), "continuous studies\n")
  print(head(data_continuous, 3))
})

# ============================================================
# SECTION 4: Pairwise Effect Size Calculation
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 4: Pairwise Effect Size Calculation\n")
cat(strrep("=", 60), "\n")

run_test("prepare_pairwise_effects() - HR (already has yi, se)", {
  result <- prepare_pairwise_effects(data_hr, measure = "HR")
  stopifnot("vi" %in% names(result))
  stopifnot(all(is.finite(result$yi)))
  stopifnot(all(is.finite(result$se)))
  cat("Effect sizes preserved, variance added\n")
})

data_or <- NULL
run_test("prepare_pairwise_effects() - OR from binary", {
  data_or <<- prepare_pairwise_effects(data_binary, measure = "OR")
  stopifnot(all(c("yi", "se", "vi") %in% names(data_or)))
  stopifnot(all(is.finite(data_or$yi)))
  cat("Calculated OR effect sizes for", nrow(data_or), "studies\n")
  cat("Mean log(OR):", round(mean(data_or$yi), 3), "\n")
})

data_smd <- NULL
run_test("prepare_pairwise_effects() - SMD from continuous", {
  data_smd <<- prepare_pairwise_effects(data_continuous, measure = "SMD")
  stopifnot(all(c("yi", "se", "vi") %in% names(data_smd)))
  stopifnot(all(is.finite(data_smd$yi)))
  cat("Calculated SMD effect sizes for", nrow(data_smd), "studies\n")
  cat("Mean SMD:", round(mean(data_smd$yi), 3), "\n")
})

# ============================================================
# SECTION 5: Validation
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 5: Data Validation\n")
cat(strrep("=", 60), "\n")

run_test("cbamm_pairwise_validator() - HR data", {
  validation <- cbamm_pairwise_validator(data_hr, measure = "HR")
  stopifnot(is.list(validation))
  stopifnot(all(c("ok", "issues", "notes", "rare_hint") %in% names(validation)))
  cat("Validation OK:", validation$ok, "\n")
  if (length(validation$issues) > 0) {
    cat("Issues:", paste(validation$issues, collapse = "; "), "\n")
  }
  if (length(validation$notes) > 0) {
    cat("Notes:", paste(validation$notes, collapse = "; "), "\n")
  }
})

run_test("cbamm_pairwise_validator() - OR data", {
  validation <- cbamm_pairwise_validator(data_or, measure = "OR")
  cat("Validation OK:", validation$ok, "\n")
  cat("Rare events hint:", validation$rare_hint, "\n")
  if (length(validation$notes) > 0) {
    cat("Notes:\n")
    for (note in validation$notes) cat("  -", note, "\n")
  }
})

# ============================================================
# SECTION 6: Core Meta-Analysis Functions
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 6: Core Meta-Analysis Functions\n")
cat(strrep("=", 60), "\n")

fit_hr <- NULL
run_test("robust_rma() - on HR data", {
  fit_hr <<- robust_rma(data_hr$yi, data_hr$se, method = "REML", use_hksj = TRUE)
  stopifnot(inherits(fit_hr, "rma.uni"))
  cat("Pooled log(HR):", round(coef(fit_hr), 3), "\n")
  cat("Pooled HR:", round(exp(coef(fit_hr)), 3), "\n")
  cat("τ²:", round(fit_hr$tau2, 4), "\n")
  cat("I²:", round(fit_hr$I2, 1), "%\n")
})

run_test("robust_rma() - on OR data", {
  fit_or <- robust_rma(data_or$yi, data_or$se, method = "REML", use_hksj = TRUE)
  stopifnot(inherits(fit_or, "rma.uni"))
  cat("Pooled log(OR):", round(coef(fit_or), 3), "\n")
  cat("Pooled OR:", round(exp(coef(fit_or)), 3), "\n")
})

run_test("pet_peese() - publication bias", {
  pp <- pet_peese(data_hr$yi, data_hr$se)
  stopifnot(is.numeric(pp))
  stopifnot(length(pp) == 2)
  stopifnot(all(c("PET", "PEESE") %in% names(pp)))
  cat("PET intercept:", round(pp["PET"], 3), "\n")
  cat("PEESE intercept:", round(pp["PEESE"], 3), "\n")
  cat("PET HR:", round(exp(pp["PET"]), 3), "\n")
  cat("PEESE HR:", round(exp(pp["PEESE"]), 3), "\n")
})

# ============================================================
# SECTION 7: Weighting Functions
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 7: Weighting Functions\n")
cat(strrep("=", 60), "\n")

run_test("compute_transport_weights() - with target population", {
  target_pop <- list(
    age_mean = 70.0,
    female_pct = 0.45,
    bmi_mean = 28.0,
    charlson = 1.8
  )

  weights <- compute_transport_weights(data_hr, target_pop, truncation = 0.02)
  stopifnot(is.numeric(weights))
  stopifnot(length(weights) == nrow(data_hr))
  stopifnot(all(weights > 0))
  stopifnot(abs(sum(weights) - 1) < 0.01)  # Should sum to ~1

  cat("Transport weights calculated\n")
  cat("Min weight:", round(min(weights), 4), "\n")
  cat("Max weight:", round(max(weights), 4), "\n")
  cat("Sum of weights:", round(sum(weights), 4), "\n")
})

run_test("compute_transport_weights() - missing covariates (fallback)", {
  data_minimal <- data.frame(
    study_id = c("S1", "S2"),
    yi = c(log(0.8), log(0.9)),
    se = c(0.1, 0.12),
    study_type = c("RCT", "OBS")
  )

  target_pop <- list(age_mean = 70, female_pct = 0.5, bmi_mean = 28, charlson = 2)

  suppressWarnings({
    weights <- compute_transport_weights(data_minimal, target_pop)
  })

  stopifnot(all(weights == 0.5))  # Should be uniform
  cat("Fallback to uniform weights: SUCCESS\n")
})

# ============================================================
# SECTION 8: Full Analysis Pipeline
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 8: Full Analysis Pipeline\n")
cat(strrep("=", 60), "\n")

run_test("run_cbamm_analysis() - basic execution", {
  config <- setup_cbamm(
    effect_measure = "HR",
    use_transport = FALSE,  # Disable to avoid dependency on WeightIt
    use_bayesian = FALSE,   # Disable to speed up test
    run_mv = FALSE,         # Disable MV for now
    use_ml = FALSE,
    export_results = FALSE
  )

  # Ensure required columns
  test_data <- data_hr
  if (!"grade" %in% names(test_data)) {
    test_data$grade <- factor(sample(c("High", "Moderate", "Low"),
                                     nrow(test_data), replace = TRUE),
                              levels = c("High", "Moderate", "Low", "Very low"))
  }

  results <- run_cbamm_analysis(test_data, target_population = NULL, config = config)

  stopifnot(is.list(results))
  stopifnot("results" %in% names(results))
  stopifnot("analysis_data" %in% names(results))

  cat("Analysis completed successfully\n")
  cat("Result components:\n")
  cat("  -", paste(names(results), collapse = "\n  - "), "\n")

  if (!is.null(results$results$pooled)) {
    cat("\nPooled analysis results available\n")
  }
  if (!is.null(results$results$pet_peese)) {
    cat("PET-PEESE results available\n")
  }
})

# ============================================================
# SECTION 9: Edge Cases and Error Handling
# ============================================================

cat("\n"); cat(strrep("=", 60), "\n")
cat("SECTION 9: Edge Cases and Error Handling\n")
cat(strrep("=", 60), "\n")

run_test("Handle insufficient data (< 3 studies)", {
  data_tiny <- data.frame(
    study_id = c("S1", "S2"),
    yi = c(log(0.8), log(0.9)),
    se = c(0.1, 0.12),
    study_type = c("RCT", "OBS")
  )

  result <- tryCatch({
    robust_rma(data_tiny$yi, data_tiny$se)
    FALSE  # Should not get here
  }, error = function(e) {
    cat("Expected error caught:", conditionMessage(e), "\n")
    TRUE
  })

  stopifnot(result)
})

run_test("Handle non-finite values", {
  data_bad <- data.frame(
    study_id = c("S1", "S2", "S3"),
    yi = c(log(0.8), NA, log(0.9)),
    se = c(0.1, 0.12, 0.11),
    study_type = rep("RCT", 3)
  )

  result <- tryCatch({
    robust_rma(data_bad$yi, data_bad$se)
    FALSE
  }, error = function(e) {
    cat("Expected error caught:", conditionMessage(e), "\n")
    TRUE
  })

  stopifnot(result)
})

run_test("Validate wrong measure specification", {
  result <- tryCatch({
    validation <- cbamm_pairwise_validator(data_binary, measure = "SMD")
    !validation$ok  # Should fail validation
  }, error = function(e) {
    TRUE  # Error is also acceptable
  })

  stopifnot(result)
  cat("Measure mismatch detected correctly\n")
})

# ============================================================
# FINAL SUMMARY
# ============================================================

cat("\n\n")
cat(strrep("=", 60), "\n")
cat("TEST SUMMARY\n")
cat(strrep("=", 60), "\n\n")

cat(sprintf("Total tests:  %d\n", test_count))
cat(sprintf("✓ Passed:     %d (%.1f%%)\n", pass_count, 100 * pass_count / test_count))
cat(sprintf("✗ Failed:     %d (%.1f%%)\n", fail_count, 100 * fail_count / test_count))

if (fail_count == 0) {
  cat("\n🎉 ALL TESTS PASSED! Package is working correctly.\n\n")
} else {
  cat("\n⚠️  SOME TESTS FAILED. Review errors above.\n\n")
  cat("Failed tests:\n")
  for (name in names(test_results)) {
    if (grepl("^FAIL:", test_results[[name]])) {
      cat(sprintf("  - %s: %s\n", name, test_results[[name]]))
    }
  }
  cat("\n")
}

cat(strrep("=", 60), "\n")

# Save results
saveRDS(test_results, file = "test_results.rds")
cat("Test results saved to: test_results.rds\n")

# Exit with appropriate code
if (fail_count > 0) {
  quit(save = "no", status = 1)
} else {
  quit(save = "no", status = 0)
}
