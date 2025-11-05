# CBAMMR Input Validation Audit - Complete Report

**Total Functions Needing Validation:** 26

## 1. Effect Size Functions (yi, vi, sei) - 14 functions

These functions handle effect sizes and variances directly.
**Recommended validation:** `validate_meta_inputs(yi, vi)` or `validate_meta_inputs(yi, sei)`

- **cbamm_prob_best** (clinical-decision-tools.R:319)
  - Critical inputs: yi, vi
- **pet_peese** (core-functions.R:182)
  - Critical inputs: yi, sei
- **cbamm_heterogeneity_bf** (heterogeneity-methods.R:324)
  - Critical inputs: yi, vi, prior_tau
- **cbamm_heterogeneity_decomp** (heterogeneity-methods.R:518)
  - Critical inputs: yi, vi
- **cbamm_lrt** (model-selection.R:361)
  - Critical inputs: yi, vi
- **cbamm_compare_fe_re** (model-selection.R:453)
  - Critical inputs: yi, vi
- **cbamm_publication_bias_sensitivity** (sensitivity-analysis.R:343)
  - Critical inputs: yi, vi
- **cbamm_egger_test** (small-study-effects.R:210)
  - Critical inputs: yi, vi
- **cbamm_begg_test** (small-study-effects.R:259)
  - Critical inputs: yi, vi
- **cbamm_pcurve** (small-study-effects.R:460)
  - Critical inputs: yi, vi

## 2. Data Frame Functions (data) - 11 functions

These functions operate on data frames with study data.
**Recommended validation:** `validate_meta_data(data, required_cols = ...)`

- **cbamm_fragility_index** (clinical-decision.R:24)
  - Critical inputs: data, direction
- **compute_transport_weights** (core-functions.R:19)
  - Critical inputs: data, target_population, truncation
- **cbamm_calc_or** (effect-sizes.R:169)
  - Critical inputs: ai, bi, ci, di, data
- **cbamm_calc_rr** (effect-sizes.R:176)
  - Critical inputs: ai, bi, ci, di, data
- **cbamm_calc_rd** (effect-sizes.R:183)
  - Critical inputs: ai, bi, ci, di, data
- **cbamm_calc_peto** (effect-sizes.R:190)
  - Critical inputs: ai, bi, ci, di, data
- **cbamm_calc_md** (effect-sizes.R:197)
  - Critical inputs: m1i, sd1i, n1i, m2i, sd2i, n2i, data
- **cbamm_calc_smd** (effect-sizes.R:206)
  - Critical inputs: m1i, sd1i, n1i, m2i, sd2i, n2i, data
- **cbamm_calc_prop** (effect-sizes.R:215)
  - Critical inputs: xi, mi, data
- **cbamm_calc_ir** (effect-sizes.R:221)
  - Critical inputs: xi, ti, data
- **cbamm_calc_zcor** (effect-sizes.R:227)
  - Critical inputs: ri, ni, data
- **cbamm_make_summary_table** (tables.R:13)
  - Critical inputs: data, config

## 3. Other Functions - 5 functions

These functions have mixed validation requirements.

- **cbamm_rmst_meta** (clinical-decision-tools.R:237)
  - Critical inputs: rmst1, rmst0, se1, se0, time_horizon
  - Needs: rmst1, rmst0, se1, se0, time_horizon
- **initialize_cbamm** (setup.R:202)
  - Critical inputs: config
  - Needs: config
- **simulate_cbamm_binary** (simulation.R:75)
  - Critical inputs: seed
  - Needs: 
- **simulate_cbamm_continuous** (simulation.R:107)
  - Critical inputs: seed
  - Needs: 

## Functions by File

### clinical-decision-tools.R (2 functions)

- **Line 237:** `cbamm_rmst_meta`
  - Parameters: rmst1, rmst0, se1, se0, time_horizon
  - Critical: rmst1, rmst0, se1, se0, time_horizon

- **Line 319:** `cbamm_prob_best`
  - Parameters: yi, vi, treatment_names, n_sim
  - Critical: yi, vi

### clinical-decision.R (1 functions)

- **Line 24:** `cbamm_fragility_index`
  - Parameters: results, data, alpha, direction
  - Critical: data, direction

### core-functions.R (2 functions)

- **Line 19:** `compute_transport_weights`
  - Parameters: data, target_population, truncation
  - Critical: data, target_population, truncation

- **Line 182:** `pet_peese`
  - Parameters: yi, sei
  - Critical: yi, sei

### effect-sizes.R (9 functions)

- **Line 169:** `cbamm_calc_or`
  - Parameters: ai, bi, ci, di, data, ...
  - Critical: ai, bi, ci, di, data

- **Line 176:** `cbamm_calc_rr`
  - Parameters: ai, bi, ci, di, data, ...
  - Critical: ai, bi, ci, di, data

- **Line 183:** `cbamm_calc_rd`
  - Parameters: ai, bi, ci, di, data, ...
  - Critical: ai, bi, ci, di, data

- **Line 190:** `cbamm_calc_peto`
  - Parameters: ai, bi, ci, di, data, ...
  - Critical: ai, bi, ci, di, data

- **Line 197:** `cbamm_calc_md`
  - Parameters: m1i, sd1i, n1i, m2i, sd2i, n2i, data, ...
  - Critical: m1i, sd1i, n1i, m2i, sd2i, n2i, data

- **Line 206:** `cbamm_calc_smd`
  - Parameters: m1i, sd1i, n1i, m2i, sd2i, n2i, data, ...
  - Critical: m1i, sd1i, n1i, m2i, sd2i, n2i, data

- **Line 215:** `cbamm_calc_prop`
  - Parameters: xi, mi, data, ...
  - Critical: xi, mi, data

- **Line 221:** `cbamm_calc_ir`
  - Parameters: xi, ti, data, ...
  - Critical: xi, ti, data

- **Line 227:** `cbamm_calc_zcor`
  - Parameters: ri, ni, data, ...
  - Critical: ri, ni, data

### heterogeneity-methods.R (2 functions)

- **Line 324:** `cbamm_heterogeneity_bf`
  - Parameters: yi, vi, prior_tau
  - Critical: yi, vi, prior_tau

- **Line 518:** `cbamm_heterogeneity_decomp`
  - Parameters: yi, vi, subgroups, method
  - Critical: yi, vi

### model-selection.R (2 functions)

- **Line 361:** `cbamm_lrt`
  - Parameters: yi, vi, mods1, mods2, method
  - Critical: yi, vi

- **Line 453:** `cbamm_compare_fe_re`
  - Parameters: yi, vi
  - Critical: yi, vi

### sensitivity-analysis.R (1 functions)

- **Line 343:** `cbamm_publication_bias_sensitivity`
  - Parameters: yi, vi, methods
  - Critical: yi, vi

### setup.R (1 functions)

- **Line 202:** `initialize_cbamm`
  - Parameters: config
  - Critical: config

### simulation.R (2 functions)

- **Line 75:** `simulate_cbamm_binary`
  - Parameters: n, measure, seed
  - Critical: seed

- **Line 107:** `simulate_cbamm_continuous`
  - Parameters: n, measure, seed
  - Critical: seed

### small-study-effects.R (3 functions)

- **Line 210:** `cbamm_egger_test`
  - Parameters: yi, vi, method
  - Critical: yi, vi

- **Line 259:** `cbamm_begg_test`
  - Parameters: yi, vi
  - Critical: yi, vi

- **Line 460:** `cbamm_pcurve`
  - Parameters: yi, vi
  - Critical: yi, vi

### tables.R (1 functions)

- **Line 13:** `cbamm_make_summary_table`
  - Parameters: results, data, config
  - Critical: data, config
