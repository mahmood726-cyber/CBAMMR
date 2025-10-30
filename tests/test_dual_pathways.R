#!/usr/bin/env Rscript
# Test Dual-Pathway Functionality
# Tests both standard and advanced pathways with example data

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  CBAMMR Dual-Pathway Test Suite\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Load required libraries
suppressMessages({
  library(metafor)
})

# Source CBAMMR functions
cat("Loading CBAMMR functions...\n")
source("R/intelligent-auto-analysis.R")
source("R/effect-sizes.R")
source("R/meta-analysis.R")
source("R/heterogeneity.R")
source("R/publication-bias.R")
source("R/sensitivity.R")
source("R/visualization.R")

# Test 1: Binary data - Standard pathway
cat("\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("Test 1: Binary Outcomes - STANDARD Pathway\n")
cat("─────────────────────────────────────────────────────────────\n")

# Create binary test data
data_binary <- data.frame(
  study = c("Smith 2020", "Jones 2019", "Brown 2021", "Wilson 2018", "Davis 2022", "Taylor 2020"),
  year = c(2020, 2019, 2021, 2018, 2022, 2020),
  ai = c(15, 8, 22, 5, 31, 12),
  bi = c(85, 92, 178, 45, 269, 88),
  ci = c(25, 18, 35, 12, 48, 20),
  di = c(75, 82, 165, 38, 252, 80),
  quality = c(8, 7, 9, 6, 8, 7)
)

tryCatch({
  result_standard <- cbamm_auto(
    data = data_binary,
    pathway = "standard",
    study_id = "study",
    verbose = TRUE,
    generate_rmd = FALSE
  )

  cat("\n✓ Standard pathway completed successfully\n")
  cat("  Pathway:", result_standard$pathway, "\n")
  cat("  Estimate:", sprintf("%.3f", result_standard$estimate), "\n")
  cat("  95% CI: [", sprintf("%.3f", result_standard$ci_lb), ", ",
      sprintf("%.3f", result_standard$ci_ub), "]\n")
  cat("  p-value:", sprintf("%.4f", result_standard$pval), "\n")
  cat("  Method:", result_standard$method, "\n")
  cat("  Estimator:", result_standard$estimator, "\n")

  test1_pass <- TRUE
}, error = function(e) {
  cat("\n✗ Standard pathway FAILED\n")
  cat("Error:", e$message, "\n")
  test1_pass <- FALSE
})

# Test 2: Binary data - Advanced pathway
cat("\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("Test 2: Binary Outcomes - ADVANCED Pathway\n")
cat("─────────────────────────────────────────────────────────────\n")

tryCatch({
  result_advanced <- cbamm_auto(
    data = data_binary,
    pathway = "advanced",
    study_id = "study",
    verbose = TRUE,
    generate_rmd = FALSE
  )

  cat("\n✓ Advanced pathway completed successfully\n")
  cat("  Pathway:", result_advanced$pathway, "\n")
  cat("  Estimate:", sprintf("%.3f", result_advanced$estimate), "\n")
  cat("  95% CI: [", sprintf("%.3f", result_advanced$ci_lb), ", ",
      sprintf("%.3f", result_advanced$ci_ub), "]\n")
  cat("  p-value:", sprintf("%.4f", result_advanced$pval), "\n")
  cat("  Method:", result_advanced$method, "\n")

  if (!is.null(result_advanced$advanced_results)) {
    cat("  Advanced analyses:", length(result_advanced$advanced_results), "completed\n")
    if (length(result_advanced$advanced_results) > 0) {
      cat("  Available:", paste(names(result_advanced$advanced_results), collapse = ", "), "\n")
    }
  }

  test2_pass <- TRUE
}, error = function(e) {
  cat("\n✗ Advanced pathway FAILED\n")
  cat("Error:", e$message, "\n")
  test2_pass <- FALSE
})

# Test 3: Continuous data - Standard pathway
cat("\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("Test 3: Continuous Outcomes - STANDARD Pathway\n")
cat("─────────────────────────────────────────────────────────────\n")

data_continuous <- data.frame(
  study = c("Smith 2020", "Jones 2019", "Brown 2021", "Wilson 2018", "Davis 2022", "Taylor 2020"),
  year = c(2020, 2019, 2021, 2018, 2022, 2020),
  mean_treat = c(12.5, 10.2, 11.8, 13.2, 9.8, 11.2),
  sd_treat = c(3.2, 2.8, 3.0, 3.8, 2.5, 3.1),
  n_treat = c(50, 65, 120, 35, 90, 75),
  mean_control = c(15.8, 13.1, 14.5, 16.1, 12.7, 14.3),
  sd_control = c(3.5, 3.1, 3.2, 4.0, 2.9, 3.4),
  n_control = c(48, 62, 118, 33, 88, 72),
  quality = c(8, 7, 9, 6, 8, 8)
)

tryCatch({
  result_cont_standard <- cbamm_auto(
    data = data_continuous,
    pathway = "standard",
    study_id = "study",
    verbose = TRUE,
    generate_rmd = FALSE
  )

  cat("\n✓ Standard pathway (continuous) completed successfully\n")
  cat("  Pathway:", result_cont_standard$pathway, "\n")
  cat("  Estimate:", sprintf("%.3f", result_cont_standard$estimate), "\n")
  cat("  95% CI: [", sprintf("%.3f", result_cont_standard$ci_lb), ", ",
      sprintf("%.3f", result_cont_standard$ci_ub), "]\n")
  cat("  p-value:", sprintf("%.4f", result_cont_standard$pval), "\n")

  test3_pass <- TRUE
}, error = function(e) {
  cat("\n✗ Standard pathway (continuous) FAILED\n")
  cat("Error:", e$message, "\n")
  test3_pass <- FALSE
})

# Test 4: Pre-calculated effect sizes - Standard pathway
cat("\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("Test 4: Pre-calculated Effect Sizes - STANDARD Pathway\n")
cat("─────────────────────────────────────────────────────────────\n")

data_es <- data.frame(
  study = c("Study 1", "Study 2", "Study 3", "Study 4", "Study 5", "Study 6"),
  year = c(2020, 2019, 2021, 2018, 2022, 2020),
  yi = c(-0.523, -0.812, -0.345, -0.678, -0.456, -0.589),
  vi = c(0.045, 0.068, 0.032, 0.091, 0.038, 0.052)
)

tryCatch({
  result_es_standard <- cbamm_auto(
    data = data_es,
    pathway = "standard",
    study_id = "study",
    verbose = TRUE,
    generate_rmd = FALSE
  )

  cat("\n✓ Standard pathway (effect sizes) completed successfully\n")
  cat("  Pathway:", result_es_standard$pathway, "\n")
  cat("  Estimate:", sprintf("%.3f", result_es_standard$estimate), "\n")
  cat("  95% CI: [", sprintf("%.3f", result_es_standard$ci_lb), ", ",
      sprintf("%.3f", result_es_standard$ci_ub), "]\n")

  test4_pass <- TRUE
}, error = function(e) {
  cat("\n✗ Standard pathway (effect sizes) FAILED\n")
  cat("Error:", e$message, "\n")
  test4_pass <- FALSE
})

# Test 5: Pathway parameter validation
cat("\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("Test 5: Pathway Parameter Validation\n")
cat("─────────────────────────────────────────────────────────────\n")

# Test default (should be "standard")
tryCatch({
  result_default <- cbamm_auto(
    data = data_es,
    study_id = "study",
    verbose = FALSE,
    generate_rmd = FALSE
  )

  if (result_default$pathway == "standard") {
    cat("✓ Default pathway is 'standard' (correct)\n")
    test5a_pass <- TRUE
  } else {
    cat("✗ Default pathway is '", result_default$pathway, "' (should be 'standard')\n")
    test5a_pass <- FALSE
  }
}, error = function(e) {
  cat("✗ Default pathway test FAILED:", e$message, "\n")
  test5a_pass <- FALSE
})

# Test invalid pathway (should error)
tryCatch({
  result_invalid <- cbamm_auto(
    data = data_es,
    pathway = "invalid",
    study_id = "study",
    verbose = FALSE,
    generate_rmd = FALSE
  )

  cat("✗ Invalid pathway did not throw error (should have failed)\n")
  test5b_pass <- FALSE
}, error = function(e) {
  cat("✓ Invalid pathway correctly rejected\n")
  test5b_pass <- TRUE
})

# Summary
cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  Test Summary\n")
cat("═══════════════════════════════════════════════════════════════\n")

all_tests <- c(
  test1_pass, test2_pass, test3_pass, test4_pass,
  test5a_pass, test5b_pass
)

if (exists("test1_pass")) {
  cat("Test 1 (Binary - Standard):", if(test1_pass) "✓ PASS" else "✗ FAIL", "\n")
}
if (exists("test2_pass")) {
  cat("Test 2 (Binary - Advanced):", if(test2_pass) "✓ PASS" else "✗ FAIL", "\n")
}
if (exists("test3_pass")) {
  cat("Test 3 (Continuous - Standard):", if(test3_pass) "✓ PASS" else "✗ FAIL", "\n")
}
if (exists("test4_pass")) {
  cat("Test 4 (Effect Sizes - Standard):", if(test4_pass) "✓ PASS" else "✗ FAIL", "\n")
}
if (exists("test5a_pass")) {
  cat("Test 5a (Default pathway):", if(test5a_pass) "✓ PASS" else "✗ FAIL", "\n")
}
if (exists("test5b_pass")) {
  cat("Test 5b (Invalid pathway):", if(test5b_pass) "✓ PASS" else "✗ FAIL", "\n")
}

cat("\n")
passed <- sum(sapply(list(test1_pass, test2_pass, test3_pass, test4_pass, test5a_pass, test5b_pass),
                     function(x) if(exists(deparse(substitute(x)))) x else FALSE))
total <- 6

if (passed == total) {
  cat("✓ ALL TESTS PASSED (", passed, "/", total, ")\n")
  cat("\nCBAMMR dual-pathway functionality is working correctly!\n")
} else {
  cat("✗ SOME TESTS FAILED (", passed, "/", total, " passed)\n")
  cat("\nPlease review errors above.\n")
}

cat("═══════════════════════════════════════════════════════════════\n\n")
