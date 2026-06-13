# SBC + Truth-Recovery for CBAMMR

CBAMMR computes an **exact grid posterior** for a Bayesian Normal-Normal random-
effects meta-analysis (half-Cauchy τ prior). Its 25 unit tests check the
posterior is *computed* correctly. They do not check the two things that decide
whether its intervals can be *trusted*. This module adds both.

> Truth-first: seeded, reproducible. `node truth-recovery/harness.mjs --sbc 2000 --reps 600`
> (results below: 1500 prior draws for SBC; 500 reps/cell for coverage; seed=20260613).

## 1. Simulation-Based Calibration (Talts et al. 2018) — **PASS**

Draw `(μ, τ)` from the prior → simulate data → refit → the posterior quantile
(PIT) of the true `μ` must be Uniform(0,1). Any miscalibration (bug in the
posterior, prior, or grid) shows up as a non-uniform PIT.

| statistic | value | target |
|---|---|---|
| PIT KS distance | **0.0104** | < 0.0351 (95% crit) → **CALIBRATED** |
| PIT mean | 0.4994 | 0.5 |
| PIT χ²(9 df) | 2.13 | ~8.3 |
| PIT histogram (10 bins) | [153,152,142,155,152,140,156,155,143,152] | flat @ 150 |

This is the **first formal calibration evidence** for the engine: its grid
posterior recovers the truth with exactly nominal uncertainty when the model is
correct. A regression test (`test-truth-recovery.mjs`) now guards it.

## 2. Frequentist coverage of the Bayesian intervals under known truth

(`mu=0.3, tau2=0.05`, allmeta truth-recovery DGP)

| | clean (no selection) | nominal |
|---|---|---|
| 95% credible interval of μ | **0.968** | 0.95 |
| 95% posterior-predictive interval (new study) | **0.961** | 0.95 |

On clean data both intervals are honest (mildly conservative — the half-Cauchy
prior slightly widens them, which is the safe direction). Notably the Bayesian
**predictive** interval is far more robust to publication selection than
frequentist plug-in PIs: under `step_strong` it holds 0.78–0.92 (vs the t_{k-1}
plug-in PI which collapses), because selection inflates the apparent τ² that
dominates the predictive width.

## Honest limitation

The **credible interval of μ** collapses under strong selection (0.10 at k=20),
exactly like every method that does not model selection — CBAMMR's likelihood has
no selection component. That is expected and is the gap a selection-aware prior
(or a Copas/PET-PEESE layer) would fill; the number quantifies it.

## What transferred from the allmeta estimator work

- **Transferred:** SBC (the simulation-based-calibration check that delivers
  honest coverage guarantees) applied perfectly here — the grid posterior is
  deterministic, so SBC is exact and cheap, and it confirms calibration. Plus the
  known-truth coverage yardstick.
- **Did not transfer:** the NPE estimator and conformal calibration are
  alternatives to this Bayesian engine, not additions to it; out of scope. SBC
  was the relevant learning and it fit cleanly.

## Files
`dgp.mjs` (seeded known-truth DGP + new-study draw) · `harness.mjs` (SBC + coverage) ·
`test-truth-recovery.mjs` (6 measured invariants).
