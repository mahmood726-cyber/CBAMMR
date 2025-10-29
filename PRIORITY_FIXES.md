# CBAMMR Priority Fixes - Action Plan

## Summary of Review
**Overall Rating: 6.5/10** - Good concept, needs implementation refinement
**Status: BETA** - Not yet production-ready for high-stakes publications

---

## CRITICAL ISSUES (Must Fix Before Publication Use)

### 1. **Journal Output Placeholders** ⚠️ HIGHEST PRIORITY
**Problem:** Output contains many [placeholder] texts that users must manually fill
**Impact:** FALSE ADVERTISING - not truly "copy-paste ready"
**Locations:**
- Line 155: `[add total participants]`
- Line 182: `[N]` for sample sizes
- Line 191: `[specify tool]` for quality
- Line 209: `[describe direction and magnitude]`

**Fix:**
```r
# Option A: Extract real values from data
study_info <- data.frame(
  study_name = ...,
  sample_size = ...,
  year = ...
)

# Option B: Clear warnings
"[USER MUST ADD: total participants]"

# Option C: Remove feature until ready
```

**Effort:** Medium (2-3 days)
**Impact:** HIGH - Affects credibility

---

### 2. **Rare Events Not Handled** ⚠️ HIGH PRIORITY
**Problem:** Always uses standard OR, even for rare events (<1%)
**Impact:** Biased estimates, incorrect conclusions for adverse events
**Location:** `R/intelligent-auto-analysis.R:330`

**Fix:**
```r
# After detecting binary data:
event_rate <- calculate_event_rate(data)

if (any(event_rate < 0.01)) {
  measure <- "PETO"  # Peto OR for rare events
  warning("Rare events detected. Using Peto OR instead of standard OR.")
} else if (any(event_rate < 0.05)) {
  warning("Moderately rare events. Standard OR may be biased. Consider Peto OR.")
  measure <- "OR"
} else {
  measure <- "OR"
}
```

**Effort:** Medium (1-2 days)
**Impact:** HIGH - Affects statistical validity

---

### 3. **Publication Bias Vote Counting** ⚠️ HIGH PRIORITY
**Problem:** Counting significant tests is crude and ignores power/sample size
**Impact:** Misleading bias assessment
**Location:** `R/intelligent-auto-analysis.R:572-607`

**Fix:**
```r
if (k < 10) {
  concern <- "UNCERTAIN"
  decision <- "Too few studies for reliable publication bias assessment"
  recommend_adjustment <- FALSE
} else {
  # Use weighted evidence approach
  # Consider magnitude, not just significance
  # Prioritize Egger's test over others

  if (egger$p_value < 0.05 && abs(egger$estimate) > threshold) {
    concern <- "MODERATE to HIGH"
  } else if (multiple_tests_borderline) {
    concern <- "MODERATE"
  } else {
    concern <- "LOW"
  }
}
```

**Effort:** Medium (1-2 days)
**Impact:** MODERATE - Improves accuracy

---

### 4. **No Validation** ⚠️ HIGH PRIORITY
**Problem:** No evidence that automated decisions are correct
**Impact:** Unknown accuracy, trustworthiness unclear

**Fix:**
```r
# Create validation suite:
1. Benchmark against 20 Cochrane reviews
2. Compare cbamm_auto() results to published results
3. Check that calculations match metafor exactly
4. Document agreement rates
5. Create unit tests for all functions
```

**Effort:** High (1-2 weeks)
**Impact:** CRITICAL - Required for credibility

---

## IMPORTANT ISSUES (Should Fix Soon)

### 5. **Study Metadata Missing** 📋 MODERATE PRIORITY
**Problem:** Can't populate Table 1 with real study names, years, samples
**Impact:** Output not truly publication-ready

**Fix:**
```r
cbamm_auto <- function(data, study_id = NULL,
                       study_info = NULL,  # NEW parameter
                       ...) {
  # study_info should contain:
  # - study_name
  # - year
  # - sample_size_treatment
  # - sample_size_control
  # - quality_assessment (optional)
}
```

**Effort:** Medium (2-3 days)
**Impact:** MODERATE - Improves usability

---

### 6. **Heterogeneity Thresholds Arbitrary** 📊 MODERATE PRIORITY
**Problem:** I² thresholds (25%, 50%, 75%) not evidence-based
**Impact:** Potentially misleading interpretations

**Fix:**
```r
# De-emphasize I² thresholds
# Emphasize prediction intervals instead
# Add confidence intervals for I²
# Context-dependent interpretation

het_text <- paste0(
  "Heterogeneity: I² = ", I2, "% (95% CI: [", I2_lb, ", ", I2_ub, "]). ",
  "Prediction interval: [", pi_lb, ", ", pi_ub, "]. ",
  "The prediction interval shows the expected range of effects in new studies, ",
  "which is ", interpret_pi_width(pi_lb, pi_ub)
)
```

**Effort:** Low (1 day)
**Impact:** MODERATE - Better interpretation

---

### 7. **No Subgroup Analysis** 📈 MODERATE PRIORITY
**Problem:** Recommends exploring heterogeneity but doesn't do it
**Impact:** Incomplete analysis when I² > 75%

**Fix:**
```r
# When I² > 75%, automatically:
1. Detect categorical/continuous variables in data
2. Run subgroup analyses for categorical
3. Run meta-regression for continuous
4. Report as exploratory
5. Create subgroup forest plots

if (het$I2 > 75 && !is.null(moderators)) {
  subgroup_results <- auto_explore_moderators(yi, vi, moderators)
  recommendations$heterogeneity <- paste0(
    "HIGH heterogeneity detected. Exploratory moderator analyses conducted. ",
    "Results suggest [X] may explain some heterogeneity. ",
    "Results are exploratory and hypothesis-generating."
  )
}
```

**Effort:** High (3-5 days)
**Impact:** MODERATE - More complete analysis

---

## NICE TO HAVE (Future Enhancements)

### 8. **Risk of Bias Integration** 🔍 LOW PRIORITY
**Fix:** Add RoB 2.0 / ROBINS-I parameters and sensitivity analysis by quality
**Effort:** High (1 week)

### 9. **GRADE Assessment** 📝 LOW PRIORITY
**Fix:** Automate certainty of evidence assessment
**Effort:** High (1-2 weeks)

### 10. **Advanced Methods** 🚀 LOW PRIORITY
**Fix:** Add robust variance estimation, three-level MA, multivariate MA
**Effort:** Very High (months)

---

## QUICK WINS (Easy Fixes)

### Error Handling
```r
# Add at start of cbamm_auto():
if (nrow(data) < 3) {
  stop("Meta-analysis requires at least 3 studies. Current: ", nrow(data))
}

if (any(is.na(yi)) || any(is.na(vi))) {
  warning("Missing effect sizes or variances detected. These will be excluded.")
  complete <- !is.na(yi) & !is.na(vi)
  yi <- yi[complete]
  vi <- vi[complete]
}
```

### Better Interpretation
```r
# Replace Cohen's benchmarks with contextual language
interpret_es <- function(es, measure, context = NULL) {
  if (!is.null(context)) {
    # Use context-specific interpretation
  } else {
    # Provide number without interpretation
    paste0("The effect size of ", round(es, 3),
           " should be interpreted in the context of the specific field and outcome.")
  }
}
```

---

## IMPLEMENTATION TIMELINE

### Week 1-2: Critical Fixes
- [ ] Fix journal output placeholders (Issue #1)
- [ ] Add rare event detection (Issue #2)
- [ ] Improve publication bias logic (Issue #3)

### Week 3-4: Validation
- [ ] Create validation suite (Issue #4)
- [ ] Benchmark against Cochrane reviews
- [ ] Write validation report

### Week 5-6: Important Improvements
- [ ] Add study metadata integration (Issue #5)
- [ ] Improve heterogeneity interpretation (Issue #6)
- [ ] Better error handling

### Week 7-8: Nice to Have
- [ ] Add automatic subgroup analysis (Issue #7)
- [ ] Risk of bias integration (Issue #8)
- [ ] Documentation improvements

---

## TESTING PROTOCOL

### Before Each Release:
1. ✓ All unit tests pass
2. ✓ Validation benchmarks pass
3. ✓ No placeholders in output
4. ✓ Manual review of 5 example outputs
5. ✓ External expert review

### Test Datasets Needed:
- Binary outcomes (common events)
- Binary outcomes (rare events) ← CRITICAL
- Continuous outcomes (homogeneous)
- Continuous outcomes (heterogeneous)
- Small k (3-5 studies)
- Large k (>30 studies)
- Zero cells / continuity corrections
- Known Cochrane reviews (for validation)

---

## DECISION POINTS

**Question 1: Fix Now or Start Over?**
**Answer:** FIX NOW - core is sound, issues are fixable

**Question 2: Keep Full Automation?**
**Answer:** YES - but add warnings and caveats where needed

**Question 3: Remove Journal Output Feature?**
**Answer:** NO - but fix placeholders first, then re-release

**Question 4: Priority Order?**
**Recommendation:**
1. Placeholders (credibility)
2. Rare events (validity)
3. Validation (trust)
4. Publication bias (accuracy)
5. Everything else

---

## SUCCESS CRITERIA

**Version 1.0 Production Ready When:**
- ✓ Zero placeholders in output OR clear [USER MUST ADD] labels
- ✓ Rare events handled correctly
- ✓ Validated against ≥20 published meta-analyses (>90% agreement)
- ✓ Publication bias assessment improved
- ✓ Comprehensive error handling
- ✓ External expert review completed
- ✓ Documentation updated
- ✓ All unit tests passing

**Then:** Ready for publication in methods journal and broader adoption

---

## BOTTOM LINE

**Current State:** Promising beta tool (6.5/10)
**With Fixes:** Production-ready tool (8.5-9/10)
**Time Needed:** 6-8 weeks of focused development
**Worth It?:** YES - addresses real problems in meta-analysis

**The concept is excellent. The implementation needs polish.**
