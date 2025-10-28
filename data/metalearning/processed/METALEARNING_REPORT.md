# Meta-Learning Database Report

**Generated:** 1761649723.9744897

## Summary Statistics

- **Total Datasets:** 27
- **With Effect Sizes:** 0
- **With Heterogeneity Stats (I², τ²):** 0
- **Year Range:** 2006-2020
- **Avg Studies per Dataset:** 66.0
- **Median Studies per Dataset:** 45

## Datasets by Source

- **synergy:** 27

## Top 10 Domains

- Dementia: 2
- Software Fault Prediction: 2
- Wilson disease: 1
- Animal Model of Depression: 1
- ACEInhibitors: 1
- ADHD: 1
- Antihistamines: 1
- Atypical Antipsychotics: 1
- Beta Blockers: 1
- Calcium Channel Blockers: 1

## Next Steps

### For SYNERGY datasets (screening data only):
- ✅ Extracted: n_studies, domain, year, screening statistics
- ❌ Missing: Effect sizes, I², τ², Q (not in SYNERGY)
- **Action:** Use as supplementary metadata only

### For metadat package (actual meta-analysis data):
- ❌ Not yet processed (requires R integration)
- **Action:** Run R script to extract effect sizes and heterogeneity

### Training Meta-Learning Models:
- **Need:** 500+ datasets with I² and τ² statistics
- **Have:** SYNERGY metadata (no effect sizes)
- **TODO:** Process metadat package (350+ datasets with effect sizes)
- **TODO:** Find additional sources with published meta-analysis results

