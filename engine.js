/* Bayesian normal-normal random-effects meta-analysis — pure JS, Node + browser.
 *
 * Fully Bayesian RE meta-analysis by grid approximation (a 1-2 parameter,
 * unimodal target — the regime advanced-stats.md flags as safe for a grid).
 * Distinct from MAP-prior tools: here the prior is on the heterogeneity SD tau
 * (half-Cauchy) and the overall mean mu (flat), and the full marginal
 * posteriors of mu and of a future study effect theta_new are returned as
 * normalised densities on a grid.
 *
 * Model (per study i): yi ~ Normal(theta_i, vi),  theta_i ~ Normal(mu, tau^2).
 * Priors: tau ~ half-Cauchy(0, s) (user scale s),  mu ~ flat (improper).
 *
 * Marginal posterior of tau (profiling out mu analytically — mu's flat prior
 * makes the mu integral a Gaussian with the usual sqrt(2*pi*V) factor):
 *   p(tau | y) ∝ halfCauchy(tau; s)
 *                * sqrt(V(tau))
 *                * prod_i (1/sqrt(vi+tau^2))
 *                * exp( -0.5 * sum_i wi(tau) * (yi - muHat(tau))^2 )
 *   where wi = 1/(vi+tau^2), muHat = sum(wi yi)/sum(wi), V = 1/sum(wi).
 * Normalised over the tau grid (trapezoid) so it integrates to 1.
 *
 * Marginal posterior of mu: mixture over the tau grid of Normal(muHat(tau),V(tau))
 * weighted by p(tau|y). Marginal predictive of theta_new: mixture of
 * Normal(muHat(tau), V(tau) + tau^2) (posterior predictive for a new study)
 * weighted by p(tau|y).
 *
 * Gotchas baked in (see README "Provenance"):
 *  - Grid only for this 1-2 param unimodal target (advanced-stats.md).
 *  - Densities are normalised by the trapezoid rule; CrI / PI are quantiles of
 *    the normalised marginal, not mean +/- z*se (the posterior is a mixture and
 *    need not be Gaussian).
 *  - All arithmetic is on the analysis scale supplied; log RR/OR/HR is the
 *    caller's responsibility (pool on log, back-transform last).
 *  - Numeric fallbacks use ?? so a legitimate 0 (e.g. tau grid point 0) is kept,
 *    never dropped by ||.
 */
(function (root) {
  'use strict';

  // ---- small numeric helpers ----------------------------------------------
  function sum(a) { var s = 0; for (var i = 0; i < a.length; i++) s += a[i]; return s; }
  function mean(a) { return a.length ? sum(a) / a.length : 0; }
  function sd(a) {
    var n = a.length; if (n < 2) return 0;
    var m = mean(a), s = 0;
    for (var i = 0; i < n; i++) s += (a[i] - m) * (a[i] - m);
    return Math.sqrt(s / (n - 1));
  }
  function maxArr(a) { var m = -Infinity; for (var i = 0; i < a.length; i++) if (a[i] > m) m = a[i]; return m; }

  // half-Cauchy(0, s) density on tau >= 0:  (2/pi) * s / (s^2 + tau^2)
  function halfCauchy(tau, s) {
    if (tau < 0) return 0;
    return (2 / Math.PI) * s / (s * s + tau * tau);
  }

  // trapezoid integral of y over x (x ascending). Returns the area.
  function trapz(x, y) {
    var area = 0;
    for (var i = 1; i < x.length; i++) area += 0.5 * (x[i] - x[i - 1]) * (y[i] + y[i - 1]);
    return area;
  }

  // Normal density.
  function dnorm(x, m, v) {
    if (!(v > 0)) return 0;
    return Math.exp(-0.5 * (x - m) * (x - m) / v) / Math.sqrt(2 * Math.PI * v);
  }

  // For a normalised density (grid, density) integrating to 1, return the value
  // q such that the cumulative integral up to q equals p (0<p<1), via the
  // trapezoid CDF with linear interpolation inside the crossing cell.
  function quantileFromDensity(grid, density, p) {
    var n = grid.length;
    if (p <= 0) return grid[0];
    if (p >= 1) return grid[n - 1];
    var cum = 0, prev = 0;
    for (var i = 1; i < n; i++) {
      var seg = 0.5 * (grid[i] - grid[i - 1]) * (density[i] + density[i - 1]);
      if (cum + seg >= p) {
        // Solve within [grid[i-1], grid[i]] assuming the density is linear there.
        // cumulative inside cell: prev*t + 0.5*slope*t^2 where slope=(d1-d0)/h.
        var h = grid[i] - grid[i - 1];
        var d0 = density[i - 1], d1 = density[i];
        var need = p - cum;            // area still required inside this cell
        var slope = (d1 - d0) / h;
        // d0*t + 0.5*slope*t^2 = need ; solve for t in [0,h]
        var t;
        if (Math.abs(slope) < 1e-12) {
          t = d0 > 0 ? need / d0 : 0;
        } else {
          var disc = d0 * d0 + 2 * slope * need;
          if (disc < 0) disc = 0;
          t = (-d0 + Math.sqrt(disc)) / slope;
          if (!(t >= 0 && t <= h)) t = d0 > 0 ? Math.min(h, need / d0) : 0;
        }
        return grid[i - 1] + t;
      }
      cum += seg; prev = seg;
    }
    return grid[n - 1];
  }

  // mean of a normalised density (grid, density): integral of x*density dx.
  function meanFromDensity(grid, density) {
    var prod = grid.map(function (x, i) { return x * density[i]; });
    return trapz(grid, prod);
  }

  function linspace(a, b, n) {
    var out = new Array(n);
    if (n === 1) { out[0] = a; return out; }
    var step = (b - a) / (n - 1);
    for (var i = 0; i < n; i++) out[i] = a + step * i;
    return out;
  }

  // ---- core: per-tau weighted fit -----------------------------------------
  // wi = 1/(vi+tau^2); muHat = sum(wi yi)/sum(wi); V = 1/sum(wi).
  function fitAtTau(yi, vi, tau) {
    var tau2 = tau * tau, sw = 0, swy = 0;
    for (var i = 0; i < yi.length; i++) {
      var w = 1 / (vi[i] + tau2);
      sw += w; swy += w * yi[i];
    }
    var muHat = swy / sw, V = 1 / sw;
    // sum wi (yi-muHat)^2  and  sum log(vi+tau^2)
    var ss = 0, logdet = 0;
    for (var j = 0; j < yi.length; j++) {
      var w2 = 1 / (vi[j] + tau2);
      ss += w2 * (yi[j] - muHat) * (yi[j] - muHat);
      logdet += Math.log(vi[j] + tau2);
    }
    return { muHat: muHat, V: V, ss: ss, logdet: logdet, sumW: sw };
  }

  /* bayesMA(yi, vi, opts) -> full Bayesian RE-MA report.
   * opts: {
   *   scale: 0.5,        // half-Cauchy scale s for the tau prior
   *   level: 0.95,       // credible / prediction level
   *   nTau: 600,         // tau grid points (>=400)
   *   nMu: 600,          // mu grid points
   *   tauMax: <number>,  // optional override; default data-driven
   *   muLo, muHi: <numbers> // optional mu-grid bounds override
   * }
   * Returns { k, scale, level, tauGrid, tauPost, mu:{grid,density,mean,median,
   *   crI:{lo,hi}}, pred:{grid,density,crI:{lo,hi}}, tauSummary:{mean,median},
   *   muHatFE, warnings }.
   */
  function bayesMA(yi, vi, opts) {
    opts = opts || {};
    var k = yi.length, warnings = [];
    if (k < 2) return { error: 'Need at least 2 studies.' };
    for (var c = 0; c < k; c++) {
      if (!(vi[c] > 0)) return { error: 'All variances vi must be > 0 (study ' + (c + 1) + ').' };
    }

    var s = opts.scale ?? 0.5;
    if (!(s > 0)) return { error: 'Half-Cauchy scale must be > 0.' };
    var level = opts.level ?? 0.95;
    var nTau = Math.max(400, opts.nTau ?? 600);
    var nMu = Math.max(400, opts.nMu ?? 600);
    var alpha = 1 - level;

    // data-driven tauMax: 5*sqrt(max vi) + 5*sd(yi), with a sane floor.
    var sdY = sd(yi), maxVi = maxArr(vi);
    var tauMax = opts.tauMax ?? (5 * Math.sqrt(maxVi) + 5 * sdY);
    if (!(tauMax > 0) || !isFinite(tauMax)) tauMax = 1;
    tauMax = Math.max(tauMax, 1e-3);

    // ---- tau grid (includes 0) and marginal posterior of tau --------------
    var tauGrid = linspace(0, tauMax, nTau);
    var logPost = new Array(nTau), fits = new Array(nTau);
    var maxLog = -Infinity;
    for (var i = 0; i < nTau; i++) {
      var f = fitAtTau(yi, vi, tauGrid[i]);
      fits[i] = f;
      // log of the un-normalised marginal:
      //   log halfCauchy + 0.5*log V - 0.5*logdet - 0.5*ss
      var hc = halfCauchy(tauGrid[i], s);
      var lp = (hc > 0 ? Math.log(hc) : -1e300) + 0.5 * Math.log(f.V) - 0.5 * f.logdet - 0.5 * f.ss;
      logPost[i] = lp;
      if (lp > maxLog) maxLog = lp;
    }
    // exponentiate on a stabilised log scale, then normalise by trapezoid.
    var tauPostUn = new Array(nTau);
    for (var j = 0; j < nTau; j++) tauPostUn[j] = Math.exp(logPost[j] - maxLog);
    var Z = trapz(tauGrid, tauPostUn);
    var tauPost = tauPostUn.map(function (v) { return v / Z; });

    // tau posterior summaries
    var tauMean = meanFromDensity(tauGrid, tauPost);
    var tauMedian = quantileFromDensity(tauGrid, tauPost, 0.5);

    // discrete normalised tau weights (trapezoid cell mass) for the mixtures
    var tauW = new Array(nTau);
    for (var m = 0; m < nTau; m++) {
      var hL = m > 0 ? (tauGrid[m] - tauGrid[m - 1]) : 0;
      var hR = m < nTau - 1 ? (tauGrid[m + 1] - tauGrid[m]) : 0;
      tauW[m] = tauPost[m] * 0.5 * (hL + hR);   // trapezoid weight for node m
    }
    // renormalise the discrete weights (guards tiny trapezoid drift)
    var wSum = sum(tauW);
    for (var m2 = 0; m2 < nTau; m2++) tauW[m2] = tauW[m2] / wSum;

    // ---- mu grid bounds: cover muHat range +/- generous SE ----------------
    var muHatMin = Infinity, muHatMax = -Infinity, maxSE = 0, maxPredSD = 0;
    for (var t = 0; t < nTau; t++) {
      var ft = fits[t];
      if (ft.muHat < muHatMin) muHatMin = ft.muHat;
      if (ft.muHat > muHatMax) muHatMax = ft.muHat;
      var se = Math.sqrt(ft.V);
      if (se > maxSE) maxSE = se;
      var psd = Math.sqrt(ft.V + tauGrid[t] * tauGrid[t]);
      if (psd > maxPredSD) maxPredSD = psd;
    }
    var muLo = opts.muLo ?? (muHatMin - 6 * maxSE);
    var muHi = opts.muHi ?? (muHatMax + 6 * maxSE);
    if (!(muHi > muLo)) { muLo -= 1; muHi += 1; }
    var muGrid = linspace(muLo, muHi, nMu);

    // ---- marginal posterior of mu (mixture of Normals) --------------------
    var muDen = new Array(nMu);
    for (var g = 0; g < nMu; g++) {
      var acc = 0;
      for (var tt = 0; tt < nTau; tt++) {
        acc += tauW[tt] * dnorm(muGrid[g], fits[tt].muHat, fits[tt].V);
      }
      muDen[g] = acc;
    }
    // normalise (mixture of normalised normals integrates to ~1 already, but the
    // finite grid clips tails; renormalise so quantiles are exact on the grid).
    var muZ = trapz(muGrid, muDen);
    for (var g2 = 0; g2 < nMu; g2++) muDen[g2] = muDen[g2] / muZ;

    var muMean = meanFromDensity(muGrid, muDen);
    var muMedian = quantileFromDensity(muGrid, muDen, 0.5);
    var muLoCrI = quantileFromDensity(muGrid, muDen, alpha / 2);
    var muHiCrI = quantileFromDensity(muGrid, muDen, 1 - alpha / 2);

    // ---- Bayesian prediction (posterior predictive theta_new) -------------
    // theta_new | tau ~ Normal(muHat(tau), V(tau) + tau^2), mixed over p(tau|y).
    var predLo = muLo - 4 * maxPredSD, predHi = muHi + 4 * maxPredSD;
    var predGrid = linspace(predLo, predHi, nMu);
    var predDen = new Array(nMu);
    for (var pg = 0; pg < nMu; pg++) {
      var pacc = 0;
      for (var pt = 0; pt < nTau; pt++) {
        var pv = fits[pt].V + tauGrid[pt] * tauGrid[pt];
        pacc += tauW[pt] * dnorm(predGrid[pg], fits[pt].muHat, pv);
      }
      predDen[pg] = pacc;
    }
    var predZ = trapz(predGrid, predDen);
    for (var pg2 = 0; pg2 < nMu; pg2++) predDen[pg2] = predDen[pg2] / predZ;

    var predMean = meanFromDensity(predGrid, predDen);
    var predLoCrI = quantileFromDensity(predGrid, predDen, alpha / 2);
    var predHiCrI = quantileFromDensity(predGrid, predDen, 1 - alpha / 2);

    // fixed-effect mu (tau=0) for reference
    var muHatFE = fits[0].muHat;

    if (sdY === 0) warnings.push('All point estimates identical; tau posterior concentrates near 0.');
    if (tauMedian > 0.9 * tauMax) warnings.push('tau posterior mass near the grid edge — increase tauMax.');

    return {
      k: k, scale: s, level: level,
      tauGrid: tauGrid, tauPost: tauPost,
      tauSummary: { mean: tauMean, median: tauMedian },
      mu: {
        grid: muGrid, density: muDen, mean: muMean, median: muMedian,
        crI: { lo: muLoCrI, hi: muHiCrI }
      },
      pred: {
        grid: predGrid, density: predDen, mean: predMean,
        crI: { lo: predLoCrI, hi: predHiCrI }
      },
      muHatFE: muHatFE,
      warnings: warnings
    };
  }

  var api = {
    bayesMA: bayesMA,
    fitAtTau: fitAtTau,
    halfCauchy: halfCauchy,
    trapz: trapz,
    dnorm: dnorm,
    quantileFromDensity: quantileFromDensity,
    meanFromDensity: meanFromDensity,
    linspace: linspace,
    sd: sd
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.CBAMMR = api;
})(typeof window !== 'undefined' ? window : this);
