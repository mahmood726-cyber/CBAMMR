# CBAMMR Statistical Methods Documentation

**Package:** CBAMMR v9.0.0
**Date:** November 5, 2025
**Purpose:** Formal documentation of statistical methods and decision algorithms

---

## 1. INTRODUCTION

### 1.1 Package Scope

CBAMMR is an integrated workflow package for meta-analysis that builds on established statistical software (metafor, meta, RoBMA). It does not implement novel statistical estimators but rather:

1. **Integrates** existing methods into streamlined workflows
2. **Standardizes** common analytical decisions
3. **Extends** functionality with clinical decision tools and transportability analysis

### 1.2 Foundational Packages

All core statistical methods rely on peer-reviewed implementations:

- **metafor** (Viechtbauer, 2010): Effect size calculation, meta-analysis models, heterogeneity estimation
- **meta** (Schwarzer, 2007): Alternative meta-analysis framework, network meta-analysis integration
- **RoBMA** (Bartoš et al., 2022): Bayesian model averaging for publication bias
- **brms** (Bürkner, 2017): Bayesian meta-regression and multilevel models
- **weightr** (Coburn & Vevea, 2019): Selection models for publication bias

###  1.3 Key References

**Core methodology:**
- Viechtbauer W. (2010). Conducting meta-analyses in R with the metafor package. *Journal of Statistical Software*, 36(3), 1-48.
- Schwarzer G, Carpenter JR, Rücker G. (2015). *Meta-Analysis with R*. Springer.
- Borenstein M, et al. (2009). *Introduction to Meta-Analysis*. Wiley.

**Advanced methods:**
- Bartoš F, et al. (2022). Robust Bayesian meta-analysis. *Psychological Methods*, 27(3), 407-431.
- Hedges LV, Vevea JL. (1998). Fixed- and random-effects models in meta-analysis. *Psychological Methods*, 3(4), 486-504.
- DerSimonian R, Laird N. (1986). Meta-analysis in clinical trials. *Controlled Clinical Trials*, 7(3), 177-188.

---

## 2. EFFECT SIZE CALCULATION

### 2.1 Binary Outcomes

CBAMMR wraps `metafor::escalc()` for all effect size calculations. Supported measures for binary (2×2 table) data:

#### Odds Ratio (OR)
$$OR = \frac{a/b}{c/d} = \frac{ad}{bc}$$
$$\log(OR) = \log(a) + \log(d) - \log(b) - \log(c)$$
$$Var[\log(OR)] = \frac{1}{a} + \frac{1}{b} + \frac{1}{c} + \frac{1}{d}$$

**When to use:** Case-control studies, rare outcomes, logistic regression context

#### Risk Ratio (RR)
$$RR = \frac{a/(a+b)}{c/(c+d)}$$
$$\log(RR) = \log(a) - \log(a+b) - \log(c) + \log(c+d)$$

**When to use:** Cohort studies, clinical trials with binary outcomes

#### Risk Difference (RD)
$$RD = \frac{a}{a+b} - \frac{c}{c+d}$$

**When to use:** Absolute risk reduction, number needed to treat (NNT) calculations

#### Peto Odds Ratio
For rare events (cell frequencies < 5):
$$OR_{Peto} = \exp\left(\frac{\sum O_i - E_i}{\sum V_i}\right)$$

**When to use:** Sparse data, zero cells in some studies

### 2.2 Continuous Outcomes

#### Standardized Mean Difference (SMD/Cohen's d)
$$d = \frac{\bar{X}_1 - \bar{X}_2}{S_{pooled}}$$
$$S_{pooled} = \sqrt{\frac{(n_1-1)S_1^2 + (n_2-1)S_2^2}{n_1 + n_2 - 2}}$$

**Hedge's g correction for small samples:**
$$g = d \times \left(1 - \frac{3}{4(n_1 + n_2 - 2) - 1}\right)$$

**When to use:** Different measurement scales across studies

#### Raw Mean Difference (MD)
$$MD = \bar{X}_1 - \bar{X}_2$$

**When to use:** Same measurement scale across studies

### 2.3 Correlation Coefficients

#### Fisher's z-transformation
$$z = \frac{1}{2}\log\left(\frac{1+r}{1-r}\right) = \text{arctanh}(r)$$
$$Var(z) = \frac{1}{n-3}$$

**When to use:** Meta-analysis of correlation coefficients

### 2.4 Handling Zero Cells

When cells contain zeros, continuity correction is applied:

**Continuity correction (default: 0.5):**
$$a' = a + \delta, \quad b' = b + \delta, \quad c' = c + \delta, \quad d' = d + \delta$$

**Options:**
- `to = "only0"`: Add correction only to studies with zero cells (default)
- `to = "all"`: Add correction to all studies
- `to = "none"`: No correction (may produce undefined values)

---

## 3. META-ANALYSIS MODELS

### 3.1 Fixed-Effects Model

**Inverse-variance weighted mean:**
$$\hat{\theta}_{FE} = \frac{\sum w_i y_i}{\sum w_i}$$

where $w_i = 1/v_i$ (precision weights)

**Variance:**
$$Var(\hat{\theta}_{FE}) = \frac{1}{\sum w_i}$$

**When to use:**
- Homogeneous studies (I² < 25%)
- Interest in included studies only
- NOT recommended for most applications (Borenstein et al., 2010)

### 3.2 Random-Effects Model

**DerSimonian-Laird (1986) formulation:**
$$\hat{\theta}_{RE} = \frac{\sum w_i^* y_i}{\sum w_i^*}$$

where $w_i^* = 1/(v_i + \hat{\tau}^2)$

**Between-study variance ($\tau^2$) estimation methods:**

#### REML (Restricted Maximum Likelihood) - **Recommended default**
Maximizes:
$$L(\tau^2) = -\frac{1}{2}\left[\log|\mathbf{V}| + (\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}})'\mathbf{V}^{-1}(\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}}) + \log|\mathbf{X}'\mathbf{V}^{-1}\mathbf{X}|\right]$$

**Properties:**
- Less biased than ML for small samples
- Generally preferred for inference
- Default in metafor and CBAMMR

#### DerSimonian-Laird (DL)
$$\hat{\tau}^2_{DL} = \max\left(0, \frac{Q - (k-1)}{\sum w_i - \frac{\sum w_i^2}{\sum w_i}}\right)$$

where $Q = \sum w_i(y_i - \hat{\theta}_{FE})^2$

**Properties:**
- Simple, non-iterative
- Can underestimate τ² (Veroniki et al., 2016)
- Historical standard, still widely used

#### Other Estimators Available
- **ML**: Maximum likelihood
- **EB**: Empirical Bayes
- **SJ**: Sidik-Jonkman
- **HS**: Hunter-Schmidt
- **PM**: Paule-Mandel

**Selection in CBAMMR:**
- Standard pathway: REML (default)
- Advanced pathway: Multiple estimators compared via AIC/BIC
- Custom pathway: User-specified

### 3.3 Hartung-Knapp-Sidik-Jonkman (HKSJ) Adjustment

**Problem:** Standard RE variance can underestimate uncertainty in small meta-analyses

**Solution (Hartung & Knapp, 2001):**

Adjusted variance:
$$Var^*(\hat{\theta}_{RE}) = Var(\hat{\theta}_{RE}) \times \frac{Q}{k-1}$$

Confidence intervals use t-distribution with k-1 degrees of freedom instead of normal distribution.

**When to use:**
- k < 30 studies
- Concern about small-sample bias
- **CBAMMR default for standard pathway**

### 3.4 Prediction Intervals

**95% Prediction Interval for new study:**
$$\hat{\theta} \pm t_{k-2, 0.975} \times \sqrt{Var(\hat{\theta}) + \hat{\tau}^2}$$

**Interpretation:** Expected range of effects in 95% of similar future studies

**Difference from CI:**
- CI: Uncertainty about mean effect
- PI: Dispersion of true effects across studies

---

## 4. HETEROGENEITY ASSESSMENT

### 4.1 Cochran's Q Test

**Test statistic:**
$$Q = \sum_{i=1}^k w_i(y_i - \hat{\theta}_{FE})^2$$

Under homogeneity: $Q \sim \chi^2_{k-1}$

**Limitations:**
- Low power with few studies
- High power (overly sensitive) with many studies
- Significance doesn't indicate magnitude

### 4.2 I² Statistic (Higgins & Thompson, 2002)

$$I^2 = \max\left(0, \frac{Q - (k-1)}{Q} \times 100\%\right)$$

**Interpretation:**
- I² < 25%: Low heterogeneity
- I² = 25-50%: Moderate heterogeneity
- I² = 50-75%: Substantial heterogeneity
- I² > 75%: Considerable heterogeneity

**Advantages:**
- Intuitive interpretation (% of variance due to heterogeneity)
- Not affected by number of studies or measurement scale

**Limitations:**
- Uncertainty not always reported
- Can be misleading with very small or very large meta-analyses

### 4.3 τ² (Tau-squared)

**Between-study variance on original scale**

**Interpretation depends on effect size:**
- SMD: τ² = 0.04 (small), 0.09 (medium), 0.16 (large)
- Log OR: τ² = 0.01 (small), 0.04 (medium), 0.09 (large)

### 4.4 H² Statistic

$$H^2 = \frac{Q}{k-1}$$

**Interpretation:**
- H² = 1: No heterogeneity
- H² > 1: Heterogeneity present

---

## 5. PUBLICATION BIAS ASSESSMENT

### 5.1 Funnel Plot Asymmetry

**Visual inspection:**
- Plot: Effect size (y-axis) vs. Standard error (x-axis)
- Expected: Symmetric inverted funnel
- Asymmetry suggests: Publication bias, heterogeneity, or chance

**Contour-enhanced funnel plots:**
- Add significance contours (p = 0.05, 0.01, 0.001)
- Helps distinguish bias from heterogeneity

### 5.2 Egger's Regression Test (Egger et al., 1997)

**Model:**
$$\frac{y_i}{SE_i} = \beta_0 + \beta_1 \times \frac{1}{SE_i} + \epsilon_i$$

**Test:** H₀: β₀ = 0 (no small-study effects)

**Implementation in CBAMMR:**
```r
# Via metafor
regtest(rma_object, model = "lm")
```

**Limitations:**
- Can be misleading with heterogeneity
- Low power with < 10 studies

### 5.3 PET-PEESE (Stanley & Doucouliagos, 2014)

**Precision-Effect Test (PET):**
$$y_i = \beta_0 + \beta_1 \times SE_i + \epsilon_i$$

If PET shows no effect, stop. If effect detected, use PEESE:

**Precision-Effect Estimate with Standard Error (PEESE):**
$$y_i = \beta_0 + \beta_1 \times SE_i^2 + \epsilon_i$$

**Advantage:** Less biased than Egger's in presence of true effect

### 5.4 Trim-and-Fill (Duval & Tweedie, 2000)

**Algorithm:**
1. Rank studies by effect size
2. Estimate number of missing studies (k₀)
3. "Fill" with imputed mirror-image studies
4. Re-estimate pooled effect

**Interpretation:**
- Adjusted estimate assuming symmetric funnel plot
- k₀ = estimated number of missing studies

**Limitations:**
- Assumes symmetry should exist
- Doesn't work well with genuine heterogeneity

### 5.5 Selection Models (Vevea & Hedges, 1995)

**Implemented via `weightr` package**

**Model:** Studies selected based on p-values

**Selection function:**
$$w(p) = \begin{cases}
1 & \text{if } p < p_1 \\
\omega_1 & \text{if } p_1 \leq p < p_2 \\
\omega_2 & \text{if } p \geq p_2
\end{cases}$$

where ω parameters model selection bias

**Advantage:** Formal statistical model of publication process

### 5.6 RoBMA (Robust Bayesian Meta-Analysis)

**Implemented via `RoBMA` package (Bartoš et al., 2022)**

**Approach:**
- Bayesian model averaging across:
  - Effect vs. no effect
  - Heterogeneity vs. no heterogeneity
  - Publication bias vs. no publication bias

**Models:** 12 models (2 × 2 × 3 combinations)

**Output:**
- Posterior model probabilities
- Model-averaged effect estimate
- Bayes factors for each component

**Advantage:** Accounts for model uncertainty, robust to specification

---

## 6. BAYESIAN METHODS

### 6.1 Bayesian Bootstrap (Rubin, 1981)

**Algorithm:**
1. Draw Dirichlet weights: $(\omega_1, ..., \omega_k) \sim \text{Dir}(\alpha, ..., \alpha)$
2. Compute weighted average: $\hat{\theta}^{(b)} = \sum \omega_i w_i y_i / \sum \omega_i w_i$
3. Repeat B times to obtain posterior distribution

**Prior:**
- Default: α = 1 (uniform prior on weights)
- Weakly informative: α = 0.5

**Output:**
- Posterior mean
- Posterior median
- 95% credible interval
- Full posterior distribution

**Use in CBAMMR:**
```r
cbamm_bayesian_bootstrap(yi, vi, n_boot = 10000, prior_weight = 1)
```

### 6.2 Bayesian Meta-Analysis (via brms)

**Hierarchical model:**
$$y_i | \theta_i, \sigma_i \sim N(\theta_i, \sigma_i^2)$$
$$\theta_i | \mu, \tau \sim N(\mu, \tau^2)$$

**Priors (default weakly informative):**
$$\mu \sim N(0, 1)$$
$$\tau \sim \text{Half-Cauchy}(0, 0.5)$$

**Advantages:**
- Full posterior distribution
- Natural uncertainty quantification
- Flexible modeling of complex structures

---

## 7. CLINICAL DECISION TOOLS

### 7.1 Fragility Index

**Definition:** Number of events that would need to change to make a significant result non-significant (or vice versa)

**Algorithm for meta-analysis:**
1. Start with observed data
2. Iteratively move one event from treatment to control
3. Stop when p-value crosses 0.05 threshold
4. FI = number of events moved

**Interpretation:**
- FI < 5: Fragile result
- FI ≥ 20: Robust result

**Novel contribution of CBAMMR:** Extends fragility index to meta-analytic context

### 7.2 Number Needed to Treat by Baseline Risk

**Standard NNT (ignores baseline risk):**
$$NNT = \frac{1}{RD} = \frac{1}{p_{control} - p_{treatment}}$$

**Risk-stratified NNT (CBAMMR):**
For odds ratio OR and baseline risk p₀:
$$p_{treatment} = \frac{OR \times p_0}{1 - p_0 + OR \times p_0}$$
$$NNT(p_0) = \frac{1}{p_0 - p_{treatment}}$$

**Use case:**
```r
# Calculate NNT for different baseline risks
cbamm_nnt_by_risk(ma_result,
                  baseline_risks = c(0.01, 0.05, 0.10, 0.20))
```

**Clinical utility:** Personalizes treatment benefit to patient risk

### 7.3 Minimal Important Difference (MID)

**Anchor-based approach:**
Compare effect size to empirically-derived MID for the outcome measure

**Distribution-based approach:**
$$MID \approx 0.5 \times SD_{baseline}$$

**CBAMMR assessment:**
- Compares pooled effect to established MIDs
- Flags when effect < MID (not clinically meaningful)
- Provides evidence for clinical significance beyond statistical significance

---

## 8. TRANSPORTABILITY ANALYSIS

### 8.1 Motivation

**External validity question:** Do meta-analytic results generalize to my target population?

**Problem:** Studies often not representative of clinical practice populations

### 8.2 Entropy Balancing Approach

**Goal:** Re-weight studies to match target population covariate distribution

**Method (Hainmueller, 2012):**

Minimize entropy distance:
$$\min_w \sum_{i=1}^k w_i \log(w_i / q_i)$$

Subject to:
$$\sum_{i=1}^k w_i X_{ij} = \bar{X}_{target,j} \quad \forall j$$
$$\sum_{i=1}^k w_i = 1$$
$$w_i \geq 0 \quad \forall i$$

where:
- $X_{ij}$: Covariate j in study i
- $\bar{X}_{target,j}$: Target population mean for covariate j
- $q_i$: Base weights (typically $1/k$)

**Implementation:**
```r
cbamm_transport_weights(data, target_population,
                        covariates = c("age_mean", "female_pct", "bmi_mean"))
```

### 8.3 Transported Estimate

After obtaining weights $w_i^*$:

$$\hat{\theta}_{transported} = \frac{\sum w_i^* (1/v_i) y_i}{\sum w_i^* (1/v_i)}$$

**Confidence interval:** Bootstrap or influence function

### 8.4 Sensitivity Analysis

**Assess robustness to:**
1. **Unmeasured confounding:** E-value calculation
2. **Weight truncation:** Limit extreme weights (e.g., < 0.01 or > 0.50)
3. **Covariate selection:** Try different covariate sets

**Validation status:** ⚠️ **Methodological validation ongoing**

- Novel application of entropy balancing to meta-analysis
- Requires peer-reviewed publication
- Use with caution and expert consultation
- Always report both standard and transported estimates

---

## 9. AUTOMATED DECISION ALGORITHMS

### 9.1 Data Type Detection

**Algorithm (`cbamm_auto()` function):**

```
IF columns contain (ai, bi, ci, di) OR (event_t, n_t, event_c, n_c) THEN
    data_type = "binary_2x2"
ELSE IF columns contain (m1i, sd1i, n1i, m2i, sd2i, n2i) THEN
    data_type = "continuous_two_group"
ELSE IF columns contain (yi, vi) OR (yi, sei) THEN
    data_type = "effect_size_precalculated"
ELSE
    ERROR: "Cannot detect data format"
END IF
```

### 9.2 Effect Size Selection

**For binary data:**
```
IF data_type = "binary_2x2" THEN
    IF any cell frequency < 5 IN > 20% of studies THEN
        effect_measure = "PETO"  # Rare events
        log_decision("Rare events detected, using Peto OR")
    ELSE IF design = "case_control" THEN
        effect_measure = "OR"
        log_decision("Case-control design, using odds ratio")
    ELSE
        effect_measure = "RR"  # Default for cohort/RCT
        log_decision("Cohort/RCT design, using risk ratio")
    END IF
END IF
```

**For continuous data:**
```
IF data_type = "continuous_two_group" THEN
    IF all studies use same measurement scale THEN
        effect_measure = "MD"
        log_decision("Same scale across studies, using mean difference")
    ELSE
        effect_measure = "SMD"
        log_decision("Different scales across studies, using SMD")
    END IF
END IF
```

### 9.3 Heterogeneity Estimator Selection

**Standard pathway:**
```
estimator = "REML"  # Default, generally preferred
```

**Advanced pathway:**
```
estimators = c("REML", "DL", "ML", "EB", "PM")
FOR each estimator DO
    fit_model(estimator)
    calculate_AIC[estimator]
    calculate_BIC[estimator]
END FOR
best_estimator = argmin(AIC)  # or BIC
log_decision("Selected {best_estimator} based on AIC")
```

### 9.4 Publication Bias Assessment Triggers

```
IF k >= 10 THEN
    run_egger_test()
    run_trimfill()
    IF enough variation in SE THEN
        run_pet_peese()
    END IF
END IF

IF k >= 5 AND RoBMA package available THEN
    IF user_time_budget = "high" THEN
        run_robma()  # Can be slow
    END IF
END IF
```

### 9.5 Decision Logging

All automated decisions are logged in `result$decisions`:

```r
result$decisions <- list(
  pathway = "standard",
  data_detection = list(
    type = "binary_2x2",
    k_studies = 20,
    reason = "Detected ai, bi, ci, di columns"
  ),
  effect_size = list(
    measure = "RR",
    reason = "RCT/cohort design, no rare events"
  ),
  estimator = list(
    method = "REML",
    reason = "Standard pathway default"
  ),
  hksj_adjustment = TRUE,
  publication_bias = list(
    egger = "run",
    trimfill = "run",
    pet_peese = "skipped (insufficient power)"
  )
)
```

**User responsibility:** Review all automated decisions

---

## 10. VALIDATION FRAMEWORK

### 10.1 Validation Against metafor

**Test suite:** `test-validation-against-metafor.R`

**Tests include:**
1. Effect size calculations match `escalc()` to 1e-10 tolerance
2. Meta-analysis models match `rma()` exactly
3. Heterogeneity statistics (Q, I², H², τ²) validated
4. Publication bias methods match `regtest()`, `trimfill()`
5. Edge cases handled correctly (zero cells, small samples)
6. Confidence interval coverage validated via simulation

### 10.2 Published Meta-Analysis Reproductions

**Test suite:** `test-published-reproductions.R`

**Landmark studies reproduced (n=10):**
1. BCG vaccine (Colditz 1994) - JAMA
2. Aspirin for MI (Antiplatelet 1994) - BMJ
3. Magnesium for MI (Teo 1991) - BMJ
4. Exercise for depression (Lawlor 2001) - BMJ
5. Teacher expectancy (Raudenbush 1984) - Psych Bull
6. Smoking & lung cancer (Doll & Hill 1950) - BMJ
7. Hormone therapy & CHD (Grady 1992) - Ann IM
8. Probiotics for AAD (D'Souza 2002) - BMJ
9. Bariatric surgery (Buchwald 2004) - JAMA
10. Beta-blockers after MI (Freemantle 1999) - BMJ

**Coverage:**
- Time span: 1950-2004 (54 years)
- Disciplines: Cardiology, infectious disease, psychology, epidemiology, surgery
- Journals: JAMA (3), BMJ (5), Psych Bull (1), Ann IM (1)

### 10.3 Performance Benchmarks

**Test suite:** `test-performance-benchmarks.R`

**Benchmarks include:**
1. Effect size calculation overhead (< 20% vs metafor)
2. Model fitting scalability (linear or better)
3. Large dataset performance (2000 studies in < 60s)
4. cbamm_auto() overhead (< 5x basic workflow)
5. Publication bias methods speed
6. Memory efficiency
7. Heterogeneity estimator comparison

---

## 11. LIMITATIONS

### 11.1 Current Limitations

1. **Transportability methods:**
   - Novel application, not yet peer-reviewed
   - Validation studies ongoing
   - Requires assumptions about covariate relationships
   - May not work well with strong effect modification
   - **Status:** Use with caution and expert consultation

2. **Automated GRADE assessment:**
   - Provides preliminary assessments only
   - Cannot replace expert judgment for:
     - Risk of bias assessment (requires study-level evaluation)
     - Indirectness (requires clinical knowledge)
     - Some aspects of imprecision
   - **Status:** Expert review always required

3. **Computational performance:**
   - Slower than metafor alone due to additional analyses
   - RoBMA can be computationally intensive
   - Bayesian methods require adequate computation time
   - **Status:** Accept performance trade-off for comprehensive workflow

4. **Scalability:**
   - Tested up to 2000 studies
   - Very large meta-analyses (> 5000 studies) may have issues
   - Interactive features require optional packages
   - **Status:** Works well for typical meta-analyses (k < 100)

### 11.2 When NOT to Use CBAMMR

**Use metafor directly for:**
- Complex multilevel models
- Network meta-analysis (use netmeta)
- Individual participant data meta-analysis with custom models
- Methodological research requiring maximum flexibility
- Publication of novel statistical methods

**Use meta directly for:**
- Network meta-analysis
- Specific German healthcare contexts
- Integration with specific Cochrane workflows

### 11.3 Assumptions

**All meta-analyses assume:**
1. Studies are measuring the same underlying construct
2. Study-level estimates are properly calculated
3. Within-study variance estimates are accurate
4. No unmodeled dependencies between studies
5. Random-effects model: Effects ~ N(μ, τ²)

**Additional CBAMMR assumptions:**
- Automated decisions are appropriate (user should verify)
- Transportability: Measured covariates capture relevant differences
- GRADE automation: Preliminary assessments are followed up

---

## 12. BEST PRACTICES

### 12.1 Standard Workflow

1. **Data preparation:** Ensure proper format and documentation
2. **Run cbamm_auto():** Use standard pathway for initial analysis
3. **Review decisions:** Check automated choices in `result$decisions`
4. **Validate critical results:** Compare with direct metafor analysis
5. **Report transparently:** Include all decisions and sensitivity analyses

### 12.2 Reporting Standards

**PRISMA 2020 compliance:**
- Use `cbamm_prisma_checklist()` as starting point
- Complete missing items manually
- Document any deviations

**Methods section should include:**
- Effect size measure and justification
- Heterogeneity estimator and reason
- Publication bias methods used
- Automated decisions made (if using cbamm_auto)
- Software versions (CBAMMR, metafor, R)

### 12.3 Sensitivity Analyses

**Recommended:**
1. Compare REML vs DL estimators
2. With/without HKSJ adjustment
3. Fixed-effects vs random-effects
4. Influence analysis (leave-one-out)
5. Subgroup analyses by study quality, design, etc.

### 12.4 Quality Assessment

**Use established tools:**
- Cochrane Risk of Bias 2.0 (RCTs)
- ROBINS-I (observational studies)
- GRADE for evidence certainty

**CBAMMR's GRADE automation:**
- Provides starting point only
- Requires expert review and modification
- Document all adjustments made

---

## 13. FUTURE DEVELOPMENTS

### 13.1 Planned Enhancements (v9.x)

1. **Transportability validation:**
   - Simulation studies of method performance
   - Comparison with alternative approaches
   - Peer-reviewed methodology paper
   - **Timeline:** 2-3 months

2. **Performance optimization:**
   - Parallel processing for intensive computations
   - Caching of intermediate results
   - Streamlined workflows
   - **Timeline:** 1-2 months

3. **Additional validation:**
   - 50+ published meta-analysis reproductions
   - Comparison with CMA software
   - User testing studies
   - **Timeline:** 3-6 months

### 13.2 Potential Extensions (v10.x)

- Network meta-analysis integration
- Machine learning for heterogeneity prediction
- Real-time updating meta-analysis
- Interactive dashboard enhancements

---

## 14. CONCLUSIONS

CBAMMR provides an integrated workflow for meta-analysis that:

✓ **Builds on proven foundations** (metafor, meta, RoBMA)
✓ **Streamlines common workflows** while maintaining transparency
✓ **Extends functionality** with clinical decision tools
✓ **Validates comprehensively** against published results
✓ **Documents honestly** including limitations

**Use CBAMMR when:**
- Standard workflow is appropriate
- Clinical decision tools are valuable
- Automated reporting is helpful
- Transparency in decision-making is desired

**Use metafor/meta directly when:**
- Maximum flexibility is required
- Complex models are needed
- Methodological research is the goal
- Custom approaches are necessary

---

## REFERENCES

**Core methodology:**
1. Viechtbauer W. (2010). Conducting meta-analyses in R with the metafor package. *Journal of Statistical Software*, 36(3), 1-48.
2. Schwarzer G, et al. (2015). *Meta-Analysis with R*. Springer.
3. Borenstein M, et al. (2009). *Introduction to Meta-Analysis*. Wiley.
4. Hedges LV, Olkin I. (1985). *Statistical Methods for Meta-Analysis*. Academic Press.

**Heterogeneity:**
5. Higgins JPT, Thompson SG. (2002). Quantifying heterogeneity in a meta-analysis. *Statistics in Medicine*, 21(11), 1539-1558.
6. Veroniki AA, et al. (2016). Methods to estimate the between-study variance in meta-analysis. *Research Synthesis Methods*, 7(1), 55-79.

**Publication bias:**
7. Egger M, et al. (1997). Bias in meta-analysis detected by a simple, graphical test. *BMJ*, 315(7109), 629-634.
8. Stanley TD, Doucouliagos H. (2014). Meta-regression approximations to reduce publication selection bias. *Research Synthesis Methods*, 5(1), 60-78.
9. Bartoš F, et al. (2022). Robust Bayesian meta-analysis. *Psychological Methods*, 27(3), 407-431.

**Advanced methods:**
10. Hartung J, Knapp G. (2001). A refined method for the meta-analysis of controlled clinical trials. *Statistics in Medicine*, 20(24), 3875-3889.
11. Rubin DB. (1981). The Bayesian bootstrap. *The Annals of Statistics*, 9(1), 130-134.
12. Hainmueller J. (2012). Entropy balancing for causal effects. *Political Analysis*, 20(1), 25-46.

---

**Document Version:** 1.0
**Last Updated:** November 5, 2025
**Maintained by:** CBAMMR Development Team
**Contact:** https://github.com/mahmood726-cyber/CBAMMR/issues
