# CBAMMR Complete Effect Sizes Guide

**All Supported Summary Measures**

CBAMMR supports **all 40+ effect size measures from metafor** plus additional measures. You can use any of these measures in the custom pathway or CBAMMR will auto-select the appropriate one in standard/advanced pathways.

---

## Quick Reference by Data Type

| Data Type | Common Measures | When to Use |
|-----------|----------------|-------------|
| **Binary** | OR, RR, RD, Peto | RCTs with binary outcomes |
| **Continuous** | SMD, MD, ROM | RCTs with continuous outcomes |
| **Correlations** | ZCOR, COR | Association studies |
| **Proportions** | PLO, PFT | Single-arm studies |
| **Rates** | IRLN, IRFT | Incidence/time-to-event |
| **Pre-Post** | SMCC, SMCR | Within-subject designs |

---

## Binary Outcome Measures

### 1. **Odds Ratio (OR / LogOR)**

**Formula:** OR = (a × d) / (b × c)

**When to use:**
- ✅ Case-control studies
- ✅ Logistic regression results
- ✅ Common in medical research
- ⚠️ NOT for rare events (<1%) - use Peto OR instead

**CSV format:**
```csv
study,ai,bi,ci,di
Study 1,15,85,25,75
```

**R code:**
```r
# Auto-select
result <- cbamm_auto(data)

# Custom pathway - specify OR
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "OR")
```

**Interpretation:**
- OR = 1: No effect
- OR > 1: Increased odds in treatment
- OR < 1: Decreased odds in treatment

---

### 2. **Risk Ratio (RR / LogRR)**

**Formula:** RR = [a/(a+b)] / [c/(c+d)]

**When to use:**
- ✅ Cohort studies
- ✅ RCTs
- ✅ More intuitive than OR
- ✅ Better for common outcomes (>10%)

**CSV format:** Same as OR

**R code:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "RR")
```

**Interpretation:**
- RR = 1: No effect
- RR > 1: Increased risk in treatment
- RR < 1: Decreased risk (protective)

---

### 3. **Risk Difference (RD)**

**Formula:** RD = [a/(a+b)] - [c/(c+d)]

**When to use:**
- ✅ Public health (absolute risk reduction)
- ✅ NNT calculations
- ✅ Policy decisions

**R code:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "RD")
```

**Interpretation:**
- RD = 0: No effect
- RD > 0: Increased risk
- RD < 0: Risk reduction

**Note:** RD is on absolute scale, easier for public to understand

---

### 4. **Peto Odds Ratio (Peto / PETO)**

**When to use:**
- ✅ **Rare events (<1%)**
- ✅ Adverse events
- ✅ Mortality in low-risk populations
- ✅ Sparse data (many zero cells)

**Why Peto?**
- Less biased for rare events
- Doesn't need continuity corrections
- Recommended by Cochrane for rare events

**CSV format:** Same as OR

**R code:**
```r
# CBAMMR auto-detects rare events and switches to Peto
result <- cbamm_auto(data)  # Auto-switches if <1%

# Force Peto OR
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "Peto")
```

---

### 5. **Other Binary Measures**

| Measure | Description | Use Case |
|---------|-------------|----------|
| `AS` | Arcsine square root RD | Variance stabilization |
| `PBIT` | Probit transformed RD | Alternative to AS |
| `OR2D` | OR to standardized MD | Converting to SMD |
| `OR2DN` | OR to SMD (normal) | Normal approximation |
| `OR2DL` | OR to SMD (logistic) | Logistic approximation |

---

## Continuous Outcome Measures

### 1. **Standardized Mean Difference (SMD / Hedges' g)**

**Formula:** SMD = (M1 - M2) / SD_pooled × correction

**When to use:**
- ✅ **Different scales across studies**
- ✅ Depression scores (BDI, HAMD, etc.)
- ✅ Quality of life (different instruments)
- ✅ Most common in meta-analysis

**CSV format:**
```csv
study,mean_treat,sd_treat,n_treat,mean_control,sd_control,n_control
Study 1,12.5,3.2,50,15.8,3.5,48
```

**R code:**
```r
# Auto-select (chooses SMD for different scales)
result <- cbamm_auto(data)

# Explicit
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "SMD")
```

**Interpretation (Cohen's benchmarks):**
- |SMD| < 0.2: Negligible
- |SMD| 0.2-0.5: Small
- |SMD| 0.5-0.8: Medium
- |SMD| > 0.8: Large

**Note:** CBAMMR uses Hedges' g (bias-corrected)

---

### 2. **Mean Difference (MD)**

**Formula:** MD = M1 - M2

**When to use:**
- ✅ **Same scale across studies**
- ✅ Blood pressure (mmHg)
- ✅ Weight (kg)
- ✅ Lab values (same units)

**CSV format:** Same as SMD

**R code:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "MD")
```

**Interpretation:**
- Direct units (e.g., -5 mmHg reduction)
- Clinically meaningful thresholds
- Easier for clinicians

---

### 3. **Ratio of Means (ROM / LogROM)**

**Formula:** ROM = M1 / M2

**When to use:**
- ✅ Skewed data
- ✅ Ratios make sense (costs, lengths)
- ✅ Multiplicative effects

**R code:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "ROM")
```

---

### 4. **Response Ratio (RPB / RBIS)**

**For special continuous data types**

| Measure | Description | Use Case |
|---------|-------------|----------|
| `RPB` | Point-biserial correlation | Binary predictor, continuous outcome |
| `RBIS` | Biserial correlation | Dichotomized continuous predictor |
| `D2OR` | SMD to OR | Converting effect sizes |
| `D2ORN` | SMD to OR (normal) | Normal approximation |
| `D2ORL` | SMD to OR (logistic) | Logistic approximation |

---

## Correlation Measures

### 1. **Fisher's Z-transformed Correlation (ZCOR)**

**Formula:** z = 0.5 × ln[(1+r)/(1-r)]

**When to use:**
- ✅ **Meta-analysis of correlations**
- ✅ Association studies
- ✅ Variance stabilization

**CSV format:**
```csv
study,ri,ni
Study 1,0.45,120
Study 2,0.38,95
```

**R code:**
```r
# CBAMMR auto-detects correlation data
data$yi <- 0.5 * log((1 + data$ri) / (1 - data$ri))
data$vi <- 1 / (data$ni - 3)

result <- cbamm_auto(data)

# Or use escalc
library(metafor)
es <- escalc(measure = "ZCOR", ri = ri, ni = ni, data = data)
result <- cbamm_auto(es)
```

**Interpretation:**
- Transform back: r = (exp(2z) - 1) / (exp(2z) + 1)
- |r| < 0.3: Weak
- |r| 0.3-0.5: Moderate
- |r| > 0.5: Strong

---

### 2. **Raw Correlation (COR)**

**When to use:**
- ✅ Reporting untransformed
- ⚠️ Less stable for meta-analysis

**R code:**
```r
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "COR")
```

---

### 3. **Other Correlation Measures**

| Measure | Description | Use Case |
|---------|-------------|----------|
| `UCOR` | Uncorrected correlation | No sample size correction |
| `RTET` | Tetrachoric correlation | Both variables binary |
| `ZTET` | Fisher's Z (tetrachoric) | Meta-analysis of tetrachoric |

---

## Single Proportion Measures

**For single-arm studies (no control group)**

### 1. **Log Odds (PLO)**

**When to use:**
- ✅ Prevalence studies
- ✅ Response rates

**CSV format:**
```csv
study,xi,ni
Study 1,45,100
Study 2,52,120
```

**R code:**
```r
es <- escalc(measure = "PLO", xi = xi, ni = ni, data = data)
result <- cbamm_auto(es)
```

---

### 2. **Other Proportion Measures**

| Measure | Description | Best For |
|---------|-------------|----------|
| `PR` | Raw proportion | Simple pooling |
| `PLN` | Log proportion | Rare events |
| `PAS` | Arcsine transformed | Variance stabilization |
| `PFT` | Freeman-Tukey double arcsine | Near 0 or 1 |

---

## Incidence Rate Measures

**For time-to-event / person-time data**

| Measure | Description | CSV Format |
|---------|-------------|------------|
| `IR` | Raw incidence rate | xi (events), ti (person-time) |
| `IRLN` | Log incidence rate | Most common |
| `IRS` | Square root transformed | Variance stabilization |
| `IRFT` | Freeman-Tukey transformed | Near-zero rates |

**CSV format:**
```csv
study,xi,ti
Study 1,15,1000
Study 2,8,850
```

**R code:**
```r
es <- escalc(measure = "IRLN", xi = xi, ti = ti, data = data)
result <- cbamm_auto(es)
```

---

## Pre-Post / Change Score Measures

**For within-subject designs**

### 1. **Standardized Mean Change (SMCC)**

**When to use:**
- ✅ Pre-post designs
- ✅ Controlled change scores

**CSV format:**
```csv
study,m1i,m2i,sd1i,ni,ri
Study 1,15.2,12.3,3.5,50,0.7
```
(ri = pre-post correlation, often 0.5-0.7)

**R code:**
```r
es <- escalc(measure = "SMCC",
             m1i = m1i, m2i = m2i,
             sd1i = sd1i, ni = ni, ri = ri,
             data = data)
result <- cbamm_auto(es)
```

---

### 2. **Other Change Measures**

| Measure | Description | Use Case |
|---------|-------------|----------|
| `MC` | Mean change | Raw units |
| `SMCR` | SMD for change (raw) | Different scales |
| `SMCRH` | SMD for change (Hedges) | Bias-corrected |
| `ROMC` | Ratio of mean changes | Skewed data |

---

## Alpha / Reliability Measures

**For reliability/agreement studies**

| Measure | Description | Use Case |
|---------|-------------|----------|
| `ARAW` | Raw alpha | Cronbach's alpha |
| `AHW` | Transformed alpha | Variance stabilization |
| `ABT` | Bonett-transformed | Better properties |

---

## Complete List of All Measures

### Binary Outcomes (2x2 tables)
1. `OR` - Odds ratio (log)
2. `RR` - Risk ratio (log)
3. `RD` - Risk difference
4. `AS` - Arcsine square root RD
5. `PETO` - Peto odds ratio
6. `PBIT` - Probit RD
7. `OR2D` - OR to SMD
8. `OR2DN` - OR to SMD (normal)
9. `OR2DL` - OR to SMD (logistic)

### Continuous Outcomes (means/SDs)
10. `MD` - Mean difference (raw)
11. `SMD` - Standardized MD (Hedges' g)
12. `SMDH` - Hedges' g
13. `ROM` - Ratio of means (log)
14. `RPB` - Point-biserial correlation
15. `RBIS` - Biserial correlation
16. `D2OR` - SMD to OR
17. `D2ORN` - SMD to OR (normal)
18. `D2ORL` - SMD to OR (logistic)

### Correlations
19. `COR` - Raw correlation
20. `UCOR` - Uncorrected correlation
21. `ZCOR` - Fisher's z
22. `RTET` - Tetrachoric correlation
23. `ZTET` - Fisher's z (tetrachoric)

### Single Proportions
24. `PR` - Raw proportion
25. `PLN` - Log proportion
26. `PLO` - Log odds
27. `PAS` - Arcsine transformed
28. `PFT` - Freeman-Tukey transformed

### Incidence Rates
29. `IR` - Raw incidence rate
30. `IRLN` - Log incidence rate
31. `IRS` - Square root transformed
32. `IRFT` - Freeman-Tukey transformed

### Pre-Post Changes
33. `MC` - Mean change
34. `SMCC` - Standardized mean change (controlled)
35. `SMCR` - Standardized mean change (raw)
36. `SMCRH` - Standardized mean change (Hedges)
37. `ROMC` - Ratio of mean changes

### Reliability/Agreement
38. `ARAW` - Raw alpha
39. `AHW` - Transformed alpha
40. `ABT` - Bonett-transformed alpha

---

## How to Choose

### Decision Tree

```
Is your data:

├─ Binary outcomes (event/no event)?
│  ├─ Events < 1%? → Peto OR
│  ├─ Case-control? → OR
│  ├─ Cohort/RCT? → RR (or OR)
│  └─ Need absolute risk? → RD
│
├─ Continuous outcomes (means/SDs)?
│  ├─ Same scale? → MD
│  ├─ Different scales? → SMD (Hedges' g)
│  └─ Skewed/ratio? → ROM
│
├─ Correlations?
│  └─ → ZCOR (Fisher's z)
│
├─ Single proportions (no control)?
│  ├─ Common (10-90%)? → PFT
│  └─ Rare? → PLO
│
├─ Incidence rates (person-time)?
│  └─ → IRLN (log rate)
│
└─ Pre-post design?
   └─ → SMCC or SMCR
```

---

## Usage Examples

### Example 1: Auto-Detection (Recommended)
```r
# CBAMMR detects data type and chooses appropriate measure
data <- read.csv("binary_data.csv")  # Has ai, bi, ci, di
result <- cbamm_auto(data)  # Automatically chooses OR or RR
```

### Example 2: Custom Pathway - Specify Measure
```r
# You choose the exact measure
data <- read.csv("adverse_events.csv")  # Rare events
result <- cbamm_auto(data,
                     pathway = "custom",
                     custom_effect_measure = "Peto")  # Force Peto OR
```

### Example 3: Using escalc Directly
```r
library(metafor)

# Calculate effect sizes first
es <- escalc(measure = "ZCOR",  # Fisher's z
             ri = correlation,
             ni = sample_size,
             data = mydata)

# Then meta-analyze
result <- cbamm_auto(es)
```

### Example 4: Pre-calculated Effect Sizes
```r
# You already have yi and vi
data <- read.csv("precalculated.csv")  # Has yi, vi columns
result <- cbamm_auto(data)  # Uses pre-calculated values
```

---

## Forest Plot Options

All effect sizes work with all forest plot styles:

```r
# Metafor style (publication quality)
result <- cbamm_auto(data, forest_style = "metafor")
plot(result)

# Meta package style (European preference)
result <- cbamm_auto(data, forest_style = "meta")
plot(result)

# ggplot2 style (customizable)
result <- cbamm_auto(data, forest_style = "ggplot")
plot(result)

# Auto-select based on number of studies
result <- cbamm_auto(data, forest_style = "auto")
```

---

## References

1. **Borenstein et al. (2009).** Introduction to Meta-Analysis. Wiley.
2. **Cochrane Handbook (2023).** Chapter 10: Analysing data and undertaking meta-analyses.
3. **Viechtbauer (2010).** Conducting meta-analyses in R with the metafor package. J Stat Softw, 36(3).

---

## Quick Lookup Table

| Your Data | CSV Columns | Effect Size | Forest Style |
|-----------|-------------|-------------|--------------|
| RCT, binary | ai,bi,ci,di | OR or RR | metafor |
| RCT, continuous (different scales) | m1,sd1,n1,m2,sd2,n2 | SMD | metafor |
| RCT, continuous (same scale) | m1,sd1,n1,m2,sd2,n2 | MD | metafor |
| Adverse events (<1%) | ai,bi,ci,di | Peto | metafor |
| Correlations | ri,ni | ZCOR | meta |
| Single proportions | xi,ni | PLO or PFT | meta |
| Already calculated | yi,vi | (use as is) | any |

---

## FAQ

**Q: Which is better, OR or RR?**
A: RR is more intuitive but OR is standard in case-control studies. For RCTs, either works.

**Q: When should I use Peto OR?**
A: Always for rare events (<1%). CBAMMR auto-detects this.

**Q: SMD vs MD?**
A: SMD when scales differ (e.g., different depression scales). MD when same scale (e.g., all mmHg).

**Q: Do I need to calculate effect sizes manually?**
A: No! CBAMMR auto-calculates from raw data. Just provide CSV with the right columns.

**Q: Can I use custom transformations?**
A: Yes, in custom pathway you can specify any metafor measure.

**Q: Which forest plot style is best?**
A: metafor for publications, meta for European journals, ggplot for presentations. Use "auto" if unsure.

---

*Last updated: 2025-10-30*
*CBAMMR version: 8.8.0*
