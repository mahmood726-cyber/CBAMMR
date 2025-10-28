# Test script for advanced methods
# Tests basic functionality of new functions without full package installation

cat("Testing CBAMMR Advanced Methods\n")
cat("================================\n\n")

# Source the new files
source("R/advanced-methods.R")
source("R/clinical-decision-tools.R")

cat("✓ Files sourced successfully\n\n")

# Create test data
set.seed(123)
n_studies <- 10
yi <- rnorm(n_studies, mean = 0.5, sd = 0.3)
vi <- runif(n_studies, 0.01, 0.1)

cat("Test Data Created:\n")
cat(sprintf("  - %d studies\n", n_studies))
cat(sprintf("  - Mean effect: %.3f\n", mean(yi)))
cat(sprintf("  - Mean variance: %.3f\n\n", mean(vi)))

# Test 1: Permutation Test
cat("Test 1: cbamm_permutation_test()\n")
cat("---------------------------------\n")
tryCatch({
  result <- cbamm_permutation_test(yi, vi, n_perm = 1000)
  cat("✓ Function executed successfully\n")
  cat(sprintf("  Observed statistic: %.3f\n", result$observed_stat))
  cat(sprintf("  P-value: %.3f\n", result$pvalue))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 2: Bootstrap CI
cat("Test 2: cbamm_bootstrap_ci()\n")
cat("-----------------------------\n")
tryCatch({
  result <- cbamm_bootstrap_ci(yi, vi, n_boot = 1000, method = "percentile")
  cat("✓ Function executed successfully\n")
  cat(sprintf("  Estimate: %.3f\n", result$estimate))
  cat(sprintf("  95%% CI: [%.3f, %.3f]\n", result$ci[1], result$ci[2]))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 3: Quantile MA
cat("Test 3: cbamm_quantile_ma()\n")
cat("----------------------------\n")
tryCatch({
  result <- cbamm_quantile_ma(yi, vi, tau = c(0.25, 0.5, 0.75))
  cat("✓ Function executed successfully\n")
  cat(sprintf("  Number of quantiles: %d\n", nrow(result$quantile_estimates)))
  cat(sprintf("  Median effect (50th): %.3f\n",
              result$quantile_estimates$estimate[result$quantile_estimates$quantile == 0.5]))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 4: Threshold Analysis
cat("Test 4: cbamm_threshold_analysis()\n")
cat("-----------------------------------\n")
tryCatch({
  result <- cbamm_threshold_analysis(yi, vi, decision_threshold = 0.3)
  cat("✓ Function executed successfully\n")
  cat(sprintf("  Threshold bias: %.3f\n", result$threshold_bias))
  cat(sprintf("  Current estimate: %.3f\n", result$current_estimate))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 5: EVPI
cat("Test 5: cbamm_evpi()\n")
cat("---------------------\n")
tryCatch({
  result <- cbamm_evpi(yi, vi, benefit_per_unit = 1000, population_size = 100000)
  cat("✓ Function executed successfully\n")
  cat(sprintf("  EVPI per person: $%.2f\n", result$evpi_per_person))
  cat(sprintf("  Total EVPI: $%.0f\n", result$evpi_total))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 6: Decision Curve
cat("Test 6: cbamm_decision_curve()\n")
cat("-------------------------------\n")
tryCatch({
  result <- cbamm_decision_curve(yi, vi, threshold_range = seq(0.1, 0.9, by = 0.2))
  cat("✓ Function executed successfully\n")
  cat(sprintf("  Optimal threshold: %.2f\n", result$optimal_threshold))
  cat(sprintf("  Max net benefit: %.3f\n", result$max_net_benefit))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 7: Probability Best
cat("Test 7: cbamm_prob_best()\n")
cat("--------------------------\n")
tryCatch({
  result <- cbamm_prob_best(yi[1:5], vi[1:5], n_sim = 1000)
  cat("✓ Function executed successfully\n")
  cat(sprintf("  Number of treatments: %d\n", length(result$prob_best)))
  cat(sprintf("  Best treatment: %d (prob = %.3f)\n",
              which.max(result$prob_best), max(result$prob_best)))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test 8: NNT Meta
cat("Test 8: cbamm_nnt_meta()\n")
cat("-------------------------\n")
tryCatch({
  result <- cbamm_nnt_meta(yi, vi, baseline_risk = 0.3, measure = "OR")
  cat("✓ Function executed successfully\n")
  cat(sprintf("  NNT: %.1f\n", result$nnt))
  cat(sprintf("  ARR: %.3f\n", result$arr))
  cat(sprintf("  Result class: %s\n\n", class(result)[1]))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

# Test print methods
cat("Test 9: Print Methods\n")
cat("----------------------\n")
tryCatch({
  result <- cbamm_permutation_test(yi, vi, n_perm = 100)
  cat("Print method for permutation test:\n")
  print(result)
  cat("\n✓ Print method works\n\n")
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n\n", e$message))
})

cat("================================\n")
cat("Testing Complete!\n")
cat("================================\n")
