# Internal utility functions for CBAMMR

#' @keywords internal
.cbamm_measure_meta <- function(measure) {
  ratio <- measure %in% c("HR","RR","OR")
  list(
    measure = measure,
    is_ratio = ratio,
    transf = if (ratio) exp else identity,
    inv_transf = if (ratio) log else identity,
    effect_label = switch(measure,
      HR = "Hazard Ratio", RR = "Risk Ratio", OR = "Odds Ratio",
      RD = "Risk Difference", MD = "Mean Difference", SMD = "Standardized Mean Difference", "Effect"),
    axis_scale_fun = function(p) { if (ratio) p + ggplot2::scale_x_log10() else p }
  )
}

#' @keywords internal
.prepare_from_hrish <- function(d) {
  if (all(c("yi","se") %in% names(d))) return(d)
  if (all(c("logHR","SE") %in% names(d))) { d$yi <- as.numeric(d$logHR); d$se <- as.numeric(d$SE); return(d) }
  if (all(c("HR","ci_lb","ci_ub") %in% names(d))) {
    d$yi <- log(as.numeric(d$HR))
    d$se <- (log(as.numeric(d$ci_ub)) - log(as.numeric(d$ci_lb))) / (2*1.96)
    return(d)
  }
  if (all(c("OE","V") %in% names(d))) { d$yi <- as.numeric(d$OE) / as.numeric(d$V); d$se <- sqrt(1/as.numeric(d$V)); return(d) }
  if (all(c("TE","seTE") %in% names(d))) { d$yi <- as.numeric(d$TE); d$se <- as.numeric(d$seTE); return(d) }
  d
}

#' @keywords internal
.standardize_pairwise_cols <- function(d) {
  if (all(c("event_t","n_t","event_c","n_c") %in% names(d))) {
    d$ai <- d$event_t; d$bi <- d$n_t - d$event_t
    d$ci <- d$event_c; d$di <- d$n_c - d$event_c
  }
  if (all(c("mean_t","sd_t","n_t","mean_c","sd_c","n_c") %in% names(d))) {
    d$m1i <- d$mean_t; d$sd1i <- d$sd_t; d$n1i <- d$n_t
    d$m2i <- d$mean_c; d$sd2i <- d$sd_c; d$n2i <- d$n_c
  }
  d
}

#' @keywords internal
.split_shared_controls <- function(d, measure) {
  if (!"study_id" %in% names(d) || !any(duplicated(d$study_id))) return(d)
  if (!any(c("ai","bi","ci","di") %in% names(d)) &&
      !any(c("m1i","sd1i","n1i","m2i","sd2i","n2i") %in% names(d))) return(d)
  dd <- d %>% dplyr::group_by(study_id) %>% dplyr::group_split()
  out <- lapply(dd, function(g) {
    if (nrow(g) <= 1) return(g)
    if (all(c("ci","di") %in% names(g)) && length(unique(paste(g$ci, g$di))) == 1L) {
      k <- nrow(g); g$ci <- g$ci / k; g$di <- g$di / k; return(g)
    }
    if (all(c("m2i","sd2i","n2i") %in% names(g)) && length(unique(g$n2i)) == 1L) {
      k <- nrow(g); g$n2i <- ceiling(g$n2i / k); return(g)
    }
    g
  })
  dplyr::bind_rows(out)
}
