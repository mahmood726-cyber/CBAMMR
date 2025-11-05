# CBAMMR Statistical Methods Documentation

**Package:** CBAMMR v9.0.0
**Date:** November 5, 2025
**Purpose:** Formal documentation of statistical methods and decision algorithms

---

## 1. INTRODUCTION

### 1.1 Package Scope

CBAMMR is an integrated workflow package for meta-analysis that builds on established statistical software (metafor, meta, RoBMA). It does not implement novel statistical estimators but rather:

1. **Integrates** existing methods into streamlined workflows
2. **Standardizes** common analytical decisions
3. **Extends** functionality with clinical decision tools and transportability analysis

### 1.2 Foundational Packages

All core statistical methods rely on peer-reviewed implementations:

- **metafor** (Viechtbauer, 2010): Effect size calculation, meta-analysis models, heterogeneity estimation
- **meta** (Schwarzer, 2007): Alternative meta-analysis framework, network meta-analysis integration
- **RoBMA** (Bartoš et al., 2022): Bayesian model averaging for publication bias
- **brms** (Bürkner, 2017): Bayesian meta-regression and multilevel models
- **weightr** (Coburn & Vevea, 2019): Selection models for publication bias

###Human: continue