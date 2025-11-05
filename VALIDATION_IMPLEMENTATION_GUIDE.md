# CBAMMR Input Validation Implementation Guide

**Audit Date:** November 5, 2025  
**Total Functions Reviewed:** 32 exported functions  
**Functions Lacking Validation:** 26 functions  
**Critical Priority:** 14 effect size functions + 11 data frame functions  

---

## Executive Summary

This audit identified **26 exported functions** that lack proper input validation. These functions are critical to the CBAMMR package and handle sensitive operations like:
- Effect size calculations (yi, vi, sei)
- Meta-analysis computations
- Data frame processing
- Configuration validation

The good news: **Validation helpers already exist** in `/home/user/CBAMMR/R/validation-helpers.R` and should be systematically integrated.

---

## Available Validation Functions

A complete validation library already exists:

```r
# From validation-helpers.R
validate_meta_inputs(yi, vi = NULL, sei = NULL, allow_na = FALSE)
validate_meta_data(data, required_cols, numeric_cols, positive_cols)
validate_effect_measure(measure)
validate_sample_size(n_studies, analysis_type, warning_only)
validate_config(config, required_fields)
check_package_available(package, function_name)
safe_predict(fit, transf, context)
safe_try(expr, context, return_on_error, warn)
```

---

## Functions Grouped by Validation Category

### CATEGORY 1: Effect Size Vector Functions (14 functions)

These functions directly handle yi, vi, or sei vectors.  
**Primary Validation:** `validate_meta_inputs(yi, vi)` or `validate_meta_inputs(yi, sei)`

| File | Function | Line | Action |
|------|----------|------|--------|
| small-study-effects.R | cbamm_egger_test | 210 | Add validate_meta_inputs(yi, vi, method="REML") |
| small-study-effects.R | cbamm_begg_test | 259 | Add validate_meta_inputs(yi, vi) |
| small-study-effects.R | cbamm_pcurve | 460 | Add validate_meta_inputs(yi, vi) + check k >= 3 |
| core-functions.R | pet_peese | 182 | Add validate_meta_inputs(yi, sei) |
| clinical-decision-tools.R | cbamm_prob_best | 319 | Add validate_meta_inputs(yi, vi) |
| heterogeneity-methods.R | cbamm_heterogeneity_bf | 324 | Add validate_meta_inputs(yi, vi, allow_na=FALSE) |
| heterogeneity-methods.R | cbamm_heterogeneity_decomp | 518 | Add validate_meta_inputs(yi, vi) |
| model-selection.R | cbamm_lrt | 361 | Add validate_meta_inputs(yi, vi) |
| model-selection.R | cbamm_compare_fe_re | 453 | Add validate_meta_inputs(yi, vi) |
| sensitivity-analysis.R | cbamm_publication_bias_sensitivity | 343 | Add validate_meta_inputs(yi, vi) |

**Implementation Pattern:**
```r
function_name <- function(yi, vi, ...) {
  # ADD THIS:
  validate_meta_inputs(yi, vi)
  
  # rest of function
}
```

---

### CATEGORY 2: Data Frame Functions (11 functions)

These functions process data frames with study-level data.  
**Primary Validation:** `validate_meta_data(data, required_cols = ...)`

#### Subtype 2A: Effect Size Calculation Functions (9 functions in effect-sizes.R)
Lines 169, 176, 183, 190, 197, 206, 215, 221, 227
- Functions: cbamm_calc_or, cbamm_calc_rr, cbamm_calc_rd, cbamm_calc_peto, 
             cbamm_calc_md, cbamm_calc_smd, cbamm_calc_prop, cbamm_calc_ir, cbamm_calc_zcor

These are wrappers around metafor::escalc(). Validation should check:
1. Data frame structure (if provided)
2. Required columns present
3. Numeric columns are actually numeric
4. No NaN/Inf values in data

**Implementation Pattern:**
```r
cbamm_calc_or <- function(ai, bi, ci, di, data = NULL, ...) {
  # ADD THIS VALIDATION:
  if (!is.null(data)) {
    validate_meta_data(data, 
                      required_cols = c("ai", "bi", "ci", "di"),
                      numeric_cols = c("ai", "bi", "ci", "di"),
                      positive_cols = c("ai", "bi", "ci", "di"))
  }
  
  # Delegate to cbamm_escalc
  cbamm_escalc(measure = "OR", ai = ai, bi = bi, ci = ci, di = di, 
               data = data, ...)
}
```

#### Subtype 2B: Other Data Frame Functions (2 functions)

| File | Function | Line | Critical Inputs | Action |
|------|----------|------|-----------------|--------|
| core-functions.R | compute_transport_weights | 19 | data, target_population | Validate data frame has required columns |
| clinical-decision.R | cbamm_fragility_index | 24 | data, results | Check data is data frame |
| tables.R | cbamm_make_summary_table | 13 | data, config | Validate both data frame and config |

---

### CATEGORY 3: Other Validation Requirements (5 functions)

#### Mixed Validation Functions

| File | Function | Line | Inputs | Validation Needed |
|------|----------|------|--------|-------------------|
| clinical-decision-tools.R | cbamm_rmst_meta | 237 | rmst1, rmst0, se1, se0, time_horizon | Vector length consistency, positive values |
| setup.R | initialize_cbamm | 202 | config | Use validate_config(config) |
| simulation.R | simulate_cbamm_binary | 75 | n, measure, seed | Validate n > 0, valid measure |
| simulation.R | simulate_cbamm_continuous | 107 | n, measure, seed | Validate n > 0, valid measure |

**Implementation Pattern for rmst_meta:**
```r
cbamm_rmst_meta <- function(rmst1, rmst0, se1, se0, time_horizon) {
  # Validate inputs
  if (!is.numeric(rmst1) || !is.numeric(rmst0) || 
      !is.numeric(se1) || !is.numeric(se0)) {
    stop("All RMST and SE arguments must be numeric")
  }
  
  if (length(rmst1) != length(rmst0) || 
      length(rmst1) != length(se1) || 
      length(rmst1) != length(se0)) {
    stop("rmst1, rmst0, se1, se0 must have equal length")
  }
  
  if (any(se1 <= 0) || any(se0 <= 0)) {
    stop("Standard errors (se1, se0) must be positive")
  }
  
  if (!is.numeric(time_horizon) || time_horizon <= 0) {
    stop("time_horizon must be a positive number")
  }
  
  # rest of function...
}
```

---

## Implementation Priority

### PRIORITY 1 (Critical - 10 functions)
These are core statistical functions with high risk:
1. `cbamm_egger_test` - Publication bias test
2. `cbamm_begg_test` - Rank correlation test  
3. `cbamm_pcurve` - p-curve analysis (must have n >= 3 significant)
4. `cbamm_compare_fe_re` - Model comparison
5. `cbamm_lrt` - Likelihood ratio test
6. `cbamm_heterogeneity_bf` - Bayes factor heterogeneity
7. `cbamm_calc_or`, `cbamm_calc_rr`, `cbamm_calc_rd`, `cbamm_calc_peto` - Core effect size calculations

**Time to implement:** 2-3 hours
**High impact** - these affect publication-ready results

### PRIORITY 2 (Important - 10 functions)
Secondary analysis functions:
- Remaining effect size calculation functions
- Data frame processing functions
- Sensitivity analysis functions

**Time to implement:** 3-4 hours
**Medium impact** - affect supplementary analyses

### PRIORITY 3 (Beneficial - 6 functions)
Utility and setup functions:
- Simulation functions
- Configuration initialization
- Summary table generation

**Time to implement:** 1-2 hours
**Lower impact** - utility functions

---

## Implementation Checklist

### Step 1: Add Validation to Top 10 Functions
- [ ] `cbamm_egger_test` - Add `validate_meta_inputs(yi, vi)`
- [ ] `cbamm_begg_test` - Add `validate_meta_inputs(yi, vi)`
- [ ] `cbamm_pcurve` - Add `validate_meta_inputs(yi, vi)` + `stopifnot(sum(p_sig >= 3))`
- [ ] `cbamm_compare_fe_re` - Add `validate_meta_inputs(yi, vi)`
- [ ] `cbamm_lrt` - Add `validate_meta_inputs(yi, vi)`
- [ ] `cbamm_heterogeneity_bf` - Add `validate_meta_inputs(yi, vi)`
- [ ] `cbamm_calc_or/rr/rd/peto` - Add data validation

### Step 2: Add Validation to Secondary Functions
- [ ] All remaining effect size functions (calc_md, calc_smd, etc.)
- [ ] Data frame processing functions
- [ ] Sensitivity analysis functions

### Step 3: Test Validation Errors
- [ ] Test with missing arguments
- [ ] Test with wrong data types
- [ ] Test with incompatible vector lengths
- [ ] Test with non-finite values
- [ ] Test with negative values where positive required

### Step 4: Documentation
- [ ] Add validation requirements to roxygen comments
- [ ] Update function examples with error cases
- [ ] Create vignette on input requirements

---

## Code Templates

### Template 1: Simple Effect Size Validation
```r
function_name <- function(yi, vi, ...) {
  # Validate core inputs
  validate_meta_inputs(yi, vi)
  
  # Continue with function logic...
}
```

### Template 2: Effect Size Validation with SEI
```r
function_name <- function(yi, sei = NULL, vi = NULL, ...) {
  # Validate - accept either sei or vi
  if (is.null(sei) && is.null(vi)) {
    stop("Must provide either 'sei' or 'vi'")
  }
  
  if (is.null(vi)) {
    vi <- sei^2
  }
  
  validate_meta_inputs(yi, vi)
  
  # Continue with function logic...
}
```

### Template 3: Data Frame Validation
```r
function_name <- function(ai, bi, ci, di, data = NULL, ...) {
  # Validate data frame if provided
  if (!is.null(data)) {
    validate_meta_data(data,
                      required_cols = c("ai", "bi", "ci", "di"),
                      numeric_cols = c("ai", "bi", "ci", "di"))
  } else {
    # If data not provided, validate individual vectors
    stopifnot(
      is.numeric(ai), is.numeric(bi), is.numeric(ci), is.numeric(di),
      length(ai) == length(bi), length(ai) == length(ci), 
      length(ai) == length(di),
      all(ai >= 0, na.rm = TRUE), all(bi >= 0, na.rm = TRUE),
      all(ci >= 0, na.rm = TRUE), all(di >= 0, na.rm = TRUE)
    )
  }
  
  # Continue with function logic...
}
```

### Template 4: Multi-Vector Validation
```r
function_name <- function(rmst1, rmst0, se1, se0, time_horizon) {
  # Check types
  if (!is.numeric(rmst1) || !is.numeric(rmst0) || 
      !is.numeric(se1) || !is.numeric(se0)) {
    stop("RMST and SE arguments must be numeric")
  }
  
  # Check lengths match
  if (length(rmst1) != length(rmst0) || 
      length(rmst1) != length(se1) || 
      length(rmst1) != length(se0)) {
    stop("rmst1, rmst0, se1, se0 must have equal length")
  }
  
  # Check finite values
  if (!all(is.finite(c(rmst1, rmst0, se1, se0)))) {
    stop("RMST and SE values must be finite (no NA, NaN, Inf)")
  }
  
  # Check SE positive
  if (any(se1 <= 0) || any(se0 <= 0)) {
    stop("Standard errors must be positive values")
  }
  
  # Check time horizon
  if (!is.numeric(time_horizon) || length(time_horizon) != 1 || 
      !is.finite(time_horizon) || time_horizon <= 0) {
    stop("time_horizon must be a single positive number")
  }
  
  # Continue with function logic...
}
```

---

## Testing Validation

Create unit tests for each function:

```r
# Example test for cbamm_egger_test
test_that("cbamm_egger_test validates inputs", {
  yi <- c(0.1, 0.2, 0.3)
  vi <- c(0.01, 0.02, 0.03)
  
  # Valid case
  expect_error(cbamm_egger_test(yi, vi), NA)  # Should NOT error
  
  # Invalid cases
  expect_error(cbamm_egger_test(yi, vi[1:2]))  # Length mismatch
  expect_error(cbamm_egger_test(c("a", "b", "c"), vi))  # Non-numeric yi
  expect_error(cbamm_egger_test(yi, c(0.01, -0.01, 0.02)))  # Negative vi
  expect_error(cbamm_egger_test(c(0.1, NA, 0.3), vi))  # NA in yi
})
```

---

## Expected Outcomes

After implementing validation across these 26 functions:

✓ **Reduced user confusion** - Clear error messages when inputs are invalid  
✓ **Fewer downstream errors** - Prevent bad data from propagating  
✓ **Better reproducibility** - Consistent validation across all functions  
✓ **Improved documentation** - Clear requirements for each parameter  
✓ **Easier debugging** - Validation errors caught at function entry  

---

## Notes

1. **Validation helpers already exist** - No need to write custom validation code
2. **Consistent patterns** - Use the same validation helpers across all functions
3. **Error messages** - Validation-helpers.R provides clear, informative error messages
4. **Performance** - Validation overhead is negligible for meta-analysis workflows
5. **Backward compatibility** - Adding validation is backward compatible (only prevents bad inputs)

---

## Quick Reference: Files Needing Updates

```
clinical-decision-tools.R     - 2 functions
clinical-decision.R           - 1 function  
core-functions.R              - 2 functions
effect-sizes.R                - 9 functions
heterogeneity-methods.R       - 2 functions
model-selection.R             - 2 functions
sensitivity-analysis.R        - 1 function
setup.R                       - 1 function
simulation.R                  - 2 functions
small-study-effects.R         - 3 functions
tables.R                      - 1 function

TOTAL: 11 files, 26 functions
```

