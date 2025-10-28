# CBAMMR Benchmark Comparison with Other R Meta-Analysis Packages

**Date:** October 28, 2025
**CBAMMR Version:** 7.0.0

## Executive Summary

This document provides a comprehensive comparison of CBAMMR with major R meta-analysis packages to identify strengths, gaps, and opportunities for improvement.

**Key Finding:** CBAMMR excels in **transportability analysis**, **integrated Shiny app**, **complete workflows**, and **2024-2025 journal compliance**, but could benefit from adding **network meta-analysis**, **component analysis**, and **advanced Bayesian methods**.

---

## Packages Compared

1. **metafor** (v4.6+, 2024) - Comprehensive meta-analysis toolkit
2. **meta** (v7.0+, 2025) - User-friendly general meta-analysis
3. **netmeta** (v2.9+, 2025) - Network meta-analysis
4. **RoBMA** (v3.3, 2025) - Robust Bayesian meta-analysis
5. **metasens** (v1.5+, 2025) - Sensitivity analysis for bias
6. **CBAMMR** (v7.0, 2025) - Comprehensive Bayesian & Advanced Methods

---

## Feature Comparison Matrix

### Core Meta-Analysis Methods

| Feature | metafor | meta | netmeta | RoBMA | metasens | CBAMMR |
|---------|---------|------|---------|-------|----------|---------|
| **Basic Meta-Analysis** |
| Fixed-effects models | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Random-effects models | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Mixed-effects models | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Hartung-Knapp adjustment | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| Prediction intervals | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Effect Measures** |
| OR, RR, RD (binary) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| MD, SMD (continuous) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| HR (survival) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| IRR (rate data) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Heterogeneity** |
| I², τ², H² | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Estimators (REML, DL, ML, etc.) | ✅ (9+) | ✅ (7+) | ✅ | ✅ | ✅ | ✅ (3) |
| Outlier detection | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Influence diagnostics | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |

### Advanced Methods

| Feature | metafor | meta | netmeta | RoBMA | metasens | CBAMMR |
|---------|---------|------|---------|-------|----------|---------|
| **Publication Bias** |
| Funnel plot | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Egger's test | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| PET-PEESE | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| Trim-and-fill | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Selection models | ✅ | ❌ | ❌ | ✅ | ✅ (Copas) | ✅ |
| **Meta-Regression** |
| Simple meta-regression | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Multiple moderators | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Non-linear (splines) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Advanced Models** |
| Multivariate MA | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Multilevel models | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Network meta-analysis | ❌ | ✅ (via netmeta) | ✅ | ❌ | ❌ | ❌ |
| Component NMA | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Bayesian Methods** |
| Bayesian MA | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ (stacking) |
| Model averaging | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Bayes factors | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |

### Unique/Innovative Features

| Feature | metafor | meta | netmeta | RoBMA | metasens | CBAMMR |
|---------|---------|------|---------|-------|----------|---------|
| **Novel Methods** |
| Transportability weighting | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Robust variance estimation (RVE) | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Machine learning heterogeneity | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Limit meta-analysis | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| SUCRA/P-scores (NMA) | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Spike-and-slab priors | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Clinical Decision Tools** |
| Fragility index | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| NNT by baseline risk | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| MID/MCID assessment | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Decision curve analysis | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Net clinical benefit | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

### Reporting & Compliance

| Feature | metafor | meta | netmeta | RoBMA | metasens | CBAMMR |
|---------|---------|------|---------|-------|----------|---------|
| **Standards Compliance** |
| PRISMA 2020 checklist | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| GRADE assessment | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (auto) |
| Reproducibility bundle | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Manuscript text generation | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Power analysis | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Visualization** |
| Forest plots | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Funnel plots | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Network plots | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| GOSH plots | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Customizable plots (25+ params) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

### User Experience

| Feature | metafor | meta | netmeta | RoBMA | metasens | CBAMMR |
|---------|---------|------|---------|-------|----------|---------|
| **Ease of Use** |
| Learning curve | Steep | Moderate | Moderate | Steep | Moderate | Easy |
| Interactive Shiny app | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| One-function workflow | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Preset configurations | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Example datasets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Documentation** |
| Comprehensive vignettes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Quick start guide | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| Journal enhancements doc | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Plot customization guide | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Detailed Package Analysis

### 1. metafor (Comprehensive Toolkit)

**Strengths:**
- Most comprehensive R package for meta-analysis
- 9+ heterogeneity estimators (vs CBAMMR's 3)
- Multivariate and multilevel models
- GOSH plots for outlier detection
- Extensive documentation and examples
- Wide community adoption (396,067 downloads)

**Weaknesses:**
- Steep learning curve
- No built-in Shiny interface
- No automated reporting (PRISMA, GRADE)
- No transportability analysis
- No clinical decision tools

**What CBAMMR Does Better:**
- ✅ Transportability weighting
- ✅ Integrated Shiny app
- ✅ One-function complete workflow
- ✅ PRISMA/GRADE automation
- ✅ Clinical decision tools (fragility, NNT, DCA)
- ✅ Manuscript text generation

**What metafor Does Better:**
- ✅ More heterogeneity estimators (9 vs 3)
- ✅ Multilevel models
- ✅ GOSH plots
- ✅ More flexible model specification

### 2. meta (User-Friendly General Package)

**Strengths:**
- User-friendly, intuitive syntax
- Quick implementation
- Integrates with netmeta for network MA
- Good visualization defaults
- Updated September 2025
- 279,975 downloads

**Weaknesses:**
- Less flexible than metafor
- No multivariate models
- No transportability analysis
- No advanced Bayesian methods

**What CBAMMR Does Better:**
- ✅ Transportability analysis
- ✅ Shiny interface
- ✅ Clinical decision tools
- ✅ GRADE automation
- ✅ Machine learning heterogeneity analysis
- ✅ Bayesian model averaging

**What meta Does Better:**
- ✅ Network meta-analysis (via netmeta integration)
- ✅ Simpler syntax for basic analyses
- ✅ Better defaults for quick analyses

### 3. netmeta (Network Meta-Analysis Specialist)

**Strengths:**
- Comprehensive network meta-analysis
- Component network meta-analysis (CNMA)
- SUCRA and P-score rankings
- Additive models for combination treatments
- Updated July 2025
- Handles complex treatment networks

**Weaknesses:**
- Limited to network MA
- No transportability
- No Hartung-Knapp adjustment
- No clinical decision tools

**What CBAMMR Does Better:**
- ✅ Transportability weighting
- ✅ Hartung-Knapp adjustment
- ✅ Clinical decision tools
- ✅ GRADE assessment
- ✅ Shiny interface
- ✅ Complete workflow automation

**What netmeta Does Better:**
- ✅ **Network meta-analysis** (major gap for CBAMMR)
- ✅ **Component network meta-analysis**
- ✅ SUCRA/P-scores for treatment ranking
- ✅ Additive models for combinations

### 4. RoBMA (Robust Bayesian Methods)

**Strengths:**
- Robust Bayesian model-averaging
- Bayes factors for effect/bias testing
- Spike-and-slab priors (v3.3)
- Meta-regression (RoBMA-reg)
- Tests for publication bias presence
- Updated February 2025

**Weaknesses:**
- Steep learning curve
- Limited to Bayesian framework
- No transportability
- No clinical decision tools
- Computationally intensive

**What CBAMMR Does Better:**
- ✅ Transportability weighting
- ✅ Simpler frequentist + Bayesian hybrid
- ✅ Clinical decision tools
- ✅ GRADE automation
- ✅ Shiny interface
- ✅ Faster computation (stacking vs full Bayes)

**What RoBMA Does Better:**
- ✅ **Bayes factors** for hypothesis testing
- ✅ **Spike-and-slab priors** for variable selection
- ✅ More sophisticated Bayesian model averaging
- ✅ Publication bias detection via model comparison

### 5. metasens (Sensitivity Analysis)

**Strengths:**
- Limit meta-analysis for bias adjustment
- Copas selection model
- Imputation for missing data
- Extended random effects models
- Updated July 2025

**Weaknesses:**
- Limited scope (sensitivity only)
- No general MA functionality
- No transportability
- No visualization tools

**What CBAMMR Does Better:**
- ✅ Complete meta-analysis toolkit
- ✅ Transportability analysis
- ✅ Clinical decision tools
- ✅ Shiny interface
- ✅ Comprehensive visualization

**What metasens Does Better:**
- ✅ **Limit meta-analysis** (Rücker method)
- ✅ **Copas selection model** (more sophisticated than CBAMMR's)
- ✅ Imputation for missing data

---

## CBAMMR Unique Strengths

### 1. Transportability Analysis ⭐
**Unique to CBAMMR**
- Weights studies by similarity to target population
- Accounts for effect modification across populations
- Essential for external validity
- No other package offers this

### 2. Integrated Shiny App ⭐
**Unique to CBAMMR**
- Complete point-and-click interface
- 25+ plot customization parameters
- Real-time preview
- No coding required
- Downloadable outputs

### 3. Clinical Decision Tools ⭐
**Unique to CBAMMR**
- Fragility index (FI ≥22 = robust)
- NNT by baseline risk (personalized medicine)
- MID/MCID assessment
- Decision curve analysis
- Net clinical benefit
- Prediction interval interpretation

### 4. 2024-2025 Journal Compliance ⭐
**Unique to CBAMMR**
- PRISMA 2020 auto-checklist
- GRADE auto-assessment
- Reproducibility bundle (OSF/Zenodo ready)
- Manuscript text generation
- Power analysis

### 5. Complete Workflow Automation ⭐
**Unique to CBAMMR**
- One function: `cbamm_complete_workflow()`
- Runs all analyses automatically
- Generates all outputs
- Creates manuscript text
- Exports reproducibility bundle

---

## CBAMMR Gaps & Improvement Opportunities

### HIGH PRIORITY (Major Gaps)

#### 1. Network Meta-Analysis ❌
**Gap:** CBAMMR lacks network MA capabilities
**Impact:** Cannot analyze indirect comparisons or treatment networks
**Packages with this:** netmeta, meta
**Recommendation:** Add basic network MA in future version
```r
# Proposed function
cbamm_network_ma(data, treatments, outcomes, reference)
```

#### 2. Component Network Meta-Analysis ❌
**Gap:** No component analysis for combination treatments
**Impact:** Cannot evaluate individual components
**Packages with this:** netmeta
**Recommendation:** Add CNMA for v8.0

#### 3. Bayes Factors ❌
**Gap:** No Bayes factor hypothesis testing
**Impact:** Cannot formally test effect/bias presence
**Packages with this:** RoBMA
**Recommendation:** Add BF module using bridgesampling
```r
# Proposed function
cbamm_bayes_factor(results, hypothesis = "effect")
```

#### 4. More Heterogeneity Estimators ⚠️
**Gap:** Only 3 estimators (REML, DL, ML) vs metafor's 9+
**Impact:** Less flexibility for different data types
**Packages with this:** metafor (9+), meta (7+)
**Recommendation:** Add PM, EB, SJ, HS estimators

### MEDIUM PRIORITY (Nice to Have)

#### 5. Multilevel Models ❌
**Gap:** No multilevel/hierarchical models
**Impact:** Cannot properly handle nested data
**Packages with this:** metafor
**Recommendation:** Add multilevel capability for clustered studies

#### 6. GOSH Plots ❌
**Gap:** No Graphical Display of Study Heterogeneity
**Impact:** Less comprehensive outlier detection
**Packages with this:** metafor
**Recommendation:** Add GOSH plotting function

#### 7. Limit Meta-Analysis ❌
**Gap:** No Rücker limit MA for bias adjustment
**Impact:** One less bias adjustment method
**Packages with this:** metasens
**Recommendation:** Add limit MA as alternative to PET-PEESE

#### 8. Advanced Copas Selection Model ⚠️
**Gap:** Basic selection model vs sophisticated Copas
**Impact:** Less powerful bias detection
**Packages with this:** metasens
**Recommendation:** Enhance selection model implementation

### LOW PRIORITY (Minor Improvements)

#### 9. SUCRA/P-scores (for NMA) ❌
**Gap:** No SUCRA/P-scores for treatment ranking
**Impact:** NA (CBAMMR has no NMA yet)
**Packages with this:** netmeta
**Recommendation:** Add when NMA is implemented

#### 10. Spike-and-Slab Priors ❌
**Gap:** No spike-and-slab for variable selection
**Impact:** Less sophisticated Bayesian model averaging
**Packages with this:** RoBMA
**Recommendation:** Consider for advanced Bayesian module

---

## Recommendations for CBAMMR v8.0

### Phase 1: Fill Critical Gaps (v7.1)
1. **Add more heterogeneity estimators**
   - PM (Paule-Mandel)
   - EB (Empirical Bayes)
   - SJ (Sidik-Jonkman)
   - HS (Hunter-Schmidt)

2. **Enhance selection models**
   - Implement Copas selection model
   - Add model diagnostics

3. **Add Bayes factors**
   - Effect presence testing
   - Heterogeneity testing
   - Publication bias testing

### Phase 2: Network Meta-Analysis (v7.5)
1. **Basic network MA**
   - Frequentist network MA
   - Consistency/inconsistency models
   - Network plots

2. **Treatment ranking**
   - SUCRA scores
   - P-scores
   - Rankograms

### Phase 3: Advanced Features (v8.0)
1. **Component network MA**
   - Additive models
   - Component contributions

2. **Multilevel models**
   - Nested study designs
   - Multiple endpoints per study

3. **GOSH plots**
   - Graphical heterogeneity display
   - Outlier detection

### Phase 4: Enhancements (v8.5)
1. **Limit meta-analysis**
   - Rücker method implementation

2. **Advanced Bayesian**
   - Spike-and-slab priors
   - Model comparison tools

---

## Performance Comparison

### Download Statistics (CRAN)
- **metafor:** 396,067 downloads
- **meta:** 279,975 downloads
- **netmeta:** ~100,000+ downloads (estimated)
- **RoBMA:** ~20,000+ downloads (estimated)
- **CBAMMR:** Not yet on CRAN (GitHub only)

**Recommendation:** Submit to CRAN after v7.1 improvements

### Speed Comparison (Estimated)
Based on typical 20-study meta-analysis:

| Package | Time (seconds) | Method |
|---------|---------------|--------|
| meta | 0.1-0.5 | Fast (optimized) |
| metafor | 0.2-1.0 | Fast-Medium |
| CBAMMR | 1.0-3.0 | Medium (comprehensive) |
| RoBMA | 10-60 | Slow (MCMC) |

**Note:** CBAMMR slower due to comprehensive analysis (transportability, GRADE, fragility, etc.). This is acceptable trade-off for automation.

### Memory Usage
- **metafor:** Low-Medium
- **meta:** Low
- **CBAMMR:** Medium (stores more results)
- **RoBMA:** High (MCMC chains)

---

## User Base Comparison

### Target Audiences

| Package | Primary Users |
|---------|--------------|
| metafor | Meta-analysis experts, statisticians, methodologists |
| meta | Clinical researchers, applied researchers, students |
| netmeta | Network MA specialists, HTA researchers |
| RoBMA | Bayesian statisticians, methodologists |
| metasens | Bias-focused researchers, methodologists |
| CBAMMR | Clinical researchers, journal submission, reproducibility-focused |

### CBAMMR Competitive Advantage
1. **Ease of use** (one-function workflow, Shiny app)
2. **Journal compliance** (PRISMA, GRADE, reproducibility)
3. **Clinical decision support** (fragility, NNT, DCA)
4. **Transportability** (unique feature)
5. **Complete automation** (manuscript-ready outputs)

---

## Market Positioning

### CBAMMR Positioning Statement
> "CBAMMR is the complete, user-friendly meta-analysis solution for clinical researchers who need journal-ready, reproducible analyses with built-in transportability assessment and clinical decision tools—all accessible through both R code and an interactive Shiny interface."

### Competitive Differentiation

**vs metafor:** CBAMMR trades some advanced flexibility for ease of use, automation, and clinical decision support

**vs meta:** CBAMMR adds transportability, clinical tools, Shiny interface, and complete automation

**vs netmeta:** CBAMMR focuses on transportable pairwise MA with clinical tools; netmeta excels at network MA

**vs RoBMA:** CBAMMR provides faster, hybrid Bayesian-frequentist approach with clinical focus; RoBMA for pure Bayesian inference

**vs metasens:** CBAMMR is comprehensive toolkit; metasens is specialized sensitivity tool

---

## Conclusion

### CBAMMR Strengths Summary
1. ✅ **Unique transportability analysis**
2. ✅ **Only package with integrated Shiny app**
3. ✅ **Only package with clinical decision tools**
4. ✅ **Best journal compliance automation**
5. ✅ **Easiest complete workflow**
6. ✅ **Most comprehensive plot customization**

### Priority Improvements
1. 🔴 **Add network meta-analysis** (fills major gap)
2. 🔴 **Add more heterogeneity estimators** (matches metafor)
3. 🟡 **Add Bayes factors** (enhances Bayesian capability)
4. 🟡 **Add multilevel models** (handles complex data)
5. 🟢 **Add GOSH plots** (enhances diagnostics)

### CRAN Readiness
**Current Status:** Ready for CRAN after minor improvements
**Timeline:**
- v7.1 (heterogeneity estimators, Bayes factors) → CRAN submission
- v7.5 (network MA) → Major update
- v8.0 (multilevel, CNMA) → Comprehensive package

### Final Verdict
**CBAMMR is the best choice for:**
- Clinical researchers needing journal-ready outputs
- Studies requiring transportability assessment
- Users wanting Shiny interface
- Reproducibility-focused research
- Clinical decision support needs

**Use other packages when:**
- Network MA needed → **netmeta**
- Maximum flexibility needed → **metafor**
- Pure Bayesian inference → **RoBMA**
- Quick basic MA → **meta**
- Specialized bias analysis → **metasens**

---

## References

1. Lortie et al. (2020). A contrast of meta and metafor packages for meta-analyses in R. *Ecology and Evolution*, 10(20), 10916-10921.
2. Viechtbauer (2010). Conducting meta-analyses in R with the metafor package. *Journal of Statistical Software*, 36(3), 1-48.
3. Rücker et al. (2024). *netmeta: Network Meta-Analysis using Frequentist Methods*. R package version 2.9+.
4. Bartoš et al. (2025). *RoBMA: Robust Bayesian Meta-Analyses*. R package version 3.3.
5. Schwarzer et al. (2025). *meta: General Package for Meta-Analysis*. R package version 7.0+.

---

**Prepared by:** CBAMMR Development Team
**Next Review:** After implementing v7.1 improvements
