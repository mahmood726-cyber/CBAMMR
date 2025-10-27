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
