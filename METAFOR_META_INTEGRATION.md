# CBAMMR v8.3.0 - Complete metafor & meta Integration

## Overview

CBAMMR v8.3.0 now provides **complete integration** with the metafor and meta packages, offering access to **ALL** their plotting and analysis capabilities through a unified, user-friendly interface.

This makes CBAMMR the **ultimate meta-analysis package** - combining the best of:
- **CBAMMR's** advanced Bayesian methods, clinical decision tools, and distribution-free methods
- **metafor's** comprehensive diagnostics and flexible modeling
- **meta's** alternative implementations and specialized visualizations

---

## Key Features

### ✅ Unified Plotting Interface

Access all plot types from a single function:

```r
# Automatic package selection
cbamm_plot(yi, vi, plot_type = "forest")

# Specify package
cbamm_plot(yi, vi, plot_type = "funnel", package = "metafor")
cbamm_plot(yi, vi, plot_type = "funnel", package = "meta")
```

### ✅ Batch Plot Generation

Generate multiple diagnostic plots at once:

```r
# Create standard diagnostic suite
cbamm_batch_plots(yi, vi,
                  plots = c("forest", "funnel", "baujat", "radial"))

# Save to files
cbamm_batch_plots(yi, vi,
                  plots = c("forest", "funnel", "baujat"),
                  output_dir = "plots",
                  file_prefix = "myanalysis")
```

### ✅ Cross-Package Comparison

Compare implementations side-by-side:

```r
# Compare forest plots from metafor and meta
cbamm_compare_plots(yi, vi,
                    plot_type = "forest",
                    packages = c("metafor", "meta"))
```

### ✅ 10 Example Datasets

Real-world datasets ready for analysis:

1. **bcg_vaccine** - BCG vaccine for tuberculosis (13 RCTs)
2. **aspirin_mi** - Aspirin for MI prevention (7 trials)
3. **magnesium_mi** - Magnesium for MI (16 trials)
4. **smoking_cessation** - Antidepressants for smoking cessation (28 trials)
5. **teacher_expectancy** - Teacher expectancy effects (19 studies)
6. **estrogen_chd** - Estrogen therapy and CHD (15 studies)
7. **tobacco_lung_cancer** - ETS and lung cancer (37 studies)
8. **exercise_depression** - Exercise for depression (23 trials)
9. **bariatric_surgery** - Bariatric vs medical treatment (12 trials)
10. **probiotics_diarrhea** - Probiotics for AAD (31 trials)

```r
# Load and use
data(bcg_vaccine)
head(bcg_vaccine)

# Quick analysis
library(metafor)
dat <- escalc(measure="OR", ai=tpos, bi=tneg, ci=cpos, di=cneg,
              data=bcg_vaccine)
cbamm_forest_metafor(dat$yi, dat$vi)
```

---

## Complete Function Reference

### metafor Integration (10 Functions)

#### Plotting Functions

**1. cbamm_forest_metafor()**
- Publication-quality forest plots
- Extensive customization options
- Study weights, prediction intervals, credibility intervals

```r
cbamm_forest_metafor(yi, vi,
                     study_labels = study_names,
                     method = "REML",
                     addcred = TRUE,
                     showweights = TRUE)
```

**2. cbamm_funnel_metafor()**
- Contour-enhanced funnel plots
- Multiple significance contours
- Publication bias assessment

```r
cbamm_funnel_metafor(yi, vi,
                     level = c(90, 95, 99),
                     shade = c("white", "gray85", "gray70"))
```

**3. cbamm_radial_metafor()**
- Radial (Galbraith) plots
- Outlier detection
- Heterogeneity visualization

```r
cbamm_radial_metafor(yi, vi, method = "REML")
```

**4. cbamm_baujat_metafor()**
- Identify heterogeneity contributors
- Assess influence on overall result

```r
cbamm_baujat_metafor(yi, vi, method = "REML")
```

**5. cbamm_labbe_metafor()**
- L'Abbé plots for binary outcomes
- Visualize treatment vs control event rates

```r
cbamm_labbe_metafor(ai, bi, ci, di)
```

**6. cbamm_gosh_metafor()**
- Graphical Display of Study Heterogeneity
- Detect patterns across all possible subsets

```r
result <- cbamm_gosh_metafor(yi, vi, subsets = 10000)
plot(result)
```

#### Analysis Functions

**7. cbamm_influence_metafor()**
- Comprehensive influence diagnostics
- Cook's distances, hat values, DFBETAS
- Identifies outliers and influential studies

```r
result <- cbamm_influence_metafor(yi, vi)
print(result)
plot(result)

# Returns:
# - Outliers (|studentized residual| > 2)
# - Influential studies (Cook's d > 4/k or hat > 2p/k)
# - All diagnostic statistics
```

**8. cbamm_cumulative_metafor()**
- Cumulative meta-analysis
- Shows evolution of pooled estimate as studies added
- Typically chronological order

```r
result <- cbamm_cumulative_metafor(yi, vi,
                                   order = order(year))
print(result)
plot(result)
```

**9. cbamm_loo_metafor()**
- Leave-one-out sensitivity analysis
- Assesses impact of each study

```r
result <- cbamm_loo_metafor(yi, vi)
print(result)
```

**10. cbamm_trimfill_metafor()**
- Trim-and-fill for publication bias
- Imputes potentially missing studies

```r
result <- cbamm_trimfill_metafor(yi, vi, estimator = "L0")
print(result)

# Shows:
# - Number of imputed studies
# - Original vs adjusted estimate
# - Change in effect size
```

---

### meta Package Integration (10 Functions)

#### Plotting Functions

**1. cbamm_forest_meta()**
- Forest plots with meta package styling
- Alternative layout options
- Hartung-Knapp adjustment support

```r
cbamm_forest_meta(yi, sei = sqrt(vi),
                  sm = "MD",
                  hakn = TRUE,
                  prediction = TRUE)
```

**2. cbamm_funnel_meta()**
- Funnel plots with meta styling
- Contour-enhanced options

```r
cbamm_funnel_meta(yi, sei = sqrt(vi),
                  contour = TRUE)
```

**3. cbamm_radial_meta()**
- Radial plots using meta

```r
cbamm_radial_meta(yi, sei = sqrt(vi))
```

**4. cbamm_baujat_meta()**
- Baujat plots using meta

```r
cbamm_baujat_meta(yi, sei = sqrt(vi))
```

**5. cbamm_labbe_meta()**
- L'Abbé plots for binary data

```r
cbamm_labbe_meta(ai, bi, ci, di, sm = "OR")
```

**6. cbamm_bubble_meta()**
- Bubble plots for meta-regression
- Shows effect of continuous covariate

```r
cbamm_bubble_meta(yi, sei = sqrt(vi),
                  x = age,
                  xlab = "Mean Age")
```

**7. cbamm_drapery_meta()**
- Drapery plots showing p-value functions
- Visualizes uncertainty for all studies
- **UNIQUE to meta package**

```r
cbamm_drapery_meta(yi, sei = sqrt(vi))
```

#### Analysis Functions

**8. cbamm_metareg_meta()**
- Meta-regression using meta
- Hartung-Knapp adjustment
- R² calculation

```r
moderators <- data.frame(age = age_vec,
                         year = year_vec)
result <- cbamm_metareg_meta(yi, sei = sqrt(vi),
                             moderators = moderators,
                             hakn = TRUE)
print(result)
```

**9. cbamm_trimfill_meta()**
- Trim-and-fill using meta package

```r
result <- cbamm_trimfill_meta(yi, sei = sqrt(vi))
print(result)
```

---

### Unified Plotting Interface (5 Functions)

**1. cbamm_plot()**
- Universal plotting function
- Auto-selects optimal package
- Single interface for all plot types

```r
# Let CBAMMR choose the best package
cbamm_plot(yi, vi, plot_type = "forest")

# Specify package
cbamm_plot(yi, vi, plot_type = "baujat", package = "metafor")
```

**2. cbamm_available_plots()**
- Lists all available plot types
- Shows which packages provide each plot
- Checks package installation status

```r
plots_df <- cbamm_available_plots()
print(plots_df)

# Returns data frame with:
# - plot_type
# - description
# - metafor (available?)
# - meta (available?)
# - cbammr (available?)
```

**3. cbamm_batch_plots()**
- Generate multiple plots at once
- Save to files automatically
- Publication-ready output

```r
# Generate and display
cbamm_batch_plots(yi, vi,
                  plots = c("forest", "funnel", "baujat", "radial"))

# Generate and save
cbamm_batch_plots(yi, vi,
                  plots = c("forest", "funnel", "baujat"),
                  output_dir = "manuscript_figures",
                  file_prefix = "meta_analysis",
                  width = 10,
                  height = 8,
                  dpi = 300)
```

**4. cbamm_compare_plots()**
- Side-by-side comparison
- Same plot type, different packages
- Evaluate implementation differences

```r
# Compare forest plots
par(mfrow = c(1, 2))
cbamm_compare_plots(yi, vi,
                    plot_type = "forest",
                    packages = c("metafor", "meta"))

# Compare funnel plots
cbamm_compare_plots(yi, vi,
                    plot_type = "funnel",
                    packages = c("metafor", "meta"))
```

**5. cbamm_plot_capabilities()**
- Print comprehensive summary
- All available plots
- Package status
- Usage examples

```r
cbamm_plot_capabilities()

# Prints formatted summary with:
# - All plot types and descriptions
# - Package availability status
# - Usage examples
```

---

## Complete Plot Type Reference

| Plot Type | Description | metafor | meta | CBAMMR |
|-----------|-------------|---------|------|--------|
| **forest** | Forest plot with effect sizes and CIs | ✓ | ✓ | ✗ |
| **funnel** | Funnel plot for publication bias | ✓ | ✓ | ✗ |
| **radial** | Radial/Galbraith plot for outliers | ✓ | ✓ | ✗ |
| **baujat** | Baujat plot for heterogeneity contributors | ✓ | ✓ | ✗ |
| **labbe** | L'Abbé plot for binary outcomes | ✓ | ✓ | ✗ |
| **bubble** | Bubble plot for meta-regression | ✗ | ✓ | ✗ |
| **drapery** | Drapery plot (p-value functions) | ✗ | ✓ | ✗ |
| **gosh** | GOSH plot for heterogeneity patterns | ✓ | ✗ | ✗ |
| **influence** | Influence diagnostics | ✓ | ✗ | ✗ |
| **cumulative** | Cumulative meta-analysis | ✓ | ✗ | ✗ |

**Total: 10 different plot types across packages**

---

## Workflow Examples

### Example 1: Complete Diagnostic Workflow

```r
library(CBAMMR)

# Load data
data(bcg_vaccine)

# Calculate effect sizes
library(metafor)
dat <- escalc(measure="OR", ai=tpos, bi=tneg, ci=cpos, di=cneg,
              data=bcg_vaccine)

# Extract effect sizes and variances
yi <- dat$yi
vi <- dat$vi

# Step 1: Basic forest plot
cbamm_forest_metafor(yi, vi,
                     study_labels = bcg_vaccine$study,
                     xlab = "Log Odds Ratio")

# Step 2: Publication bias assessment
cbamm_funnel_metafor(yi, vi)

# Step 3: Identify heterogeneity contributors
cbamm_baujat_metafor(yi, vi)

# Step 4: Outlier detection
cbamm_radial_metafor(yi, vi)

# Step 5: Influence diagnostics
infl <- cbamm_influence_metafor(yi, vi)
print(infl)
plot(infl)

# Step 6: Leave-one-out sensitivity
loo <- cbamm_loo_metafor(yi, vi, study_labels = bcg_vaccine$study)
print(loo)

# Step 7: Trim and fill
taf <- cbamm_trimfill_metafor(yi, vi)
print(taf)
```

### Example 2: Batch Plot Generation for Manuscript

```r
# Generate all diagnostic plots and save
cbamm_batch_plots(
  yi = yi,
  vi = vi,
  plots = c("forest", "funnel", "baujat", "radial"),
  output_dir = "manuscript_figures",
  file_prefix = "bcg_vaccine",
  width = 10,
  height = 8,
  dpi = 300
)

# Files created:
# - manuscript_figures/bcg_vaccine_forest.png
# - manuscript_figures/bcg_vaccine_funnel.png
# - manuscript_figures/bcg_vaccine_baujat.png
# - manuscript_figures/bcg_vaccine_radial.png
```

### Example 3: Cross-Package Comparison

```r
# Compare forest plot implementations
par(mfrow = c(1, 2))
cbamm_compare_plots(yi, vi,
                    plot_type = "forest",
                    packages = c("metafor", "meta"))

# Compare funnel plot implementations
par(mfrow = c(1, 2))
cbamm_compare_plots(yi, vi,
                    plot_type = "funnel",
                    packages = c("metafor", "meta"))
```

### Example 4: Using Example Datasets

```r
# 1. Teacher expectancy dataset
data(teacher_expectancy)
head(teacher_expectancy)

# Basic analysis
cbamm_permutation_test(teacher_expectancy$yi,
                       teacher_expectancy$vi)

# Plots
cbamm_forest_metafor(teacher_expectancy$yi,
                     teacher_expectancy$vi)

# Meta-regression with moderator
mod_matrix <- cbind(1, teacher_expectancy$weeks)
result <- cbamm_bayesian_metareg(teacher_expectancy$yi,
                                 teacher_expectancy$vi,
                                 X = mod_matrix,
                                 n_iter = 2000)

# 2. Exercise for depression
data(exercise_depression)

# Quantile meta-analysis
qma <- cbamm_quantile_ma(exercise_depression$yi,
                         exercise_depression$vi,
                         taus = c(0.25, 0.50, 0.75))
plot(qma)

# 3. Smoking cessation
data(smoking_cessation)

# Calculate OR
library(metafor)
dat <- escalc(measure="OR",
              ai=quit_treat, n1i=n_treat,
              ci=quit_control, n2i=n_control,
              data=smoking_cessation)

# Cumulative meta-analysis
cumul <- cbamm_cumulative_metafor(dat$yi, dat$vi,
                                  order = order(smoking_cessation$year))
plot(cumul)
```

---

## Technical Details

### Package Requirements

**Required:**
- metafor (>= 3.0.0) - in Imports

**Optional (Suggests):**
- meta (>= 6.0.0) - for meta package integration

### Function Naming Convention

All wrapper functions follow the pattern:
```
cbamm_[function]_[package]()
```

Examples:
- `cbamm_forest_metafor()` - forest plot using metafor
- `cbamm_funnel_meta()` - funnel plot using meta
- `cbamm_plot()` - unified interface (no package suffix)

### Return Values

**metafor functions** return:
- S3 objects with class `cbamm_[function]_metafor`
- Include the underlying metafor rma object
- Have custom print() and plot() methods

**meta functions** return:
- S3 objects with class `cbamm_[function]_meta`
- Include the underlying meta object
- Have custom print() methods

### Error Handling

All functions check for package availability:
```r
if (!requireNamespace("metafor", quietly = TRUE)) {
  stop("Package 'metafor' is required. Install with: install.packages('metafor')")
}
```

Graceful degradation when packages not available.

---

## Integration with Existing CBAMMR Features

The new metafor/meta integration works seamlessly with all existing CBAMMR methods:

### Distribution-Free Methods
```r
# CBAMMR permutation test
perm <- cbamm_permutation_test(yi, vi)

# Then use metafor for visualization
cbamm_forest_metafor(yi, vi)
```

### Clinical Decision Tools
```r
# CBAMMR decision curve
dca <- cbamm_decision_curve(yi, vi)
plot(dca)

# Combine with metafor diagnostics
cbamm_baujat_metafor(yi, vi)
```

### Bayesian Methods
```r
# CBAMMR Bayesian bootstrap
bayes <- cbamm_bayesian_bootstrap(yi, vi, n_boot = 5000)
print(bayes)

# Visualize with metafor
cbamm_forest_metafor(yi, vi)
```

### Sensitivity Analysis
```r
# CBAMMR sensitivity analysis
sens <- cbamm_sensitivity_analysis(yi, vi)
print(sens)

# metafor influence diagnostics
infl <- cbamm_influence_metafor(yi, vi)
plot(infl)
```

---

## Benefits of Integration

### 1. Best of All Worlds
- CBAMMR's advanced methods
- metafor's comprehensive diagnostics
- meta's specialized visualizations

### 2. Unified Interface
- Single function call for all plots
- Consistent syntax across packages
- Automatic package selection

### 3. Enhanced Workflows
- Batch plot generation
- Cross-package comparisons
- Publication-ready outputs

### 4. Complete Diagnostics
- 10 different plot types
- Influence analysis
- Cumulative meta-analysis
- GOSH diagnostics
- Drapery plots

### 5. Example Datasets
- 10 real-world datasets
- Documented and ready to use
- Cover diverse outcome types

---

## Comparison with Other Packages

| Feature | CBAMMR 8.3 | metafor | meta | metaplus | rmeta |
|---------|-----------|---------|------|----------|-------|
| Advanced Bayesian methods | ✓ | ✗ | ✗ | ✗ | ✗ |
| Clinical decision tools | ✓ | ✗ | ✗ | ✗ | ✗ |
| Distribution-free methods | ✓ | ✗ | ✗ | ✗ | ✗ |
| metafor integration | ✓ | N/A | ✗ | ✗ | ✗ |
| meta integration | ✓ | ✗ | N/A | ✗ | ✗ |
| Unified plot interface | ✓ | ✗ | ✗ | ✗ | ✗ |
| Batch plotting | ✓ | ✗ | ✗ | ✗ | ✗ |
| Cross-package comparison | ✓ | ✗ | ✗ | ✗ | ✗ |
| Example datasets | ✓ (10) | ✗ | ✗ | ✗ | ✗ |
| Interactive GUI | ✓ | ✗ | ✗ | ✗ | ✗ |

**CBAMMR is the only package that provides ALL capabilities in one unified framework.**

---

## What's New in v8.3.0

### New Functions (25 total)

**metafor wrappers (10):**
- cbamm_forest_metafor()
- cbamm_funnel_metafor()
- cbamm_radial_metafor()
- cbamm_baujat_metafor()
- cbamm_labbe_metafor()
- cbamm_influence_metafor()
- cbamm_cumulative_metafor()
- cbamm_loo_metafor()
- cbamm_gosh_metafor()
- cbamm_trimfill_metafor()

**meta wrappers (10):**
- cbamm_forest_meta()
- cbamm_funnel_meta()
- cbamm_radial_meta()
- cbamm_baujat_meta()
- cbamm_labbe_meta()
- cbamm_bubble_meta()
- cbamm_drapery_meta()
- cbamm_metareg_meta()
- cbamm_trimfill_meta()

**Unified interface (5):**
- cbamm_plot()
- cbamm_available_plots()
- cbamm_batch_plots()
- cbamm_compare_plots()
- cbamm_plot_capabilities()

### New Datasets (10)

1. bcg_vaccine
2. aspirin_mi
3. magnesium_mi
4. smoking_cessation
5. teacher_expectancy
6. estrogen_chd
7. tobacco_lung_cancer
8. exercise_depression
9. bariatric_surgery
10. probiotics_diarrhea

### New Documentation

- Complete function reference
- Workflow examples
- Technical specifications
- Integration guide

---

## Future Directions

Planned for v8.4.0:
- Integration with additional specialized packages
- More example datasets
- Enhanced GUI with all new plots
- Additional visualization types
- Performance optimizations

---

## Citation

If you use CBAMMR's metafor/meta integration in your research, please cite:

```
CBAMMR: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R
Version 8.3.0 (2025)
https://github.com/mahmood726-cyber/CBAMMR
```

And the underlying packages:

```
Viechtbauer, W. (2010). Conducting meta-analyses in R with the metafor package.
Journal of Statistical Software, 36(3), 1-48.

Balduzzi, S., Rücker, G., & Schwarzer, G. (2019). How to perform a
meta-analysis with R: a practical tutorial. Evidence-Based Mental Health,
22(4), 153-160.
```

---

## Support

- Issues: https://github.com/mahmood726-cyber/CBAMMR/issues
- Documentation: See function help pages (?cbamm_plot)
- Examples: See vignettes (browseVignettes("CBAMMR"))

---

**CBAMMR v8.3.0 - The Complete Meta-Analysis Solution**

*Bringing together the best of CBAMMR, metafor, and meta in one unified framework.*
