#' Prepare Pairwise Effect Sizes
#'
#' Calculate effect sizes from arm-level data or convert from various input formats
#'
#' @param data Data frame with study-level data
#' @param measure Effect measure: "HR", "RR", "OR", "RD", "MD", or "SMD"
#' @param add Continuity correction value (default 0.5)
#' @param cc_when When to apply continuity correction: "only0" or "all"
#' @param multiarm_strategy How to handle multi-arm trials: "keep_cr2" or "split_shared_control"
#'
#' @return Data frame with yi (effect size) and se/vi (variance) added
#' @export
#'
#' @examples
#' \dontrun{
#' # For binary outcomes (OR)
#' data <- data.frame(
#'   study_id = c("S1", "S2"),
#'   event_t = c(10, 15),
#'   n_t = c(100, 120),
#'   event_c = c(20, 25),
#'   n_c = c(100, 120)
#' )
#' data_with_effects <- prepare_pairwise_effects(data, measure = "OR")
#' }
prepare_pairwise_effects <- function(data, measure = "HR",
                                     add = 0.5, cc_when = "only0",
                                     multiarm_strategy = "keep_cr2") {
  stopifnot(is.data.frame(data))
  measure <- match.arg(measure, c("HR","RR","OR","RD","MD","SMD"))
  cc_when <- match.arg(cc_when, c("only0","all"))
  multiarm_strategy <- match.arg(multiarm_strategy, c("keep_cr2","split_shared_control"))

  d <- data
  d <- .prepare_from_hrish(d)
  d <- .standardize_pairwise_cols(d)

  has_yi_se <- all(c("yi","se") %in% names(d)) && all(is.finite(d$yi)) && all(is.finite(d$se)) && all(d$se > 0)
  if (has_yi_se) { d$vi <- d$se^2; return(d) }

  if (measure %in% c("RR","OR","RD") && all(c("ai","bi","ci","di") %in% names(d))) {
    esc <- metafor::escalc(measure = measure, ai = d$ai, bi = d$bi, ci = d$ci, di = d$di, add = add, to = cc_when)
    d$yi <- as.numeric(esc$yi); d$vi <- as.numeric(esc$vi); d$se <- sqrt(d$vi)
  } else if (measure %in% c("MD","SMD") && all(c("m1i","sd1i","n1i","m2i","sd2i","n2i") %in% names(d))) {
    esc <- metafor::escalc(measure = measure, m1i = d$m1i, sd1i = d$sd1i, n1i = d$n1i, m2i = d$m2i, sd2i = d$sd2i, n2i = d$n2i, vtype = if (measure == "SMD") "UB" else NULL)
    d$yi <- as.numeric(esc$yi); d$vi <- as.numeric(esc$vi); d$se <- sqrt(d$vi)
  } else if (measure == "HR") {
    stop("For measure='HR', provide either yi+se (logHR+SE), HR with 95% CI, TE+seTE, or O–E+V.")
  } else {
    stop("Could not derive yi,se for measure='", measure, "'. Provide yi+se or arm-level inputs.")
  }

  if (multiarm_strategy == "split_shared_control") d <- .split_shared_controls(d, measure)
  d
}

#' Validate Pairwise Meta-Analysis Data
#'
#' Check data schema, detect issues, and provide recommendations
#'
#' @param data Data frame with study data
#' @param measure Effect measure to validate for
#'
#' @return List with ok (logical), issues (character vector), notes (character vector), and rare_hint (logical)
#' @export
#'
#' @examples
#' \dontrun{
#' data <- simulate_cbamm_binary(n = 20)
#' validation <- cbamm_pairwise_validator(data, measure = "OR")
#' if (!validation$ok) {
#'   cat("Issues found:\n", validation$issues, "\n")
#' }
#' }
cbamm_pairwise_validator <- function(data, measure = "HR") {
  mm <- .cbamm_measure_meta(measure)
  issues <- c(); notes <- c()
  d <- data

  have_yise <- all(c("yi","se") %in% names(d))
  have_counts <- all(c("ai","bi","ci","di") %in% names(d)) || all(c("event_t","n_t","event_c","n_c") %in% names(d))
  have_cont <- all(c("m1i","sd1i","n1i","m2i","sd2i","n2i") %in% names(d)) || all(c("mean_t","sd_t","n_t","mean_c","sd_c","n_c") %in% names(d))
  have_hrish <- all(c("logHR","SE") %in% names(d)) || all(c("HR","ci_lb","ci_ub") %in% names(d)) || all(c("OE","V") %in% names(d)) || all(c("TE","seTE") %in% names(d))

  schema_ok <- switch(measure,
    HR  = have_yise || have_hrish,
    RR  = have_yise || have_counts,
    OR  = have_yise || have_counts,
    RD  = have_yise || have_counts,
    MD  = have_yise || have_cont,
    SMD = have_yise || have_cont
  )

  if (!schema_ok) issues <- c(issues, sprintf("Input schema incomplete for %s. Provide yi+se OR appropriate arm-level inputs.", mm$effect_label))

  if (have_counts) {
    d <- .standardize_pairwise_cols(d)
    if (all(c("ai","bi","ci","di") %in% names(d))) {
      zeros <- sum(d$ai==0 | d$bi==0 | d$ci==0 | d$di==0, na.rm = TRUE)
      if (zeros > 0) notes <- c(notes, sprintf("Zero cells detected in %d rows — continuity correction recommended (default 0.5).", zeros))
      rate_t <- mean(d$ai/(d$ai+d$bi), na.rm = TRUE)
      rate_c <- mean(d$ci/(d$ci+d$di), na.rm = TRUE)
      if (rate_t < 0.01 || rate_c < 0.01) notes <- c(notes, "Rare events suspected (<1%); rare-events suite (Peto/MH/GLMM) advisable.")
    }
  }

  multi_arm <- "study_id" %in% names(d) && any(duplicated(d$study_id))
  if (multi_arm) {
    tab <- sort(table(d$study_id), decreasing = TRUE)
    notes <- c(notes, sprintf("Multi-arm structure detected in %d studies; CR2 and MV available.", sum(tab>1)))
  }

  if (have_yise) {
    if (any(!is.finite(d$yi) | !is.finite(d$se) | d$se <= 0)) issues <- c(issues, "Non-finite/inadmissible yi or se.")
    bigse <- sum(d$se > quantile(d$se, .95, na.rm = TRUE), na.rm = TRUE)
    if (bigse > 0) notes <- c(notes, sprintf("Top 5%% SEs found (%d rows) — inspect outliers/influence.", bigse))
  }

  list(ok = length(issues) == 0, issues = unique(issues), notes = unique(notes), rare_hint = any(grepl("Rare events", notes)))
}
