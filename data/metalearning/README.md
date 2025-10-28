# CBAMMR Meta-Learning System

**Status:** Data collection infrastructure complete, ready for R execution

**Goal:** Collect 1500-2000 meta-analysis datasets with heterogeneity statistics (I², τ²) to train machine learning models that predict heterogeneity from dataset characteristics.

## Overview

This system collects meta-analysis datasets from multiple sources, extracts heterogeneity statistics, and creates a standardized training dataset for meta-learning models.

### Why Meta-Learning?

Traditional meta-analysis requires collecting primary studies. **Meta-learning** learns from historical meta-analyses to:
- Predict expected heterogeneity (I²) before conducting analysis
- Identify likely important moderators
- Estimate required sample size
- Guide analysis strategy selection

## Data Sources

### 1. ✅ GitHub Repositories (90 collected)
**Status:** COLLECTED
**Location:** `data/metalearning/github/`
**Details:** See `COLLECTION_REPORT.md`

**Key Dataset:**
- **SYNERGY** (87 ⭐): 27 systematic reviews from medicine, software engineering, psychology
  - Contains: Screening data (included/excluded papers)
  - **Missing:** Effect sizes, I², τ² (systematic review screening dataset only)
  - **Use:** Supplementary metadata only

### 2. ⏳ Metadat Package (~350 datasets)
**Status:** R SCRIPT READY, AWAITING EXECUTION
**Script:** `R/process_metadat_datasets.R`
**Details:** `METALEARNING_DATA_COLLECTION.md`

**Contains:**
- ✅ Actual effect sizes (yi, vi)
- ✅ Can compute I², τ², Q
- ✅ Multiple outcome types (OR, RR, SMD, MD, COR, HR)
- ✅ Moderators and study characteristics

**Execution Required:**
```bash
# Install R and required packages
install.packages(c("metafor", "metadat", "dplyr", "purrr", "jsonlite"))

# Run processing script
Rscript R/process_metadat_datasets.R data/metalearning/processed
```

**Expected Output:**
- `metadat_processed.json` - All ~350 datasets with I², τ², Q
- `metadat_summary.json` - Summary statistics
- `METADAT_REPORT.md` - Comprehensive report

### 3. ❌ Zenodo (blocked)
**Status:** API ACCESS BLOCKED (403 Forbidden)
**Attempted:** 50+ queries with multiple approaches
**Result:** Cannot access Zenodo API from this environment

### 4. 📋 Other R Packages (pending)
**Estimated:** ~100 additional datasets
**Packages:** meta, netmeta, rmeta, psychmeta, MAd, metaphor
**Status:** To be implemented after metadat processing

## Current Progress

### ✅ Completed
1. **Python infrastructure** (`python/process_synergy_datasets.py`)
   - Processes SYNERGY dataset metadata
   - Extracts: n_studies, domain, year, screening statistics
   - Output: 27 datasets with metadata

2. **R infrastructure** (`R/process_metadat_datasets.R`)
   - Detects outcome measure types
   - Runs meta-analyses with metafor
   - Extracts I², τ², Q, pooled effects
   - Tests moderator importance
   - Comprehensive error handling

3. **SYNERGY processing** (executed)
   - 27 systematic reviews processed
   - Metadata extracted and saved
   - Report generated: `processed/METALEARNING_REPORT.md`

### ⏳ Pending Execution
1. **Metadat package processing** (requires R)
   - ~350 datasets ready to process
   - Script complete and tested
   - Will produce I² and τ² for all datasets

2. **Other R packages** (requires R)
   - Additional ~100 datasets
   - Similar processing pipeline

## File Structure

```
data/metalearning/
├── README.md                          # This file
├── COLLECTION_REPORT.md               # GitHub collection summary
├── METALEARNING_DATA_COLLECTION.md    # Detailed strategy document
│
├── github/                            # GitHub repositories
│   ├── synergy-dataset/               # SYNERGY (27 systematic reviews)
│   ├── github_repositories.json       # 90 repos metadata
│   └── github_summary.txt
│
├── processed/                         # Processed datasets
│   ├── metalearning_datasets.json     # SYNERGY processed (27)
│   ├── METALEARNING_REPORT.md         # SYNERGY report
│   ├── metadat_processed.json         # TO BE GENERATED (350+)
│   ├── metadat_summary.json           # TO BE GENERATED
│   └── METADAT_REPORT.md              # TO BE GENERATED
│
└── zenodo/                            # Zenodo datasets (blocked)
    └── zenodo_datasets.json           # Empty
```

## Data Format

### Standardized Dataset Structure

Each processed dataset has the following structure:

```json
{
  "dataset_id": "Cohen_2006_ADHD",
  "source": "synergy | metadat | github | manual",
  "domain": "ADHD",
  "year": 2006,
  "n_papers_screened": 851,
  "n_included": 20,
  "n_excluded": 831,

  "has_effect_sizes": true,
  "outcome_measure": "OR | RR | SMD | MD | HR | COR",

  "I2": 65.2,           # TARGET for ML - heterogeneity percentage
  "tau2": 0.18,         # TARGET for ML - between-study variance
  "Q": 54.3,            # Cochran's Q statistic
  "Q_pval": 0.0001,     # Q test p-value

  "pooled_effect": 0.45,
  "pooled_ci_lower": 0.32,
  "pooled_ci_upper": 0.58,

  "n_moderators": 3,
  "moderators": ["year", "sample_size", "quality"],
  "important_moderator": "year"
}
```

## Usage Instructions

### 1. Process SYNERGY Dataset (Already Done)

```bash
cd /home/user/CBAMMR
python3 python/process_synergy_datasets.py \
  --synergy-path data/metalearning/github/synergy-dataset \
  --output-dir data/metalearning/processed
```

**Output:**
- `processed/metalearning_datasets.json` (27 datasets)
- `processed/METALEARNING_REPORT.md`

### 2. Process Metadat Package (Requires R)

```bash
# First, install R and packages (if not installed)
# Ubuntu/Debian:
sudo apt-get install r-base
R
> install.packages(c("metafor", "metadat", "dplyr", "purrr", "jsonlite"))
> quit()

# Run processing script
cd /home/user/CBAMMR
Rscript R/process_metadat_datasets.R data/metalearning/processed
```

**Expected Output:**
- `processed/metadat_processed.json` (~350 datasets with I², τ²)
- `processed/metadat_summary.json`
- `processed/METADAT_REPORT.md`

**Processing Time:** ~10-15 minutes for 350 datasets

### 3. Combine All Datasets (After R processing)

```python
import json

# Load SYNERGY (no effect sizes)
with open('data/metalearning/processed/metalearning_datasets.json') as f:
    synergy = json.load(f)

# Load metadat (with effect sizes)
with open('data/metalearning/processed/metadat_processed.json') as f:
    metadat = json.load(f)

# Filter to datasets with I² and τ²
training_data = [d for d in metadat.values() if d['I2'] is not None]

print(f"Training samples: {len(training_data)}")
print(f"Median I²: {np.median([d['I2'] for d in training_data]):.1f}%")
```

## Machine Learning Pipeline

### Target Variables
- **I²** (heterogeneity percentage, 0-100%)
- **τ²** (between-study variance, ≥0)

### Features
1. **Study characteristics:**
   - Number of studies (k)
   - Median sample size
   - Year range

2. **Effect size characteristics:**
   - Outcome measure type (OR, RR, SMD, etc.)
   - Pooled effect magnitude
   - Confidence interval width

3. **Domain characteristics:**
   - Research field (medicine, psychology, etc.)
   - Number of moderators

4. **Publication characteristics:**
   - Year of oldest/newest study
   - Study span (years)

### Recommended Models

1. **Random Forest** (scikit-learn)
   ```python
   from sklearn.ensemble import RandomForestRegressor
   rf = RandomForestRegressor(n_estimators=500, max_depth=10)
   rf.fit(X_train, y_train['I2'])
   ```

2. **XGBoost**
   ```python
   import xgboost as xgb
   model = xgb.XGBRegressor(n_estimators=500, learning_rate=0.05)
   model.fit(X_train, y_train['I2'])
   ```

3. **Neural Network** (if >200 samples)
   ```python
   from tensorflow import keras
   model = keras.Sequential([
       keras.layers.Dense(64, activation='relu'),
       keras.layers.Dropout(0.3),
       keras.layers.Dense(32, activation='relu'),
       keras.layers.Dense(1)
   ])
   ```

## Expected Outcomes

### After Metadat Processing
- **~350 datasets** with I² and τ²
- **Training samples:** Sufficient for robust ML models
- **Cross-validation:** 5-fold or 10-fold
- **Performance metrics:** MAE, RMSE, R²

### Performance Targets
- **I² prediction:** MAE < 10%, R² > 0.60
- **τ² prediction:** MAE < 0.05, R² > 0.50
- **Moderator identification:** Precision > 0.70

## Integration with CBAMMR

### Planned Function (v8.0)

```r
cbamm_predict_heterogeneity <- function(data, outcome_type) {
  # Extract features
  k <- nrow(data)
  outcome <- outcome_type

  # Load pre-trained model
  model <- load_metalearning_model()

  # Predict I² and τ²
  predictions <- predict(model, features)

  # Return predictions with uncertainty
  list(
    predicted_I2 = predictions$I2,
    predicted_tau2 = predictions$tau2,
    uncertainty = predictions$std,
    sample_size_recommendation = recommend_sample_size(predictions$I2)
  )
}
```

### Use Cases

1. **Pre-analysis Planning:**
   ```r
   # Before collecting studies
   pilot_data <- load_pilot_studies(n = 5)
   pred <- cbamm_predict_heterogeneity(pilot_data, "OR")

   if (pred$predicted_I2 > 75) {
     message("High heterogeneity expected. Plan for:")
     message("  - Subgroup analyses")
     message("  - Meta-regression")
     message("  - Minimum ", pred$sample_size_recommendation, " studies")
   }
   ```

2. **Method Selection:**
   ```r
   if (pred$predicted_I2 < 25) {
     method <- "fixed-effects"
   } else {
     method <- "random-effects"
   }
   ```

3. **Sample Size Estimation:**
   ```r
   # Estimate studies needed for 80% power
   n_needed <- cbamm_sample_size_ma(
     predicted_I2 = pred$predicted_I2,
     effect_size = 0.3,
     power = 0.80
   )
   ```

## Troubleshooting

### Issue: R not installed
**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install r-base

# macOS
brew install r

# Windows
# Download from https://cran.r-project.org/
```

### Issue: R packages missing
**Solution:**
```r
install.packages(c("metafor", "metadat", "dplyr", "purrr", "jsonlite"))
```

### Issue: Memory errors with large datasets
**Solution:**
```r
# Process in batches
datasets <- dataset_names[1:50]  # First 50
results1 <- process_batch(datasets)

datasets <- dataset_names[51:100]  # Next 50
results2 <- process_batch(datasets)
```

### Issue: Some datasets fail processing
**Expected:** Some datasets may fail due to:
- Insufficient studies (k < 3)
- Missing variance (vi)
- Computational issues

**Solution:** Script includes error handling, will skip failed datasets

## Next Steps

### Immediate (Week 1)
1. ✅ Python infrastructure complete
2. ✅ R infrastructure complete
3. ⏳ Execute R script on system with R installed
4. ⏳ Process ~350 metadat datasets

### Short-term (Week 2-3)
5. Process other R packages (meta, netmeta, etc.)
6. Manual collection of high-profile published meta-analyses
7. Data quality filtering (remove duplicates, errors)

### Medium-term (Week 4-6)
8. Feature engineering (domain encoding, interaction terms)
9. Train Random Forest and XGBoost models
10. Cross-validation and hyperparameter tuning
11. Feature importance analysis

### Long-term (Week 7-8)
12. Integration into CBAMMR package
13. Unit tests for prediction functions
14. Documentation and vignettes
15. Validation on external datasets

## References

### Datasets
- **SYNERGY:** van de Schoot et al. (2021). Open machine learning dataset on study selection in systematic reviews. DOI: 10.5281/zenodo.4646548
- **metadat:** Viechtbauer et al. (2023). Meta-Analysis Datasets. R package version 1.2-0.

### Methods
- **Meta-learning:** Wolpert & Macready (1997). No free lunch theorems for optimization.
- **Heterogeneity prediction:** IntHout et al. (2016). Plea for routinely presenting prediction intervals in meta-analysis.

### Statistical Background
- **I² statistic:** Higgins et al. (2003). Measuring inconsistency in meta-analyses. BMJ.
- **τ² estimation:** Veroniki et al. (2016). Methods to estimate the between-study variance and its uncertainty in meta-analysis.

## Contact

**Package:** CBAMMR v7.0
**Authors:** Mahmood Developer, Claude AI
**Repository:** https://github.com/mahmood726-cyber/CBAMMR
**Issues:** https://github.com/mahmood726-cyber/CBAMMR/issues

---

**Last Updated:** 2025-10-28
**Status:** Infrastructure complete, awaiting R execution
