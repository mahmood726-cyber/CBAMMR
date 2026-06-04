# CBAMMR — Bayesian Normal-Normal Meta-Analysis

A single-file, fully-offline browser tool for **fully Bayesian random-effects
meta-analysis by grid approximation**. The heterogeneity standard deviation
*τ* receives a half-Cauchy(0, *s*) prior and the overall mean *μ* a flat prior;
the tool returns the **marginal posterior of μ** with its credible interval and
a **Bayesian prediction interval** for a future study effect.

It is intentionally distinct from the portfolio's MAP-prior tools: those place
an informative prior on the *current* mean borrowed from historical data; this
tool does a standard objective-prior Bayesian RE meta-analysis and exposes the
full posterior densities, not just summaries.

## Model

For studies *i = 1…k* with estimate *yᵢ* and known variance *vᵢ* on the
analysis scale:

```
yᵢ      ~ Normal(θᵢ, vᵢ)
θᵢ      ~ Normal(μ, τ²)
τ       ~ half-Cauchy(0, s)      (user scale s, default 0.5)
μ       ~ flat (improper)
```

The overall-mean prior being flat, *μ* integrates out analytically (a Gaussian
integral), giving the **marginal posterior of τ**:

```
p(τ | y) ∝ halfCauchy(τ; s) · √V(τ) · ∏ᵢ (vᵢ+τ²)^(−1/2) · exp(−½ Σᵢ wᵢ(τ)(yᵢ−μ̂(τ))²)
wᵢ(τ) = 1/(vᵢ+τ²),   μ̂(τ) = Σ wᵢyᵢ / Σ wᵢ,   V(τ) = 1/Σ wᵢ
```

normalised over a τ grid (≥ 400 points, default 600; `tauMax = 5·√(max vᵢ) +
5·sd(yᵢ)`). The **marginal posterior of μ** is the mixture over the τ grid of
`Normal(μ̂(τ), V(τ))` weighted by `p(τ|y)`; the **posterior predictive** of a
new study `θ_new` mixes `Normal(μ̂(τ), V(τ)+τ²)`. Credible and prediction
intervals are **quantiles of the normalised marginal densities** (trapezoid
CDF), not mean ± z·SE — the mixture is generally non-Gaussian.

Grid approximation is appropriate here because the inference target is a 1–2
parameter unimodal problem (the regime flagged as grid-safe in the portfolio's
`advanced-stats.md`).

## Provenance

| Choice | Value / rule | Why |
|---|---|---|
| τ prior | half-Cauchy(0, *s*), default *s* = 0.5 | Standard weakly-informative prior for a heterogeneity SD (Gelman 2006; Polson & Scott 2012) |
| μ prior | flat (improper) | Objective overall-mean prior; integrates out analytically |
| τ grid | ≥ 400 points incl. 0; `tauMax = 5·√(max vᵢ) + 5·sd(yᵢ)` | Data-driven upper bound; grid OK for 1–2 unimodal params |
| Normalisation | trapezoid rule; densities sum to 1 | Quantile intervals require an exact normalised density |
| Intervals | density quantiles, not mean ± z·SE | Posterior of μ is a τ-mixture, not Gaussian |
| Numeric fallbacks | `??` (nullish), never `\|\|` | Keeps legitimate 0 (e.g. τ grid point 0, scale, level) |
| Anchor | metafor `rma(yi, vi, method="REML")` | Under a vague prior the posterior **mean** of μ ≈ REML point estimate |

## Validation

`tests.js` anchors the engine against **metafor 4.x (R 4.6.0)**. For the
10-study dataset

```
yi <- c(0.00,0.52,-0.30,0.81,0.18,0.95,-0.12,0.60,0.35,0.05)
vi <- c(0.02,0.03,0.015,0.04,0.02,0.05,0.018,0.03,0.025,0.012)
rma(yi, vi, method="REML")$beta  ->  0.27980708
```

the fully-Bayesian posterior **mean** of μ under a wide half-Cauchy (s = 5) is
`0.281991`, within `0.0022` of the REML point estimate (spec tolerance 0.02).
Tests also assert: τ and μ posteriors each integrate to 1; the credible
interval brackets the posterior mean; the prediction interval is wider than and
encloses the credible interval; and credible-interval width is **monotone
increasing** in the half-Cauchy scale.

## Layout

| File | Role |
|---|---|
| `engine.js` | Pure logic (no DOM). IIFE exporting to `module.exports` (Node) and `window.CBAMMR` (browser). |
| `tests.js` | Node test harness (`require('./engine.js')`). Prints `N passed, M failed`, exits non-zero on any failure. |
| `index.html` | Single-file offline UI. Loads `chartkit.js` then `engine.js` then an inline script. |
| `chartkit.js` | Offline SVG dataviz kit, copied verbatim from the e156 flagship kit. Uses `renderDensity`. |
| `README.md` | This file. |
| `E156-PROTOCOL.md` | E156 micro-paper protocol (CURRENT BODY + submission flag). |
| `LICENSE` | MIT. |

## Tests

```
$ node tests.js

25 passed, 0 failed
```

## Reuse vs net-new

**Reused.** The IIFE dual-export module pattern, the `approx`/`ok` Node test
harness, and the single-file offline HTML/CSS shell follow
`html1-effectsize`. The metafor-anchored validation discipline follows
`htmlpairwise-repro`. The `renderDensity` SVG renderer and the entire
`chartkit.js` are copied verbatim from `C:/Projects/e156/flagship/kit`.

**Net-new.** The grid-approximation Bayesian normal-normal engine: the
profiled marginal posterior of τ under a half-Cauchy prior, the τ-mixture
marginal posterior of μ, the posterior-predictive prediction interval, and the
trapezoid-CDF density-quantile routine used for all intervals. No prior
portfolio tool computes a full Bayesian RE posterior by grid — the MAP-prior
tools solve a different problem (informative borrowing of the current mean).

## Usage

Open `index.html` in any browser (no server needed). Paste studies as
`label, estimate, variance` (one per line; variance = SE²), pick a half-Cauchy
scale and credible level, optionally toggle the log axis for ratio measures,
and read the posterior summary and density. Verify any posterior against your
primary analysis before reporting.
