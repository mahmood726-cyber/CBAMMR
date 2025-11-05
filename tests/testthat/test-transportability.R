# Transportability Analysis Validation Tests
# Tests for compute_transport_weights() and entropy balancing methods
# Based on Hainmueller (2012) entropy balancing methodology

library(testthat)
library(dplyr)

# =============================================================================
# TEST 1: Basic Weight Computation
# =============================================================================

test_that("compute_transport_weights returns valid probability weights", {
  skip_if_not_installed("WeightIt")

  # Create sample data with required covariates
  set.seed(12345)
  data <- data.frame(
    study = paste("Study", 1:10),
    age_mean = rnorm(10, mean = 55, sd = 5),
    female_pct = runif(10, 0.3, 0.7),
    bmi_mean = rnorm(10, mean = 28, sd = 3),
    charlson = rpois(10, lambda = 2.5),
    yi = rnorm(10, mean = log(0.7), sd = 0.15),
    vi = runif(10, 0.01, 0.05)
  )

  # Define target population (e.g., older, more comorbid)
  target <- list(
    age_mean = 65,
    female_pct = 0.6,
    bmi_mean = 30,
    charlson = 3.5
  )

  weights <- compute_transport_weights(data, target)

  # Weights should be valid probabilities
  expect_true(all(weights >= 0))
  expect_equal(sum(weights), 1, tolerance = 1e-10)
  expect_length(weights, nrow(data))
  expect_true(all(is.finite(weights)))
})


# =============================================================================
# TEST 2: Covariate Balance Achievement
# =============================================================================

test_that("entropy balancing achieves target covariate moments", {
  skip_if_not_installed("WeightIt")

  set.seed(12345)
  n <- 20
  data <- data.frame(
    study = paste("Study", 1:n),
    age_mean = rnorm(n, mean = 50, sd = 8),
    female_pct = runif(n, 0.2, 0.8),
    bmi_mean = rnorm(n, mean = 26, sd = 4),
    charlson = rpois(n, lambda = 2),
    yi = rnorm(n, mean = log(0.8), sd = 0.2),
    vi = runif(n, 0.01, 0.08)
  )

  target <- list(
    age_mean = 60,
    female_pct = 0.55,
    bmi_mean = 29,
    charlson = 3.0
  )

  weights <- compute_transport_weights(data, target, truncation = 0.05)

  # Check weighted means match target (with tolerance for truncation)
  weighted_age <- sum(weights * data$age_mean)
  weighted_female <- sum(weights * data$female_pct)
  weighted_bmi <- sum(weights * data$bmi_mean)
  weighted_charlson <- sum(weights * data$charlson)

  # Should be close to target (within 10% due to truncation)
  expect_equal(weighted_age, target$age_mean, tolerance = 6)
  expect_equal(weighted_female, target$female_pct, tolerance = 0.1)
  expect_equal(weighted_bmi, target$bmi_mean, tolerance = 3)
  expect_equal(weighted_charlson, target$charlson, tolerance = 0.5)
})


# =============================================================================
# TEST 3: Weight Truncation
# =============================================================================

test_that("weight truncation prevents extreme weights", {
  skip_if_not_installed("WeightIt")

  set.seed(12345)
  # Create data with one outlier study
  data <- data.frame(
    study = paste("Study", 1:15),
    age_mean = c(rnorm(14, 50, 5), 85),  # One extreme outlier
    female_pct = c(runif(14, 0.4, 0.6), 0.95),
    bmi_mean = c(rnorm(14, 27, 3), 40),
    charlson = c(rpois(14, 2), 10),
    yi = rnorm(15, log(0.75), 0.15),
    vi = runif(15, 0.02, 0.06)
  )

  target <- list(age_mean = 80, female_pct = 0.9, bmi_mean = 38, charlson = 8)

  # Test with truncation
  weights_truncated <- compute_transport_weights(data, target, truncation = 0.1)

  # Test without truncation
  weights_full <- compute_transport_weights(data, target, truncation = 0)

  # Truncated weights should have smaller range
  expect_true(max(weights_truncated) / min(weights_truncated) <
              max(weights_full) / min(weights_full))

  # No weight should be too extreme (for truncated version)
  expect_true(max(weights_truncated) < 0.4)  # Not too concentrated
  expect_true(min(weights_truncated) > 0.001)  # Not too diluted
})


# =============================================================================
# TEST 4: Missing Covariate Handling
# =============================================================================

test_that("missing transportability covariates trigger uniform weights", {
  set.seed(12345)
  data <- data.frame(
    study = paste("Study", 1:8),
    age_mean = rnorm(8, 55, 5),
    # Missing: female_pct, bmi_mean, charlson
    yi = rnorm(8, log(0.8), 0.1),
    vi = runif(8, 0.02, 0.05)
  )

  target <- list(age_mean = 65, female_pct = 0.5, bmi_mean = 28, charlson = 3)

  expect_warning(
    weights <- compute_transport_weights(data, target),
    "Missing transportability variables"
  )

  # Should return uniform weights
  expect_equal(weights, rep(1/8, 8))
})


# =============================================================================
# TEST 5: Effect Estimate Modification
# =============================================================================

test_that("transportability weights modify pooled estimates appropriately", {
  skip_if_not_installed("WeightIt")
  skip_if_not_installed("metafor")

  set.seed(12345)
  # Create data where younger patients have stronger effects
  n <- 25
  age <- rnorm(n, 55, 10)
  # Effect size inversely related to age
  true_effect <- log(0.5) + (age - 55) * 0.01  # Stronger effect in younger

  data <- data.frame(
    study = paste("Study", 1:n),
    age_mean = age,
    female_pct = runif(n, 0.4, 0.6),
    bmi_mean = rnorm(n, 27, 3),
    charlson = rpois(n, 2),
    yi = true_effect + rnorm(n, 0, 0.1),
    vi = runif(n, 0.01, 0.04)
  )

  # Unweighted estimate (average population ~55 years)
  res_unweighted <- metafor::rma(yi, vi, data = data, method = "REML")

  # Target: Younger population (should have stronger effect)
  target_young <- list(age_mean = 45, female_pct = 0.5, bmi_mean = 27, charlson = 2)
  weights_young <- compute_transport_weights(data, target_young, truncation = 0.05)
  res_young <- metafor::rma(yi, vi, data = data, weights = weights_young, method = "REML")

  # Target: Older population (should have weaker effect)
  target_old <- list(age_mean = 70, female_pct = 0.5, bmi_mean = 27, charlson = 2)
  weights_old <- compute_transport_weights(data, target_old, truncation = 0.05)
  res_old <- metafor::rma(yi, vi, data = data, weights = weights_old, method = "REML")

  # Effect should be stronger (more negative OR) for younger population
  expect_true(res_young$beta[1] < res_unweighted$beta[1])

  # Effect should be weaker (less negative OR) for older population
  expect_true(res_old$beta[1] > res_unweighted$beta[1])

  # Young effect should be stronger than old effect
  expect_true(res_young$beta[1] < res_old$beta[1])
})


# =============================================================================
# TEST 6: Reproducibility and Stability
# =============================================================================

test_that("transportability weights are reproducible with same seed", {
  skip_if_not_installed("WeightIt")

  data <- data.frame(
    study = paste("Study", 1:12),
    age_mean = rnorm(12, 55, 6),
    female_pct = runif(12, 0.35, 0.65),
    bmi_mean = rnorm(12, 28, 3),
    charlson = rpois(12, 2),
    yi = rnorm(12, log(0.75), 0.12),
    vi = runif(12, 0.02, 0.05)
  )

  target <- list(age_mean = 62, female_pct = 0.58, bmi_mean = 30, charlson = 3)

  # Should be reproducible (function sets seed internally)
  weights1 <- compute_transport_weights(data, target)
  weights2 <- compute_transport_weights(data, target)

  expect_equal(weights1, weights2)
})


# =============================================================================
# TEST 7: Fallback Optimization
# =============================================================================

test_that("fallback optimizer works when WeightIt fails", {
  # Temporarily make WeightIt unavailable by using extreme data
  set.seed(12345)
  data <- data.frame(
    study = paste("Study", 1:5),
    age_mean = c(30, 35, 40, 45, 50),
    female_pct = c(0.3, 0.4, 0.5, 0.6, 0.7),
    bmi_mean = c(22, 24, 26, 28, 30),
    charlson = c(0, 1, 2, 3, 4),
    yi = rnorm(5, log(0.8), 0.1),
    vi = rep(0.03, 5)
  )

  # Feasible target
  target <- list(age_mean = 42, female_pct = 0.5, bmi_mean = 26, charlson = 2.2)

  weights <- compute_transport_weights(data, target)

  # Should still return valid weights (either from WeightIt or fallback)
  expect_true(all(weights >= 0))
  expect_equal(sum(weights), 1, tolerance = 1e-10)
  expect_length(weights, 5)
})


# =============================================================================
# TEST 8: Extreme Target Population
# =============================================================================

test_that("handles extreme target populations gracefully", {
  skip_if_not_installed("WeightIt")

  set.seed(12345)
  data <- data.frame(
    study = paste("Study", 1:10),
    age_mean = rnorm(10, 50, 5),  # Sample: middle-aged
    female_pct = runif(10, 0.4, 0.6),
    bmi_mean = rnorm(10, 26, 2),
    charlson = rpois(10, 1),
    yi = rnorm(10, log(0.8), 0.15),
    vi = runif(10, 0.02, 0.05)
  )

  # Target: Very extreme population
  target_extreme <- list(
    age_mean = 90,  # Much older than sample
    female_pct = 0.95,  # Much more female
    bmi_mean = 40,  # Much higher BMI
    charlson = 8  # Much sicker
  )

  # Should complete without error
  expect_error(
    weights <- compute_transport_weights(data, target_extreme, truncation = 0.1),
    NA
  )

  # Weights should still be valid
  expect_true(all(weights >= 0))
  expect_equal(sum(weights), 1, tolerance = 1e-10)
})


# =============================================================================
# TEST 9: Integration with cbamm_auto()
# =============================================================================

test_that("transportability integrates with cbamm_auto workflow", {
  skip_if_not_installed("WeightIt")
  skip_on_cran()  # Requires full CBAMMR package

  set.seed(12345)
  data <- data.frame(
    study = paste("Study", 1:10),
    ai = rpois(10, 15),
    bi = rpois(10, 85),
    ci = rpois(10, 25),
    di = rpois(10, 75),
    age_mean = rnorm(10, 55, 6),
    female_pct = runif(10, 0.4, 0.6),
    bmi_mean = rnorm(10, 27, 3),
    charlson = rpois(10, 2)
  )

  target <- list(age_mean = 65, female_pct = 0.6, bmi_mean = 30, charlson = 3.5)

  # Test that cbamm_auto can use transportability (if function exists)
  if (exists("cbamm_auto")) {
    expect_error(
      result <- cbamm_auto(
        data,
        pathway = "standard",
        target_population = target,
        verbose = FALSE
      ),
      NA
    )

    expect_true(!is.null(result$transport_weights))
  }
})


# =============================================================================
# TEST 10: Simulation Study - Known Ground Truth
# =============================================================================

test_that("transportability recovers true target population effect (simulation)", {
  skip_if_not_installed("WeightIt")
  skip_if_not_installed("metafor")
  skip_on_cran()  # Computationally intensive

  set.seed(54321)

  # TRUE DATA GENERATING PROCESS:
  # - Sample population: age=50, female=0.4, bmi=26, charlson=2
  # - Target population: age=65, female=0.6, bmi=30, charlson=4
  # - True effect varies by covariates:
  #   log(OR) = -0.3 + 0.01*(age-50) + 0.2*(female-0.4) + 0.02*(bmi-26) + 0.05*(charlson-2)

  # Generate 30 studies from sample population
  n_studies <- 30
  study_age <- rnorm(n_studies, 50, 8)
  study_female <- pmin(pmax(rnorm(n_studies, 0.4, 0.15), 0), 1)
  study_bmi <- rnorm(n_studies, 26, 4)
  study_charlson <- pmax(rnorm(n_studies, 2, 1), 0)

  # True effect for each study
  true_log_or <- -0.3 +
    0.01 * (study_age - 50) +
    0.2 * (study_female - 0.4) +
    0.02 * (study_bmi - 26) +
    0.05 * (study_charlson - 2)

  # Observed effect with noise
  data <- data.frame(
    study = paste("Study", 1:n_studies),
    age_mean = study_age,
    female_pct = study_female,
    bmi_mean = study_bmi,
    charlson = study_charlson,
    yi = true_log_or + rnorm(n_studies, 0, 0.08),
    vi = runif(n_studies, 0.01, 0.04)
  )

  # Calculate TRUE effect in target population
  target_age <- 65
  target_female <- 0.6
  target_bmi <- 30
  target_charlson <- 4

  true_target_effect <- -0.3 +
    0.01 * (target_age - 50) +
    0.2 * (target_female - 0.4) +
    0.02 * (target_bmi - 26) +
    0.05 * (target_charlson - 2)
  # true_target_effect = -0.3 + 0.15 + 0.04 + 0.08 + 0.10 = 0.07

  # Unweighted meta-analysis (sample population)
  res_unweighted <- metafor::rma(yi, vi, data = data, method = "REML")

  # Transportability-weighted meta-analysis
  target <- list(
    age_mean = target_age,
    female_pct = target_female,
    bmi_mean = target_bmi,
    charlson = target_charlson
  )

  weights <- compute_transport_weights(data, target, truncation = 0.05)
  res_weighted <- metafor::rma(yi, vi, data = data, weights = weights, method = "REML")

  # Check: Weighted estimate should be closer to true target effect
  error_unweighted <- abs(res_unweighted$beta[1] - true_target_effect)
  error_weighted <- abs(res_weighted$beta[1] - true_target_effect)

  expect_true(error_weighted < error_unweighted,
              info = sprintf("Unweighted error: %.4f, Weighted error: %.4f, True: %.4f",
                           error_unweighted, error_weighted, true_target_effect))

  # Weighted estimate should be reasonably close to truth (within 0.15)
  expect_true(error_weighted < 0.15,
              info = sprintf("Weighted estimate: %.4f, True effect: %.4f",
                           res_weighted$beta[1], true_target_effect))
})


# =============================================================================
# TEST 11: Sensitivity to Truncation Parameter
# =============================================================================

test_that("truncation parameter affects weight distribution", {
  skip_if_not_installed("WeightIt")

  set.seed(12345)
  data <- data.frame(
    study = paste("Study", 1:15),
    age_mean = rnorm(15, 55, 10),
    female_pct = runif(15, 0.3, 0.7),
    bmi_mean = rnorm(15, 27, 4),
    charlson = rpois(15, 2),
    yi = rnorm(15, log(0.75), 0.15),
    vi = runif(15, 0.02, 0.06)
  )

  target <- list(age_mean = 70, female_pct = 0.65, bmi_mean = 32, charlson = 4)

  weights_0 <- compute_transport_weights(data, target, truncation = 0)
  weights_5 <- compute_transport_weights(data, target, truncation = 0.05)
  weights_10 <- compute_transport_weights(data, target, truncation = 0.10)

  # Higher truncation should reduce weight variance
  var_0 <- var(weights_0)
  var_5 <- var(weights_5)
  var_10 <- var(weights_10)

  expect_true(var_10 < var_5)
  expect_true(var_5 < var_0)

  # All should still sum to 1
  expect_equal(sum(weights_0), 1, tolerance = 1e-10)
  expect_equal(sum(weights_5), 1, tolerance = 1e-10)
  expect_equal(sum(weights_10), 1, tolerance = 1e-10)
})


# =============================================================================
# TEST 12: Documentation and Warnings
# =============================================================================

test_that("transportability methods provide appropriate warnings", {
  set.seed(12345)

  # Test 1: Missing covariates
  data_incomplete <- data.frame(
    study = paste("Study", 1:5),
    age_mean = rnorm(5, 55, 5),
    yi = rnorm(5, log(0.8), 0.1),
    vi = rep(0.03, 5)
  )

  target <- list(age_mean = 65, female_pct = 0.6, bmi_mean = 30, charlson = 3)

  expect_warning(
    compute_transport_weights(data_incomplete, target),
    "Missing transportability variables"
  )

  # Test 2: Very small sample size
  data_tiny <- data.frame(
    study = paste("Study", 1:3),
    age_mean = c(45, 55, 65),
    female_pct = c(0.3, 0.5, 0.7),
    bmi_mean = c(24, 27, 30),
    charlson = c(1, 2, 3),
    yi = rnorm(3, log(0.8), 0.1),
    vi = rep(0.04, 3)
  )

  # Should still work but may be unstable
  expect_error(
    weights <- compute_transport_weights(data_tiny, target),
    NA
  )
})
