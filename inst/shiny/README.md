# CBAMMR Shiny App

Interactive web application for comprehensive meta-analysis following 2024-2025 journal standards.

## Features

✅ **Data Upload**
- CSV/Excel file upload
- Example datasets
- Simulated data generation
- Downloadable templates

✅ **Analysis Configuration**
- Multiple effect measures (OR, RR, HR, MD, SMD)
- Hartung-Knapp adjustments
- Transportability weighting
- Bayesian analysis options

✅ **Comprehensive Results**
- Forest plots
- Funnel plots for publication bias
- GRADE evidence assessment
- Fragility index
- Risk-stratified NNT
- Decision curve analysis

✅ **Publication Outputs**
- PRISMA 2020 checklist
- Manuscript-ready text (Methods & Results)
- High-resolution plot downloads (PNG, PDF, SVG)
- Excel/CSV table exports
- Complete reproducibility bundle

## Running the App

### From R Console

```r
library(CBAMMR)
run_cbammr_app()
```

### From Package Installation

```r
shiny::runApp(system.file("shiny", package = "CBAMMR"))
```

## Data Format Requirements

### Binary Outcomes (OR, RR, HR)

**Option 1: 2x2 Table Data**
```
study, ai, bi, ci, di, year
Smith 2020, 20, 80, 30, 70, 2020
```

**Option 2: Effect Sizes**
```
study, yi, sei, n1i, n2i, year
Smith 2020, -0.356, 0.15, 100, 100, 2020
```

### Continuous Outcomes (SMD, MD)

```
study, yi, sei, n1i, n2i, year
Smith 2020, -0.40, 0.15, 50, 50, 2020
```

### Optional Columns

- `age_mean`: For transportability weighting
- `female_pct`: For transportability weighting
- `study_type`: 'RCT' or 'Obs' for GRADE assessment
- `quality_score`: For quality down-weighting

## Quick Start

1. **Upload/Select Data**: Use example dataset or upload your own
2. **Configure**: Set effect measure and options
3. **Run Analysis**: Click "Run Complete Analysis"
4. **View Results**: Explore plots, tables, assessments
5. **Download**: Export publication-ready outputs

## All Features Tested

✅ All buttons functional
✅ All sliders working correctly
✅ All downloads at high resolution (300+ DPI)
✅ Example data loads properly
✅ Error handling comprehensive
✅ Responsive design
✅ Mobile-friendly

## Download Options

### Plots
- PNG (high resolution, 300-600 DPI)
- PDF (vector, publication-ready)
- SVG (scalable vector graphics)

### Tables
- CSV (Excel-compatible)
- Excel (.xlsx)
- Text files for manuscript

### Bundles
- Complete ZIP with data, code, results
- OSF/Zenodo ready

## Support

- GitHub: https://github.com/mahmood726-cyber/CBAMMR
- Documentation: See package vignette
- Issues: GitHub Issues page

## Citation

```
CBAMMR v7.0: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R
https://github.com/mahmood726-cyber/CBAMMR
```

---

**Version**: 7.0.0
**Last Updated**: 2025-10-27
**License**: MIT
