# CBAMMR 8.6.1

## Code Quality Improvements (2025-11-05)

### Code Quality Enhancements

* **New Centralized Constants** (`R/constants.R`)
  - Statistical constants (QNORM_95, etc.)
  - Fragility index thresholds
  - Heterogeneity interpretation thresholds
  - Sample size requirements
  - Standardized error/warning messages

* **New Validation Helpers** (`R/validation-helpers.R`)
  - `validate_meta_inputs()` - Comprehensive input validation
  - `validate_meta_data()` - Data frame validation
  - `validate_config()` - Configuration validation
  - `check_package_available()` - Safe namespace checking
  - `safe_predict()` - Error-safe predictions
  - `safe_try()` - Improved error handling

* **Namespace Improvements**
  - Fixed unsafe `require()` calls in `R/advanced-methods.R`
  - Added proper package availability checks
  - Improved error messages for missing dependencies

* **Input Validation**
  - Added validation to `cbamm_quantile_ma()`
  - Added validation to `cbamm_individualized_effect()`
  - Improved error messages throughout

* **Documentation**
  - Added comprehensive CODE_REVIEW_REPORT.md
  - Detailed analysis of code quality
  - Prioritized improvement recommendations
  - CRAN submission checklist

### Bug Fixes

* Fixed potential NULL pointer issues in several functions
* Improved error handling to prevent silent failures

### Internal Changes

* Better separation of concerns with helper modules
* Reduced code duplication
* Improved maintainability

---

# CBAMMR 7.0.0

## Initial Release (2025-10-27)

### Major Features

* **Pairwise Effect Size Calculation**
  - Automatic calculation for HR, RR, OR, RD, MD, and SMD
  - Multiple input format support (logHR+SE, HR+CI, O-E+V, arm-level data)
  - Smart validator with diagnostic checks

* **Advanced Weighting**
  - Transportability weighting with entropy balancing
  - GRADE-based quality down-weighting
  - Weight truncation to handle extreme values

* **Robust Inference**
  - Hartung-Knapp-Sidik-Jonkman adjustments
  - Prediction intervals for all analyses
  - CR2 cluster-robust variance estimation

* **Publication Bias Suite**
  - PET-PEESE
  - Selection models (weightr)
  - RoBMA model averaging
  - p-uniform* methods
  - Trim-and-fill
  - Begg's and Egger's tests
  - P-curve analysis

* **Multivariate Meta-Analysis**
  - rma.mv with assumed correlations
  - Sensitivity analysis across ρ values
  - Exact covariance structures for log OR (shared controls)

* **Rare Events Methods**
  - Peto odds ratio
  - Mantel-Haenszel OR/RR
  - GLMM with binomial likelihood

* **Bayesian Analysis**
  - brms with model stacking
  - JAGS fallback
  - Customizable priors

* **Diagnostics**
  - Influence analysis and outlier detection
  - Leave-one-out sensitivity
  - Cumulative meta-analysis
  - Robust M-location
  - E-values for unmeasured confounding

* **Meta-Regression**
  - Natural splines for time trends
  - Flexible moderator modeling

* **Machine Learning**
  - Random forest heterogeneity analysis

* **Visualization**
  - Comprehensive plotting suite
  - Forest, funnel, and diagnostic plots
  - Interactive plotly support

### Data Simulation

* `simulate_cbamm_data()` - Generate HR data
* `simulate_cbamm_binary()` - Generate binary outcome data
* `simulate_cbamm_continuous()` - Generate continuous outcome data

### Documentation

* Complete function documentation with roxygen2
* Comprehensive README with examples
* Detailed vignettes (planned for future releases)

## Future Plans

### v7.1.0 (Planned)

* Network meta-analysis support
* Component network meta-analysis
* Additional dose-response methods
* Enhanced IPD support
* More publication bias methods

### v7.2.0 (Planned)

* Shiny dashboard for interactive analysis
* More comprehensive vignettes
* Additional diagnostic tools
* Enhanced machine learning methods
