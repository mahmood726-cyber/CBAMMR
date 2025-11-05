# CBAMMR Package Constants
# Centralized location for magic numbers and thresholds
# This improves code maintainability and clarity

# ========================================
# STATISTICAL CONSTANTS
# ========================================

#' @keywords internal
#' Standard normal quantiles for confidence intervals
QNORM_90 <- 1.645
QNORM_95 <- 1.96
QNORM_99 <- 2.576

#' @keywords internal
#' Default confidence level
DEFAULT_CONF_LEVEL <- 0.95

# ========================================
# FRAGILITY INDEX THRESHOLDS
# ========================================

#' @keywords internal
#' Fragility index interpretation thresholds
#' Based on Walsh et al. (2014) and recent methodological reviews
FRAGILITY_THRESHOLD_FRAGILE <- 5     # ≤5 = fragile
FRAGILITY_THRESHOLD_MODERATE <- 10   # 6-10 = moderate
FRAGILITY_THRESHOLD_ROBUST <- 22     # ≥22 = robust

# ========================================
# HETEROGENEITY INTERPRETATION THRESHOLDS
# ========================================

#' @keywords internal
#' I² interpretation thresholds (Higgins & Thompson, 2002)
I2_LOW <- 25          # <25% = low heterogeneity
I2_MODERATE <- 50     # 25-50% = moderate heterogeneity
I2_SUBSTANTIAL <- 75  # 50-75% = substantial heterogeneity
                      # >75% = considerable heterogeneity

#' @keywords internal
#' Tau² thresholds for interpretation
TAU2_SMALL <- 0.04
TAU2_MODERATE <- 0.09
TAU2_LARGE <- 0.16

# ========================================
# SAMPLE SIZE THRESHOLDS
# ========================================

#' @keywords internal
#' Minimum studies for various analyses
MIN_STUDIES_META <- 3           # Minimum for any meta-analysis
MIN_STUDIES_SUBGROUP <- 4       # Minimum per subgroup
MIN_STUDIES_REGRESSION <- 10    # Minimum for meta-regression
MIN_STUDIES_PUB_BIAS <- 10      # Minimum for publication bias tests

#' @keywords internal
#' Sample size categories
SMALL_MA_THRESHOLD <- 10        # <10 studies = small MA
LARGE_MA_THRESHOLD <- 30        # >30 studies = large MA

# ========================================
# EFFECT SIZE THRESHOLDS
# ========================================

#' @keywords internal
#' Cohen's guidelines for effect sizes
COHEN_SMALL <- 0.2
COHEN_MEDIUM <- 0.5
COHEN_LARGE <- 0.8

#' @keywords internal
#' Clinical significance thresholds for ratios
RATIO_MINIMAL_IMPORTANT <- 0.10  # 10% difference from null

# ========================================
# COMPUTATIONAL DEFAULTS
# ========================================

#' @keywords internal
#' Default iterations and resampling
DEFAULT_BAYES_CHAINS <- 2
DEFAULT_BAYES_ITER <- 2000
DEFAULT_BAYES_WARMUP <- 1000
DEFAULT_BOOTSTRAP_ITER <- 1000
DEFAULT_PERMUTATION_ITER <- 1000

#' @keywords internal
#' Convergence and tolerance
DEFAULT_TOLERANCE <- 1e-8
DEFAULT_MAX_ITER <- 1000
DEFAULT_ADAPT_DELTA <- 0.95

# ========================================
# PLOTTING CONSTANTS
# ========================================

#' @keywords internal
#' Default plot dimensions
DEFAULT_PLOT_WIDTH <- 10
DEFAULT_PLOT_HEIGHT <- 8
DEFAULT_DPI <- 300

#' @keywords internal
#' Color palettes for different study types
COLOR_RCT <- "#2E86AB"      # Blue
COLOR_OBS <- "#A23B72"      # Purple
COLOR_MR <- "#F18F01"       # Orange
COLOR_POOLED <- "#C73E1D"   # Red

# ========================================
# FILE AND OUTPUT CONSTANTS
# ========================================

#' @keywords internal
#' Default output directory
DEFAULT_OUTPUT_DIR <- "cbamm_results"

#' @keywords internal
#' Maximum output line length for printing
MAX_LINE_LENGTH <- 100

# ========================================
# QUALITY THRESHOLDS
# ========================================

#' @keywords internal
#' GRADE quality weights
GRADE_WEIGHT_HIGH <- 1.0
GRADE_WEIGHT_MODERATE <- 0.8
GRADE_WEIGHT_LOW <- 0.6
GRADE_WEIGHT_VERY_LOW <- 0.4

# ========================================
# ERROR AND WARNING MESSAGES
# ========================================

#' @keywords internal
#' Standard error messages
ERROR_MSG_INSUFFICIENT_DATA <- "Insufficient data for analysis. At least %d studies required."
ERROR_MSG_INVALID_INPUT <- "Invalid input: %s"
ERROR_MSG_MISSING_COLUMN <- "Required column '%s' not found in data"
ERROR_MSG_NON_NUMERIC <- "Column '%s' must be numeric"
ERROR_MSG_NON_POSITIVE <- "Column '%s' must contain positive values"

#' @keywords internal
#' Standard warning messages
WARN_MSG_SMALL_SAMPLE <- "Small sample size (k=%d). Results should be interpreted with caution."
WARN_MSG_HIGH_HETEROGENEITY <- "High heterogeneity detected (I²=%.1f%%). Consider subgroup analysis."
WARN_MSG_PUBLICATION_BIAS <- "Evidence of publication bias detected. Results may be overestimated."
