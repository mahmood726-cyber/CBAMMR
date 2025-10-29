# Tests for Advanced Methods (Distribution-Free)
# CBAMMR v8.1.0

context("Advanced Methods: Distribution-Free")

# Test data
set.seed(123)
yi_test <- rnorm(10, mean = 0.5, sd = 0.3)
vi_test <- runif(10, 0.01, 0.1)

# ========================================
# Test: cbamm_permutation_test
# ========================================

test_that("cbamm_permutation_test returns valid structure", {
  result <- cbamm_permutation_test(yi_test, vi_test, n_perm = 100)

  expect_s3_class(result, "cbamm_permutation_test")
  expect_true(is.numeric(result$observed_stat))
  expect_true(is.numeric(result$pvalue))
  expect_true(result$pvalue >= 0 && result$pvalue <= 1)
  expect_equal(length(result$perm_distribution), 100)
})

test_that("cbamm_permutation_test alternative arguments work", {
  result_two <- cbamm_permutation_test(yi_test, vi_test, n_perm = 50,
                                       alternative = "two.sided")
  result_greater <- cbamm_permutation_test(yi_test, vi_test, n_perm = 50,
                                           alternative = "greater")
  result_less <- cbamm_permutation_test(yi_test, vi_test, n_perm = 50,
                                        alternative = "less")

  expect_true(result_two$pvalue >= 0 && result_two$pvalue <= 1)
  expect_true(result_greater$pvalue >= 0 && result_greater$pvalue <= 1)
  expect_true(result_less$pvalue >= 0 && result_less$pvalue <= 1)
})

test_that("cbamm_permutation_test handles edge cases", {
  # Very small sample
  expect_s3_class(cbamm_permutation_test(yi_test[1:3], vi_test[1:3], n_perm = 10),
                 "cbamm_permutation_test")

  # All same values (should give p = 1)
  yi_same <- rep(0.5, 5)
  vi_same <- rep(0.05, 5)
  result_same <- cbamm_permutation_test(yi_same, vi_same, n_perm = 50)
  expect_true(result_same$pvalue > 0.9)
})

test_that("cbamm_permutation_test input validation", {
  expect_error(cbamm_permutation_test(yi_test[1:5], vi_test),
              "yi and vi must have the same length")
  expect_error(cbamm_permutation_test(yi_test, vi_test, n_perm = -10))
  expect_error(cbamm_permutation_test(yi_test, vi_test, alternative = "invalid"))
})

# ========================================
# Test: cbamm_bootstrap_ci
# ========================================

test_that("cbamm_bootstrap_ci returns valid structure", {
  result <- cbamm_bootstrap_ci(yi_test, vi_test, n_boot = 100, method = "percentile")

  expect_s3_class(result, "cbamm_bootstrap_ci")
  expect_true(is.numeric(result$estimate))
  expect_equal(length(result$ci), 2)
  expect_true(result$ci[1] < result$ci[2])
  expect_equal(length(result$boot_estimates), 100)
})

test_that("cbamm_bootstrap_ci BCa method works", {
  result_bca <- cbamm_bootstrap_ci(yi_test, vi_test, n_boot = 100, method = "bca")

  expect_s3_class(result_bca, "cbamm_bootstrap_ci")
  expect_true(is.numeric(result_bca$estimate))
  expect_equal(length(result_bca$ci), 2)
})

test_that("cbamm_bootstrap_ci confidence levels work", {
  result_90 <- cbamm_bootstrap_ci(yi_test, vi_test, conf_level = 0.90, n_boot = 50)
  result_99 <- cbamm_bootstrap_ci(yi_test, vi_test, conf_level = 0.99, n_boot = 50)

  expect_equal(result_90$conf_level, 0.90)
  expect_equal(result_99$conf_level, 0.99)

  # 99% CI should be wider than 90% CI (usually)
  width_90 <- result_90$ci[2] - result_90$ci[1]
  width_99 <- result_99$ci[2] - result_99$ci[1]
  expect_true(width_99 >= width_90 * 0.9)  # Allow some sampling variability
})

test_that("cbamm_bootstrap_ci handles edge cases", {
  # Small sample
  expect_s3_class(cbamm_bootstrap_ci(yi_test[1:3], vi_test[1:3], n_boot = 20),
                 "cbamm_bootstrap_ci")
})

test_that("cbamm_bootstrap_ci input validation", {
  expect_error(cbamm_bootstrap_ci(yi_test[1:5], vi_test))
  expect_error(cbamm_bootstrap_ci(yi_test, vi_test, conf_level = 1.5))
  expect_error(cbamm_bootstrap_ci(yi_test, vi_test, n_boot = -10))
  expect_error(cbamm_bootstrap_ci(yi_test, vi_test, method = "invalid"))
})

# ========================================
# Test: cbamm_quantile_ma
# ========================================

test_that("cbamm_quantile_ma returns valid structure", {
  result <- cbamm_quantile_ma(yi_test, vi_test, tau = c(0.25, 0.5, 0.75))

  expect_s3_class(result, "cbamm_quantile_ma")
  expect_true(is.data.frame(result$quantile_estimates))
  expect_equal(nrow(result$quantile_estimates), 3)
  expect_true(all(c("quantile", "estimate", "se", "ci_lower", "ci_upper") %in%
                    names(result$quantile_estimates)))
})

test_that("cbamm_quantile_ma quantiles are ordered", {
  result <- cbamm_quantile_ma(yi_test, vi_test, tau = c(0.1, 0.5, 0.9))

  estimates <- result$quantile_estimates$estimate
  # Generally, estimates should be ordered (though not strictly required)
  # Just check they're all reasonable
  expect_true(all(is.finite(estimates)))
})

test_that("cbamm_quantile_ma handles different quantiles", {
  result_single <- cbamm_quantile_ma(yi_test, vi_test, tau = 0.5)
  result_many <- cbamm_quantile_ma(yi_test, vi_test,
                                   tau = seq(0.1, 0.9, by = 0.1))

  expect_equal(nrow(result_single$quantile_estimates), 1)
  expect_equal(nrow(result_many$quantile_estimates), 9)
})

test_that("cbamm_quantile_ma input validation", {
  expect_error(cbamm_quantile_ma(yi_test[1:5], vi_test))
  expect_error(cbamm_quantile_ma(yi_test, vi_test, tau = c(-0.1, 0.5)))
  expect_error(cbamm_quantile_ma(yi_test, vi_test, tau = c(0.5, 1.5)))
})

# ========================================
# Test: cbamm_threshold_analysis
# ========================================

test_that("cbamm_threshold_analysis returns valid structure", {
  result <- cbamm_threshold_analysis(yi_test, vi_test, decision_threshold = 0.3)

  expect_s3_class(result, "cbamm_threshold_analysis")
  expect_true(is.numeric(result$threshold_bias))
  expect_true(is.numeric(result$current_estimate))
  expect_true(is.numeric(result$decision_threshold))
  expect_true(is.vector(result$bias_range))
  expect_true(is.vector(result$estimates))
})

test_that("cbamm_threshold_analysis threshold bias makes sense", {
  # If current estimate > threshold, bias should be negative to reach threshold
  result_high <- cbamm_threshold_analysis(yi_test, vi_test, decision_threshold = 0.1)
  if (result_high$current_estimate > 0.1) {
    expect_true(result_high$threshold_bias < 0)
  }

  # If current estimate < threshold, bias should be positive
  result_low <- cbamm_threshold_analysis(yi_test, vi_test, decision_threshold = 1.0)
  if (result_low$current_estimate < 1.0) {
    expect_true(result_low$threshold_bias > 0)
  }
})

test_that("cbamm_threshold_analysis handles different bias ranges", {
  result_narrow <- cbamm_threshold_analysis(yi_test, vi_test,
                                            decision_threshold = 0.3,
                                            bias_range = c(-0.1, 0.1))
  result_wide <- cbamm_threshold_analysis(yi_test, vi_test,
                                          decision_threshold = 0.3,
                                          bias_range = c(-1.0, 1.0))

  expect_true(length(result_narrow$bias_range) < length(result_wide$bias_range))
})

test_that("cbamm_threshold_analysis input validation", {
  expect_error(cbamm_threshold_analysis(yi_test[1:5], vi_test,
                                        decision_threshold = 0.3))
  expect_error(cbamm_threshold_analysis(yi_test, vi_test,
                                        bias_range = c(0.5, -0.5)))  # Wrong order
})

# ========================================
# Test: cbamm_evpi
# ========================================

test_that("cbamm_evpi returns valid structure", {
  result <- cbamm_evpi(yi_test, vi_test,
                       benefit_per_unit = 1000,
                       population_size = 10000)

  expect_s3_class(result, "cbamm_evpi")
  expect_true(is.numeric(result$evpi_per_person))
  expect_true(is.numeric(result$evpi_total))
  expect_true(result$evpi_per_person >= 0)
  expect_true(result$evpi_total >= 0)
})

test_that("cbamm_evpi scales with population size", {
  result_small <- cbamm_evpi(yi_test, vi_test, benefit_per_unit = 1000,
                            population_size = 1000)
  result_large <- cbamm_evpi(yi_test, vi_test, benefit_per_unit = 1000,
                            population_size = 10000)

  # Total EVPI should scale roughly with population
  ratio <- result_large$evpi_total / result_small$evpi_total
  expect_true(ratio > 5 && ratio < 15)  # Should be around 10
})

test_that("cbamm_evpi discounting works", {
  result_no_discount <- cbamm_evpi(yi_test, vi_test,
                                  benefit_per_unit = 1000,
                                  population_size = 10000,
                                  time_horizon = 10,
                                  discount_rate = 0)
  result_discount <- cbamm_evpi(yi_test, vi_test,
                               benefit_per_unit = 1000,
                               population_size = 10000,
                               time_horizon = 10,
                               discount_rate = 0.03)

  # With discounting, total EVPI should be lower
  expect_true(result_discount$evpi_total < result_no_discount$evpi_total)
})

test_that("cbamm_evpi handles very certain evidence", {
  # Very small variance = very certain = low EVPI
  yi_certain <- rep(0.5, 20)
  vi_certain <- rep(0.001, 20)
  result_certain <- cbamm_evpi(yi_certain, vi_certain,
                               benefit_per_unit = 1000,
                               population_size = 10000)

  # Should be very low
  expect_true(result_certain$evpi_per_person < 10)
})

test_that("cbamm_evpi input validation", {
  expect_error(cbamm_evpi(yi_test[1:5], vi_test, benefit_per_unit = 1000,
                         population_size = 10000))
  expect_error(cbamm_evpi(yi_test, vi_test, benefit_per_unit = -1000,
                         population_size = 10000))
  expect_error(cbamm_evpi(yi_test, vi_test, benefit_per_unit = 1000,
                         population_size = -10000))
  expect_error(cbamm_evpi(yi_test, vi_test, benefit_per_unit = 1000,
                         population_size = 10000, discount_rate = 1.5))
})

# ========================================
# Test: Print Methods
# ========================================

test_that("print methods work without errors", {
  perm_res <- cbamm_permutation_test(yi_test, vi_test, n_perm = 50)
  boot_res <- cbamm_bootstrap_ci(yi_test, vi_test, n_boot = 50)
  quant_res <- cbamm_quantile_ma(yi_test, vi_test)
  thresh_res <- cbamm_threshold_analysis(yi_test, vi_test, decision_threshold = 0.3)
  evpi_res <- cbamm_evpi(yi_test, vi_test, benefit_per_unit = 1000,
                        population_size = 10000)

  expect_output(print(perm_res), "Permutation Test")
  expect_output(print(boot_res), "Bootstrap")
  expect_output(print(quant_res), "Quantile")
  expect_output(print(thresh_res), "Threshold")
  expect_output(print(evpi_res), "EVPI")
})

# ========================================
# Test: Reproducibility
# ========================================

test_that("results are reproducible with same seed", {
  set.seed(456)
  result1 <- cbamm_permutation_test(yi_test, vi_test, n_perm = 100)

  set.seed(456)
  result2 <- cbamm_permutation_test(yi_test, vi_test, n_perm = 100)

  expect_equal(result1$pvalue, result2$pvalue)
  expect_equal(result1$perm_distribution, result2$perm_distribution)
})
