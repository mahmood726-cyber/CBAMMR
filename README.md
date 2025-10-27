# CBAMMR: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![R](https://img.shields.io/badge/R-%3E%3D4.0.0-blue)](https://www.r-project.org/)

## Overview

CBAMMR (Comprehensive Bayesian and Advanced Meta-Analysis Methods in R) v7.0 is a comprehensive framework for conducting state-of-the-art meta-analyses with advanced methodological features.

### Key Features

#### Core Functionality
- **Pairwise Effect Size Calculation**: Automatic calculation for HR, RR, OR, RD, MD, and SMD
- **Multiple Input Formats**: Support for logHR+SE, HR with CIs, O–E+V, and arm-level data
- **Transportability Weighting**: Entropy balancing to transport results to target populations
- **HKSJ Adjustments**: Hartung-Knapp-Sidik-Jonkman small-sample corrections
- **Prediction Intervals**: Full uncertainty quantification for new settings

#### Publication Bias Assessment
- PET-PEESE (Precision-Effect Test/Estimate with Standard Error)
- Selection models (weightr)
- RoBMA (Robust Bayesian Meta-Analysis) model averaging
- p-uniform* methods
- Trim-and-fill
- Egger's and Begg's tests
- Simple p-curve analysis

#### Advanced Methods
- **Multivariate Meta-Analysis**: `rma.mv` with:
  - Assumed within-study correlation (ρ) with sensitivity analysis
  - Exact covariance structures for log OR with shared controls
- **Rare Events Suite**:
  - Peto odds ratio
  - Mantel-Haenszel OR/RR
  - GLMM (binomial likelihood) OR/RR
- **Robust Variance Estimation**: CR2 cluster-robust standard errors (clubSandwich)
- **Bayesian Analysis**:
  - brms with model stacking
  - JAGS fallback for complex models
  - Customizable priors
- **Meta-Regression**: Natural splines for time trends
- **Machine Learning**: Heterogeneity analysis with random forests (ranger)

#### Diagnostic Tools
- Influence analysis and outlier detection
- Leave-one-out sensitivity
- Cumulative meta-analysis
- Robust M-location estimation
- E-values for unmeasured confounding
- Conflict detection via clustering

#### Visualization
- Forest plots (stratified by study type)
- Funnel plots with contours
- PET/PEESE diagnostic plots
- Leave-one-out plots
- Cumulative meta-analysis plots
- Multiverse analysis plots
- Bayesian posterior density plots
- ρ-sensitivity plots for multivariate models
- Interactive plotly support

## Installation

### From GitHub (Development Version)

```r
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install CBAMMR from GitHub
devtools::install_github("mahmood726-cyber/CBAMMR")
```

### Required Dependencies

```r
# Core required packages
install.packages(c("metafor", "dplyr", "tidyr", "tibble", "purrr",
                   "ggplot2", "patchwork", "coda", "splines"))
```

### Optional Dependencies (for full functionality)

```r
# Transportability
install.packages(c("WeightIt", "cobalt"))

# Bayesian analysis
install.packages(c("brms", "posterior", "loo", "rjags"))

# Robust variance estimation
install.packages("clubSandwich")

# Additional features
install.packages(c("plotly", "cluster", "weightr", "ranger",
                   "MASS", "puniform", "RoBMA"))
```

## Quick Start

### Example 1: Hazard Ratio Meta-Analysis

```r
library(CBAMMR)

# Show package features
cbamm_novelty_notes()

# Simulate data (18 RCTs, 18 observational studies, 8 MR studies)
set.seed(1)
demo_data <- simulate_cbamm_data(n_rct = 18, n_obs = 18, n_mr = 8)

# Define target population for transportability
target_pop <- list(
  age_mean = 72.0,
  female_pct = 0.48,
  bmi_mean = 29.4,
  charlson = 2.1
)

# Configure analysis
config <- setup_cbamm(
  effect_measure = "HR",
  use_transport = TRUE,
  use_hksj = TRUE,
  use_bayesian = TRUE,
  use_rve_as_primary = TRUE,
  run_mv = TRUE,
  exact_cov_logOR = TRUE,
  run_meta_regression = TRUE
)

# Run complete analysis
results <- run_cbamm_analysis(
  data = demo_data,
  target_population = target_pop,
  config = config
)

# View summary table
print(results$results$summary_table)
```

### Example 2: Odds Ratio with Rare Events

```r
library(CBAMMR)

# Simulate binary data with rare events
bin_data <- simulate_cbamm_binary(n = 30, measure = "OR")

# Configure for rare events
config <- setup_cbamm(
  effect_measure = "OR",
  force_rare_events = TRUE,  # or let validator auto-detect
  rare_event_models = c("Peto", "MH", "GLMM"),
  run_mv = TRUE,
  exact_cov_logOR = TRUE
)

# Run analysis
results <- run_cbamm_analysis(bin_data, config = config)
```

### Example 3: Standardized Mean Difference

```r
library(CBAMMR)

# Simulate continuous outcomes
cont_data <- simulate_cbamm_continuous(n = 25, measure = "SMD")

# Configure analysis
config <- setup_cbamm(effect_measure = "SMD")

# Run analysis
results <- run_cbamm_analysis(cont_data, config = config)
```

## Data Format

### For Hazard Ratios (HR)

Provide **one** of the following:
- `yi` (log HR) and `se` (standard error)
- `logHR` and `SE`
- `HR`, `ci_lb`, `ci_ub` (HR with 95% CI)
- `OE` (observed - expected) and `V` (variance)
- `TE` and `seTE` (generic effect + SE)

**Required columns**: `study_id`, `study_type` (RCT/OBS/MR)

### For Binary Outcomes (OR, RR, RD)

Provide **either**:
- `yi` and `se` (already calculated)
- Arm-level data:
  - `event_t`, `n_t`, `event_c`, `n_c`, or
  - `ai`, `bi`, `ci`, `di`

### For Continuous Outcomes (MD, SMD)

Provide **either**:
- `yi` and `se`
- Arm-level data:
  - `mean_t`, `sd_t`, `n_t`, `mean_c`, `sd_c`, `n_c`, or
  - `m1i`, `sd1i`, `n1i`, `m2i`, `sd2i`, `n2i`

### Optional Columns

- `grade`: GRADE quality (High, Moderate, Low, Very low)
- `year`: Publication year (for meta-regression)
- `age_mean`, `female_pct`, `bmi_mean`, `charlson`: For transportability weighting
- `neg_ctrl`: Negative control outcome estimates (for bias assessment)

## Configuration Options

```r
config <- setup_cbamm(
  # Core options
  effect_measure = "HR",         # HR, RR, OR, RD, MD, or SMD
  use_hksj = TRUE,               # Hartung-Knapp adjustments

  # Weighting
  use_transport = TRUE,          # Transportability weighting
  use_grade_weighting = TRUE,    # GRADE-based down-weighting
  transport_truncation = 0.02,   # Weight truncation level

  # Heterogeneity estimators
  tau_estimators = c("REML", "DL", "PM", "HE", "ML", "EB"),

  # Binary outcomes
  continuity_correction = 0.5,    # For zero cells
  continuity_when = "only0",      # "only0" or "all"

  # Multi-arm trials
  multiarm_strategy = "keep_cr2", # or "split_shared_control"
  use_rve_as_primary = FALSE,     # Use CR2 as primary inference

  # Rare events
  force_rare_events = FALSE,      # Force rare-events models
  rare_event_models = c("Peto", "MH", "GLMM"),
  glmm_model = "CM.EL",           # GLMM specification

  # Multivariate
  run_mv = TRUE,                  # Run multivariate MA
  mv_assumed_rho = 0.50,          # Assumed correlation
  mv_rho_grid = seq(0, 0.9, 0.1), # Sensitivity analysis grid
  exact_cov_logOR = TRUE,         # Exact covariance for log OR

  # Meta-regression
  run_meta_regression = TRUE,
  meta_regression_df = 3,         # Spline degrees of freedom

  # Bayesian
  use_bayesian = TRUE,
  bayes_chains = 2,
  bayes_iter = 2000,
  bayes_warmup = 1000,

  # Other
  use_ml = FALSE,                 # ML heterogeneity analysis
  use_interactive = FALSE,        # Interactive plotly plots
  export_results = FALSE,         # Export to files
  output_dir = "cbamm_results"
)
```

## Output Structure

Results object contains:
- `$pooled`: Pooled meta-analysis results
- `$stratified`: Results stratified by study type
- `$multiverse`: Multiverse analysis across specifications
- `$rare_events`: Rare-events suite results
- `$mv`: Multivariate meta-analysis results
- `$mv_rho`: ρ-sensitivity analysis
- `$pet_peese`: PET-PEESE results
- `$pub_bias`: Publication bias analyses
- `$robma`: RoBMA model averaging
- `$puniform`: p-uniform* results
- `$bayesian`: Bayesian analysis results
- `$meta_regression`: Time trend analysis
- `$influence`: Influence diagnostics
- `$plots`: All visualization objects
- `$summary_table`: Manuscript-ready summary table

## Citation

If you use CBAMMR in your research, please cite:

```
CBAMMR: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R.
Version 7.0. https://github.com/mahmood726-cyber/CBAMMR
```

## License

Apache License 2.0. See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or pull request on GitHub.

## Support

For issues and feature requests, please use the [GitHub issue tracker](https://github.com/mahmood726-cyber/CBAMMR/issues).

## References

Key methodological references:
- Hartung & Knapp (2001): HKSJ adjustments
- Egger et al. (1997): Small-study effects
- Stanley & Doucouliagos (2014): PET-PEESE
- Viechtbauer (2010): metafor package
- Makowski et al. (2023): RoBMA
- van Aert et al. (2016): p-uniform*

## Version History

### v7.0.0 (2025-10-27)
- Initial CRAN-ready release
- Full pairwise + validator pipeline
- Rare-events suite (Peto, MH, GLMM)
- Multivariate with exact covariance structures
- RoBMA publication bias model averaging
- Bayesian stacking with brms
- Comprehensive diagnostic suite
- Publication-ready tables and plots
