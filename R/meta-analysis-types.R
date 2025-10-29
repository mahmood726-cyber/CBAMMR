#' Comprehensive Meta-Analysis Types
#'
#' Complete implementation of all meta-analysis types from meta package
#' with enhanced features and CBAMMR integration.
#'
#' @name meta-analysis-types
#' @keywords internal
NULL

#' Binary Outcome Meta-Analysis
#'
#' Comprehensive meta-analysis for binary outcomes with multiple effect
#' measures and methods. Wraps meta::metabin() with enhancements.
#'
#' @param event.e Number of events in experimental/treatment group
#' @param n.e Total sample size in experimental group
#' @param event.c Number of events in control group
#' @param n.c Total sample size in control group
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure ("OR", "RR", "RD", "ASD", "VE")
#' @param method Meta-analysis method ("MH", "Inverse", "Peto", "SSW")
#' @param method.tau Tau² estimator ("DL", "PM", "REML", "ML", "HS", "SJ", "HE", "EB")
#' @param hakn Use Hartung-Knapp adjustment?
#' @param adhoc.hakn.ci Hartung-Knapp CI adjustment
#' @param prediction Add prediction interval?
#' @param method.incr Continuity correction method
#' @param incr Continuity correction value
#' @param allincr Apply to all studies?
#' @param addincr Add to treatment and control?
#' @param allstudies Include all studies?
#' @param MH.exact Use exact MH method?
#' @param RR.cochrane Use Cochrane's RR method?
#' @param Q.cochrane Use Cochrane's Q?
#' @param model.glmm GLMM model type
#' @param ... Additional arguments passed to meta::metabin()
#'
#' @return Object of class "cbamm_metabin" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' # Using BCG vaccine data
#' data(bcg_vaccine)
#' result <- cbamm_metabin(
#'   event.e = tpos,
#'   n.e = tpos + tneg,
#'   event.c = cpos,
#'   n.c = cpos + cneg,
#'   studlab = study,
#'   data = bcg_vaccine,
#'   sm = "OR",
#'   method = "MH"
#' )
#' print(result)
#' plot(result)
#' }
cbamm_metabin <- function(event.e, n.e, event.c, n.c,
                          studlab = NULL,
                          data = NULL,
                          sm = "OR",
                          method = "MH",
                          method.tau = "DL",
                          hakn = FALSE,
                          adhoc.hakn.ci = NULL,
                          prediction = TRUE,
                          method.incr = "only0",
                          incr = 0.5,
                          allincr = FALSE,
                          addincr = FALSE,
                          allstudies = TRUE,
                          MH.exact = FALSE,
                          RR.cochrane = FALSE,
                          Q.cochrane = FALSE,
                          model.glmm = "UM.FS",
                          ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Call meta::metabin
  result <- meta::metabin(
    event.e = event.e,
    n.e = n.e,
    event.c = event.c,
    n.c = n.c,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    adhoc.hakn.ci = adhoc.hakn.ci,
    prediction = prediction,
    method.incr = method.incr,
    incr = incr,
    allincr = allincr,
    addincr = addincr,
    allstudies = allstudies,
    MH.exact = MH.exact,
    RR.cochrane = RR.cochrane,
    Q.cochrane = Q.cochrane,
    model.glmm = model.glmm,
    ...
  )

  # Add CBAMM enhancements
  class(result) <- c("cbamm_metabin", class(result))
  return(result)
}


#' Continuous Outcome Meta-Analysis
#'
#' Meta-analysis for continuous outcomes (mean differences, standardized
#' mean differences). Wraps meta::metacont() with enhancements.
#'
#' @param n.e Sample size in experimental group
#' @param mean.e Mean in experimental group
#' @param sd.e Standard deviation in experimental group
#' @param n.c Sample size in control group
#' @param mean.c Mean in control group
#' @param sd.c Standard deviation in control group
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure ("MD", "SMD", "ROM")
#' @param method Meta-analysis method ("Inverse", "Hedges", "Cohen", "Glass")
#' @param method.tau Tau² estimator
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Add prediction interval?
#' @param method.smd SMD calculation method
#' @param sd.glass Which group's SD for Glass's delta
#' @param exact.smd Exact SMD calculation?
#' @param pooledvar Pool variances?
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metacont" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_metacont(
#'   n.e = n1, mean.e = m1, sd.e = sd1,
#'   n.c = n2, mean.c = m2, sd.c = sd2,
#'   data = mydata,
#'   sm = "SMD",
#'   method.smd = "Hedges"
#' )
#' print(result)
#' }
cbamm_metacont <- function(n.e, mean.e, sd.e,
                           n.c, mean.c, sd.c,
                           studlab = NULL,
                           data = NULL,
                           sm = "MD",
                           method = "Inverse",
                           method.tau = "REML",
                           hakn = FALSE,
                           prediction = TRUE,
                           method.smd = "Hedges",
                           sd.glass = "control",
                           exact.smd = FALSE,
                           pooledvar = FALSE,
                           ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  result <- meta::metacont(
    n.e = n.e,
    mean.e = mean.e,
    sd.e = sd.e,
    n.c = n.c,
    mean.c = mean.c,
    sd.c = sd.c,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    prediction = prediction,
    method.smd = method.smd,
    sd.glass = sd.glass,
    exact.smd = exact.smd,
    pooledvar = pooledvar,
    ...
  )

  class(result) <- c("cbamm_metacont", class(result))
  return(result)
}


#' Single Proportion Meta-Analysis
#'
#' Meta-analysis of single proportions (prevalence, incidence, etc.).
#' Wraps meta::metaprop() with enhancements.
#'
#' @param event Number of events
#' @param n Total sample size
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure ("PLOGIT", "PAS", "PFT", "PRAW")
#' @param method Meta-analysis method ("Inverse", "GLMM")
#' @param method.tau Tau² estimator
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Add prediction interval?
#' @param method.ci CI method ("CP", "WS", "WSCC", "AC", "SA", "NAsm")
#' @param incr Continuity correction
#' @param method.incr When to add correction
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metaprop" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' # Prevalence meta-analysis
#' result <- cbamm_metaprop(
#'   event = cases,
#'   n = total,
#'   data = prevalence_data,
#'   sm = "PLOGIT",
#'   method.ci = "CP"
#' )
#' print(result)
#' }
cbamm_metaprop <- function(event, n,
                           studlab = NULL,
                           data = NULL,
                           sm = "PLOGIT",
                           method = "Inverse",
                           method.tau = "DL",
                           hakn = FALSE,
                           prediction = TRUE,
                           method.ci = "CP",
                           incr = 0.5,
                           method.incr = "only0",
                           ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  result <- meta::metaprop(
    event = event,
    n = n,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    prediction = prediction,
    method.ci = method.ci,
    incr = incr,
    method.incr = method.incr,
    ...
  )

  class(result) <- c("cbamm_metaprop", class(result))
  return(result)
}


#' Incidence Rate Meta-Analysis
#'
#' Meta-analysis of incidence rates (events per person-time).
#' Wraps meta::metarate() with enhancements.
#'
#' @param event Number of events
#' @param time Person-time at risk
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure ("IRLN", "IRS", "IRFT")
#' @param method Meta-analysis method
#' @param method.tau Tau² estimator
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Add prediction interval?
#' @param method.ci CI method
#' @param incr Continuity correction
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metarate" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_metarate(
#'   event = events,
#'   time = person_years,
#'   data = rate_data,
#'   sm = "IRLN"
#' )
#' print(result)
#' }
cbamm_metarate <- function(event, time,
                           studlab = NULL,
                           data = NULL,
                           sm = "IRLN",
                           method = "Inverse",
                           method.tau = "DL",
                           hakn = FALSE,
                           prediction = TRUE,
                           method.ci = "classic",
                           incr = 0.5,
                           ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  result <- meta::metarate(
    event = event,
    time = time,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    prediction = prediction,
    method.ci = method.ci,
    incr = incr,
    ...
  )

  class(result) <- c("cbamm_metarate", class(result))
  return(result)
}


#' Incidence Rate Ratio Meta-Analysis
#'
#' Meta-analysis comparing incidence rates between two groups.
#' Wraps meta::metainc() with enhancements.
#'
#' @param event.e Events in experimental group
#' @param time.e Person-time in experimental group
#' @param event.c Events in control group
#' @param time.c Person-time in control group
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure ("IRR", "IRD")
#' @param method Meta-analysis method
#' @param method.tau Tau² estimator
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Add prediction interval?
#' @param incr Continuity correction
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metainc" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_metainc(
#'   event.e = events_treat,
#'   time.e = time_treat,
#'   event.c = events_control,
#'   time.c = time_control,
#'   data = mydata,
#'   sm = "IRR"
#' )
#' }
cbamm_metainc <- function(event.e, time.e,
                          event.c, time.c,
                          studlab = NULL,
                          data = NULL,
                          sm = "IRR",
                          method = "Inverse",
                          method.tau = "DL",
                          hakn = FALSE,
                          prediction = TRUE,
                          incr = 0.5,
                          ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  result <- meta::metainc(
    event.e = event.e,
    time.e = time.e,
    event.c = event.c,
    time.c = time.c,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    prediction = prediction,
    incr = incr,
    ...
  )

  class(result) <- c("cbamm_metainc", class(result))
  return(result)
}


#' Correlation Meta-Analysis
#'
#' Meta-analysis of correlation coefficients with Fisher's z transformation.
#' Wraps meta::metacor() with enhancements.
#'
#' @param cor Correlation coefficient
#' @param n Sample size
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure ("ZCOR", "COR")
#' @param method Meta-analysis method
#' @param method.tau Tau² estimator
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Add prediction interval?
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metacor" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_metacor(
#'   cor = r,
#'   n = sample_size,
#'   data = correlation_data,
#'   sm = "ZCOR"
#' )
#' }
cbamm_metacor <- function(cor, n,
                          studlab = NULL,
                          data = NULL,
                          sm = "ZCOR",
                          method = "Inverse",
                          method.tau = "DL",
                          hakn = FALSE,
                          prediction = TRUE,
                          ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  result <- meta::metacor(
    cor = cor,
    n = n,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    prediction = prediction,
    ...
  )

  class(result) <- c("cbamm_metacor", class(result))
  return(result)
}


#' Mean Change Meta-Analysis
#'
#' Meta-analysis of mean changes from baseline (paired data).
#' Wraps meta::metacr() with enhancements.
#'
#' @param n Sample size
#' @param mean.e Mean at endpoint
#' @param sd.e SD at endpoint
#' @param mean.c Mean at baseline
#' @param sd.c SD at baseline
#' @param studlab Study labels
#' @param data Optional data frame
#' @param cor Assumed correlation between baseline and endpoint
#' @param sm Summary measure ("MD", "SMD")
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metacr" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_metacr(
#'   n = sample_size,
#'   mean.e = endpoint_mean,
#'   sd.e = endpoint_sd,
#'   mean.c = baseline_mean,
#'   sd.c = baseline_sd,
#'   cor = 0.7,
#'   data = change_data
#' )
#' }
cbamm_metacr <- function(n, mean.e, sd.e, mean.c, sd.c,
                         studlab = NULL,
                         data = NULL,
                         cor = 0.5,
                         sm = "MD",
                         ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Calculate change scores
  mean_change <- mean.e - mean.c
  sd_change <- sqrt(sd.e^2 + sd.c^2 - 2*cor*sd.e*sd.c)

  # Single-arm meta-analysis of changes
  result <- meta::metagen(
    TE = mean_change,
    seTE = sd_change / sqrt(n),
    studlab = studlab,
    data = data,
    sm = sm,
    ...
  )

  attr(result, "correlation") <- cor
  class(result) <- c("cbamm_metacr", class(result))
  return(result)
}


#' Generic Meta-Analysis
#'
#' Generic meta-analysis for pre-calculated effect sizes.
#' Wraps meta::metagen() with CBAMMR enhancements.
#'
#' @param TE Effect size (treatment effect)
#' @param seTE Standard error of effect size
#' @param studlab Study labels
#' @param data Optional data frame
#' @param sm Summary measure label
#' @param method Meta-analysis method
#' @param method.tau Tau² estimator
#' @param hakn Use Hartung-Knapp adjustment?
#' @param prediction Add prediction interval?
#' @param ... Additional arguments
#'
#' @return Object of class "cbamm_metagen" containing meta-analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' result <- cbamm_metagen(
#'   TE = effect_size,
#'   seTE = standard_error,
#'   data = mydata,
#'   sm = "OR",
#'   method.tau = "REML"
#' )
#' }
cbamm_metagen <- function(TE, seTE,
                          studlab = NULL,
                          data = NULL,
                          sm = "MD",
                          method = "Inverse",
                          method.tau = "REML",
                          hakn = TRUE,
                          prediction = TRUE,
                          ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  result <- meta::metagen(
    TE = TE,
    seTE = seTE,
    studlab = studlab,
    data = data,
    sm = sm,
    method = method,
    method.tau = method.tau,
    hakn = hakn,
    prediction = prediction,
    ...
  )

  class(result) <- c("cbamm_metagen", class(result))
  return(result)
}


#' Subgroup Analysis
#'
#' Comprehensive subgroup analysis with tests for subgroup differences.
#'
#' @param x Meta-analysis object (from meta package)
#' @param byvar Subgroup variable
#' @param data Optional data frame
#' @param tau.common Use common tau² across subgroups?
#' @param ... Additional arguments
#'
#' @return Updated meta-analysis object with subgroup results
#' @export
#'
#' @examples
#' \dontrun{
#' # Create meta-analysis
#' ma <- cbamm_metabin(event.e = e1, n.e = n1,
#'                     event.c = e2, n.c = n2,
#'                     data = mydata)
#'
#' # Add subgroup analysis
#' ma_sub <- cbamm_subgroup(ma, byvar = treatment_type,
#'                          data = mydata)
#' print(ma_sub)
#' }
cbamm_subgroup <- function(x, byvar, data = NULL, tau.common = FALSE, ...) {

  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package 'meta' is required. Install with: install.packages('meta')")
  }

  # Update meta object with subgroup
  result <- meta::update.meta(
    x,
    subgroup = byvar,
    data = data,
    tau.common = tau.common,
    ...
  )

  class(result) <- c("cbamm_subgroup", class(result))
  return(result)
}
