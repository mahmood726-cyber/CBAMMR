#' @keywords internal
"_PACKAGE"

#' CBAMMR: Comprehensive Bayesian and Advanced Meta-Analysis Methods in R
#'
#' @description
#' CBAMMR v7.0 provides a comprehensive framework for conducting advanced meta-analyses
#' with support for:
#' \itemize{
#'   \item Pairwise effect size calculation for HR, RR, OR, RD, MD, SMD
#'   \item Transportability weighting with entropy balancing
#'   \item Hartung-Knapp-Sidik-Jonkman (HKSJ) adjustments
#'   \item Prediction intervals
#'   \item Publication bias assessment (PET-PEESE, selection models, RoBMA, p-uniform*)
#'   \item Robust variance estimation with CR2 (clubSandwich)
#'   \item Multivariate meta-analysis with correlation sensitivity
#'   \item Rare-events methods (Peto OR, Mantel-Haenszel, GLMM)
#'   \item Bayesian model averaging with stacking (brms/JAGS)
#'   \item Meta-regression with natural splines
#'   \item ML heterogeneity analysis
#'   \item Comprehensive diagnostic tools
#' }
#'
#' @docType package
#' @name CBAMMR-package
#' @aliases CBAMMR
#'
#' @import metafor
#' @import ggplot2
#' @importFrom dplyr filter mutate select group_by group_split bind_rows n_distinct case_when coalesce all_of row_number across where
#' @importFrom tidyr expand_grid
#' @importFrom tibble tibble
#' @importFrom purrr map_dfr
#' @importFrom readr write_csv
#' @importFrom patchwork wrap_plots plot_layout
#' @importFrom coda as.matrix.mcmc.list
#' @importFrom splines ns
#' @importFrom stats lm coef optim quantile rnorm runif rbinom pnorm weighted.mean
#' @importFrom utils capture.output installed.packages
#' @importFrom parallel detectCores
#' @importFrom grDevices pdf dev.off png
NULL

## usethis namespace: start
## usethis namespace: end
NULL
