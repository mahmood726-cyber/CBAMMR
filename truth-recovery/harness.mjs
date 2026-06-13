// ============================================================
// harness.mjs — Truth-recovery + Simulation-Based Calibration (SBC) for CBAMMR.
//
// CBAMMR computes an exact grid posterior for a Bayesian Normal-Normal random-
// effects meta-analysis (half-Cauchy tau prior). Its 25 unit tests check the
// posterior is computed correctly. They do NOT check the two things that decide
// whether the intervals can be trusted:
//
//   1. SBC (Talts et al. 2018): if you draw (mu, tau) from the PRIOR, simulate
//      data, and refit, the posterior quantile (PIT) of the true mu must be
//      Uniform(0,1). Non-uniform PIT = the inference is miscalibrated (a bug in
//      the posterior, the prior, or the grid). This is the gold-standard self-
//      consistency check for a Bayesian engine and CBAMMR had none.
//
//   2. Frequentist coverage under KNOWN TRUTH: a 95% credible interval need not
//      cover the true mu 95% of the time; and the posterior-predictive interval
//      need not cover a NEW study's true effect. We measure both, on clean data
//      and under publication selection (allmeta truth-recovery DGP).
//
// Truth-first: seeded, reproducible. Nothing hand-entered.
//   node truth-recovery/harness.mjs --sbc 2000 --reps 600
// ============================================================

import { createRequire } from 'node:module';
import { generate, makeRng, SCENARIOS } from './dgp.mjs';
const require = createRequire(import.meta.url);
const M = require('../engine.js');

const BASE_SEED = 20260613;
const SCALE = 0.5;           // half-Cauchy scale used both as prior and in fits
const LEVEL = 0.95;

// ---- seeded standard normal (mulberry32 stream -> Box-Muller) ----
function randn(rng) {
  let u1 = rng(); const u2 = rng();
  if (u1 < 1e-12) u1 = 1e-12;
  return Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
}
// half-Cauchy(scale) via inverse CDF of the folded Cauchy
function halfCauchyDraw(rng, scale) {
  return Math.abs(scale * Math.tan(Math.PI * (rng() - 0.5)));
}

// posterior CDF at a value, from the engine's normalised density grid (trapz).
function posteriorCdf(grid, density, x) {
  if (x <= grid[0]) return 0;
  if (x >= grid[grid.length - 1]) return 1;
  let area = 0;
  for (let i = 1; i < grid.length; i++) {
    const x0 = grid[i - 1], x1 = grid[i];
    if (x1 <= x) {
      area += 0.5 * (density[i - 1] + density[i]) * (x1 - x0);
    } else {
      // partial trapezoid up to x
      const t = (x - x0) / (x1 - x0);
      const dx = x - x0;
      const dAtX = density[i - 1] + t * (density[i] - density[i - 1]);
      area += 0.5 * (density[i - 1] + dAtX) * dx;
      break;
    }
  }
  return Math.min(1, Math.max(0, area));
}

// ---------------------------------------------------------------------------
// SBC: PIT of the true mu should be Uniform(0,1) when the model is correct.
// ---------------------------------------------------------------------------
export function runSBC(nSim, { k = 12, scale = SCALE } = {}) {
  const rng = makeRng(BASE_SEED ^ 0x5bc);
  const pit = [];
  for (let s = 0; s < nSim; s++) {
    const tau = halfCauchyDraw(rng, scale);
    const mu = 1.0 * randn(rng);                 // wide-ish prior on mu
    const se = Array.from({ length: k }, () =>
      Math.exp(Math.log(0.1) + (Math.log(0.7) - Math.log(0.1)) * rng()));
    const yi = se.map(sei => mu + tau * randn(rng) + sei * randn(rng));
    const vi = se.map(sei => sei * sei);
    let res;
    try { res = M.bayesMA(yi, vi, { scale, level: LEVEL }); } catch { continue; }
    if (!res || res.error) continue;
    pit.push(posteriorCdf(res.mu.grid, res.mu.density, mu));
  }
  // KS distance of PIT to Uniform(0,1)
  const sorted = [...pit].sort((a, b) => a - b);
  const n = sorted.length;
  let ks = 0;
  for (let i = 0; i < n; i++) {
    ks = Math.max(ks, Math.abs(sorted[i] - i / n), Math.abs((i + 1) / n - sorted[i]));
  }
  // 10-bin histogram of PIT (should be ~flat at n/10)
  const bins = new Array(10).fill(0);
  for (const p of pit) bins[Math.min(9, Math.floor(p * 10))]++;
  const expected = n / 10;
  const chi2 = bins.reduce((a, b) => a + (b - expected) ** 2 / expected, 0);
  const ksCrit = 1.358 / Math.sqrt(n);   // ~95% KS critical value
  return { n, ks: +ks.toFixed(4), ksCrit: +ksCrit.toFixed(4),
           calibrated: ks < ksCrit, chi2_9df: +chi2.toFixed(2),
           pitMean: +(pit.reduce((a, b) => a + b, 0) / n).toFixed(4),
           histogram: bins };
}

// ---------------------------------------------------------------------------
// Frequentist coverage of the Bayesian intervals under known truth.
// ---------------------------------------------------------------------------
export function runCoverageCell(mu, tau2, k, scenario, reps, rng) {
  let covMu = 0, nMu = 0, covPred = 0, nPred = 0, biasSum = 0, n = 0, wMu = 0, wPred = 0;
  for (let r = 0; r < reps; r++) {
    const { yi, vi, newTheta } = generate(mu, tau2, k, scenario, rng);
    let res;
    try { res = M.bayesMA(yi, vi, { scale: SCALE, level: LEVEL }); } catch { continue; }
    if (!res || res.error) continue;
    n++; biasSum += res.mu.median - mu;
    nMu++; wMu += res.mu.crI.hi - res.mu.crI.lo;
    if (res.mu.crI.lo <= mu && mu <= res.mu.crI.hi) covMu++;
    nPred++; wPred += res.pred.crI.hi - res.pred.crI.lo;
    if (res.pred.crI.lo <= newTheta && newTheta <= res.pred.crI.hi) covPred++;
  }
  return {
    n, bias: n ? +(biasSum / n).toFixed(4) : null,
    covMu: nMu ? +(covMu / nMu).toFixed(3) : null,
    covPred: nPred ? +(covPred / nPred).toFixed(3) : null,
    widthMu: nMu ? +(wMu / nMu).toFixed(3) : null,
    widthPred: nPred ? +(wPred / nPred).toFixed(3) : null,
  };
}

export function runCoverageGrid({ reps = 600, ks = [5, 10, 20], tau2 = 0.05,
                                  scenarios = SCENARIOS, mu = 0.3 } = {}) {
  const rng = makeRng(BASE_SEED);
  const grid = [];
  for (const scen of scenarios)
    for (const k of ks)
      grid.push({ scen, k, ...runCoverageCell(mu, tau2, k, scen, reps, rng) });
  return grid;
}

const isMain = process.argv[1]?.endsWith('harness.mjs');
if (isMain) {
  const arg = (f, d) => { const i = process.argv.indexOf(f); return i >= 0 ? Number(process.argv[i + 1]) : d; };
  const nSbc = arg('--sbc', 2000);
  const reps = arg('--reps', 600);
  const t0 = Date.now();

  console.log(`\n# CBAMMR — SBC + truth-recovery  (scale=${SCALE}, seed=${BASE_SEED})\n`);
  const sbc = runSBC(nSbc);
  console.log(`## Simulation-Based Calibration (n=${sbc.n} prior draws, k=12)`);
  console.log(`PIT KS distance = ${sbc.ks}  (95% critical = ${sbc.ksCrit})  -> ` +
    (sbc.calibrated ? 'CALIBRATED' : 'MISCALIBRATED'));
  console.log(`PIT mean = ${sbc.pitMean} (target 0.5)   chi2(9df) = ${sbc.chi2_9df} (target ~8.3)`);
  console.log(`PIT histogram (10 bins, target flat @ ${(sbc.n / 10).toFixed(0)}): [${sbc.histogram.join(', ')}]`);

  const grid = runCoverageGrid({ reps });
  console.log(`\n## Frequentist coverage of the Bayesian intervals (mu=0.3, tau2=0.05, reps=${reps}/cell)\n`);
  console.log('scenario       k   covMu  covPred   widthMu  widthPred   bias');
  for (const c of grid) {
    console.log(c.scen.padEnd(13), String(c.k).padStart(3),
      String(c.covMu).padStart(6), String(c.covPred).padStart(7),
      String(c.widthMu).padStart(10), String(c.widthPred).padStart(10),
      String(c.bias).padStart(8));
  }
  const mean = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;
  const cleanMu = mean(grid.filter(c => c.scen === 'none').map(c => c.covMu));
  const cleanPred = mean(grid.filter(c => c.scen === 'none').map(c => c.covPred));
  console.log(`\n## Clean-data means: credible-mu coverage=${cleanMu.toFixed(3)}  predictive coverage=${cleanPred.toFixed(3)} (nominal 0.95)`);
  console.log(`\n(${((Date.now() - t0) / 1000).toFixed(1)}s)`);
}
