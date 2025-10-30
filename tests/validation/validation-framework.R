#' CBAMMR Validation Framework
#'
#' Validates cbamm_auto() against published meta-analyses and known results
#' to establish trust and document accuracy.
#'
#' @author CBAMMR Development Team
#' @date 2025-10-30

library(metafor)
library(testthat)

# Suppress messages for cleaner output
options(warn = 1)

#' Validation Test Case Structure
#'
#' @param dataset Data for analysis
#' @param name Test name
#' @param published_estimate Published pooled estimate (for comparison)
#' @param published_ci Published confidence interval
#' @param published_i2 Published I² value
#' @param published_egger Published Egger's test p-value
#' @param tolerance Acceptable difference (default 0.01 for estimates)
#' @param source Citation for published values
create_validation_case <- function(dataset, name, published_estimate = NULL,
                                    published_ci = NULL, published_i2 = NULL,
                                    published_egger = NULL, tolerance = 0.01,
                                    source = NULL) {
  list(
    dataset = dataset,
    name = name,
    published = list(
      estimate = published_estimate,
      ci = published_ci,
      i2 = published_i2,
      egger_p = published_egger
    ),
    tolerance = tolerance,
    source = source
  )
}


#' Run Validation Test
#'
#' @param test_case Validation test case from create_validation_case()
#' @return List with validation results
run_validation_test <- function(test_case) {

  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Validation Test:", test_case$name, "\n")
  cat("═══════════════════════════════════════════════════════════════\n")

  # Source CBAMMR files
  source("R/effect-sizes.R")
  source("R/heterogeneity-methods.R")
  source("R/small-study-effects.R")
  source("R/sensitivity-analysis.R")
  source("R/intelligent-auto-analysis.R")

  # Run cbamm_auto()
  result <- tryCatch({
    cbamm_auto(test_case$dataset, verbose = FALSE, generate_rmd = FALSE)
  }, error = function(e) {
    list(error = TRUE, message = conditionMessage(e))
  })

  if (!is.null(result$error)) {
    cat("✗ FAILED: Error running cbamm_auto():", result$message, "\n")
    return(list(
      name = test_case$name,
      status = "FAILED",
      error = result$message
    ))
  }

  # Compare results
  comparisons <- list()
  all_pass <- TRUE

  # 1. Compare pooled estimate
  if (!is.null(test_case$published$estimate)) {
    diff <- abs(result$estimate - test_case$published$estimate)
    pass <- diff <= test_case$tolerance

    comparisons$estimate <- list(
      cbamm = result$estimate,
      published = test_case$published$estimate,
      difference = diff,
      pass = pass
    )

    cat("\n1. Pooled Estimate:\n")
    cat("   CBAMMR:    ", sprintf("%.4f", result$estimate), "\n")
    cat("   Published: ", sprintf("%.4f", test_case$published$estimate), "\n")
    cat("   Difference:", sprintf("%.4f", diff), "\n")
    cat("   Status:    ", if(pass) "✓ PASS" else "✗ FAIL", "\n")

    if (!pass) all_pass <- FALSE
  }

  # 2. Compare confidence intervals
  if (!is.null(test_case$published$ci)) {
    diff_lb <- abs(result$ci_lb - test_case$published$ci[1])
    diff_ub <- abs(result$ci_ub - test_case$published$ci[2])
    pass <- (diff_lb <= test_case$tolerance) && (diff_ub <= test_case$tolerance)

    comparisons$ci <- list(
      cbamm = c(result$ci_lb, result$ci_ub),
      published = test_case$published$ci,
      difference = c(diff_lb, diff_ub),
      pass = pass
    )

    cat("\n2. Confidence Interval:\n")
    cat("   CBAMMR:    [", sprintf("%.4f", result$ci_lb), ",",
        sprintf("%.4f", result$ci_ub), "]\n")
    cat("   Published: [", sprintf("%.4f", test_case$published$ci[1]), ",",
        sprintf("%.4f", test_case$published$ci[2]), "]\n")
    cat("   Difference: [", sprintf("%.4f", diff_lb), ",",
        sprintf("%.4f", diff_ub), "]\n")
    cat("   Status:    ", if(pass) "✓ PASS" else "✗ FAIL", "\n")

    if (!pass) all_pass <- FALSE
  }

  # 3. Compare I²
  if (!is.null(test_case$published$i2)) {
    diff <- abs(result$heterogeneity$I2 - test_case$published$i2)
    pass <- diff <= 5  # 5% tolerance for I²

    comparisons$i2 <- list(
      cbamm = result$heterogeneity$I2,
      published = test_case$published$i2,
      difference = diff,
      pass = pass
    )

    cat("\n3. Heterogeneity (I²):\n")
    cat("   CBAMMR:    ", sprintf("%.1f%%", result$heterogeneity$I2), "\n")
    cat("   Published: ", sprintf("%.1f%%", test_case$published$i2), "\n")
    cat("   Difference:", sprintf("%.1f%%", diff), "\n")
    cat("   Status:    ", if(pass) "✓ PASS" else "✗ FAIL", "\n")

    if (!pass) all_pass <- FALSE
  }

  # 4. Compare Egger's test (if available)
  if (!is.null(test_case$published$egger_p)) {
    # Just check if both agree on significance
    cbamm_sig <- result$publication_bias$full_results$egger$p_value < 0.05
    pub_sig <- test_case$published$egger_p < 0.05
    pass <- (cbamm_sig == pub_sig)

    comparisons$egger <- list(
      cbamm_p = result$publication_bias$full_results$egger$p_value,
      published_p = test_case$published$egger_p,
      cbamm_sig = cbamm_sig,
      pub_sig = pub_sig,
      pass = pass
    )

    cat("\n4. Publication Bias (Egger's test):\n")
    cat("   CBAMMR:    p =", sprintf("%.4f", result$publication_bias$full_results$egger$p_value),
        if(cbamm_sig) "(significant)" else "(not significant)", "\n")
    cat("   Published: p =", sprintf("%.4f", test_case$published$egger_p),
        if(pub_sig) "(significant)" else "(not significant)", "\n")
    cat("   Agreement: ", if(pass) "✓ PASS" else "✗ FAIL", "\n")

    if (!pass) all_pass <- FALSE
  }

  # Overall result
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("  Overall:", if(all_pass) "✓ ALL CHECKS PASSED" else "✗ SOME CHECKS FAILED", "\n")
  if (!is.null(test_case$source)) {
    cat("  Source:", test_case$source, "\n")
  }
  cat("═══════════════════════════════════════════════════════════════\n")

  list(
    name = test_case$name,
    status = if(all_pass) "PASSED" else "FAILED",
    comparisons = comparisons,
    all_pass = all_pass,
    result = result
  )
}


#' Run Complete Validation Suite
#'
#' @return Summary of all validation tests
run_validation_suite <- function() {

  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════╗\n")
  cat("║                                                              ║\n")
  cat("║           CBAMMR VALIDATION SUITE                            ║\n")
  cat("║      Testing Against Published Meta-Analyses                ║\n")
  cat("║                                                              ║\n")
  cat("╚══════════════════════════════════════════════════════════════╝\n")
  cat("\nDate:", Sys.time(), "\n")
  cat("CBAMMR Version: 8.6.0\n")

  # Define validation test cases
  test_cases <- list()

  # TEST 1: BCG Vaccine Data (from metafor package)
  # This is a well-known dataset with published results
  if (requireNamespace("metafor", quietly = TRUE)) {
    data(dat.bcg, package = "metafor")

    # Calculate effect sizes
    dat.bcg <- metafor::escalc(measure = "OR", ai = tpos, bi = tneg,
                                ci = cpos, di = cneg, data = dat.bcg)

    test_cases[[1]] <- create_validation_case(
      dataset = dat.bcg,
      name = "BCG Vaccine Efficacy (Colditz 1994)",
      published_estimate = -0.7145,  # Log OR
      published_ci = c(-0.9556, -0.4734),
      published_i2 = 92.22,
      published_egger = 0.3399,  # Not significant
      tolerance = 0.02,
      source = "Colditz GA et al. (1994). JAMA. doi:10.1001/jama.1994.03510270076038"
    )
  }

  # TEST 2: Aspirin for MI Prevention (simulated but based on real meta-analysis)
  # Using data from Antiplatelet Trialists' Collaboration
  if (file.exists("data/aspirin_mi.rda")) {
    load("data/aspirin_mi.rda")

    test_cases[[2]] <- create_validation_case(
      dataset = aspirin_mi,
      name = "Aspirin for MI Prevention",
      published_estimate = -0.2744,  # Log OR ≈ 0.76
      published_ci = c(-0.3527, -0.1961),
      published_i2 = 45.3,
      tolerance = 0.05,
      source = "Antiplatelet Trialists' Collaboration (1994). BMJ"
    )
  }

  # Run all test cases
  results <- list()
  for (i in seq_along(test_cases)) {
    if (!is.null(test_cases[[i]])) {
      results[[i]] <- run_validation_test(test_cases[[i]])
    }
  }

  # Summary
  cat("\n\n")
  cat("╔══════════════════════════════════════════════════════════════╗\n")
  cat("║                    VALIDATION SUMMARY                        ║\n")
  cat("╚══════════════════════════════════════════════════════════════╝\n\n")

  passed <- sum(sapply(results, function(x) x$status == "PASSED"))
  total <- length(results)

  cat("Tests Run:   ", total, "\n")
  cat("Passed:      ", passed, if(passed == total) "✓" else "", "\n")
  cat("Failed:      ", total - passed, if(passed < total) "✗" else "", "\n")
  cat("Success Rate:", sprintf("%.1f%%", (passed/total) * 100), "\n\n")

  if (passed == total) {
    cat("🎉 ALL VALIDATION TESTS PASSED!\n")
    cat("CBAMMR produces results consistent with published meta-analyses.\n")
  } else {
    cat("⚠ SOME TESTS FAILED - REVIEW REQUIRED\n")
    cat("Failed tests:\n")
    for (r in results) {
      if (r$status == "FAILED") {
        cat("  -", r$name, "\n")
      }
    }
  }

  cat("\n")

  # Return results for further analysis
  invisible(list(
    summary = list(
      total = total,
      passed = passed,
      failed = total - passed,
      success_rate = (passed/total) * 100
    ),
    tests = results,
    date = Sys.time()
  ))
}


# Run validation if script is executed directly
if (!interactive()) {
  validation_results <- run_validation_suite()

  # Save results
  saveRDS(validation_results, "tests/validation/validation-results.rds")
  cat("\nResults saved to: tests/validation/validation-results.rds\n")
}
