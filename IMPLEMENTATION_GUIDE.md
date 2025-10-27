# CBAMMR Package Implementation Guide

## Current Status

✅ **Complete:** Package structure and framework
⚠️ **Needs Work:** Full function implementations in `R/all-cbamm-functions.R`

## Package Structure Created

```
CBAMMR/
├── DESCRIPTION           # Package metadata and dependencies
├── NAMESPACE            # Exported functions and imports
├── LICENSE              # Apache 2.0 license
├── README.md            # Installation and usage guide
├── NEWS.md              # Version history
├── .Rbuildignore        # Files to ignore during build
├── .gitignore           # Git ignore patterns
├── R/                   # R source code
│   ├── cbammr-package.R      # Package documentation
│   ├── setup.R               # Configuration functions (COMPLETE)
│   ├── utils.R               # Internal utilities (COMPLETE)
│   ├── pairwise.R            # Effect size calculation (COMPLETE)
│   ├── core-functions.R      # Core meta-analysis (COMPLETE)
│   ├── simulation.R          # Data simulation (COMPLETE)
│   └── all-cbamm-functions.R # Main runner (NEEDS EXPANSION)
├── man/                 # Documentation (will be generated)
├── tests/               # Unit tests (optional)
├── vignettes/           # Long-form documentation (optional)
├── data-raw/            # Data preparation scripts (optional)
└── inst/
    └── CITATION         # Citation information
```

## Next Steps to Complete the Package

### Step 1: Add Your Complete Code

Open `R/all-cbamm-functions.R` and replace the placeholder content with all your remaining functions from the original code. This includes:

**Multivariate Meta-Analysis:**
```r
.build_V_block()
.build_V_exact_logOR()
run_mv_meta()
run_mv_meta_exact_logOR()
run_mv_rho_sensitivity()
```

**Rare Events Suite:**
```r
run_rare_event_models()
```

**Diagnostic Functions:**
```r
run_influence()
run_small_study_tests()
run_robust_location()
compute_evalue()
run_pcurve()
```

**Publication Bias:**
```r
.cbamm_build_weightr_breaks()
run_publication_bias_sensitivity()
run_robma()
run_puniform()
```

**Analysis Functions:**
```r
run_adaptive_advisor()
run_stratified_analysis()
run_pooled_and_rve()
run_multiverse_analysis()
```

**Bayesian Methods:**
```r
run_bayesian_analysis()
```

**Meta-Regression:**
```r
run_meta_regression_ns()
```

**Machine Learning:**
```r
run_ml_heterogeneity()
```

**Visualization:**
```r
.create_multiverse_plot()
.create_forest_plot()
.create_funnel_plot()
.create_pet_plot()
.create_peese_plot()
.create_leave1out_plot()
.create_cumulative_plot()
.create_conflict_plot()
.create_missing_heatmap()
.create_bayesian_plot()
.create_rho_sensitivity_plot()
.create_influence_plot()
.create_pcurve_plot()
.create_meta_regression_plot()
create_result_plots()
cbamm_show_all_plots()
```

**Tables:**
```r
cbamm_make_summary_table()
```

### Step 2: Generate Documentation

Once you've added all functions, run:

```r
# Install roxygen2 if needed
install.packages("roxygen2")

# Generate documentation from roxygen comments
devtools::document()
```

This will:
- Create all .Rd files in `man/`
- Update NAMESPACE
- Process all @export, @param, @return tags

### Step 3: Check Package

Run R CMD check to find any issues:

```r
# Install devtools if needed
install.packages("devtools")

# Check package
devtools::check()
```

Fix any ERRORs, WARNINGs, or NOTEs that appear.

### Step 4: Install and Test

```r
# Install the package locally
devtools::install()

# Load and test
library(CBAMMR)

# Run a test analysis
data <- simulate_cbamm_data(n_rct = 20, n_obs = 15)
config <- setup_cbamm(effect_measure = "HR")
results <- run_cbamm_analysis(data, config = config)
```

### Step 5: Add Unit Tests (Recommended)

Create test files in `tests/testthat/`:

```r
# tests/testthat/test-setup.R
test_that("setup_cbamm creates valid config", {
  config <- setup_cbamm()
  expect_type(config, "list")
  expect_true("effect_measure" %in% names(config))
})

# tests/testthat/test-pairwise.R
test_that("prepare_pairwise_effects works for HR", {
  data <- data.frame(
    study_id = "S1",
    yi = log(0.8),
    se = 0.1,
    study_type = "RCT"
  )
  result <- prepare_pairwise_effects(data, measure = "HR")
  expect_true("vi" %in% names(result))
})
```

### Step 6: Add Vignettes (Optional but Recommended)

Create vignettes in `vignettes/`:

```r
# vignettes/introduction.Rmd
---
title: "Introduction to CBAMMR"
author: "Your Name"
date: "`r Sys.Date()`"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Introduction to CBAMMR}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Quick Start

...examples here...
```

### Step 7: Build Package

```r
# Build source package
devtools::build()

# Build binary package
devtools::build(binary = TRUE)
```

## Installation for Users

Once complete, users can install with:

```r
# From GitHub
devtools::install_github("mahmood726-cyber/CBAMMR")

# Or from source (after building)
install.packages("path/to/CBAMMR_7.0.0.tar.gz", repos = NULL, type = "source")
```

## Adding More Documentation

### For Each Function

Use roxygen2 format above each function:

```r
#' Function Title (Short Description)
#'
#' Longer description explaining what the function does and when to use it.
#'
#' @param param1 Description of parameter 1
#' @param param2 Description of parameter 2
#'
#' @return Description of what the function returns
#' @export
#'
#' @examples
#' # Example usage
#' result <- my_function(param1 = "value", param2 = 10)
#'
#' @references
#' Author (Year). Title. Journal.
my_function <- function(param1, param2) {
  # implementation
}
```

### Export Control

- Use `@export` for functions users should access
- Use `@keywords internal` for helper functions (don't export)
- Internal functions should start with `.` by convention

## Common Issues and Solutions

### Issue: "object not found" errors

**Solution:** Make sure all dependencies are imported in `R/cbammr-package.R`:
```r
#' @importFrom package function_name
```

### Issue: NAMESPACE conflicts

**Solution:** Be specific about imports:
```r
#' @importFrom dplyr filter mutate select
```

Instead of:
```r
#' @import dplyr  # imports everything
```

### Issue: "non-exported object" errors

**Solution:** Either:
1. Add `@export` to make it public
2. Use `package:::function` for internal access
3. Add `@keywords internal` if it should stay internal

### Issue: Documentation warnings

**Solution:** Add missing @param, @return, or @examples tags

## Submission to CRAN (Future)

If you want to submit to CRAN:

1. Ensure `devtools::check()` passes with no ERRORs, WARNINGs, or NOTEs
2. Add comprehensive tests (coverage >80%)
3. Add at least one vignette
4. Check on multiple platforms (winbuilder, rhub)
5. Prepare cran-comments.md
6. Submit via https://cran.r-project.org/submit.html

## File Organization Best Practices

Current organization works, but for a very large package you might split further:

```
R/
├── aaa-package.R         # Package docs (loaded first)
├── setup-config.R        # Configuration
├── data-preparation.R    # Data prep functions
├── effect-sizes.R        # Effect size calculation
├── weighting.R           # All weighting functions
├── meta-analysis.R       # Core MA functions
├── multivariate.R        # MV methods
├── rare-events.R         # Rare events suite
├── diagnostics.R         # All diagnostics
├── publication-bias.R    # Publication bias methods
├── bayesian.R            # Bayesian methods
├── meta-regression.R     # Meta-regression
├── ml-methods.R          # ML heterogeneity
├── visualization.R       # All plots
├── tables.R              # Table generation
├── simulation.R          # Simulation functions
├── analysis-runner.R     # Main run_cbamm_analysis
└── utils.R               # Utilities (loaded last)
```

## Quick Reference: devtools Commands

```r
# Document (after changing roxygen comments)
devtools::document()

# Check package
devtools::check()

# Install locally
devtools::install()

# Load for interactive development
devtools::load_all()

# Run tests
devtools::test()

# Build package
devtools::build()

# Check on winbuilder (for Windows compatibility)
devtools::check_win_devel()

# Check on rhub (multiple platforms)
devtools::check_rhub()

# Spell check
devtools::spell_check()
```

## Resources

- [R Packages Book](https://r-pkgs.org/) by Hadley Wickham & Jennifer Bryan
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html) (Official CRAN manual)
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
- [devtools cheatsheet](https://github.com/rstudio/cheatsheets/blob/main/package-development.pdf)

## Contact

For questions or issues, open an issue on GitHub:
https://github.com/mahmood726-cyber/CBAMMR/issues
