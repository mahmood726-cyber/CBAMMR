# CBAMMR Dual-Pathway Design

## Overview

CBAMMR now offers two distinct pathways for different use cases:

### 1. Standard Pathway (Default)
**Target Users:** Researchers submitting to journals, clinicians, students
**Purpose:** Production-ready, validated, journal-quality meta-analyses
**Philosophy:** Conservative, well-established methods

### 2. Advanced Pathway
**Target Users:** Methodologists, advanced researchers, doctoral students
**Purpose:** Cutting-edge methods, methodological research, exploration
**Philosophy:** Innovative, distribution-free, Bayesian approaches

---

## Pathway Comparison

| Feature | Standard Pathway | Advanced Pathway |
|---------|-----------------|------------------|
| **Effect Sizes** | OR, RR, RD, SMD, MD | All 40+ metafor measures |
| **Estimation** | REML, DL | REML, ML, EB, SJ, HS, DL, PM |
| **Heterogeneity** | I², Q, tau², PI | + Distribution-free, Bayesian |
| **Publication Bias** | Egger, Begg, Trim-fill | + PET-PEESE, selection models |
| **Clinical Metrics** | Basic NNT | NNT + decision curves + individualized effects |
| **Survival Analysis** | Not included | RMST, quantile MA |
| **Bayesian Methods** | Not included | Full Bayesian suite |
| **Transportability** | Not included | Generalizability analysis |
| **Value of Info** | Not included | EVPI, threshold analysis |
| **Diagnostics** | Leave-one-out | + Fragility, permutation tests |
| **Meta-Learning** | Not included | Pattern recognition across MAs |
| **Output** | Journal-ready Rmd | Full technical report |

---

## Usage

### Standard Pathway (Default)
```r
# Simplest usage - standard pathway
result <- cbamm_auto(data)

# Explicit standard pathway
result <- cbamm_auto(data, pathway = "standard")

# With journal-style output
result <- cbamm_auto(data,
                     pathway = "standard",
                     rmd_style = "APA")
```

### Advanced Pathway
```r
# Advanced pathway with all methods
result <- cbamm_auto(data, pathway = "advanced")

# Advanced with specific methods
result <- cbamm_auto(data,
                     pathway = "advanced",
                     include_bayesian = TRUE,
                     include_transportability = TRUE)
```

---

## Standard Pathway Details

### What's Included
1. **Data Detection:** Automatic data type recognition
2. **Effect Sizes:**
   - Binary: OR, RR, RD (with rare event detection)
   - Continuous: SMD (Hedges' g), MD
3. **Meta-Analysis:** Random-effects (REML) with DL sensitivity
4. **Heterogeneity:** I², Q-test, tau², prediction intervals
5. **Publication Bias:** Egger's test, Begg's test, trim-and-fill
6. **Diagnostics:** Leave-one-out, cumulative MA
7. **Quality Assessment:** Study quality scoring
8. **Subgroup Analysis:** If moderators provided
9. **Meta-Regression:** If continuous moderators provided
10. **Visualizations:** Forest plot, funnel plot, PRISMA diagram
11. **Output:** Publication-ready R Markdown

### What's Excluded
- Distribution-free methods
- Bayesian approaches
- Transportability analysis
- Advanced survival methods (RMST)
- Value of information analysis
- Fragility indices
- Permutation tests
- Meta-learning
- Exotic effect sizes (>90% of researchers don't need these)

### Decision Logic
```
Standard pathway prioritizes:
1. Widely accepted methods (cited in Cochrane Handbook)
2. Methods taught in standard meta-analysis courses
3. Methods accepted by high-impact journals
4. Methods with clear interpretation
5. Computational efficiency
```

---

## Advanced Pathway Details

### What's Included
**Everything in Standard PLUS:**

1. **Distribution-Free Methods:**
   - Quantile-based heterogeneity
   - Rank-based meta-analysis
   - Non-parametric bootstrap

2. **Bayesian Methods:**
   - Bayesian meta-analysis
   - Prior sensitivity analysis
   - Posterior predictive checks

3. **Clinical Decision Tools:**
   - NNT with confidence intervals
   - Decision curve analysis
   - Individualized treatment effects

4. **Survival Analysis:**
   - RMST meta-analysis
   - Quantile meta-analysis
   - Time-varying effects

5. **Transportability:**
   - External validity assessment
   - Generalizability indices
   - Transport weights

6. **Value of Information:**
   - EVPI (Expected Value of Perfect Information)
   - Threshold analysis
   - Research prioritization

7. **Advanced Diagnostics:**
   - Fragility index
   - Permutation tests
   - Influence diagnostics

8. **Meta-Learning:**
   - Pattern recognition
   - Cross-MA learning
   - Automated insights

9. **Exotic Effect Sizes:**
   - All 40+ metafor measures
   - Custom effect sizes
   - Transformation flexibility

### Decision Logic
```
Advanced pathway prioritizes:
1. Methodological innovation
2. Robustness to assumptions
3. Maximum information extraction
4. Exploration over confirmation
5. Comprehensive sensitivity analysis
```

---

## CSV Format Requirements

### General Rules
1. First row = column names
2. One row per study
3. No merged cells
4. No formatting (plain text/numbers only)
5. Missing values = leave blank or use NA
6. UTF-8 encoding recommended

---

## CSV Format Examples by Data Type

### 1. Binary Outcomes (2x2 Table Format)

**Required columns:**
- `ai` = Events in treatment group
- `bi` = Non-events in treatment group
- `ci` = Events in control group
- `di` = Non-events in control group

**Optional columns:**
- `study` = Study name or author
- `year` = Publication year
- `quality` = Quality score (0-10)

**Example CSV:**
```csv
study,year,ai,bi,ci,di,quality
Smith 2020,2020,15,85,25,75,8
Jones 2019,2019,8,92,18,82,7
Brown 2021,2021,22,178,35,165,9
Wilson 2018,2018,5,45,12,38,6
Davis 2022,2022,31,269,48,252,8
```

**R code to read:**
```r
data <- read.csv("binary_data.csv")
result <- cbamm_auto(data, study_id = "study")
```

---

### 2. Binary Outcomes (Summary Format)

**Required columns:**
- `events_treat` = Events in treatment
- `n_treat` = Total in treatment
- `events_control` = Events in control
- `n_control` = Total in control

**Example CSV:**
```csv
study,year,events_treat,n_treat,events_control,n_control
Trial A,2020,15,100,25,100
Trial B,2019,8,100,18,100
Trial C,2021,22,200,35,200
```

**R code to read:**
```r
data <- read.csv("binary_summary.csv")

# Convert to 2x2 format
data$ai <- data$events_treat
data$bi <- data$n_treat - data$events_treat
data$ci <- data$events_control
data$di <- data$n_control - data$events_control

result <- cbamm_auto(data, study_id = "study")
```

---

### 3. Continuous Outcomes (Summary Statistics)

**Required columns:**
- `mean_treat` = Mean in treatment group
- `sd_treat` = SD in treatment group
- `n_treat` = Sample size in treatment
- `mean_control` = Mean in control group
- `sd_control` = SD in control group
- `n_control` = Sample size in control

**Example CSV:**
```csv
study,year,mean_treat,sd_treat,n_treat,mean_control,sd_control,n_control,quality
Smith 2020,2020,12.5,3.2,50,15.8,3.5,48,8
Jones 2019,2019,10.2,2.8,65,13.1,3.1,62,7
Brown 2021,2021,11.8,3.0,120,14.5,3.2,118,9
Wilson 2018,2018,13.2,3.8,35,16.1,4.0,33,6
Davis 2022,2022,9.8,2.5,90,12.7,2.9,88,8
```

**R code to read:**
```r
data <- read.csv("continuous_data.csv")
result <- cbamm_auto(data, study_id = "study")
```

---

### 4. Pre-Calculated Effect Sizes

**Required columns:**
- `yi` = Effect size (log OR, SMD, etc.)
- `vi` = Variance of effect size

**Optional columns:**
- `sei` = Standard error (instead of vi)
- `measure` = Effect size type ("OR", "SMD", etc.)

**Example CSV:**
```csv
study,year,yi,vi,quality
Study 1,2020,-0.523,0.045,8
Study 2,2019,-0.812,0.068,7
Study 3,2021,-0.345,0.032,9
Study 4,2018,-0.678,0.091,6
Study 5,2022,-0.456,0.038,8
```

**R code to read:**
```r
data <- read.csv("effect_sizes.csv")
result <- cbamm_auto(data, study_id = "study")
```

---

### 5. Correlation Coefficients

**Required columns:**
- `ri` = Correlation coefficient
- `ni` = Sample size

**Example CSV:**
```csv
study,year,ri,ni
Smith 2020,2020,0.45,120
Jones 2019,2019,0.38,95
Brown 2021,2021,0.52,180
Wilson 2018,2018,0.41,75
```

**R code to read:**
```r
data <- read.csv("correlations.csv")

# Calculate Fisher's z and variance
data$yi <- 0.5 * log((1 + data$ri) / (1 - data$ri))
data$vi <- 1 / (data$ni - 3)

result <- cbamm_auto(data, study_id = "study")
```

---

### 6. With Moderators (Subgroup Analysis)

**Add moderator columns to any format above:**

**Example CSV:**
```csv
study,year,ai,bi,ci,di,country,risk_of_bias,dose
Smith 2020,2020,15,85,25,75,USA,low,100
Jones 2019,2019,8,92,18,82,UK,low,100
Brown 2021,2021,22,178,35,165,Canada,high,200
Wilson 2018,2018,5,45,12,38,USA,high,100
Davis 2022,2022,31,269,48,252,UK,low,200
```

**R code for subgroup analysis:**
```r
data <- read.csv("with_moderators.csv")

# Automatic analysis
result <- cbamm_auto(data, study_id = "study")

# Or specify moderators
result_subgroup <- cbamm_subgroup(
  yi = result$yi,
  vi = result$vi,
  moderator = data$country
)
```

---

## Common CSV Pitfalls & Solutions

### Problem 1: Excel Date Conversion
**Issue:** Excel converts "2020" to dates
**Solution:**
- Format year column as "Text" in Excel before entering data
- Or add apostrophe: '2020

### Problem 2: Decimal Separators
**Issue:** Some countries use comma (3,14) instead of period (3.14)
**Solution:**
```r
data <- read.csv("data.csv", dec = ",")
```

### Problem 3: Missing Values
**Issue:** Blank cells or "NA" text
**Solution:** Both work! CBAMMR handles blanks and NA

### Problem 4: Study Names with Commas
**Issue:** "Smith, Jones 2020" breaks CSV
**Solution:**
```csv
study,year,ai,bi,ci,di
"Smith, Jones 2020",2020,15,85,25,75
```
(Use quotes around names with commas)

### Problem 5: Special Characters
**Issue:** Study names with ñ, é, ü, etc.
**Solution:** Save as UTF-8:
```r
write.csv(data, "data.csv", fileEncoding = "UTF-8")
data <- read.csv("data.csv", fileEncoding = "UTF-8")
```

---

## Quick Start Templates

### Template 1: Binary Outcomes
```csv
study,year,ai,bi,ci,di,quality
Study 1,2020,,,,,
Study 2,2021,,,,,
Study 3,2019,,,,,
```

### Template 2: Continuous Outcomes
```csv
study,year,mean_treat,sd_treat,n_treat,mean_control,sd_control,n_control,quality
Study 1,2020,,,,,,,
Study 2,2021,,,,,,,
Study 3,2019,,,,,,,
```

### Template 3: Effect Sizes
```csv
study,year,yi,vi,quality
Study 1,2020,,,
Study 2,2021,,,
Study 3,2019,,,
```

---

## Validation Check

After importing your CSV, run this quick check:

```r
# Read data
data <- read.csv("your_data.csv")

# Check structure
str(data)

# Check for missing values
summary(data)

# Check column names
names(data)

# View first few rows
head(data)

# If everything looks good, run CBAMMR
result <- cbamm_auto(data, pathway = "standard")
```

---

## Complete Example Workflow

```r
# 1. Create CSV file in Excel/Numbers/Google Sheets
#    Save as: my_meta_analysis.csv

# 2. Read into R
library(CBAMMR)
data <- read.csv("my_meta_analysis.csv")

# 3. Quick check
head(data)
str(data)

# 4. Run standard pathway (journal submission)
result <- cbamm_auto(data,
                     pathway = "standard",
                     study_id = "study",
                     rmd_style = "APA",
                     verbose = TRUE)

# 5. Review results
print(result)
plot(result)

# 6. Output saved as "results.Rmd"
#    Open and copy into your manuscript!

# Optional: Advanced pathway for exploration
result_advanced <- cbamm_auto(data,
                              pathway = "advanced",
                              study_id = "study")
```

---

## Need Help?

**Common questions:**
1. "Which columns do I need?" → See format examples above
2. "Can I have extra columns?" → Yes! CBAMMR ignores unused columns
3. "What about missing data?" → Leave blank or use NA
4. "Which pathway should I use?" → Standard for journal, Advanced for research
5. "Can I switch pathways later?" → Yes! Just re-run with different pathway

**Troubleshooting:**
```r
# If cbamm_auto() gives an error, run diagnostics:
.detect_data_type(data, study_id = "study", verbose = TRUE)
```

This will tell you exactly what CBAMMR detected and what's missing.
