/* Node tests for the Bayesian normal-normal RE meta-analysis engine.
 *
 * Anchor: metafor 4.x (R 4.6.0) REML on the same (yi, vi) dataset.
 *   library(metafor)
 *   yi <- c(0.00,0.52,-0.30,0.81,0.18,0.95,-0.12,0.60,0.35,0.05)
 *   vi <- c(0.02,0.03,0.015,0.04,0.02,0.05,0.018,0.03,0.025,0.012)
 *   rma(yi, vi, method="REML")$beta  ->  0.27980708
 * Under a vague (wide half-Cauchy) prior on tau, the fully-Bayesian posterior
 * MEAN of mu should sit close to the REML point estimate. The anchor test
 * below asserts |posterior mean - 0.27980708| < 0.02 (spec tolerance).
 *
 * Run:  node tests.js
 */
var E = require('./engine.js');
var pass = 0, fail = 0;
function approx(name, got, want, tol) {
  tol = tol == null ? 1e-4 : tol;
  if (got == null || !isFinite(got)) { console.log('FAIL ' + name + ': got ' + got); fail++; return; }
  if (Math.abs(got - want) <= tol) pass++;
  else { console.log('FAIL ' + name + ': got ' + got + ' want ' + want + ' (tol ' + tol + ')'); fail++; }
}
function ok(name, c) { if (c) pass++; else { console.log('FAIL ' + name); fail++; } }

var yi = [0.00, 0.52, -0.30, 0.81, 0.18, 0.95, -0.12, 0.60, 0.35, 0.05];
var vi = [0.02, 0.03, 0.015, 0.04, 0.02, 0.05, 0.018, 0.03, 0.025, 0.012];
var REML_MU = 0.27980708; // metafor anchor

// --- helper / building-block checks ---------------------------------------
// half-Cauchy(0,s) peak density at tau=0 is (2/pi)/s
approx('halfCauchy(0,0.5) = (2/pi)/0.5', E.halfCauchy(0, 0.5), (2 / Math.PI) / 0.5, 1e-9);
// half-Cauchy is decreasing in tau
ok('halfCauchy decreasing', E.halfCauchy(0.2, 0.5) > E.halfCauchy(1.0, 0.5));
// trapezoid of a flat density y=1 over [0,2] = 2
approx('trapz flat', E.trapz(E.linspace(0, 2, 5), [1, 1, 1, 1, 1]), 2, 1e-9);
// dnorm integrates (coarsely) to ~1
(function () {
  var g = E.linspace(-8, 8, 2001), d = g.map(function (x) { return E.dnorm(x, 0, 1); });
  approx('dnorm integrates to 1', E.trapz(g, d), 1, 1e-4);
})();
// quantile of standard normal density: median ~ 0
(function () {
  var g = E.linspace(-8, 8, 4001), d = g.map(function (x) { return E.dnorm(x, 0, 1); });
  var Z = E.trapz(g, d); d = d.map(function (v) { return v / Z; });
  approx('quantile median of N(0,1) ~ 0', E.quantileFromDensity(g, d, 0.5), 0, 1e-3);
  approx('quantile 0.975 of N(0,1) ~ 1.96', E.quantileFromDensity(g, d, 0.975), 1.959964, 2e-3);
})();

// --- per-tau fit sanity ----------------------------------------------------
(function () {
  var f0 = E.fitAtTau(yi, vi, 0);
  // at tau=0 muHat is the fixed-effect (inverse-variance) mean
  var sw = 0, swy = 0;
  for (var i = 0; i < yi.length; i++) { var w = 1 / vi[i]; sw += w; swy += w * yi[i]; }
  approx('fitAtTau(0) muHat = FE mean', f0.muHat, swy / sw, 1e-10);
  approx('fitAtTau(0) V = 1/sumW', f0.V, 1 / sw, 1e-12);
})();

// --- main report (wide prior = vague) -------------------------------------
var rWide = E.bayesMA(yi, vi, { scale: 5.0, level: 0.95, nTau: 800, nMu: 800 });
ok('report has no error', !rWide.error);

// tau-grid posterior normalises to ~1
approx('tau posterior integrates to 1', E.trapz(rWide.tauGrid, rWide.tauPost), 1, 1e-6);
// mu posterior normalises to ~1
approx('mu posterior integrates to 1', E.trapz(rWide.mu.grid, rWide.mu.density), 1, 1e-6);
// prediction posterior normalises to ~1
approx('pred posterior integrates to 1', E.trapz(rWide.pred.grid, rWide.pred.density), 1, 1e-6);

// anchor: posterior mean of mu ~ REML mu under vague prior (spec tol 0.02)
approx('posterior mean mu ~ REML mu (vague prior)', rWide.mu.mean, REML_MU, 0.02);
// median should also be close to REML mu
approx('posterior median mu ~ REML mu (vague prior)', rWide.mu.median, REML_MU, 0.03);

// CrI brackets the posterior mean
ok('CrI brackets posterior mean', rWide.mu.crI.lo < rWide.mu.mean && rWide.mu.mean < rWide.mu.crI.hi);
// CrI is ordered
ok('mu CrI ordered', rWide.mu.crI.lo < rWide.mu.crI.hi);

// prediction interval wider than the CrI (extra tau^2 dispersion)
(function () {
  var criW = rWide.mu.crI.hi - rWide.mu.crI.lo;
  var piW = rWide.pred.crI.hi - rWide.pred.crI.lo;
  ok('prediction interval wider than CrI', piW > criW);
  // PI should also enclose the CrI
  ok('PI encloses CrI', rWide.pred.crI.lo < rWide.mu.crI.lo && rWide.pred.crI.hi > rWide.mu.crI.hi);
})();

// --- prior-scale monotonicity: larger half-Cauchy scale => wider mu CrI ----
(function () {
  var sNarrow = E.bayesMA(yi, vi, { scale: 0.1, nTau: 800, nMu: 800 });
  var sMed = E.bayesMA(yi, vi, { scale: 0.5, nTau: 800, nMu: 800 });
  var sWide = E.bayesMA(yi, vi, { scale: 5.0, nTau: 800, nMu: 800 });
  var wN = sNarrow.mu.crI.hi - sNarrow.mu.crI.lo;
  var wM = sMed.mu.crI.hi - sMed.mu.crI.lo;
  var wW = sWide.mu.crI.hi - sWide.mu.crI.lo;
  ok('CrI width monotone in scale (narrow<med)', wN < wM);
  ok('CrI width monotone in scale (med<wide)', wM < wW);
})();

// --- tau posterior summary is in range ------------------------------------
ok('tau posterior median > 0 for heterogeneous data', rWide.tauSummary.median > 0);
ok('tau posterior median < tauMax', rWide.tauSummary.median < rWide.tauGrid[rWide.tauGrid.length - 1]);

// --- guards ----------------------------------------------------------------
ok('k<2 errors', E.bayesMA([0.1], [0.02]).error != null);
ok('zero variance errors', E.bayesMA([0.1, 0.2], [0.02, 0]).error != null);

// --- determinism (no PRNG): identical inputs give identical mu mean --------
(function () {
  var a = E.bayesMA(yi, vi, { scale: 0.5, nTau: 600, nMu: 600 });
  var b = E.bayesMA(yi, vi, { scale: 0.5, nTau: 600, nMu: 600 });
  approx('deterministic mu mean', a.mu.mean, b.mu.mean, 1e-12);
})();

console.log('\n' + pass + ' passed, ' + fail + ' failed');
process.exit(fail === 0 ? 0 : 1);
