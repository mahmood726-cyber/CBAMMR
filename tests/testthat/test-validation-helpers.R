# Unit Tests for Validation Helpers
# Tests for R/validation-helpers.R functions

context("Input Validation Helpers")

# ===========================================
# TEST: validate_meta_inputs()
# ===========================================

test_that("validate_meta_inputs accepts valid yi and vi", {
  yi <- c(0.1, 0.2, 0.3, 0.4, 0.5)
  vi <- c(0.01, 0.02, 0.03, 0.04, 0.05)

  expect_silent(validate_meta_inputs(yi, vi))
})

test_that("validate_meta_inputs accepts valid yi and sei", {
  yi <- c(0.1, 0.2, 0.3, 0.4, 0.5)
  sei <- c(0.1, 0.14, 0.17, 0.2, 0.22)

  expect_silent(validate_meta_inputs(yi, vi = NULL, sei = sei))
})

test_that("validate_meta_inputs rejects missing yi", {
  vi <- c(0.01, 0.02, 0.03)
  expect_error(validate_meta_inputs(vi = vi), "Argument 'yi' is required")
})

test_that("validate_meta_inputs rejects non-numeric yi", {
  yi <- c("a", "b", "c")
  vi <- c(0.01, 0.02, 0.03)
  expect_error(validate_meta_inputs(yi, vi), "'yi' must be a numeric vector")
})

test_that("validate_meta_inputs rejects insufficient studies", {
  yi <- c(0.1, 0.2)
  vi <- c(0.01, 0.02)
  expect_error(validate_meta_inputs(yi, vi), "At least 3 studies required")
})

test_that("validate_meta_inputs rejects length mismatch", {
  yi <- c(0.1, 0.2, 0.3)
  vi <- c(0.01, 0.02)
  expect_error(validate_meta_inputs(yi, vi), "must have the same length")
})

test_that("validate_meta_inputs rejects non-positive vi", {
  yi <- c(0.1, 0.2, 0.3)
  vi <- c(0.01, -0.02, 0.03)
  expect_error(validate_meta_inputs(yi, vi), "must contain only positive values")
})

test_that("validate_meta_inputs rejects NA values", {
  yi <- c(0.1, NA, 0.3)
  vi <- c(0.01, 0.02, 0.03)
  expect_error(validate_meta_inputs(yi, vi), "contains NA values")
})

test_that("validate_meta_inputs allows NA with allow_na=TRUE", {
  yi <- c(0.1, NA, 0.3, 0.4)
  vi <- c(0.01, 0.02, NA, 0.04)
  expect_silent(validate_meta_inputs(yi, vi, allow_na = TRUE))
})

test_that("validate_meta_inputs rejects Inf values", {
  yi <- c(0.1, Inf, 0.3)
  vi <- c(0.01, 0.02, 0.03)
  expect_error(validate_meta_inputs(yi, vi), "non-finite values")
})

test_that("validate_meta_inputs rejects zero vi", {
  yi <- c(0.1, 0.2, 0.3)
  vi <- c(0.01, 0, 0.03)
  expect_error(validate_meta_inputs(yi, vi), "must contain only positive values")
})

# ===========================================
# TEST: validate_meta_data()
# ===========================================

test_that("validate_meta_data accepts valid data frame", {
  data <- data.frame(yi = c(0.1, 0.2, 0.3), vi = c(0.01, 0.02, 0.03))
  expect_silent(validate_meta_data(data))
})

test_that("validate_meta_data rejects non-data.frame", {
  data <- c(1, 2, 3)
  expect_error(validate_meta_data(data), "'data' must be a data frame")
})

test_that("validate_meta_data rejects empty data frame", {
  data <- data.frame()
  expect_error(validate_meta_data(data), "empty \\(0 rows\\)")
})

test_that("validate_meta_data checks required columns", {
  data <- data.frame(yi = c(0.1, 0.2, 0.3))
  expect_error(
    validate_meta_data(data, required_cols = c("yi", "vi")),
    "Required column 'vi' not found"
  )
})

test_that("validate_meta_data checks numeric columns", {
  data <- data.frame(yi = c("a", "b", "c"), vi = c(0.01, 0.02, 0.03))
  expect_error(
    validate_meta_data(data, numeric_cols = "yi"),
    "Column 'yi' must be numeric"
  )
})

test_that("validate_meta_data checks positive columns", {
  data <- data.frame(yi = c(0.1, 0.2, 0.3), vi = c(0.01, -0.02, 0.03))
  expect_error(
    validate_meta_data(data, positive_cols = "vi"),
    "Column 'vi' must contain only positive values"
  )
})

test_that("validate_meta_data handles multiple required columns", {
  data <- data.frame(yi = c(0.1, 0.2), vi = c(0.01, 0.02))
  expect_silent(
    validate_meta_data(data, required_cols = c("yi", "vi"))
  )
})

# ===========================================
# TEST: validate_config()
# ===========================================

test_that("validate_config accepts valid config list", {
  config <- list(effect_measure = "HR", use_hksj = TRUE)
  expect_silent(validate_config(config))
})

test_that("validate_config rejects non-list", {
  config <- "not a list"
  expect_error(validate_config(config), "'config' must be a list")
})

test_that("validate_config checks required fields", {
  config <- list(effect_measure = "HR")
  expect_error(
    validate_config(config, required_fields = c("effect_measure", "use_hksj")),
    "Configuration missing required fields: use_hksj"
  )
})

test_that("validate_config handles multiple missing fields", {
  config <- list(effect_measure = "HR")
  expect_error(
    validate_config(config, required_fields = c("use_hksj", "use_bayesian")),
    "missing required fields"
  )
})

# ===========================================
# TEST: check_package_available()
# ===========================================

test_that("check_package_available accepts installed packages", {
  # metafor should be available since it's in Imports
  expect_true(check_package_available("metafor"))
})

test_that("check_package_available rejects non-existent packages", {
  expect_error(
    check_package_available("nonexistent_package_xyz123"),
    "Package 'nonexistent_package_xyz123' required but not installed"
  )
})

test_that("check_package_available includes function name in error", {
  expect_error(
    check_package_available("nonexistent_pkg", "my_function"),
    "Function 'my_function' requires 'nonexistent_pkg'"
  )
})

test_that("check_package_available suggests installation", {
  expect_error(
    check_package_available("nonexistent_pkg"),
    "install.packages\\('nonexistent_pkg'\\)"
  )
})

# ===========================================
# TEST: validate_effect_measure()
# ===========================================

test_that("validate_effect_measure accepts valid measures", {
  valid_measures <- c("HR", "OR", "RR", "RD", "MD", "SMD", "COR", "PETO")
  for (measure in valid_measures) {
    expect_silent(validate_effect_measure(measure))
  }
})

test_that("validate_effect_measure is case-insensitive", {
  expect_silent(validate_effect_measure("hr"))
  expect_silent(validate_effect_measure("Hr"))
  expect_silent(validate_effect_measure("HR"))
})

test_that("validate_effect_measure rejects invalid measures", {
  expect_error(
    validate_effect_measure("INVALID"),
    "Effect measure 'INVALID' not recognized"
  )
})

test_that("validate_effect_measure rejects non-character", {
  expect_error(
    validate_effect_measure(123),
    "'measure' must be a single character string"
  )
})

test_that("validate_effect_measure rejects vectors", {
  expect_error(
    validate_effect_measure(c("HR", "OR")),
    "'measure' must be a single character string"
  )
})

# ===========================================
# TEST: validate_sample_size()
# ===========================================

test_that("validate_sample_size accepts sufficient studies", {
  expect_silent(validate_sample_size(10, "meta-analysis"))
  expect_silent(validate_sample_size(20, "subgroup"))
  expect_silent(validate_sample_size(15, "regression"))
})

test_that("validate_sample_size rejects insufficient studies", {
  expect_error(
    validate_sample_size(2, "meta-analysis"),
    "Insufficient studies"
  )
})

test_that("validate_sample_size issues warnings for small samples", {
  expect_warning(
    validate_sample_size(5, "meta-analysis"),
    "Small sample size"
  )
})

test_that("validate_sample_size warning_only mode", {
  expect_warning(
    validate_sample_size(2, "meta-analysis", warning_only = TRUE),
    "Insufficient studies"
  )
})

test_that("validate_sample_size handles different analysis types", {
  expect_silent(validate_sample_size(5, "meta-analysis"))
  expect_error(validate_sample_size(5, "subgroup"), "Insufficient")
  expect_error(validate_sample_size(5, "regression"), "Insufficient")
  expect_error(validate_sample_size(5, "publication-bias"), "Insufficient")
})

# ===========================================
# TEST: safe_predict()
# ===========================================

test_that("safe_predict handles valid metafor models", {
  yi <- c(0.1, 0.2, 0.3, 0.4)
  vi <- c(0.01, 0.02, 0.03, 0.04)
  fit <- metafor::rma(yi, vi)

  result <- safe_predict(fit)
  expect_s3_class(result, "list.rma")
  expect_true(!is.null(result$pred))
})

test_that("safe_predict returns NULL for NULL input", {
  expect_warning(
    result <- safe_predict(NULL),
    "Cannot predict from NULL model"
  )
  expect_null(result)
})

test_that("safe_predict handles transformations", {
  yi <- c(0.1, 0.2, 0.3, 0.4)
  vi <- c(0.01, 0.02, 0.03, 0.04)
  fit <- metafor::rma(yi, vi)

  result <- safe_predict(fit, transf = exp)
  expect_s3_class(result, "list.rma")
})

test_that("safe_predict handles errors gracefully", {
  bad_model <- list(not_a_model = TRUE)
  class(bad_model) <- "rma.uni"

  expect_warning(
    result <- safe_predict(bad_model),
    "Prediction failed"
  )
  expect_null(result)
})

test_that("safe_predict includes context in warnings", {
  bad_model <- list()
  class(bad_model) <- "rma.uni"

  expect_warning(
    safe_predict(bad_model, context = "test analysis"),
    "test analysis"
  )
})

# ===========================================
# TEST: safe_try()
# ===========================================

test_that("safe_try returns result on success", {
  result <- safe_try(2 + 2, warn = FALSE)
  expect_equal(result, 4)
})

test_that("safe_try returns default on error", {
  result <- safe_try(stop("error"), return_on_error = 99, warn = FALSE)
  expect_equal(result, 99)
})

test_that("safe_try warns on error by default", {
  expect_warning(
    safe_try(stop("test error")),
    "Operation failed"
  )
})

test_that("safe_try can suppress warnings", {
  expect_silent(
    result <- safe_try(stop("error"), return_on_error = NULL, warn = FALSE)
  )
  expect_null(result)
})

test_that("safe_try includes context in warnings", {
  expect_warning(
    safe_try(stop("error"), context = "my operation"),
    "my operation"
  )
})

test_that("safe_try handles complex expressions", {
  data <- data.frame(x = 1:5, y = 2:6)
  result <- safe_try({
    lm(y ~ x, data = data)
  }, warn = FALSE)

  expect_s3_class(result, "lm")
})

# ===========================================
# INTEGRATION TESTS
# ===========================================

test_that("validation helpers work together", {
  # Create test data
  data <- data.frame(
    yi = c(0.1, 0.2, 0.3, 0.4),
    vi = c(0.01, 0.02, 0.03, 0.04),
    study = c("A", "B", "C", "D")
  )

  # Validate data frame
  expect_silent(
    validate_meta_data(data,
                       required_cols = c("yi", "vi"),
                       numeric_cols = c("yi", "vi"),
                       positive_cols = "vi")
  )

  # Validate vectors
  expect_silent(validate_meta_inputs(data$yi, data$vi))

  # Validate sample size
  expect_silent(validate_sample_size(nrow(data), "meta-analysis"))

  # Safe execution
  result <- safe_try({
    metafor::rma(yi, vi, data = data)
  }, context = "meta-analysis", warn = FALSE)

  expect_s3_class(result, "rma.uni")

  # Safe prediction
  pred <- safe_predict(result)
  expect_true(!is.null(pred))
})

test_that("validation catches realistic errors", {
  # Empty data
  empty_data <- data.frame()
  expect_error(validate_meta_data(empty_data), "empty")

  # Mismatched lengths
  expect_error(
    validate_meta_inputs(c(0.1, 0.2), c(0.01, 0.02, 0.03)),
    "same length"
  )

  # Non-numeric
  expect_error(
    validate_meta_inputs(c("a", "b", "c"), c(0.01, 0.02, 0.03)),
    "numeric vector"
  )

  # Negative variance
  expect_error(
    validate_meta_inputs(c(0.1, 0.2, 0.3), c(-0.01, 0.02, 0.03)),
    "positive values"
  )
})
