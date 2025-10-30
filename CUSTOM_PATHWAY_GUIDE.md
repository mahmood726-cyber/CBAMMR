# CBAMMR Custom Pathway Guide
## For Advanced Meta-Analysis Practitioners

**Target Audience:** Experienced meta-analysts, methodologists, statisticians who want full control over all analytical decisions.

---

## Overview

The **Custom Pathway** gives you complete control over:
- Effect size measures (choose any of 40+ measures)
- Estimators (REML, ML, DL, EB, SJ, HS, PM)
- Heterogeneity methods (select specific methods)
- Publication bias tests (choose which tests to run)
- Sensitivity analyses (specify exactly which)
- Advanced methods (Bayesian, permutation, fragility)
- All parameters and options

**Unlike Standard/Advanced pathways** (which make automated decisions), the Custom pathway defers to YOUR expertise.

---

## When to Use Custom Pathway

### ✅ **Use Custom Pathway When:**
1. You have specific methodological requirements
2. You're comparing specific methods
3. You know exactly which estimator/measure to use
4. You're conducting methodological research
5. You want to replicate a specific published analysis
6. You need methods not in standard/advanced pathways
7. You're an experienced practitioner who doesn't need automation

### ❌ **Don't Use Custom Pathway When:**
1. You're unsure which methods to use
2. You want journal-ready automated analysis (use Standard)
3. You're learning meta-analysis
4. You want to explore many methods (use Advanced)
5. Time is limited and automation is acceptable

---

## Basic Usage

### Minimal Custom Pathway
```r
library(CBAMMR)
data <- read.csv("my_data.csv")

# Just specify pathway
result <- cbamm_auto(data, pathway = "custom")
```
**Note:** With no custom parameters, uses default REML and automated decisions for remaining choices.

### Full Custom Control
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "Peto",
                     custom_estimator = "ML",
                     custom_pub_bias = c("egger", "petpeese"),
                     custom_sensitivity = c("loo", "influence"),
                     custom_run_bayesian = TRUE,
                     custom_run_permutation = TRUE,
                     custom_n_permutations = 5000)
```

---

## Custom Parameters Reference

### 1. Effect Size Measure (`custom_effect_measure`)

**Binary outcomes:**
- `"OR"` / `"LogOR"` - Odds ratio (log scale)
- `"RR"` / `"LogRR"` - Risk ratio (log scale)
- `"RD"` - Risk difference
- `"Peto"` - Peto odds ratio (for rare events)
- `"AS"` - Arcsine square root transformed risk difference
- `"PETO"` - Peto odds ratio
- Plus 20+ more from metafor (see `?escalc`)

**Continuous outcomes:**
- `"SMD"` - Standardized mean difference (Hedges' g)
- `"MD"` - Mean difference (raw)
- `"ROM"` - Ratio of means (log scale)
- `"RPB"` - Point-biserial correlation
- Plus 10+ more from metafor

**Correlations:**
- `"ZCOR"` - Fisher's z-transformed correlation
- `"COR"` - Raw correlation

**Example:**
```r
# Use Peto OR for rare events
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "Peto")
```

---

### 2. Estimator (`custom_estimator`)

Choose the variance estimator for random-effects model:

- `"REML"` (default) - Restricted maximum likelihood
  - **Pros:** Unbiased, recommended by Cochrane
  - **Cons:** Can fail with sparse data

- `"ML"` - Maximum likelihood
  - **Pros:** Always converges
  - **Cons:** Slightly biased (underestimates tau²)

- `"DL"` - DerSimonian-Laird
  - **Pros:** Fast, historic standard
  - **Cons:** Biased, no longer recommended

- `"EB"` - Empirical Bayes
  - **Pros:** Works well with small k
  - **Cons:** Less commonly used

- `"SJ"` - Sidik-Jonkman
  - **Pros:** Robust to outliers
  - **Cons:** Can be conservative

- `"HS"` - Hunter-Schmidt
  - **Pros:** Simple, robust
  - **Cons:** Older method

- `"PM"` - Paule-Mandel
  - **Pros:** Matches Q-statistic
  - **Cons:** Can be unstable

**Example:**
```r
# Compare REML vs ML
result_reml <- cbamm_auto(data, pathway = "custom", custom_estimator = "REML")
result_ml <- cbamm_auto(data, pathway = "custom", custom_estimator = "ML")

cat("REML estimate:", result_reml$estimate, "\n")
cat("ML estimate:", result_ml$estimate, "\n")
```

---

### 3. Publication Bias Methods (`custom_pub_bias`)

**Vector of methods to run:**

- `"egger"` - Egger's regression test
- `"begg"` - Begg's rank correlation test
- `"trimfill"` - Trim-and-fill method
- `"petpeese"` - PET-PEESE correction
- `"selection"` - Selection models

**Example:**
```r
# Run only PET-PEESE and Egger's test
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_pub_bias = c("egger", "petpeese"))

# Access results
result$custom_results$pub_bias_custom$egger
result$custom_results$pub_bias_custom$petpeese
```

**Run NO publication bias tests:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_pub_bias = NULL)  # or omit parameter
```

---

### 4. Sensitivity Analyses (`custom_sensitivity`)

**Vector of sensitivity methods:**

- `"loo"` - Leave-one-out (jackknife)
- `"cumulative"` - Cumulative meta-analysis
- `"influence"` - Influence diagnostics
- `"baujat"` - Baujat plot analysis

**Example:**
```r
# Run only leave-one-out and influence
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_sensitivity = c("loo", "influence"))

# Access results
result$custom_results$sensitivity_custom$loo
result$custom_results$sensitivity_custom$influence
```

---

### 5. Heterogeneity Methods (`custom_heterogeneity`)

**Vector of heterogeneity methods:**

- `"quantile"` - Quantile-based heterogeneity (distribution-free)
- `"bootstrap"` - Bootstrap heterogeneity estimation

**Example:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_heterogeneity = c("quantile", "bootstrap"))

# Standard heterogeneity (I², Q, tau²) always calculated
# Custom methods available in:
result$custom_results$heterogeneity_custom
```

---

### 6. Bayesian Analysis (`custom_run_bayesian`)

**Boolean:** Run Bayesian meta-analysis?

**Parameters:**
- `custom_run_bayesian = TRUE/FALSE`
- `custom_prior = ...` (optional prior specification)

**Example:**
```r
# Run Bayesian with default priors
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_run_bayesian = TRUE)

# Access Bayesian results
result$custom_results$bayesian$posterior_mean
result$custom_results$bayesian$credible_interval

# Run Bayesian with custom prior (advanced)
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_run_bayesian = TRUE,
                     custom_prior = list(
                       mean = 0,
                       sd = 0.5,
                       dist = "normal"
                     ))
```

---

### 7. Permutation Tests (`custom_run_permutation`)

**Boolean:** Run permutation tests?

**Parameters:**
- `custom_run_permutation = TRUE/FALSE`
- `custom_n_permutations = 1000` (default, can increase)

**Example:**
```r
# Run 5000 permutations for precise p-value
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_run_permutation = TRUE,
                     custom_n_permutations = 5000)

# Access permutation results
result$custom_results$permutation$p_value
result$custom_results$permutation$observed_statistic
```

**Computational note:** 10,000 permutations ≈ 30 seconds for k=20 studies

---

### 8. Fragility Index (`custom_run_fragility`)

**Boolean:** Calculate fragility index?

**Requires:** Binary outcome data

**Example:**
```r
# Calculate fragility index for binary data
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_run_fragility = TRUE)

# Access fragility results
result$custom_results$fragility$index
result$custom_results$fragility$interpretation
```

---

## Complete Examples

### Example 1: Rare Events Meta-Analysis

```r
library(CBAMMR)
data <- read.csv("adverse_events.csv")

# Peto OR, ML estimator, focus on sensitivity
result <- cbamm_auto(data,
                     pathway = "custom",
                     study_id = "study",
                     custom_effect_measure = "Peto",
                     custom_estimator = "ML",
                     custom_pub_bias = c("egger", "begg"),
                     custom_sensitivity = c("loo", "cumulative"),
                     custom_run_bayesian = TRUE,
                     verbose = TRUE)

# Extract key results
cat("Peto OR:", exp(result$estimate), "\n")
cat("95% CI: [", exp(result$ci_lb), ", ", exp(result$ci_ub), "]\n", sep = "")
cat("Bayesian estimate:", exp(result$custom_results$bayesian$posterior_mean), "\n")
```

---

### Example 2: Methodological Comparison Study

```r
# Compare 4 estimators on same data
estimators <- c("REML", "ML", "DL", "EB")
results <- list()

for (est in estimators) {
  results[[est]] <- cbamm_auto(data,
                               pathway = "custom",
                               custom_estimator = est,
                               verbose = FALSE,
                               generate_rmd = FALSE)
}

# Compare estimates
comparison <- data.frame(
  Estimator = estimators,
  Estimate = sapply(results, function(x) x$estimate),
  SE = sapply(results, function(x) x$se),
  tau2 = sapply(results, function(x) x$heterogeneity$tau2),
  I2 = sapply(results, function(x) x$heterogeneity$I2)
)

print(comparison)
```

---

### Example 3: Comprehensive Sensitivity Analysis

```r
# Run extensive sensitivity analyses
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_estimator = "REML",
                     custom_pub_bias = c("egger", "begg", "trimfill", "petpeese"),
                     custom_sensitivity = c("loo", "cumulative", "influence", "baujat"),
                     custom_run_bayesian = TRUE,
                     custom_run_permutation = TRUE,
                     custom_n_permutations = 10000,
                     custom_run_fragility = TRUE,
                     verbose = TRUE)

# Create sensitivity table
sensitivity_table <- data.frame(
  Method = c("Primary", "Bayesian", "Permutation", "PET-PEESE"),
  Estimate = c(
    result$estimate,
    result$custom_results$bayesian$posterior_mean,
    NA,  # permutation gives p-value, not estimate
    result$custom_results$pub_bias_custom$petpeese$estimate
  ),
  P_value = c(
    result$pval,
    result$custom_results$bayesian$p_value,
    result$custom_results$permutation$p_value,
    result$custom_results$pub_bias_custom$petpeese$p_value
  )
)

print(sensitivity_table)
```

---

### Example 4: Replicating Published Analysis

```r
# Replicate Smith et al. (2020) who used:
# - Hedges' g
# - DL estimator
# - Egger's test only

result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "SMD",  # Hedges' g
                     custom_estimator = "DL",
                     custom_pub_bias = "egger",
                     custom_sensitivity = "loo",
                     verbose = TRUE)

# Compare to published results
published_estimate <- -0.523
published_ci <- c(-0.812, -0.234)

cat("Our estimate:", result$estimate, "\n")
cat("Published estimate:", published_estimate, "\n")
cat("Difference:", abs(result$estimate - published_estimate), "\n")
```

---

### Example 5: Minimal Custom (Just Change Estimator)

```r
# Use custom pathway just to specify ML instead of REML
# Everything else automatic
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_estimator = "ML")

# Equivalent to standard pathway but with ML
```

---

### Example 6: Maximum Custom (Full Control)

```r
# Specify EVERYTHING
result <- cbamm_auto(data,
                     pathway = "custom",
                     study_id = "study",

                     # Effect size & estimator
                     custom_effect_measure = "OR",
                     custom_estimator = "REML",

                     # Heterogeneity
                     custom_heterogeneity = c("quantile", "bootstrap"),

                     # Publication bias
                     custom_pub_bias = c("egger", "begg", "trimfill", "petpeese"),

                     # Sensitivity
                     custom_sensitivity = c("loo", "cumulative", "influence", "baujat"),

                     # Advanced methods
                     custom_run_bayesian = TRUE,
                     custom_run_permutation = TRUE,
                     custom_n_permutations = 5000,
                     custom_run_fragility = TRUE,

                     # Prior for Bayesian
                     custom_prior = list(mean = 0, sd = 0.5),

                     # Output
                     verbose = TRUE,
                     generate_rmd = FALSE)  # Don't generate Rmd for methodological work

# Access ALL results
names(result$custom_results)
```

---

## Accessing Custom Results

### Result Structure
```r
result$custom_results$
  ├─ heterogeneity_custom/      # Custom heterogeneity methods
  │  ├─ quantile                # Quantile-based results
  │  └─ bootstrap               # Bootstrap results
  ├─ pub_bias_custom/            # Custom publication bias
  │  ├─ egger                   # Egger's test
  │  ├─ begg                    # Begg's test
  │  ├─ trimfill                # Trim-and-fill
  │  ├─ petpeese                # PET-PEESE
  │  └─ selection               # Selection models
  ├─ sensitivity_custom/         # Custom sensitivity
  │  ├─ loo                     # Leave-one-out
  │  ├─ cumulative              # Cumulative MA
  │  ├─ influence               # Influence diagnostics
  │  └─ baujat                  # Baujat plot
  ├─ bayesian/                   # Bayesian results
  │  ├─ posterior_mean
  │  ├─ credible_interval
  │  └─ posterior_sd
  ├─ permutation/                # Permutation results
  │  ├─ p_value
  │  ├─ observed_statistic
  │  └─ null_distribution
  └─ fragility/                  # Fragility results
     ├─ index
     └─ interpretation
```

### Example Access
```r
# Get Bayesian posterior mean
result$custom_results$bayesian$posterior_mean

# Get PET-PEESE corrected estimate
result$custom_results$pub_bias_custom$petpeese$estimate

# Get permutation p-value
result$custom_results$permutation$p_value

# Get leave-one-out results
result$custom_results$sensitivity_custom$loo
```

---

## Decision Log

Custom pathway logs all decisions:

```r
# View decision log
result$decisions_log$pathway  # "custom"
result$decisions_log$effect_size_calculation  # Your custom measure
result$decisions_log$method_selection  # Your custom estimator

# Justifications
result$justification  # "User-specified (custom pathway)"
```

---

## Comparison Workflows

### Compare Standard vs Custom

```r
# Standard pathway (automated)
std <- cbamm_auto(data, pathway = "standard", verbose = FALSE, generate_rmd = FALSE)

# Custom pathway (manual)
custom <- cbamm_auto(data,
                     pathway = "custom",
                     custom_estimator = "REML",
                     verbose = FALSE,
                     generate_rmd = FALSE)

# Compare
cat("Standard estimate:", std$estimate, "\n")
cat("Custom estimate:", custom$estimate, "\n")
cat("Standard estimator:", std$estimator, "\n")
cat("Custom estimator:", custom$estimator, "\n")
```

### Compare Multiple Custom Configurations

```r
# Configuration 1: Conservative
config1 <- cbamm_auto(data,
                      pathway = "custom",
                      custom_estimator = "REML",
                      custom_pub_bias = c("egger", "begg", "trimfill"))

# Configuration 2: Robust
config2 <- cbamm_auto(data,
                      pathway = "custom",
                      custom_estimator = "SJ",  # Robust to outliers
                      custom_run_permutation = TRUE)

# Configuration 3: Bayesian
config3 <- cbamm_auto(data,
                      pathway = "custom",
                      custom_run_bayesian = TRUE)

# Compare conclusions
configs <- list(config1, config2, config3)
sapply(configs, function(x) x$pval < 0.05)  # All significant?
```

---

## Tips for Advanced Practitioners

### 1. **Start Minimal, Add as Needed**
```r
# Start with just changing estimator
result <- cbamm_auto(data, pathway = "custom", custom_estimator = "ML")

# If needed, add more customizations later
```

### 2. **Use Custom for Sensitivity**
```r
# Primary analysis: Standard pathway
primary <- cbamm_auto(data, pathway = "standard")

# Sensitivity: Custom pathway with different choices
sensitivity <- cbamm_auto(data,
                          pathway = "custom",
                          custom_estimator = "ML",
                          custom_run_permutation = TRUE)

# Report both
```

### 3. **Leverage Existing CBAMMR Functions**
```r
# Custom pathway uses CBAMMR's individual functions
# You can also call them directly:
es <- cbamm_calc_peto_or(ai, bi, ci, di)
ma <- cbamm_meta(es$yi, es$vi, method = "ML")
pb <- cbamm_pet_peese(es$yi, es$vi)

# Custom pathway automates this workflow
```

### 4. **Document Your Choices**
```r
# Custom pathway documents everything
result$decisions_log  # All decisions logged

# Methods statement for manuscript:
cat("Meta-analysis used", result$effect_size_measure,
    "with", result$estimator, "estimator.",
    "Rationale:", result$justification)
```

---

## When NOT to Use Custom Pathway

**Custom pathway requires expertise. Don't use if:**

1. **Unsure which estimator:** Use Standard (automated REML)
2. **Unsure which effect size:** Use Standard (auto-detects best)
3. **Want comprehensive exploration:** Use Advanced (runs all methods)
4. **Submitting to journal:** Use Standard (validated, accepted)
5. **Teaching students:** Start with Standard, graduate to Custom

**Remember:** Custom pathway = Maximum flexibility = Maximum responsibility

---

## Validation

Custom pathway uses the same validated core functions as Standard/Advanced pathways.

**What's validated:**
✅ Effect size calculations (100% match to metafor)
✅ Meta-analysis estimation (all estimators validated)
✅ Heterogeneity statistics (matches metafor)
✅ Publication bias tests (validated implementations)

**What's different:**
- Standard/Advanced: Automated decision rules
- Custom: YOU make decisions

**Your responsibility:**
- Choose appropriate methods
- Justify choices in manuscript
- Understand method assumptions
- Interpret results correctly

---

## Methods Statement Template

For manuscripts using custom pathway:

> "Meta-analyses were conducted using CBAMMR version 8.8.0 (Comprehensive Bayesian and Advanced Meta-Analysis Methods in R) with the custom pathway to implement our pre-specified analytical plan. [Specify your choices: We calculated {effect size measure} and meta-analyzed using random-effects models with {estimator} estimation. Publication bias was assessed using {methods}. Sensitivity analyses included {methods}. [If applicable: Bayesian analyses used {prior specification}. Permutation tests with {N} permutations provided exact p-values.]] All analytical choices were pre-specified prior to data analysis."

Example:
> "Meta-analyses were conducted using CBAMMR version 8.8.0 with the custom pathway. We calculated Peto odds ratios given the rarity of events (<1%) and meta-analyzed using random-effects models with ML estimation for robustness. Publication bias was assessed using Egger's test and PET-PEESE correction. Sensitivity analyses included leave-one-out analysis and permutation tests with 10,000 permutations. Bayesian analyses used weakly informative priors (normal distribution, mean=0, SD=0.5) with results confirming the frequentist findings. All analytical choices were pre-specified prior to data analysis."

---

## FAQ

**Q: Can I use custom pathway for journal submissions?**
A: Yes, but you must justify all choices. Standard pathway is easier for reviewers.

**Q: Can I combine custom parameters with standard decisions?**
A: Yes! Specify only what you want to control, rest is automated.

**Q: How do I know which estimator to use?**
A: REML is default recommendation. ML if convergence issues. SJ if outliers suspected.

**Q: Can I add methods not in CBAMMR?**
A: Use custom pathway to get effect sizes, then apply your custom methods to yi/vi.

**Q: Does custom pathway validate input?**
A: Yes - parameters are validated. Invalid choices will error with clear messages.

**Q: Can I save custom configurations?**
A: Yes:
```r
my_config <- list(
  pathway = "custom",
  custom_estimator = "ML",
  custom_pub_bias = c("egger", "petpeese")
)

result <- do.call(cbamm_auto, c(list(data = data), my_config))
```

**Q: Which pathway is fastest?**
A: Standard < Custom < Advanced (if you minimize custom methods)

---

## Summary

**Custom Pathway = Full Control**

**Use when:**
- You know exactly what you need
- Replicating published analyses
- Methodological comparison studies
- Advanced sensitivity analyses
- You're an expert practitioner

**Key benefits:**
- Complete flexibility
- Precise control
- Methodological transparency
- Research reproducibility

**Key requirement:**
- **YOU must understand the methods you choose**

---

## See Also

- **AUTHOR_GUIDE.md** - Basic usage, CSV formats
- **DUAL_PATHWAY_DESIGN.md** - Technical comparison of pathways
- **DUAL_PATHWAY_SUMMARY.md** - Quick overview

---

*Last updated: 2025-10-30*
*CBAMMR version: 8.8.0*
