# CBAMMR User Guide

**Version:** 9.0.0
**Date:** November 2025
**Status:** Publication-Ready

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [When to Use CBAMMR](#when-to-use-cbammr)
4. [Basic Workflow](#basic-workflow)
5. [Advanced Features](#advanced-features)
6. [Transportability Analysis](#transportability-analysis)
7. [Interpreting Results](#interpreting-results)
8. [Reporting Guidelines](#reporting-guidelines)
9. [Troubleshooting](#troubleshooting)
10. [Validation & Quality Assurance](#validation--quality-assurance)

---

## Quick Start

**Run a complete meta-analysis in 3 lines:**

```r
library(CBAMMR)
results <- cbamm_auto(your_data, pathway = "standard")
summary(results)
```

**That's it!** CBAMMR automatically:
- Detects your data type
- Chooses appropriate methods
- Fits models
- Tests assumptions
- Generates plots
- Creates reports

---

## Installation

```r
# Install from GitHub
devtools::install_github("mahmood726-cyber/CBAMMR")

# Load package
library(CBAMMR)

# Check version
packageVersion("CBAMMR")  # Should be ≥9.0.0
```

---

## When to Use CBAMMR

### ✓ Use CBAMMR When:

**You want integrated workflow:**
- One function (`cbamm_auto()`) handles everything
- Automatic method selection based on best practices
- Comprehensive output (estimates, plots, tables, checklists)

**You need transportability:**
- Adjust meta-analysis for specific target population
- Account for effect heterogeneity by patient characteristics
- Answer "What would the effect be in MY population?"

**You value transparency:**
- All automated decisions logged and explained
- Can review and override any choices
- Reproducible results

**You're under time pressure:**
- Fast turnaround from data to manuscript-ready results
- Automated PRISMA checklist generation
- Pre-formatted tables and figures

### ✓ Use metafor/meta Directly When:

**You need maximum flexibility:**
- Complex multilevel models
- Network meta-analysis
- Custom effect size measures
- Methodological research

**You want full control:**
- Every parameter specified manually
- Custom publication bias methods
- Non-standard model specifications

> **Note:** CBAMMR uses metafor under the hood, so you always get the same statistical rigor. We just automate intelligent decisions.

---

## Basic Workflow

### Step 1: Prepare Data

CBAMMR accepts three data formats:

#### Format A: Binary Outcomes (2×2 Tables)

```r
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  ai = c(...),  # Events in treatment group
  bi = c(...),  # Non-events in treatment
  ci = c(...),  # Events in control
  di = c(...)   # Non-events in control
)
```

**Example:** Treatment vs control for preventing infection
- `ai`: Patients with infection in treatment group
- `bi`: Patients without infection in treatment group
- `ci`: Patients with infection in control group
- `di`: Patients without infection in control group

#### Format B: Continuous Outcomes

```r
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  m1i = c(...),   # Mean in treatment group
  sd1i = c(...),  # SD in treatment group
  n1i = c(...),   # N in treatment group
  m2i = c(...),   # Mean in control group
  sd2i = c(...),  # SD in control group
  n2i = c(...)    # N in control group
)
```

**Example:** Depression scores, blood pressure, quality of life

#### Format C: Pre-Calculated Effect Sizes

```r
data <- data.frame(
  study = c("Study 1", "Study 2", ...),
  yi = c(...),  # Effect sizes (log OR, SMD, etc.)
  vi = c(...)   # Variances
)
```

### Step 2: Run Analysis

```r
results <- cbamm_auto(
  data = data,
  pathway = "standard",  # or "advanced" or "custom"
  verbose = TRUE         # Show decision process
)
```

**The three pathways:**

1. **`pathway = "standard"`** (Recommended for most users)
   - REML heterogeneity estimation
   - Hartung-Knapp-Sidik-Jonkman (HKSJ) adjustment
   - Comprehensive publication bias testing
   - Forest plots, funnel plots
   - PRISMA checklist

2. **`pathway = "advanced"`** (For complex analyses)
   - Everything in standard +
   - Bayesian meta-analysis (RoBMA)
   - Sensitivity analyses
   - Influence diagnostics
   - Leave-one-out analysis
   - Meta-regression diagnostics

3. **`pathway = "custom"`** (Full control)
   - Specify all parameters manually
   - Override automatic decisions
   - Expert users only

### Step 3: Review Results

```r
# Overall summary
summary(results)

# Pooled estimate
results$pooled
#> Random-Effects Model (REML, HKSJ)
#> OR = 0.65 (95% CI: 0.52-0.81), p < 0.001
#> I² = 42.3%, τ² = 0.12

# Automated decisions made
results$decisions

# Publication bias
results$publication_bias

# Heterogeneity
results$heterogeneity

# Forest plot
plot(results, type = "forest")

# Funnel plot
plot(results, type = "funnel")
```

---

## Advanced Features

### Meta-Regression

Add study-level moderators:

```r
# Add moderator variables to data
data$year <- c(2015, 2016, 2017, ...)
data$quality_score <- c(7, 6, 8, ...)

# Run meta-regression
results <- cbamm_auto(
  data = data,
  pathway = "standard",
  moderators = ~ year + quality_score
)

# View meta-regression results
results$meta_regression
```

**Interpretation:** Does effect size vary by publication year or study quality?

### Subgroup Analysis

```r
# Add subgroup variable
data$region <- c("Europe", "Asia", "North America", ...)

results <- cbamm_auto(
  data = data,
  pathway = "standard",
  subgroup = "region"
)

# View subgroup results
results$subgroup_analysis
```

### Bayesian Meta-Analysis

```r
results <- cbamm_auto(
  data = data,
  pathway = "advanced",
  run_bayesian = TRUE
)

# View Bayesian results
results$bayesian
#> Posterior median: -0.42 (95% CrI: -0.68 to -0.18)
#> Probability(OR < 1): 0.998
```

**Advantages:**
- Incorporates prior information
- Direct probability statements
- Better for small sample sizes
- Accounts for publication bias

### Sensitivity Analysis

```r
results <- cbamm_auto(
  data = data,
  pathway = "advanced",
  sensitivity = TRUE
)

# Influence diagnostics
results$sensitivity$influence
#> Study 3 is influential (DFFITS > 2)

# Leave-one-out
results$sensitivity$leave_one_out
#> Effect ranges from OR=0.61 to OR=0.72
```

---

## Transportability Analysis

### What is Transportability?

Meta-analyses pool studies from potentially unrepresentative samples. **Transportability** adjusts pooled estimates to reflect a specific target population.

**Example:**
- Studies enrolled relatively young, healthy patients (mean age 55, low comorbidity)
- You want to know the effect in elderly Medicare patients (age 75, high comorbidity)
- Transportability reweights studies to match your target population

### When to Use Transportability

✓ **USE when:**
- You have study-level covariate data (age, sex, BMI, comorbidities)
- Target population differs from sample (≥0.5 SD on key covariates)
- Evidence of effect heterogeneity (I² > 50%)
- ≥10 studies available
- Extrapolation is moderate (<2 SD)

✗ **AVOID when:**
- No covariate data
- Target similar to sample
- No effect heterogeneity
- Small meta-analysis (k < 10)
- Extreme extrapolation needed

### Step-by-Step Example

```r
# 1. Add patient characteristics to data
data$age_mean <- c(52, 58, 61, 55, ...)
data$female_pct <- c(0.42, 0.48, 0.51, ...)
data$bmi_mean <- c(26, 28, 27, ...)
data$charlson <- c(1.5, 2.1, 1.8, ...)  # Comorbidity index

# 2. Define target population
target <- list(
  age_mean = 72,      # Elderly
  female_pct = 0.65,  # More female
  bmi_mean = 30,      # Higher BMI
  charlson = 4.0      # More comorbid
)

# 3. Check if transportability is appropriate
check <- check_transportability(data, target)
print(check$recommendation)
#> RECOMMENDED: All criteria met

# 4. Run transportability analysis
results <- cbamm_auto(
  data = data,
  pathway = "standard",
  target_population = target
)

# 5. Compare results
cat(sprintf("Sample population OR: %.2f\n", exp(results$pooled$beta[1])))
cat(sprintf("Target population OR: %.2f\n", exp(results$pooled$transport$beta[1])))

# 6. Assess covariate balance
weights <- compute_transport_weights(data, target)
balance <- assess_covariate_balance(data, target, weights)
print(balance)
#> All covariates balanced (std diff < 0.1)
```

### Interpreting Transportability Results

**If target estimate differs from sample:**
- Effect varies by patient characteristics
- Adjustment accounts for this heterogeneity
- Target estimate is more relevant for your population

**If target estimate similar to sample:**
- Little effect modification by measured covariates
- Either (a) no heterogeneity or (b) unmeasured confounding
- Unadjusted estimate already applicable

**Reporting:**
> "The pooled OR in the study sample (mean age 58) was 0.65 (95% CI: 0.52-0.81). After transportability adjustment to our target Medicare population (mean age 72, Charlson score 4.0), the OR was 0.71 (95% CI: 0.55-0.92), suggesting a somewhat weaker effect in elderly, multimorbid patients."

### Diagnostic Tools

```r
# Generate full diagnostic report
transportability_report(data, target, weights)
#> Prints comprehensive diagnostics:
#>  1. Appropriateness assessment
#>  2. Weight quality
#>  3. Covariate balance

# Plot sample vs target distributions
plot_sample_vs_target(data, target, weights)

# Diagnose weight issues
diagnose_weights(weights, data)
#> Effective sample size: 12.3 (82% of original)
#> Assessment: GOOD WEIGHTS
```

**For full details, see:** `vignette("transportability-guide")`

---

## Interpreting Results

### Pooled Effect Size

```r
results$pooled
#> Random-Effects Model (REML, HKSJ adjustment)
#> Effect size: OR = 0.65 (95% CI: 0.52-0.81)
#> p-value: <0.001
#> I² = 42.3%, τ² = 0.12
```

**Interpretation:**
- **OR = 0.65**: Treatment reduces odds by 35% (1 - 0.65)
- **95% CI: 0.52-0.81**: We're 95% confident true OR is between 0.52 and 0.81
- **p < 0.001**: Highly statistically significant
- **I² = 42%**: Moderate heterogeneity (30-50% = moderate)
- **τ² = 0.12**: Between-study variance on log scale

### Heterogeneity

```r
results$heterogeneity
#> Q = 12.35, df = 7, p = 0.089
#> I² = 42.3% (95% CI: 0% - 72%)
#> τ² = 0.12
#> H² = 1.73
```

**I² Guidelines:**
- 0-25%: Low heterogeneity
- 25-50%: Moderate heterogeneity
- 50-75%: Substantial heterogeneity
- 75-100%: Considerable heterogeneity

**What to do:**
- **Low I²**: Effects are fairly consistent, pooling appropriate
- **High I²**: Investigate with subgroup/meta-regression analysis
- **Very high I²**: Question whether pooling makes sense

### Publication Bias

```r
results$publication_bias
#> Egger's test: t = 2.15, p = 0.068
#> Trim-and-fill: 2 studies trimmed (adjusted OR = 0.71)
#> Fail-safe N: 18 studies needed to nullify
#> Overall: MODERATE RISK
```

**Risk Levels:**
- **Low**: No strong evidence of bias
- **Moderate**: Some indicators suggest possible bias
- **High**: Multiple indicators of likely bias

**What to do:**
- **Low risk**: Proceed with confidence
- **Moderate**: Report sensitivity analyses, interpret cautiously
- **High**: Major concern, results may be biased

---

## Reporting Guidelines

### Methods Section Template

> "We conducted a random-effects meta-analysis using the CBAMMR package (v9.0.0) in R. Between-study heterogeneity was estimated using restricted maximum likelihood (REML). We applied the Hartung-Knapp-Sidik-Jonkman adjustment for more conservative confidence intervals. Heterogeneity was quantified using I² and τ². Publication bias was assessed using Egger's test, trim-and-fill, and funnel plot inspection. [If applicable:] To adjust estimates for our target population, we applied transportability analysis using entropy balancing, reweighting studies to match target characteristics (age, sex, BMI, comorbidities)."

### Results Section Template

> "We included X studies with Y participants. The pooled odds ratio was Z (95% CI: A-B), indicating a [magnitude]% [increase/reduction] in [outcome]. Between-study heterogeneity was [low/moderate/substantial] (I² = C%, τ² = D). Publication bias assessment indicated [low/moderate/high] risk (Egger's test p = E, trim-and-fill adjusted OR = F). [If transportability:] After adjusting for our target population (mean age G, Charlson score H), the transported OR was I (95% CI: J-K)."

### Tables to Include

**Table 1:** Study characteristics
```r
table1 <- cbamm_create_table(results, type = "characteristics")
```

**Table 2:** Meta-analysis results
```r
table2 <- cbamm_create_table(results, type = "results")
```

**Table 3:** Publication bias assessment
```r
table3 <- cbamm_create_table(results, type = "publication_bias")
```

### Figures to Include

**Figure 1:** PRISMA flow diagram
```r
prisma <- cbamm_generate_prisma(results)
plot(prisma)
```

**Figure 2:** Forest plot
```r
forest <- plot(results, type = "forest")
ggsave("forest_plot.png", forest, width = 8, height = 6, dpi = 300)
```

**Figure 3:** Funnel plot
```r
funnel <- plot(results, type = "funnel")
ggsave("funnel_plot.png", funnel, width = 6, height = 6, dpi = 300)
```

**Figure 4 (if applicable):** Sample vs target population
```r
if (!is.null(results$transport_weights)) {
  transport_plot <- plot_sample_vs_target(data, target, results$transport_weights)
  ggsave("transportability.png", transport_plot, width = 8, height = 5, dpi = 300)
}
```

---

## Troubleshooting

### Problem: Cannot Calculate Effect Size

**Error:** `"Error: Unable to calculate effect sizes"`

**Solution:**
1. Check column names match expected format
2. Ensure all values are numeric
3. Check for missing data

```r
# Verify data structure
str(data)
summary(data)

# For binary data, check:
names(data)  # Should include: ai, bi, ci, di

# For continuous data, check:
names(data)  # Should include: m1i, sd1i, n1i, m2i, sd2i, n2i
```

### Problem: Transportability Not Recommended

**Message:** `"Transportability NOT RECOMMENDED: Small sample size"`

**Solutions:**
- **Increase sample size**: Need ≥10 studies
- **Check covariates**: Ensure age_mean, female_pct, bmi_mean, charlson present
- **Verify target differs**: Target should be ≥0.5 SD from sample
- **Check heterogeneity**: Need I² > 50% for transportability to help

```r
# Run diagnostic
check <- check_transportability(data, target)
print(check$issues)      # See what's wrong
print(check$warnings)    # See cautions
print(check$metrics)     # Review metrics
```

### Problem: Warning About High Heterogeneity

**Warning:** `"Warning: High heterogeneity detected (I² = 78%)"`

**Solutions:**
1. **Investigate sources**: Run subgroup or meta-regression
2. **Check for outliers**: Influence diagnostics
3. **Consider**: Is pooling appropriate?

```r
# Investigate heterogeneity
results_metareg <- cbamm_auto(data, moderators = ~ year + quality)

# Check for outliers
results_sens <- cbamm_auto(data, pathway = "advanced", sensitivity = TRUE)
results_sens$sensitivity$influence
```

### Problem: Publication Bias Warning

**Message:** `"HIGH RISK of publication bias detected"`

**Actions:**
1. **Report transparently**: Acknowledge limitation
2. **Sensitivity analysis**: Try trim-and-fill adjustment
3. **Search for unpublished**: Contact authors, check registries
4. **Interpret cautiously**: Effect may be overstated

```r
# View all publication bias diagnostics
results$publication_bias

# See adjusted estimate
results$publication_bias$trim_and_fill$adjusted_estimate
```

### Problem: Model Did Not Converge

**Error:** `"Error: Model did not converge"`

**Solutions:**
1. Try different heterogeneity estimator
2. Reduce model complexity
3. Check for data issues

```r
# Try DerSimonian-Laird instead of REML
results <- cbamm_auto(data, pathway = "custom",
                     custom_method = "DL")

# Or simplify (remove moderators if included)
results <- cbamm_auto(data, pathway = "standard")
```

---

## Validation & Quality Assurance

### CBAMMR Has Been Extensively Validated

**✓ 20 Landmark Meta-Analyses Reproduced:**
- Spanning 63 years (1950-2013)
- 12 major journals (JAMA, NEJM, BMJ, Cochrane, etc.)
- 10 disciplines (cardiology to psychiatry)
- All effect size types (OR, RR, SMD)

See: `tests/testthat/test-published-reproductions.R`

**✓ 12 Comprehensive Transportability Tests:**
- Weight computation and validation
- Covariate balance achievement
- Effect modification recovery
- Simulation with known ground truth
- Edge case handling

See: `tests/testthat/test-transportability.R`

**✓ Validation Protocol:**
- Complete research protocol for transportability
- 108,000-simulation study design
- Real-world validation cases
- Peer-review ready methodology

See: `TRANSPORTABILITY_VALIDATION_PROTOCOL.md`

### Quality Standards

CBAMMR follows best practices:

**Statistical:**
- REML for heterogeneity (preferred estimator)
- HKSJ adjustment (more conservative CIs)
- Comprehensive publication bias testing
- Entropy balancing for transportability (Hainmueller 2012)

**Software:**
- Built on metafor (Viechtbauer 2010) - gold standard
- Integrates meta (Schwarzer et al. 2015)
- Uses RoBMA for Bayesian analysis (Bartoš et al. 2022)
- Full test coverage

**Documentation:**
- Transparent decision-making
- All choices logged and explained
- Comprehensive vignettes
- Peer-reviewed methods

### Citing CBAMMR

```
@software{cbammr2025,
  title = {CBAMMR: Comprehensive Bayesian and Meta-Analysis Methods in R},
  author = {{CBAMMR Development Team}},
  year = {2025},
  version = {9.0.0},
  url = {https://github.com/mahmood726-cyber/CBAMMR}
}
```

**Also cite underlying packages:**
- **metafor:** Viechtbauer (2010). *J Stat Softw*, 36(3), 1-48.
- **meta:** Schwarzer et al. (2015). *Meta-Analysis with R*. Springer.

**If using transportability:**
- **Entropy balancing:** Hainmueller (2012). *Polit Anal*, 20(1), 25-46.

---

## Getting Help

### Documentation

- **Quick start:** `vignette("cbammr-quickstart")`
- **Transportability:** `vignette("transportability-guide")`
- **Function help:** `?cbamm_auto`

### Support

- **GitHub Issues:** https://github.com/mahmood726-cyber/CBAMMR/issues
- **Email:** support@cbammr.org
- **Stack Overflow:** Tag `cbammr`

### Reporting Bugs

Please include:
1. CBAMMR version (`packageVersion("CBAMMR")`)
2. R version (`R.version.string`)
3. Minimal reproducible example
4. Expected vs actual behavior

---

## Summary

**CBAMMR is for you if you want:**

✓ Fast, automated meta-analysis
✓ Transportability to specific populations
✓ Comprehensive reporting (PRISMA, GRADE)
✓ Integrated workflow (one function does it all)
✓ Transparent, logged decisions
✓ Publication-quality outputs

**Key Features:**

- **3 pathways:** Standard (most users), Advanced (complex), Custom (experts)
- **Multiple outcomes:** Binary, continuous, pre-calculated
- **Advanced methods:** Bayesian, transportability, meta-regression
- **Quality assurance:** Validated against 20 landmark studies
- **User-friendly:** Automated decisions, comprehensive documentation

**Get Started:**

```r
library(CBAMMR)
results <- cbamm_auto(your_data, pathway = "standard")
summary(results)
```

**That's it!** You now have a complete, publication-ready meta-analysis.

---

**Version History:**
- v9.0.0 (2025-11): Major revision, transportability validation, 20 reproductions
- v8.14.0 (2024-XX): Previous release

**License:** MIT

**Acknowledgments:** Built on the shoulders of giants - Wolfgang Viechtbauer (metafor), Guido Schwarzer (meta), and many others in the meta-analysis community.
