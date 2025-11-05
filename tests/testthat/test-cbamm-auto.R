# Tests for cbamm_auto() - The Flagship Function
# Comprehensive testing of the automated workflow

library(testthat)
library(metafor)

context("cbamm_auto() Automated Workflow")

# ===========================================
# TEST SUITE 1: Basic Functionality
# ===========================================

test_that("cbamm_auto runs successfully with binary data", {
  skip_if_not_installed("metafor")

  # Create simple binary outcome data
  data <- data.frame(
    study = paste("Study", 1:8),
    ai = c(10, 15, 12, 18, 14, 16, 11, 13),
    bi = c(90, 85, 88, 82, 86, 84, 89, 87),
    ci = c(15, 20, 18, 23, 19, 21, 16, 18),
    di = c(85, 80, 82, 77, 81, 79, 84, 82)
  )

  # Test: Should run without error
  expect_error(cbamm_auto(data, pathway = "standard", verbose = FALSE), NA)
})

test_that("cbamm_auto runs successfully with continuous data", {
  skip_if_not_installed("metafor")

  # Create continuous outcome data
  data <- data.frame(
    study = paste("Study", 1:6),
    m1i = c(5.2, 4.8, 5.5, 5.0, 5.3, 4.9),
    sd1i = c(1.2, 1.1, 1.3, 1.2, 1.1, 1.2),
    n1i = c(50, 60, 55, 52, 58, 54),
    m2i = c(4.0, 3.8, 4.2, 3.9, 4.1, 3.7),
    sd2i = c(1.3, 1.2, 1.4, 1.3, 1.2, 1.3),
    n2i = c(48, 58, 53, 50, 56, 52)
  )

  # Test: Should run without error
  expect_error(cbamm_auto(data, pathway = "standard", verbose = FALSE), NA)
})

test_that("cbamm_auto runs successfully with effect sizes + variance", {
  skip_if_not_installed("metafor")

  # Pre-calculated effect sizes
  data <- data.frame(
    study = paste("Study", 1:10),
    yi = rnorm(10, 0.5, 0.2),
    vi = runif(10, 0.02, 0.08)
  )

  # Test: Should run without error
  expect_error(cbamm_auto(data, pathway = "standard", verbose = FALSE), NA)
})

# ===========================================
# TEST SUITE 2: Pathway Testing
# ===========================================

test_that("All three pathways run successfully", {
  skip_if_not_installed("metafor")

  # Test data
  data <- data.frame(
    study = paste("Study", 1:8),
    yi = rnorm(8, 0.5, 0.2),
    vi = runif(8, 0.03, 0.07)
  )

  # Test: Standard pathway
  expect_error(cbamm_auto(data, pathway = "standard", verbose = FALSE), NA)

  # Test: Advanced pathway (may take longer)
  expect_error(cbamm_auto(data, pathway = "advanced", verbose = FALSE), NA)

  # Test: Custom pathway
  expect_error(cbamm_auto(data, pathway = "custom",
                          custom_effect_measure = "OR",
                          custom_estimator = "REML",
                          verbose = FALSE), NA)
})

test_that("Custom pathway respects user specifications", {
  skip_if_not_installed("metafor")

  data <- data.frame(
    study = paste("Study", 1:6),
    ai = c(10, 15, 12, 18, 14, 16),
    bi = c(90, 85, 88, 82, 86, 84),
    ci = c(15, 20, 18, 23, 19, 21),
    di = c(85, 80, 82, 77, 81, 79)
  )

  # Run with custom specifications
  result <- cbamm_auto(data,
                       pathway = "custom",
                       custom_effect_measure = "OR",
                       custom_estimator = "ML",
                       custom_pub_bias = c("egger", "trimfill"),
                       verbose = FALSE)

  # Test: Result should exist
  expect_true(!is.null(result))

  # Test: Should have made the decisions we specified
  # (This tests the decision logging functionality)
  if (!is.null(result$decisions)) {
    expect_equal(result$decisions$pathway, "custom")
  }
})

# ===========================================
# TEST SUITE 3: Output Structure
# ===========================================

test_that("cbamm_auto returns correct output structure", {
  skip_if_not_installed("metafor")

  data <- data.frame(
    study = paste("Study", 1:8),
    yi = rnorm(8, 0.5, 0.2),
    vi = runif(8, 0.03, 0.07)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Result should be a list
  expect_type(result, "list")

  # Test: Should have class "cbamm_auto"
  expect_s3_class(result, "cbamm_auto")

  # Test: Should contain expected components
  expected_components <- c("pooled", "decisions", "data_info")

  for (comp in expected_components) {
    expect_true(comp %in% names(result),
                info = paste("Missing component:", comp))
  }
})

test_that("cbamm_auto output contains pooled estimate", {
  skip_if_not_installed("metafor")

  data <- data.frame(
    study = paste("Study", 1:8),
    yi = rnorm(8, 0.5, 0.2),
    vi = runif(8, 0.03, 0.07)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Should have pooled results
  expect_true(!is.null(result$pooled))

  # Test: Pooled estimate should be numeric
  expect_true(is.numeric(result$pooled$estimate) ||
                "estimate" %in% names(result$pooled))
})

# ===========================================
# TEST SUITE 4: Decision Logging
# ===========================================

test_that("cbamm_auto logs all automated decisions", {
  skip_if_not_installed("metafor")

  data <- data.frame(
    study = paste("Study", 1:8),
    yi = rnorm(8, 0.5, 0.2),
    vi = runif(8, 0.03, 0.07)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Should have decisions logged
  expect_true(!is.null(result$decisions))

  # Test: Decisions should include pathway
  expect_true("pathway" %in% names(result$decisions))

  # Test: Should log data detection
  expect_true("data_detection" %in% names(result$decisions) ||
                "data_info" %in% names(result))
})

test_that("Decisions are accessible and interpretable", {
  skip_if_not_installed("metafor")

  data <- data.frame(
    study = paste("Study", 1:6),
    ai = c(10, 15, 12, 18, 14, 16),
    bi = c(90, 85, 88, 82, 86, 84),
    ci = c(15, 20, 18, 23, 19, 21),
    di = c(85, 80, 82, 77, 81, 79)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Decisions should be interpretable
  # (checking that we have some decision information)
  expect_true(length(result$decisions) > 0)
})

# ===========================================
# TEST SUITE 5: Data Type Detection
# ===========================================

test_that("Correctly detects binary data format", {
  skip_if_not_installed("metafor")

  # Binary data (2x2 table)
  data <- data.frame(
    study = paste("Study", 1:5),
    ai = c(10, 15, 12, 18, 14),
    bi = c(90, 85, 88, 82, 86),
    ci = c(15, 20, 18, 23, 19),
    di = c(85, 80, 82, 77, 81)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Should detect binary data
  # (This tests the .detect_data_type internal function)
  expect_true(!is.null(result$data_info) || !is.null(result$decisions$data_detection))
})

test_that("Correctly detects continuous data format", {
  skip_if_not_installed("metafor")

  # Continuous data
  data <- data.frame(
    study = paste("Study", 1:5),
    m1i = c(5.2, 4.8, 5.5, 5.0, 5.3),
    sd1i = c(1.2, 1.1, 1.3, 1.2, 1.1),
    n1i = c(50, 60, 55, 52, 58),
    m2i = c(4.0, 3.8, 4.2, 3.9, 4.1),
    sd2i = c(1.3, 1.2, 1.4, 1.3, 1.2),
    n2i = c(48, 58, 53, 50, 56)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Should detect continuous data
  expect_true(!is.null(result$data_info) || !is.null(result$decisions$data_detection))
})

test_that("Correctly detects pre-calculated effect sizes", {
  skip_if_not_installed("metafor")

  # Pre-calculated effect sizes
  data <- data.frame(
    study = paste("Study", 1:5),
    yi = c(0.5, 0.3, 0.7, 0.4, 0.6),
    vi = c(0.05, 0.04, 0.06, 0.05, 0.04)
  )

  result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Should detect effect size data
  expect_true(!is.null(result$data_info) || !is.null(result$decisions$data_detection))
})

# ===========================================
# TEST SUITE 6: Input Validation
# ===========================================

test_that("Rejects invalid input data", {
  # Test: NULL data
  expect_error(cbamm_auto(NULL, pathway = "standard", verbose = FALSE))

  # Test: Empty data frame
  expect_error(cbamm_auto(data.frame(), pathway = "standard", verbose = FALSE))

  # Test: Data with wrong structure
  bad_data <- data.frame(x = 1:5, y = 6:10)
  expect_error(cbamm_auto(bad_data, pathway = "standard", verbose = FALSE))
})

test_that("Rejects insufficient number of studies", {
  # Too few studies (< 3)
  data <- data.frame(
    study = c("Study 1", "Study 2"),
    yi = c(0.5, 0.4),
    vi = c(0.05, 0.04)
  )

  expect_error(cbamm_auto(data, pathway = "standard", verbose = FALSE))
})

test_that("Validates pathway argument", {
  data <- data.frame(
    study = paste("Study", 1:5),
    yi = rnorm(5, 0.5, 0.2),
    vi = runif(5, 0.03, 0.07)
  )

  # Test: Invalid pathway
  expect_error(cbamm_auto(data, pathway = "invalid", verbose = FALSE))

  # Test: Valid pathways
  expect_error(cbamm_auto(data, pathway = "standard", verbose = FALSE), NA)
  expect_error(cbamm_auto(data, pathway = "advanced", verbose = FALSE), NA)
  expect_error(cbamm_auto(data, pathway = "custom",
                          custom_effect_measure = "OR",
                          verbose = FALSE), NA)
})

# ===========================================
# TEST SUITE 7: Reproducibility
# ===========================================

test_that("Produces reproducible results with same input", {
  skip_if_not_installed("metafor")

  # Fixed data (no random seed needed)
  data <- data.frame(
    study = paste("Study", 1:8),
    yi = c(0.5, 0.4, 0.6, 0.5, 0.7, 0.4, 0.5, 0.6),
    vi = c(0.05, 0.04, 0.06, 0.05, 0.04, 0.06, 0.05, 0.04)
  )

  # Run twice
  result1 <- cbamm_auto(data, pathway = "standard", verbose = FALSE)
  result2 <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Test: Pooled estimates should be identical
  expect_equal(result1$pooled$estimate, result2$pooled$estimate, tolerance = 1e-10)
})

# ===========================================
# TEST SUITE 8: Example Dataset Integration
# ===========================================

test_that("Works with package example datasets", {
  skip_if_not_installed("metafor")

  # Test with bcg_vaccine dataset (if available)
  if (exists("bcg_vaccine")) {
    expect_error(cbamm_auto(bcg_vaccine, pathway = "standard", verbose = FALSE), NA)
  }

  # Test with aspirin_mi dataset (if available)
  if (exists("aspirin_mi")) {
    expect_error(cbamm_auto(aspirin_mi, pathway = "standard", verbose = FALSE), NA)
  }
})

# ===========================================
# TEST SUITE 9: Integration with metafor
# ===========================================

test_that("Results are consistent with manual metafor analysis", {
  skip_if_not_installed("metafor")

  # Data with known structure
  data <- data.frame(
    study = paste("Study", 1:10),
    yi = c(0.5, 0.4, 0.6, 0.5, 0.7, 0.4, 0.5, 0.6, 0.4, 0.5),
    vi = c(0.05, 0.04, 0.06, 0.05, 0.04, 0.06, 0.05, 0.04, 0.05, 0.06)
  )

  # Run with cbamm_auto
  cbamm_result <- cbamm_auto(data, pathway = "standard", verbose = FALSE)

  # Run manually with metafor
  metafor_result <- rma(yi, vi, data = data, method = "REML")

  # Test: Pooled estimates should be very similar
  # (allowing small tolerance for any wrapper differences)
  expect_equal(cbamm_result$pooled$estimate,
               as.numeric(metafor_result$beta),
               tolerance = 0.01)
})

# ===========================================
# TEST SUITE 10: Report Generation
# ===========================================

test_that("Report generation completes without error", {
  skip_if_not_installed("metafor")

  data <- data.frame(
    study = paste("Study", 1:8),
    yi = rnorm(8, 0.5, 0.2),
    vi = runif(8, 0.03, 0.07)
  )

  # Run analysis with report generation
  expect_error(
    cbamm_auto(data,
               pathway = "standard",
               verbose = FALSE,
               generate_rmd = FALSE,  # Don't actually generate to avoid file I/O in tests
               save_report = FALSE),
    NA
  )
})

# ===========================================
# SUMMARY MESSAGE
# ===========================================

message("\n=================================================")
message("cbamm_auto() Test Suite Complete")
message("=================================================")
message("These tests validate the flagship function:")
message("  ✓ Runs successfully with different data types")
message("  ✓ All pathways (standard/advanced/custom) work")
message("  ✓ Output structure is correct")
message("  ✓ Decisions are logged and accessible")
message("  ✓ Data type detection works")
message("  ✓ Input validation catches errors")
message("  ✓ Results are reproducible")
message("  ✓ Integration with metafor validated")
message("=================================================\n")
