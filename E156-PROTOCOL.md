# E156-PROTOCOL — CBAMMR (Bayesian Normal-Normal Meta-Analysis)

- Project: CBAMMR — Bayesian Normal-Normal Meta-Analysis
- Repository: https://github.com/mahmood726-cyber/CBAMMR
- Dashboard: https://mahmood726-cyber.github.io/CBAMMR/
- Build date: 2026-06-04

---

## CURRENT BODY

Can a fully Bayesian random-effects meta-analysis of normally-distributed study estimates be computed offline in a browser without sampling, and stay faithful to the frequentist anchor? We use a ten-study reference set of effect estimates with known within-study variances on a single analysis scale. We place a half-Cauchy(0, s) prior on the heterogeneity standard deviation and a flat prior on the overall mean, then build the marginal posterior of the mean as a mixture, over a four-hundred-point heterogeneity grid, of inverse-variance normals weighted by the profiled heterogeneity posterior. The posterior mean of the overall effect was 0.282 under a wide prior, within 0.0022 of the metafor REML estimate of 0.280. Credible-interval width increased monotonically with the prior scale, and the prediction interval enclosed the credible interval. Grid approximation is valid because the target is unimodal in one or two parameters. Intervals are density quantiles, not normal approximations, and the method assumes within-study variances are known.

## YOUR REWRITE


## SUBMITTED: [ ]
