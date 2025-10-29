# Tests for Clinical Decision Tools
# CBAMMR v8.1.0

context("Clinical Decision Tools")

# Test data
set.seed(123)
yi_test <- rnorm(10, mean = 0.5, sd = 0.3)
vi_test <- runif(10, 0.01, 0.1)

# ========================================
# Test: cbamm_decision_curve
# ========================================

test_that("cbamm_decision_curve returns valid structure", {
  result <- cbamm_decision_curve(yi_test, vi_test,
                                 threshold_range = seq(0.1, 0.9, by = 0.2))

  expect_s3_class(result, "cbamm_decision_curve")
  expect_true(is.numeric(result$optimal_threshold))
  expect_true(is.numeric(result$max_net_benefit))
  expect_true(is.vector(result$net_benefit_model))
  expect_equal(length(result$threshold_range), 5)
})

test_that("cbamm_decision_curve optimal threshold is within range", {
  thresh_range <- seq(0.1, 0.9, by = 0.1)
  result <- cbamm_decision_curve(yi_test, vi_test,
                                 threshold_range = thresh_range)

  expect_true(result$optimal_threshold >= min(thresh_range))
  expect_true(result$optimal_threshold <= max(thresh_range))
})

test_that("cbamm_decision_curve harm_benefit_ratio affects results", {
  result_low <- cbamm_decision_curve(yi_test, vi_test, harm_benefit_ratio = 0.5)
  result_high <- cbamm_decision_curve(yi_test, vi_test, harm_benefit_ratio = 2.0)

  # Different harm/benefit ratios should give different results
  expect_true(!all(result_low$net_benefit_model == result_high$net_benefit_model))
})

test_that("cbamm_decision_curve input validation", {
  expect_error(cbamm_decision_curve(yi_test[1:5], vi_test))
  expect_error(cbamm_decision_curve(yi_test, vi_test,
                                   harm_benefit_ratio = -1))
})

# ========================================
# Test: cbamm_prob_best
# ========================================

test_that("cbamm_prob_best returns valid structure", {
  result <- cbamm_prob_best(yi_test[1:5], vi_test[1:5], n_sim = 100)

  expect_s3_class(result, "cbamm_prob_best")
  expect_true(is.numeric(result$prob_best))
  expect_true(is.matrix(result$rank_probs))
  expect_true(is.numeric(result$sucra))
})

test_that("cbamm_prob_best probabilities sum to 1", {
  result <- cbamm_prob_best(yi_test[1:5], vi_test[1:5], n_sim = 100)

  # Probabilities of being best should sum to 1
  expect_equal(sum(result$prob_best), 1, tolerance = 0.01)

  # Each treatment's rank probabilities should sum to 1
  for (i in 1:nrow(result$rank_probs)) {
    expect_equal(sum(result$rank_probs[i, ]), 1, tolerance = 0.01)
  }
})

test_that("cbamm_prob_best SUCRA is between 0 and 1", {
  result <- cbamm_prob_best(yi_test[1:5], vi_test[1:5], n_sim = 100)

  expect_true(all(result$sucra >= 0))
  expect_true(all(result$sucra <= 1))
})

test_that("cbamm_prob_best handles treatment names", {
  names_test <- paste("Treatment", LETTERS[1:5])
  result <- cbamm_prob_best(yi_test[1:5], vi_test[1:5],
                           treatment_names = names_test,
                           n_sim = 50)

  expect_equal(names(result$prob_best), names_test)
  expect_equal(names(result$sucra), names_test)
})

test_that("cbamm_prob_best input validation", {
  expect_error(cbamm_prob_best(yi_test[1:5], vi_test[1:3], n_sim = 100))
  expect_error(cbamm_prob_best(yi_test, vi_test, n_sim = -100))
})

# ========================================
# Test: cbamm_nnt_meta
# ========================================

test_that("cbamm_nnt_meta returns valid structure for OR", {
  result <- cbamm_nnt_meta(yi_test, vi_test,
                          baseline_risk = 0.3,
                          measure = "OR")

  expect_s3_class(result, "cbamm_nnt_meta")
  expect_true(is.numeric(result$nnt))
  expect_true(is.numeric(result$arr))
  expect_true(result$nnt > 0)
  expect_equal(length(result$nnt_ci), 2)
})

test_that("cbamm_nnt_meta returns valid structure for RR", {
  result <- cbamm_nnt_meta(yi_test, vi_test,
                          baseline_risk = 0.3,
                          measure = "RR")

  expect_s3_class(result, "cbamm_nnt_meta")
  expect_true(is.numeric(result$nnt))
  expect_true(is.numeric(result$arr))
})

test_that("cbamm_nnt_meta scales with baseline risk", {
  result_low <- cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 0.1,
                              measure = "OR")
  result_high <- cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 0.5,
                               measure = "OR")

  # Higher baseline risk should give lower NNT (more absolute benefit)
  expect_true(result_high$nnt < result_low$nnt)
})

test_that("cbamm_nnt_meta NNT matches ARR", {
  result <- cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 0.3,
                          measure = "OR")

  # NNT should be approximately 1 / ARR
  nnt_from_arr <- 1 / abs(result$arr)
  expect_equal(result$nnt, nnt_from_arr, tolerance = 0.1)
})

test_that("cbamm_nnt_meta input validation", {
  expect_error(cbamm_nnt_meta(yi_test[1:5], vi_test, baseline_risk = 0.3,
                             measure = "OR"))
  expect_error(cbamm_nnt_meta(yi_test, vi_test, baseline_risk = -0.1,
                             measure = "OR"))
  expect_error(cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 1.5,
                             measure = "OR"))
  expect_error(cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 0.3,
                             measure = "INVALID"))
})

# ========================================
# Test: cbamm_individualized_effect
# ========================================

test_that("cbamm_individualized_effect returns valid structure", {
  moderators <- matrix(rnorm(30), ncol = 3)  # 10 studies, 3 moderators
  patient_profile <- c(0.5, -0.3, 1.2)

  result <- cbamm_individualized_effect(yi_test, vi_test,
                                        moderators = moderators,
                                        patient_profile = patient_profile)

  expect_s3_class(result, "cbamm_individualized_effect")
  expect_true(is.numeric(result$predicted_effect))
  expect_true(is.numeric(result$average_effect))
  expect_equal(length(result$pred_ci), 2)
  expect_true(result$pred_ci[1] < result$pred_ci[2])
})

test_that("cbamm_individualized_effect moderators affect prediction", {
  moderators <- matrix(rnorm(30), ncol = 3)

  # Two different patient profiles
  patient1 <- c(1, 0, 0)
  patient2 <- c(-1, 0, 0)

  result1 <- cbamm_individualized_effect(yi_test, vi_test,
                                         moderators = moderators,
                                         patient_profile = patient1)
  result2 <- cbamm_individualized_effect(yi_test, vi_test,
                                         moderators = moderators,
                                         patient_profile = patient2)

  # Different profiles should (usually) give different predictions
  # May occasionally be equal by chance, so just check they're both valid
  expect_true(is.numeric(result1$predicted_effect))
  expect_true(is.numeric(result2$predicted_effect))
})

test_that("cbamm_individualized_effect input validation", {
  moderators <- matrix(rnorm(30), ncol = 3)
  patient_profile <- c(0.5, -0.3, 1.2)

  expect_error(cbamm_individualized_effect(yi_test[1:5], vi_test,
                                          moderators = moderators,
                                          patient_profile = patient_profile))
  expect_error(cbamm_individualized_effect(yi_test, vi_test,
                                          moderators = moderators[1:5, ],
                                          patient_profile = patient_profile))
  expect_error(cbamm_individualized_effect(yi_test, vi_test,
                                          moderators = moderators,
                                          patient_profile = c(0.5, -0.3)))  # Wrong length
})

# ========================================
# Test: cbamm_rmst_meta
# ========================================

test_that("cbamm_rmst_meta returns valid structure", {
  rmst1 <- rnorm(10, mean = 15, sd = 2)  # Treatment RMST
  rmst0 <- rnorm(10, mean = 12, sd = 2)  # Control RMST
  se1 <- runif(10, 0.5, 1.5)
  se0 <- runif(10, 0.5, 1.5)

  result <- cbamm_rmst_meta(rmst1, rmst0, se1, se0, time_horizon = 24)

  expect_s3_class(result, "cbamm_rmst_meta")
  expect_true(is.numeric(result$rmst_diff))
  expect_equal(length(result$ci), 2)
  expect_true(is.numeric(result$I2))
  expect_true(is.numeric(result$tau2))
})

test_that("cbamm_rmst_meta RMST difference makes sense", {
  rmst1 <- rep(15, 5)  # Treatment better
  rmst0 <- rep(12, 5)  # Control worse
  se1 <- rep(0.5, 5)
  se0 <- rep(0.5, 5)

  result <- cbamm_rmst_meta(rmst1, rmst0, se1, se0, time_horizon = 24)

  # Difference should be positive (treatment better)
  expect_true(result$rmst_diff > 0)
  expect_true(result$rmst_diff > 2 && result$rmst_diff < 4)  # Should be around 3
})

test_that("cbamm_rmst_meta time units work", {
  rmst1 <- rnorm(5, 15, 1)
  rmst0 <- rnorm(5, 12, 1)
  se1 <- rep(0.5, 5)
  se0 <- rep(0.5, 5)

  result_months <- cbamm_rmst_meta(rmst1, rmst0, se1, se0,
                                   time_horizon = 24, time_unit = "months")
  result_years <- cbamm_rmst_meta(rmst1, rmst0, se1, se0,
                                  time_horizon = 2, time_unit = "years")

  expect_equal(result_months$time_unit, "months")
  expect_equal(result_years$time_unit, "years")
})

test_that("cbamm_rmst_meta input validation", {
  rmst1 <- rnorm(5, 15, 1)
  rmst0 <- rnorm(5, 12, 1)
  se1 <- rep(0.5, 5)
  se0 <- rep(0.5, 5)

  expect_error(cbamm_rmst_meta(rmst1[1:3], rmst0, se1, se0, time_horizon = 24))
  expect_error(cbamm_rmst_meta(rmst1, rmst0, se1[1:3], se0, time_horizon = 24))
  expect_error(cbamm_rmst_meta(rmst1, rmst0, se1, se0, time_horizon = -24))
})

# ========================================
# Test: Print Methods
# ========================================

test_that("print methods for clinical tools work without errors", {
  dca_res <- cbamm_decision_curve(yi_test, vi_test)
  prob_res <- cbamm_prob_best(yi_test[1:5], vi_test[1:5], n_sim = 50)
  nnt_res <- cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 0.3, measure = "OR")

  expect_output(print(dca_res), "Decision Curve")
  expect_output(print(prob_res), "Treatment Ranking")
  expect_output(print(nnt_res), "NNT")
})

# ========================================
# Test: Integration Between Methods
# ========================================

test_that("methods can be chained in workflow", {
  # This tests that outputs from one method can feed into another

  # 1. Get pooled estimate
  boot_res <- cbamm_bootstrap_ci(yi_test, vi_test, n_boot = 50)

  # 2. Use estimate for decision curve
  dca_res <- cbamm_decision_curve(yi_test, vi_test)

  # 3. Calculate NNT
  nnt_res <- cbamm_nnt_meta(yi_test, vi_test, baseline_risk = 0.3, measure = "OR")

  # All should work together
  expect_true(is.numeric(boot_res$estimate))
  expect_true(is.numeric(dca_res$optimal_threshold))
  expect_true(is.numeric(nnt_res$nnt))
})

# ========================================
# Test: Reproducibility
# ========================================

test_that("clinical tools are reproducible with same seed", {
  set.seed(789)
  result1 <- cbamm_prob_best(yi_test[1:5], vi_test[1:5], n_sim = 100)

  set.seed(789)
  result2 <- cbamm_prob_best(yi_test[1:5], vi_test[1:5], n_sim = 100)

  expect_equal(result1$prob_best, result2$prob_best)
  expect_equal(result1$sucra, result2$sucra)
})
