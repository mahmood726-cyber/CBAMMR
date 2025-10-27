# CBAMMR Quick Start Guide

Get from data to publication-ready results in 5 minutes!

## Installation

```r
# Install from GitHub
devtools::install_github("mahmood726-cyber/CBAMMR")

# Load package
library(CBAMMR)
```

## Simplest Workflow (3 lines!)

```r
# 1. Setup
config <- setup_cbamm(effect_measure = "OR")

# 2. Run complete analysis
publication <- cbamm_complete_workflow(
  data = my_data,  # Your data frame
  config = config,
  outcome_name = "Mortality"
)

# 3. Done! All outputs saved to cbamm_publication_outputs/
```

That's it! You now have:
- ✅ Complete meta-analysis results
- ✅ PRISMA 2020 checklist
- ✅ GRADE evidence assessment
- ✅ Fragility index
- ✅ NNT stratified by risk
- ✅ Power analysis
- ✅ Publication-ready text
- ✅ Reproducibility bundle for OSF/Zenodo

## Your Data Format

CBAMMR accepts data in two formats:

### Format 1: Effect Sizes (Recommended)
```r
data <- data.frame(
  study = c("Smith 2020", "Jones 2021", ...),
  yi = c(log(0.70), log(0.85), ...),  # Log odds ratios
  sei = c(0.15, 0.20, ...),           # Standard errors
  n1i = c(100, 150, ...),             # Sample size group 1
  n2i = c(100, 150, ...),             # Sample size group 2
  year = c(2020, 2021, ...)
)
```

### Format 2: Raw 2x2 Table Data
```r
data <- data.frame(
  study = c("Smith 2020", "Jones 2021", ...),
  ai = c(20, 30, ...),   # Events in treatment group
  bi = c(80, 120, ...),  # Non-events in treatment
  ci = c(30, 40, ...),   # Events in control
  di = c(70, 110, ...),  # Non-events in control
  n1i = c(100, 150, ...), # Total treatment
  n2i = c(100, 150, ...)  # Total control
)
```

## Copy-Paste Example

```r
library(CBAMMR)

# Create example data (or use your own!)
set.seed(123)
data <- simulate_cbamm_binary(n = 20, measure = "OR", true_effect = 0.70)

# Optional: Add target population for transportability weighting
target_pop <- list(age_mean = 65, female_pct = 0.52)

# Configure analysis
config <- setup_cbamm(
  effect_measure = "OR",
  use_transport = TRUE,   # Apply transportability weighting
  use_hksj = TRUE,       # Hartung-Knapp adjustments (recommended!)
  use_bayesian = FALSE,  # Skip Bayesian for speed
  run_mv = TRUE,         # Multivariate meta-analysis
  export_results = TRUE  # Save all outputs
)

# Run complete workflow
publication <- cbamm_complete_workflow(
  data = data,
  target_population = target_pop,
  config = config,
  outcome_name = "All-cause mortality",
  mid = 0.10,          # Minimal important difference
  baseline_risk = 0.15  # For decision curve analysis
)

# View formatted results text
cat(publication$formatted$results_text)

# Copy methods text to your manuscript
cat(publication$formatted$methods_text)

# All files saved to cbamm_publication_outputs/
list.files("cbamm_publication_outputs", recursive = TRUE)
```

## What You Get

### 1. Manuscript Text (`manuscript_text.txt`)
Ready-to-paste Methods and Results sections following journal standards:

**Methods:**
> Meta-analysis was conducted using CBAMMR v7.0 in R version 4.4.0. We used random-effects meta-analysis with REML estimation and Hartung-Knapp-Sidik-Jonkman adjustments. Certainty of evidence was assessed using GRADE. Statistical robustness was evaluated using the fragility index...

**Results:**
> Twenty studies (n = 4,500 participants) were included. The pooled OR = 0.70 [95% CI: 0.60, 0.82], I² = 45%, τ² = 0.040, indicating moderate heterogeneity. The 95% prediction interval: 0.50-0.98. GRADE assessment yielded MODERATE (+++−) certainty evidence. The fragility index was 28, indicating highly robust findings...

### 2. PRISMA 2020 Checklist (`prisma_checklist.csv`)
All 27 items with page numbers for your manuscript

### 3. GRADE Profile (`grade_profile.csv`)
| Domain | Assessment | Explanation |
|--------|------------|-------------|
| Risk of Bias | not serious | Based on study design |
| Inconsistency | serious | I² = 45% |
| ... | ... | ... |

### 4. NNT by Risk (`nnt_by_baseline_risk.csv`)
| baseline_risk | nnt | direction |
|---------------|-----|-----------|
| 0.01 | 500 | NNTB |
| 0.40 | 12 | NNTB |

### 5. Reproducibility Bundle (`reproducibility_bundle/`)
Complete folder ready for OSF/Zenodo upload with:
- Data (CSV)
- Code (reproducible R script)
- Results (all outputs)
- Documentation (codebook, session info)
- README with installation instructions

## Individual Function Examples

If you don't want the complete workflow, use individual functions:

```r
# Just run meta-analysis
results <- run_cbamm_analysis(data, target_pop, config)

# Just PRISMA checklist
prisma <- cbamm_prisma_checklist(results = results)

# Just GRADE assessment
grade <- cbamm_grade_profile(results, data, outcome_name = "Mortality")

# Just fragility index
fragility <- cbamm_fragility_index(results, data)

# Just NNT by risk
nnt_table <- cbamm_nnt_by_baseline_risk(results, c(0.05, 0.10, 0.20, 0.40))

# Just clinical significance
clinical_sig <- cbamm_clinical_significance(results, mid = 0.10)

# Just net clinical benefit
net_benefit <- cbamm_net_clinical_benefit(results, data, baseline_risk = 0.15)

# Just reproducibility bundle
cbamm_export_bundle(results, data, config, output_dir = "osf_bundle")
```

## Continuous Outcomes

For continuous outcomes (e.g., mean differences, standardized mean differences):

```r
# Use SMD or MD as effect measure
config <- setup_cbamm(effect_measure = "SMD")

# Your data needs yi (effect sizes) and sei (standard errors)
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  yi = c(-0.40, -0.35, ...),   # Standardized mean differences
  sei = c(0.15, 0.18, ...)     # Standard errors
)

# Run analysis
results <- run_cbamm_analysis(data, config = config)

# Assess clinical significance (0.2 = small, 0.5 = medium, 0.8 = large)
clinical_sig <- cbamm_clinical_significance(results, mid = 0.20, measure = "SMD")
```

## Visualizations

All plots are automatically generated and saved to `cbamm_outputs/`:
- Forest plot
- Funnel plot (publication bias)
- Leave-one-out sensitivity
- Cumulative meta-analysis
- Multiverse analysis (specification curve)
- Meta-regression plots
- And more!

```r
# View all plots interactively
cbamm_show_all_plots(results)

# Or save as PDF
cbamm_show_all_plots(results, pdf_file = "meta_analysis_plots.pdf")
```

## Common Effect Measures

| Measure | Code | Data Type | Example |
|---------|------|-----------|---------|
| Odds Ratio | `"OR"` | Binary | Case-control studies |
| Risk Ratio | `"RR"` | Binary | Cohort studies |
| Hazard Ratio | `"HR"` | Time-to-event | Survival analysis |
| Risk Difference | `"RD"` | Binary | Absolute effects |
| Mean Difference | `"MD"` | Continuous | Same units |
| Std. Mean Diff. | `"SMD"` | Continuous | Different units |

## Tips

1. **Always use HKSJ adjustments**: `use_hksj = TRUE` (recommended by 2025 standards)
2. **Include prediction intervals**: Automatically calculated, essential for interpretation
3. **Report fragility index**: Shows statistical robustness beyond p-values
4. **Stratify NNT by risk**: Don't report a single NNT for binary outcomes
5. **Use GRADE**: Required by most medical journals
6. **Share reproducibility bundle**: Upload to OSF/Zenodo for DOI

## Getting Help

- **Documentation**: `?function_name` (e.g., `?cbamm_grade_profile`)
- **Examples**: `example(cbamm_complete_workflow`)
- **Vignette**: `vignette("cbamm-intro")`
- **GitHub Issues**: https://github.com/mahmood726-cyber/CBAMMR/issues

## Citation

When publishing, cite:

```
CBAMMR v7.0: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R
https://github.com/mahmood726-cyber/CBAMMR
```

And the reporting standards:
- PRISMA 2020: Page MJ, et al. (2021). BMJ, 372:n71
- GRADE: Guyatt GH, et al. (2011). J Clin Epidemiol, 64(4):383-394

## Next Steps

After running your analysis:

1. ✅ Review `manuscript_text.txt` for Methods/Results sections
2. ✅ Complete PRISMA checklist with page numbers
3. ✅ Review GRADE profile and adjust if needed
4. ✅ Check fragility index interpretation
5. ✅ Upload `reproducibility_bundle/` to OSF/Zenodo
6. ✅ Get DOI and cite in manuscript
7. ✅ Include all outputs as supplementary materials

**That's it! You're ready to submit to top-tier journals!** 🎉

---

**Package Version**: 7.0.0
**Standards**: PRISMA 2020, GRADE, 2024-2025 journal guidelines
**For full tutorial**: See `vignette("cbamm-intro")`
