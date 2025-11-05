# CBAMMR: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![R](https://img.shields.io/badge/R-%3E%3D4.0.0-blue)](https://www.r-project.org/)

## Overview

CBAMMR is an integrated workflow package for meta-analysis that builds on established R packages (metafor, meta, RoBMA, brms) to provide streamlined workflows and additional tools for clinical decision-making and transportability analysis.

### Design Philosophy

- **Build on proven foundations:** Leverages metafor (Viechtbauer, 2010) and meta (Schwarzer, 2007) rather than reimplementing established methods
- **Workflow integration:** Combines multiple analysis steps into reproducible workflows
- **Transparency:** All methodological choices are logged and reported
- **Flexibility:** Three analysis pathways (standard/advanced/custom) for different user needs

### Key Contributions

#### 1. Workflow Automation
The `cbamm_auto()` function provides a standardized workflow that:
- Detects data structure and types
- Calculates effect sizes using metafor::escalc()
- Selects appropriate heterogeneity estimators
- Performs publication bias assessments
- Generates reproducible reports

**Note:** Automation is intended to improve reproducibility and reduce arbitrary choices, not to replace expert judgment. Users should review and validate all automated decisions.

#### 2. Clinical Decision Support
Tools for translating meta-analytic findings into clinical practice:
- Fragility indices for meta-analysis
- Baseline-risk-specific NNT calculations
- Decision curve analysis integration
- Minimal important difference (MID) assessments

#### 3. Transportability Analysis
Novel application of entropy balancing to adjust meta-analytic estimates for target populations:
- Weights studies based on covariate similarity to target population
- Addresses external validity concerns
- Provides sensitivity analyses

**Status:** Methodological validation in progress. Use with caution and expert consultation.

### Relationship to Existing Packages

| Package | Role | Relationship |
|---------|------|--------------|
| **metafor** | Core meta-analysis engine | CBAMMR wraps metafor functions; users seeking advanced customization should use metafor directly |
| **meta** | Alternative meta-analysis framework | Compatible; CBAMMR can interface with meta objects |
| **RoBMA** | Bayesian model averaging | Integrated for publication bias assessment |
| **brms** | Bayesian modeling | Used for Bayesian meta-analysis and meta-regression |
| **weightr** | Selection models | Integrated for publication bias detection |

**When to use CBAMMR vs. metafor directly:**
- Use **metafor** for: Maximum flexibility, cutting-edge methods, complex models, methodological research
- Use **CBAMMR** for: Standardized workflows, clinical decision tools, automated reporting, transportability analysis

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

### Example 1: Automated Workflow

```r
library(CBAMMR)

# Load example data
data(bcg_vaccine)

# Run automated analysis (standard pathway)
result <- cbamm_auto(bcg_vaccine,
                     pathway = "standard",
                     verbose = TRUE)

# View summary
print(result)

# Generate forest plot
plot(result)

# Get pooled estimate
result$pooled$estimate
```

### Example 2: Custom Analysis with Manual Control

```r
library(CBAMMR)
library(metafor)

# Load data
data(aspirin_mi)

# Calculate effect sizes using metafor
es <- escalc(measure = "OR",
             ai = event_t, n1i = n_t,
             ci = event_c, n2i = n_c,
             data = aspirin_mi)

# Run meta-analysis with metafor
ma <- rma(yi, vi, data = es, method = "REML")

# Add CBAMMR clinical decision tools
fragility <- cbamm_fragility_index(ma)
nnt <- cbamm_nnt_by_risk(ma, baseline_risks = c(0.01, 0.05, 0.10))

# Generate publication-ready report
cbamm_generate_report(ma,
                      outcome_name = "Myocardial Infarction",
                      comparison = "Aspirin vs Placebo")
```

## Data Format

CBAMMR accepts standard meta-analysis data formats compatible with metafor:

### Binary Outcomes
```r
# 2x2 table format
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  ai = c(...),  # events in treatment group
  bi = c(...),  # non-events in treatment group
  ci = c(...),  # events in control group
  di = c(...)   # non-events in control group
)
```

### Continuous Outcomes
```r
# Summary statistics format
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  m1i = c(...),   # mean in group 1
  sd1i = c(...),  # SD in group 1
  n1i = c(...),   # sample size in group 1
  m2i = c(...),   # mean in group 2
  sd2i = c(...),  # SD in group 2
  n2i = c(...)    # sample size in group 2
)
```

### Pre-calculated Effect Sizes
```r
# Effect size + variance format
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  yi = c(...),  # effect size
  vi = c(...)   # sampling variance
)
```

## Key Functions

### Core Analysis
- `cbamm_auto()` - Automated workflow with three pathways
- `cbamm_escalc()` - Effect size calculation (wraps metafor::escalc)
- `cbamm_meta()` - Meta-analysis wrapper with enhanced features

### Publication Bias
- `cbamm_egger_test()` - Egger's test for small-study effects
- `cbamm_pet_peese()` - PET-PEESE analysis
- `cbamm_trim_fill()` - Trim-and-fill method
- Integration with RoBMA and weightr packages

### Clinical Tools
- `cbamm_fragility_index()` - Calculate fragility index
- `cbamm_nnt_by_risk()` - NNT stratified by baseline risk
- `cbamm_mid_assessment()` - Minimal important difference assessment
- `cbamm_decision_curve()` - Decision curve analysis

### Transportability
- `cbamm_transport_weights()` - Calculate transportability weights
- `cbamm_transport_analysis()` - Full transportability workflow

### Reporting
- `cbamm_grade_assessment()` - GRADE evidence assessment
- `cbamm_prisma_checklist()` - PRISMA 2020 checklist
- `cbamm_generate_report()` - Automated report generation

## Validation

CBAMMR has been validated against published meta-analyses (see `tests/validation/`):

- Reproduction of 10 Cochrane reviews (in progress)
- Comparison with metafor outputs (validation suite included)
- Statistical properties verified through simulation (see vignettes)

**Note:** This is an active research package. While we strive for accuracy, users should independently verify critical results.

## Citation

If you use CBAMMR in your research, please cite:

```
CBAMMR: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R.
Version 9.0. https://github.com/mahmood726-cyber/CBAMMR

And the underlying packages:
Viechtbauer W. (2010). Conducting meta-analyses in R with the metafor package.
Journal of Statistical Software, 36(3), 1-48.
```

## Contributing

Contributions are welcome! Areas particularly in need of development:
- Validation against published meta-analyses
- Simulation studies for transportability methods
- Comparative benchmarks with metafor/meta
- User experience studies

Please open an issue or pull request on GitHub.

## Limitations and Known Issues

### Current Limitations
1. **Transportability methods:** Not yet peer-reviewed; validation studies ongoing
2. **Automated decisions:** May not be appropriate for all scenarios; expert review recommended
3. **GRADE automation:** Provides preliminary assessments; expert judgment still required
4. **Computational performance:** Slower than metafor alone due to additional analyses

### When NOT to Use CBAMMR
- Complex multilevel models (use metafor directly)
- Network meta-analysis (use netmeta)
- Individual participant data meta-analysis requiring custom models
- Methodological research requiring maximum flexibility

### Known Issues
- Large datasets (>1000 studies) may have performance issues
- Some Bayesian analyses require substantial computation time
- Interactive features require optional packages

See [GitHub issues](https://github.com/mahmood726-cyber/CBAMMR/issues) for current bug reports.

## Support

- **Documentation:** See package vignettes (`browseVignettes("CBAMMR")`)
- **Issues:** Report bugs at https://github.com/mahmood726-cyber/CBAMMR/issues
- **Questions:** For general meta-analysis questions, consider the [R meta-analysis mailing list](https://stat.ethz.ch/mailman/listinfo/r-sig-meta-analysis)

## Acknowledgments

CBAMMR builds on the foundational work of:
- Wolfgang Viechtbauer (metafor package)
- Guido Schwarzer (meta package)
- František Bartoš (RoBMA package)
- And many others in the meta-analysis community

We are grateful to stand on the shoulders of giants.

## License

Apache License 2.0. See [LICENSE](LICENSE) file for details.

## Version History

### v9.0.0 (2025-11-05)
- Major revision based on peer review
- Reframed as workflow integration package
- Removed unsupported claims
- Added validation framework
- Improved documentation transparency
- Enhanced testing suite

### v8.14.0 (2025-11-05)
- Initial CRAN-ready release
- Comprehensive CI/CD implementation
- Full documentation suite
