# Transportability Validation Study Protocol

**Protocol Version:** 1.0
**Date:** November 5, 2025
**Status:** Planning Phase

---

## EXECUTIVE SUMMARY

This protocol outlines a comprehensive validation study for CBAMMR's transportability methods, which use entropy balancing (Hainmueller 2012) to reweight meta-analysis estimates for target populations. The study aims to:

1. Validate that entropy balancing achieves covariate balance
2. Compare transportability-adjusted estimates against true target population effects
3. Assess performance under various scenarios (sample-target similarity, covariate relationships, etc.)
4. Compare with alternative transportability methods
5. Provide guidance on when transportability adjustment is beneficial

**Timeline:** 2-3 months
**Lead:** Statistical methods team
**Collaborators:** Clinical epidemiologists, simulation experts

---

## 1. BACKGROUND

### 1.1 Current Implementation

CBAMMR implements transportability analysis via `compute_transport_weights()` which:
- Uses entropy balancing to reweight studies
- Matches four key covariates: age_mean, female_pct, bmi_mean, charlson
- Supports weight truncation to prevent extreme weights
- Falls back to custom optimization if WeightIt package unavailable

**Reference:** R/core-functions.R:19-83

### 1.2 Scientific Rationale

Meta-analyses pool studies from potentially unrepresentative samples. Transportability methods adjust pooled estimates to reflect a specific target population, accounting for effect heterogeneity by patient characteristics.

**Key Papers:**
- Hainmueller J. (2012). Entropy balancing for causal effects. *Political Analysis*, 20(1), 25-46.
- Stuart EA, et al. (2011). The use of propensity scores to assess the generalizability of results from randomized trials. *J R Stat Soc A*, 174(2), 369-386.
- Tipton E. (2013). Improving generalizations from experiments using propensity score subclassification. *J Exp Criminol*, 9(1), 1-24.

### 1.3 Validation Gap

Current status:
- ✅ Unit tests confirm entropy balancing achieves covariate balance (test-transportability.R)
- ✅ Simulation study shows method recovers known ground truth (TEST 10)
- ⚠️ **NEEDED:** Extensive simulation study across realistic scenarios
- ⚠️ **NEEDED:** Comparison with alternative methods
- ⚠️ **NEEDED:** Real-world data validation
- ⚠️ **NEEDED:** Guidance on when to use transportability adjustment

---

## 2. STUDY OBJECTIVES

### 2.1 Primary Objectives

**Objective 1:** Validate that entropy balancing adequately reweights study samples to match target population characteristics

**Success Criterion:** Weighted covariate means within 5% of target population means in ≥95% of scenarios

---

**Objective 2:** Assess bias reduction when transporting from sample to target population

**Success Criterion:** Transportability-adjusted estimates have lower root mean squared error (RMSE) than unadjusted estimates when sample ≠ target

---

### 2.2 Secondary Objectives

**Objective 3:** Compare entropy balancing with alternative transportability methods
- Propensity score weighting
- Calibration weighting
- Inverse probability of sampling weights (IPSW)

**Objective 4:** Identify scenarios where transportability adjustment provides greatest benefit

**Objective 5:** Develop practical guidance for CBAMMR users on when to apply transportability

---

## 3. METHODS

### 3.1 Simulation Study Design

#### 3.1.1 Data Generating Process

We will simulate meta-analyses with known data-generating mechanisms:

**Study-level covariates:**
- Age: X₁ ~ N(μ_age, σ²_age)
- Female proportion: X₂ ~ Beta(α, β) scaled to [0,1]
- BMI: X₃ ~ N(μ_bmi, σ²_bmi)
- Comorbidity (Charlson): X₄ ~ Poisson(λ) truncated at [0, 10]

**Effect heterogeneity model:**

True log odds ratio for study i:
```
log(OR_i) = β₀ + β₁(X₁ᵢ - μ₁) + β₂(X₂ᵢ - μ₂) + β₃(X₃ᵢ - μ₃) + β₄(X₄ᵢ - μ₄) + uᵢ
```

Where:
- β₀ = baseline effect (varies: -0.5, -0.3, -0.1)
- β₁, β₂, β₃, β₄ = covariate-effect relationships (varies: 0, 0.01, 0.05, 0.10)
- uᵢ ~ N(0, τ²) = between-study heterogeneity (τ² varies: 0, 0.05, 0.15)

**Observed data:**
- Sample sizes: nᵢ ~ Uniform(100, 1000) per arm
- Control event rate: 0.05 to 0.30
- Treatment effect: log(ORᵢ) as above

#### 3.1.2 Simulation Scenarios

**Scenario A: Baseline (No effect heterogeneity)**
- β₁ = β₂ = β₃ = β₄ = 0
- Tests whether transportability introduces unnecessary noise

**Scenario B: Mild effect heterogeneity**
- One covariate (age): β₁ = 0.01
- Others: β₂ = β₃ = β₄ = 0

**Scenario C: Moderate effect heterogeneity**
- Two covariates: β₁ = 0.02, β₂ = 0.05
- Others: β₃ = β₄ = 0

**Scenario D: Strong effect heterogeneity**
- All covariates: β₁ = 0.01, β₂ = 0.10, β₃ = 0.02, β₄ = 0.05

**Scenario E: Sample-target similarity**
- Near overlap: target within sample covariate range
- Moderate extrapolation: target at edge of sample range
- Strong extrapolation: target outside sample range

**Scenario F: Sample size variations**
- Small meta-analysis: k = 5 studies
- Medium: k = 15 studies
- Large: k = 50 studies

**Scenario G: Heterogeneity variations**
- Low τ² = 0.05
- Moderate τ² = 0.15
- High τ² = 0.30

**Full factorial design:** 4 (heterogeneity patterns) × 3 (sample-target overlap) × 3 (sample sizes) × 3 (τ²) = 108 scenarios

**Replications:** 1,000 per scenario = 108,000 total simulations

#### 3.1.3 Estimators to Compare

1. **Unadjusted:** Standard random-effects meta-analysis (metafor::rma)
2. **Entropy balancing:** CBAMMR compute_transport_weights()
3. **Propensity score weighting:** IPSW via propensity scores
4. **Calibration weighting:** Raking to marginal covariate distributions
5. **Oracle:** Meta-regression on all covariates (requires covariate data)

#### 3.1.4 Performance Metrics

For each scenario and replication, calculate:

**Bias:**
```
Bias = Estimate - True_Target_Effect
```

**Root Mean Squared Error (RMSE):**
```
RMSE = sqrt(mean((Estimate - True_Target_Effect)²))
```

**Coverage:**
```
Coverage = Proportion of 95% CIs containing true target effect
```

**Covariate Balance (for weighting methods):**
```
Balance = |Weighted_Sample_Mean - Target_Mean| / SD_Target
```

**Effective sample size:**
```
ESS = (sum(weights))² / sum(weights²)
```

---

### 3.2 Real-World Validation

#### 3.2.1 Data Sources

Identify 5-10 real-world cases where:
1. Multiple meta-analyses exist for same question
2. Meta-analyses differ in study populations
3. Study-level covariate data available
4. Can define meaningful target population

**Example candidates:**
- **Statin trials:** Multiple meta-analyses (primary prevention, secondary prevention, age subgroups)
- **Antihypertensive trials:** Different age/race populations
- **Diabetes interventions:** Type 1 vs Type 2, different age ranges
- **Depression treatments:** Different severity levels, age groups
- **Surgical interventions:** Different surgical risk populations

#### 3.2.2 Validation Approach

For each case:
1. Define "gold standard" target population (e.g., elderly patients)
2. Identify meta-analysis A: includes target population studies
3. Identify meta-analysis B: excludes target population
4. Apply transportability to B to match A's population
5. Compare: Transported B vs. Original A

**Success criterion:** Transportability-adjusted estimate from B within confidence interval of A

---

### 3.3 Sensitivity Analyses

#### 3.3.1 Unmeasured Confounding

Test robustness when important effect modifiers are unmeasured:
- Simulate 5th covariate that affects treatment effect
- Omit from transportability adjustment
- Assess bias when unmeasured confounder differs between sample and target

#### 3.3.2 Weight Truncation

Test impact of truncation parameter:
- No truncation (0%)
- Low truncation (2%)
- Medium truncation (5%)
- High truncation (10%)

Assess bias-variance tradeoff

#### 3.3.3 Misspecified Target

Test performance when target population parameters are misspecified:
- True age = 65, specified as 60
- True female% = 0.60, specified as 0.50
- Assess sensitivity of results

---

## 4. ANALYSIS PLAN

### 4.1 Primary Analysis

**For simulation study:**

1. Calculate bias, RMSE, coverage for each method × scenario
2. Identify scenarios where transportability reduces RMSE by ≥20%
3. Identify scenarios where transportability increases RMSE (harm)
4. Rank methods by overall performance

**Visualization:**
- Heatmaps: RMSE by scenario and method
- Forest plots: Bias by effect heterogeneity strength
- Scatter: Sample-target distance vs. RMSE improvement

**For real-world validation:**

1. Compare transported estimates to gold standard
2. Calculate absolute differences
3. Assess whether differences are clinically meaningful

### 4.2 Subgroup Analyses

Stratify results by:
- Strength of effect heterogeneity (none, mild, moderate, strong)
- Sample-target overlap (near, moderate, far)
- Meta-analysis size (small, medium, large)
- Between-study heterogeneity τ² (low, moderate, high)

### 4.3 Decision Rules

Develop evidence-based guidance:

**Use transportability when:**
- Effect heterogeneity by covariates exists (I² > 50% and moderators identified)
- Target population differs from sample by ≥0.5 SD on key covariates
- ≥10 studies available (ensures stable weights)
- Sample includes some studies similar to target (extrapolation < 2 SD)

**Avoid transportability when:**
- No evidence of effect heterogeneity
- Target population within sample covariate range
- Small meta-analysis (k < 10 studies)
- Extreme extrapolation needed (target > 2 SD from sample)

---

## 5. SAMPLE SIZE & POWER

### 5.1 Simulation Study

**Total simulations:** 108,000 (108 scenarios × 1,000 replications)

**Power calculation:**
- To detect 20% RMSE reduction with 80% power, α = 0.05
- Requires ~400 replications per scenario
- 1,000 replications provides >95% power

**Computational resources:**
- Estimated runtime: 48 hours on 16-core server
- Memory requirements: 32 GB RAM
- Storage: 500 GB for results

### 5.2 Real-World Validation

**Sample size:** 5-10 cases (limited by data availability)

**Rationale:** Real-world validation is exploratory; primary inference from simulation study

---

## 6. QUALITY CONTROL

### 6.1 Code Review

- All simulation code peer-reviewed by two independent statisticians
- Unit tests for all data generation functions
- Reproducible: Set seeds, document R/package versions

### 6.2 Intermediate Checks

**Week 2:** Pilot simulation (1 scenario, 100 reps) - check data generation
**Week 4:** Complete 10 scenarios - assess plausibility of results
**Week 6:** Full analysis - sensitivity checks

### 6.3 External Validation

- Share simulation code with 2 external methodologists for review
- Request independent replication of 10 random scenarios

---

## 7. DISSEMINATION

### 7.1 Documentation

**Deliverables:**
1. **Technical Report** (30-40 pages): Full methods, results, appendices
2. **CBAMMR User Guide** (5 pages): Practical guidance on when to use transportability
3. **Vignette** (8-10 pages): Worked examples with real data
4. **Test Suite Updates**: Add scenarios to test-transportability.R

### 7.2 Peer-Reviewed Publication

**Target journal:** Research Synthesis Methods or Statistics in Medicine

**Manuscript outline:**
1. Introduction: Need for transportability in meta-analysis
2. Methods: Entropy balancing, simulation design
3. Results: Performance across scenarios, real-world validation
4. Discussion: Practical guidance, limitations
5. Conclusion: When transportability improves meta-analysis validity

**Timeline:** Submit within 1 month of study completion

### 7.3 Software Updates

**CBAMMR package updates:**
1. Add `check_transportability()` function: Assesses whether transportability is appropriate
2. Enhanced warnings when extrapolation is extreme
3. Diagnostic plots: Sample vs. target covariate distributions
4. Documentation: Add limitations and appropriate use guidance

---

## 8. TIMELINE

### Phase 1: Preparation (Weeks 1-2)
- Finalize simulation parameters
- Write data generation functions
- Pilot test (1 scenario)
- **Milestone:** Pilot results reviewed

### Phase 2: Simulation Study (Weeks 3-6)
- Run full simulation (108,000 scenarios)
- Interim analysis at 50% completion
- Quality checks
- **Milestone:** Simulation complete

### Phase 3: Real-World Validation (Weeks 7-8)
- Identify 5-10 cases
- Extract data, apply methods
- Compare results
- **Milestone:** Real-world validation complete

### Phase 4: Analysis (Weeks 9-10)
- Primary analysis
- Subgroup analyses
- Sensitivity analyses
- Generate figures/tables
- **Milestone:** Analysis complete

### Phase 5: Dissemination (Weeks 11-12)
- Write technical report
- Write user guide
- Update documentation
- Manuscript draft
- **Milestone:** All deliverables drafted

**Total Duration:** 12 weeks (~3 months)

---

## 9. RISK MITIGATION

### Risk 1: Computational Resources

**Risk:** Simulation too computationally intensive
**Mitigation:**
- Parallelize across multiple cores
- Use high-performance computing cluster if needed
- Reduce to 500 reps if necessary

### Risk 2: Real-World Data Unavailable

**Risk:** Cannot find cases with sufficient data
**Mitigation:**
- Simulation study provides primary evidence
- Real-world validation is exploratory
- Can proceed with 3-5 cases minimum

### Risk 3: Method Performs Poorly

**Risk:** Entropy balancing underperforms in many scenarios
**Mitigation:**
- Document limitations transparently
- Develop decision rules for when NOT to use
- Consider implementing alternative methods (propensity scores, calibration)

### Risk 4: Timeline Delays

**Risk:** Study takes longer than 3 months
**Mitigation:**
- Build 2-week buffer into timeline
- Prioritize simulation study over real-world validation
- Can publish preliminary results and iterate

---

## 10. ETHICAL CONSIDERATIONS

### Data Privacy

All real-world validation uses published, de-identified meta-analysis data. No individual patient data.

### Transparency

- Pre-register simulation protocol (Open Science Framework)
- Make all code publicly available (GitHub)
- Report all scenarios (not just favorable results)

### Conflicts of Interest

None. Study conducted independently by CBAMMR development team.

---

## 11. SUCCESS CRITERIA

This validation study will be considered successful if:

1. ✅ **Completed on time:** All phases completed within 12 weeks
2. ✅ **Method validated:** Entropy balancing achieves covariate balance in ≥95% of scenarios
3. ✅ **Utility demonstrated:** Transportability reduces RMSE in ≥50% of scenarios with effect heterogeneity
4. ✅ **Guidance developed:** Clear decision rules for when to use transportability
5. ✅ **Documented:** Technical report and user guide completed
6. ✅ **Published:** Manuscript submitted to peer-reviewed journal
7. ✅ **Implemented:** CBAMMR package updated with validation results

---

## 12. REFERENCES

1. Hainmueller J. (2012). Entropy balancing for causal effects: A multivariate reweighting method to produce balanced samples in observational studies. *Political Analysis*, 20(1), 25-46.

2. Stuart EA, Cole SR, Bradshaw CP, Leaf PJ. (2011). The use of propensity scores to assess the generalizability of results from randomized trials. *J R Stat Soc Ser A*, 174(2), 369-386.

3. Tipton E. (2013). Improving generalizations from experiments using propensity score subclassification: Assumptions, properties, and contexts. *J Exp Criminol*, 9(1), 1-24.

4. Dahabreh IJ, Robertson SE, Tchetgen EJT, Stuart EA, Hernán MA. (2019). Generalizing causal inferences from individuals in randomized trials to all trial-eligible individuals. *Biometrics*, 75(2), 685-694.

5. Bareinboim E, Pearl J. (2016). Causal inference and the data-fusion problem. *Proc Natl Acad Sci USA*, 113(27), 7345-7352.

6. Lesko CR, Buchanan AL, Westreich D, Edwards JK, Hudgens MG, Cole SR. (2017). Generalizing study results: A potential outcomes perspective. *Epidemiology*, 28(4), 553-561.

7. Rudolph KE, van der Laan MJ. (2017). Robust estimation of encouragement design intervention effects transported across sites. *J R Stat Soc Series B*, 79(5), 1509-1525.

8. O'Muircheartaigh C, Hedges LV. (2014). Generalizing from unrepresentative experiments: A stratified propensity score approach. *J R Stat Soc Ser C*, 63(2), 195-210.

---

## APPENDICES

### Appendix A: R Code Template

```r
# Simulation framework for transportability validation
simulate_meta_analysis <- function(
  k = 15,                    # number of studies
  beta_age = 0.01,           # age-effect relationship
  beta_female = 0.05,        # sex-effect relationship
  beta_bmi = 0.02,           # BMI-effect relationship
  beta_charlson = 0.05,      # comorbidity-effect relationship
  tau2 = 0.10,               # between-study heterogeneity
  sample_age_mean = 55,      # sample population age
  target_age_mean = 70,      # target population age
  sample_female = 0.45,      # sample female proportion
  target_female = 0.60,      # target female proportion
  seed = NULL
) {
  if (!is.null(seed)) set.seed(seed)

  # Generate study characteristics
  # Generate true effects
  # Generate observed data
  # Apply transportability
  # Calculate performance metrics

  # Return results
}
```

### Appendix B: Decision Tree for Users

```
Should I use transportability adjustment?

1. Do I have study-level covariate data?
   NO → Cannot use transportability
   YES → Continue to Q2

2. Is there evidence of effect heterogeneity by covariates?
   NO (I² < 50% or no significant moderators) → Transportability unlikely to help
   YES → Continue to Q3

3. Does target population differ from sample?
   NO (target within sample range) → Unadjusted estimate already applicable
   YES → Continue to Q4

4. Do I have ≥10 studies?
   NO → Weights may be unstable; use with caution
   YES → Transportability likely appropriate

5. Is extrapolation extreme?
   YES (target >2 SD from sample) → Transportability may be unreliable
   NO → ✓ USE TRANSPORTABILITY
```

---

**Protocol Approval:** Pending review by CBAMMR methods team
**Version History:**
- v1.0 (2025-11-05): Initial draft

