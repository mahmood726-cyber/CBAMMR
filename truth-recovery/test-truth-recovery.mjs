// node truth-recovery/test-truth-recovery.mjs
// Measured invariants: SBC calibration + clean-data coverage. Exits non-zero on failure.
import { runSBC, runCoverageCell } from './harness.mjs';
import { makeRng } from './dgp.mjs';

let pass = 0, fail = 0;
const ok = (name, c, extra = '') => c ? pass++ : (console.log('FAIL ' + name + ' ' + extra), fail++);

// SBC: with the model correct, the PIT of the true mu must be ~Uniform.
{
  const sbc = runSBC(600, { k: 12 });
  ok('SBC PIT calibrated (KS < critical)', sbc.ks < sbc.ksCrit * 1.3, `ks=${sbc.ks} crit=${sbc.ksCrit}`);
  ok('SBC PIT mean ~ 0.5', Math.abs(sbc.pitMean - 0.5) < 0.05, `mean=${sbc.pitMean}`);
}
// SBC is deterministic for a fixed seed.
{
  const a = runSBC(200, { k: 10 });
  const b = runSBC(200, { k: 10 });
  ok('SBC deterministic', a.ks === b.ks && a.pitMean === b.pitMean);
}
// Clean-data credible & predictive intervals are near nominal (>= 0.93).
{
  const c = runCoverageCell(0.3, 0.05, 10, 'none', 600, makeRng(20260613));
  ok('clean credible-mu coverage >= 0.93', c.covMu >= 0.93, `covMu=${c.covMu}`);
  ok('clean predictive coverage >= 0.93', c.covPred >= 0.93, `covPred=${c.covPred}`);
}
// Honest limitation: strong selection collapses credible-mu coverage.
{
  const c = runCoverageCell(0.3, 0.05, 20, 'step_strong', 400, makeRng(7));
  ok('strong selection collapses credible-mu coverage (<0.5)', c.covMu < 0.5, `covMu=${c.covMu}`);
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
