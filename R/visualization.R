# Visualization Functions for CBAMMR

#' Create Multiverse Plot
#' @keywords internal
.create_multiverse_plot <- function(multiverse_results, config) {
  mv_data <- multiverse_results %>% dplyr::filter(success) %>% dplyr::mutate(eff = as.numeric(eff), ci_lb = as.numeric(ci_lb), ci_ub = as.numeric(ci_ub), spec_label = paste(estimator, subset, weighting, sep = "_"), beneficial = if (.cbamm_measure_meta(config$effect_measure)$is_ratio) eff < 1 else eff < 0) %>% dplyr::filter(is.finite(eff))
  if (nrow(mv_data) == 0) { message("[plot] Multiverse: no finite values; skipping."); return(NULL) }
  lab <- .cbamm_measure_meta(config$effect_measure)$effect_label
  p <- ggplot(mv_data, aes(x = reorder(spec_label, eff), y = eff)) +
    geom_pointrange(aes(ymin = ci_lb, ymax = ci_ub, color = beneficial), na.rm = TRUE) +
    geom_hline(yintercept = if (.cbamm_measure_meta(config$effect_measure)$is_ratio) 1 else 0, linetype = "dashed") +
    scale_color_manual(values = c("FALSE" = "red", "TRUE" = "blue")) +
    coord_flip() +
    labs(title = "Multiverse Analysis", x = "Specification", y = paste0(lab, " (95% CI)"),
         color = if (.cbamm_measure_meta(config$effect_measure)$is_ratio) paste0(lab," < 1") else paste0(lab," < 0")) +
    theme_minimal() + theme(legend.position = "bottom")
  if (isTRUE(config$use_interactive) && requireNamespace("plotly", quietly = TRUE)) return(suppressWarnings(plotly::ggplotly(p)))
  p
}

#' Create Forest Plot
#' @keywords internal
.create_forest_plot <- function(data, config) {
  mm <- .cbamm_measure_meta(config$effect_measure)
  df <- data %>% dplyr::mutate(eff = as.numeric(mm$transf(yi)), lo = as.numeric(mm$transf(yi - 1.96*se)), hi = as.numeric(mm$transf(yi + 1.96*se)), lab = paste0(study_id, " (", study_type, ")")) %>% dplyr::filter(is.finite(eff) & is.finite(lo) & is.finite(hi))
  if (nrow(df) == 0) { message("[plot] Forest: no finite values; skipping."); return(NULL) }
  p <- ggplot(df, aes(y = reorder(lab, eff), x = eff, color = study_type)) +
    geom_pointrange(aes(xmin = lo, xmax = hi), na.rm = TRUE) +
    geom_vline(xintercept = if (mm$is_ratio) 1 else 0, linetype = "dashed") +
    labs(title = "Forest Plot by Study", x = paste0(mm$effect_label, if (mm$is_ratio) " (log scale)" else ""), y = "Study", color = "Type") +
    theme_minimal() + theme(legend.position = "bottom")
  mm$axis_scale_fun(p)
}

#' Create Funnel Plot
#' @keywords internal
.create_funnel_plot <- function(pooled_results, config) {
  fit <- pooled_results$transport
  if (is.null(fit) || inherits(fit, "try-error")) { message("[plot] Funnel: no valid pooled model; skipping."); return(NULL) }
  plot_data <- data.frame(yi = as.numeric(fit$yi), sei = sqrt(as.numeric(fit$vi)))
  plot_data <- dplyr::filter(plot_data, is.finite(yi) & is.finite(sei))
  if (nrow(plot_data) == 0) { message("[plot] Funnel: empty data; skipping."); return(NULL) }
  p <- ggplot(plot_data, aes(x = yi, y = sei)) +
    geom_point(alpha = 0.7) +
    geom_vline(xintercept = as.numeric(coef(fit)), linetype = "dashed", color = "red") +
    scale_y_reverse(name = "Standard Error") +
    xlab(paste0("Model scale (", config$effect_measure, if (.cbamm_measure_meta(config$effect_measure)$is_ratio) " log" else "", ")")) +
    labs(title = "Funnel Plot") +
    theme_minimal() +
    geom_smooth(method = "lm", se = FALSE, linetype = "dotted", formula = y ~ x)
  if (isTRUE(config$use_interactive) && requireNamespace("plotly", quietly = TRUE)) return(suppressWarnings(plotly::ggplotly(p)))
  p
}

#' Create PET Plot
#' @keywords internal
.create_pet_plot <- function(data) {
  if (nrow(data) < 6) return(NULL)
  df_pp <- data.frame(yi = data$yi, se = data$se, w = 1/(data$se^2))
  fit_pet <- try(lm(yi ~ se, data = df_pp, weights = w), silent = TRUE)
  if (inherits(fit_pet, "try-error")) return(NULL)
  ggplot(df_pp, aes(x = se, y = yi)) +
    geom_point(alpha = 0.6) + geom_smooth(method = "lm", se = TRUE, formula = y ~ x) +
    geom_hline(yintercept = 0, linetype = "dotted") +
    labs(title = "PET: yi ~ SE (weights = 1/SE^2)", x = "SE", y = "yi (model scale)") +
    theme_minimal()
}

#' Create PEESE Plot
#' @keywords internal
.create_peese_plot <- function(data) {
  if (nrow(data) < 6) return(NULL)
  df_pp <- data.frame(yi = data$yi, se = data$se, w = 1/(data$se^2))
  fit <- try(lm(yi ~ I(se^2), data = df_pp, weights = w), silent = TRUE)
  if (inherits(fit, "try-error")) return(NULL)
  ggplot(df_pp, aes(x = se^2, y = yi)) +
    geom_point(alpha = 0.6) + geom_smooth(method = "lm", se = TRUE, formula = y ~ x) +
    geom_hline(yintercept = 0, linetype = "dotted") +
    labs(title = "PEESE: yi ~ SE^2 (weights = 1/SE^2)", x = "SE^2", y = "yi (model scale)") +
    theme_minimal()
}

#' Create Leave-One-Out Plot
#' @keywords internal
.create_leave1out_plot <- function(pooled_results) {
  fit <- pooled_results$transport; if (is.null(fit) || inherits(fit, "try-error")) return(NULL)
  loo <- try(metafor::leave1out(fit), silent = TRUE); if (inherits(loo, "try-error")) return(NULL)
  df_loo <- as.data.frame(loo); df_loo$eff <- exp(df_loo$estimate)
  df_loo$ci_lb <- if ("ci.lb" %in% names(df_loo)) exp(df_loo$ci.lb) else NA_real_
  df_loo$ci_ub <- if ("ci.ub" %in% names(df_loo)) exp(df_loo$ci.ub) else NA_real_
  df_loo$study <- rownames(df_loo)
  ggplot(df_loo, aes(y = reorder(study, eff), x = eff)) +
    geom_pointrange(aes(xmin = ci_lb, xmax = ci_ub)) + geom_vline(xintercept = exp(as.numeric(coef(fit))), linetype = "dashed") +
    scale_x_log10() +
    labs(title = "Leave-one-out Pooled Effect", x = "Effect (log scale)", y = "Left-out study") +
    theme_minimal()
}

#' Create Cumulative Plot
#' @keywords internal
.create_cumulative_plot <- function(pooled_results, data) {
  fit <- pooled_results$transport
  if (is.null(fit) || inherits(fit, "try-error") || !"year" %in% names(data)) return(NULL)
  ord <- order(data$year, decreasing = FALSE)
  cum  <- try(metafor::cumul(fit, order = ord), silent = TRUE)
  if (inherits(cum, "try-error")) return(NULL)
  dcc <- as.data.frame(cum); dcc$k <- seq_len(nrow(dcc))
  ggplot(dcc, aes(x = k, y = exp(estimate))) +
    geom_ribbon(aes(ymin = exp(ci.lb), ymax = exp(ci.ub)), alpha = 0.15) +
    geom_line() + geom_point() + geom_hline(yintercept = 1, linetype = "dashed") +
    labs(title = "Cumulative Meta-analysis (ordered by year)", x = "Cumulative number of studies", y = "Pooled Effect (95% CI band)") +
    theme_minimal()
}

#' Create Bayesian Plot
#' @keywords internal
.create_bayesian_plot <- function(bayes_res) {
  if (is.null(bayes_res)) return(NULL)
  draws_eff <- NULL; if (!is.null(bayes_res$draws)) draws_eff <- exp(bayes_res$draws) else if (!is.null(bayes_res$draws_mu)) draws_eff <- exp(bayes_res$draws_mu)
  if (is.null(draws_eff)) return(NULL)
  dfb <- data.frame(effect = as.numeric(draws_eff))
  ggplot(dfb, aes(x = effect)) +
    geom_density() + geom_vline(xintercept = 1, linetype = "dashed") +
    labs(title = "Bayesian Posterior Density of Effect", x = "Effect", y = "Density") +
    theme_minimal()
}

#' Create Rho Sensitivity Plot
#' @keywords internal
.create_rho_sensitivity_plot <- function(rho_df, config) {
  if (is.null(rho_df) || nrow(rho_df)==0) return(NULL)
  lab <- .cbamm_measure_meta(config$effect_measure)$effect_label
  ggplot(rho_df, aes(x = rho, y = eff)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15) + geom_line() + geom_point() +
    geom_hline(yintercept = if (.cbamm_measure_meta(config$effect_measure)$is_ratio) 1 else 0, linetype = "dashed") +
    labs(title = "MV ρ-sensitivity", x = "Assumed within-study correlation (ρ)", y = lab) +
    theme_minimal()
}

#' Create Influence Plot
#' @keywords internal
.create_influence_plot <- function(inf_res) {
  if (is.null(inf_res) || is.null(inf_res$inf)) return(NULL)
  cd <- try(as.numeric(inf_res$inf$infmat[,"cook.d"]), silent = TRUE); if (inherits(cd, "try-error") || all(is.na(cd))) return(NULL)
  df <- data.frame(study = seq_along(cd), cooks_d = cd)
  ggplot(df, aes(x = reorder(as.character(study), cooks_d), y = cooks_d)) +
    geom_col() + coord_flip() + labs(title = "Influence (Cook's D)", x = "Study index", y = "Cook's D") + theme_minimal()
}

#' Create P-Curve Plot
#' @keywords internal
.create_pcurve_plot <- function(pcurve_res) {
  if (is.null(pcurve_res) || is.null(pcurve_res$p_sig)) return(NULL)
  sig <- pcurve_res$p_sig
  bins <- cut(sig, breaks = seq(0, 0.05, by = 0.01), include.lowest = TRUE); tab <- as.data.frame(table(bins))
  ggplot(tab, aes(x = bins, y = Freq, group = 1)) +
    geom_col() + geom_line() +
    labs(title = "p-curve (significant p-values)", x = "p in (0, .05]", y = "Count") +
    theme_minimal()
}

#' Create Meta-Regression Plot
#' @keywords internal
.create_meta_regression_plot <- function(mr_res, config) {
  if (is.null(mr_res) || is.null(mr_res$preds)) return(NULL)
  lab <- .cbamm_measure_meta(config$effect_measure)$effect_label
  ggplot(mr_res$preds, aes(x = year, y = fit)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15) +
    geom_line() + geom_point(data = NULL) +
    geom_hline(yintercept = if (.cbamm_measure_meta(config$effect_measure)$is_ratio) 1 else 0, linetype = "dashed") +
    labs(title = "Meta-regression (natural spline on year)", x = "Year", y = lab) +
    theme_minimal()
}

#' Create All Result Plots
#'
#' Generate all visualization plots
#'
#' @param results Results list
#' @param data Data frame
#' @param config Configuration object
#'
#' @return List of plot objects
#' @keywords internal
create_result_plots <- function(results, data, config) {
  plots <- list(); add_plot <- function(lst, key, obj) { if (!is.null(obj)) lst[[key]] <- obj; lst }
  if (!is.null(results$multiverse)) plots <- add_plot(plots, "multiverse", try(.create_multiverse_plot(results$multiverse, config), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  if (!is.null(data)) {
    plots <- add_plot(plots, "forest", try(.create_forest_plot(data, config), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
    plots <- add_plot(plots, "pet",    try(.create_pet_plot(data), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
    plots <- add_plot(plots, "peese",  try(.create_peese_plot(data), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  }
  if (!is.null(results$pooled)) {
    plots <- add_plot(plots, "funnel", try(.create_funnel_plot(results$pooled, config), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
    plots <- add_plot(plots, "leave1out", try(.create_leave1out_plot(results$pooled), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
    plots <- add_plot(plots, "cumulative", try(.create_cumulative_plot(results$pooled, data), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  }
  if (!is.null(results$bayesian)) plots <- add_plot(plots, "bayesian_posterior", try(.create_bayesian_plot(results$bayesian), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  if (!is.null(results$mv_rho)) plots <- add_plot(plots, "mv_rho_sensitivity", try(.create_rho_sensitivity_plot(results$mv_rho, config), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  if (!is.null(results$influence)) plots <- add_plot(plots, "influence", try(.create_influence_plot(results$influence), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  if (!is.null(results$pcurve)) plots <- add_plot(plots, "pcurve", try(.create_pcurve_plot(results$pcurve), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  if (!is.null(results$meta_regression)) plots <- add_plot(plots, "meta_regression", try(.create_meta_regression_plot(results$meta_regression, config), silent = TRUE) |> (\(x) if (inherits(x,"try-error")) NULL else x)())
  plots
}

#' Show and Save All Plots
#'
#' Display and export all plots
#'
#' @param out CBAMM output object
#' @param save_dir Directory for saving plots
#' @param pdf_file PDF filename
#' @param width Plot width
#' @param height Plot height
#' @param dpi DPI for PNG export
#'
#' @return List with paths
#' @export
cbamm_show_all_plots <- function(out,
                                 save_dir = "cbamm_plots",
                                 pdf_file = "cbamm_all_plots.pdf",
                                 width = 11, height = 8.5, dpi = 300) {
  if (is.null(out) || is.null(out$results) || is.null(out$results$plots)) { message("[cbamm_show_all_plots] Nothing to plot."); return(invisible(NULL)) }
  plots <- out$results$plots
  if (!dir.exists(save_dir)) dir.create(save_dir, recursive = TRUE)
  cat("\n[CBAMM] Printing plots one-by-one to the current device...\n")
  for (nm in names(plots)) { cat(sprintf(" -> %s\n", nm)); p <- plots[[nm]]; try(print(p), silent = TRUE) }
  pdf_path <- file.path(save_dir, pdf_file)
  cat(sprintf("\n[CBAMM] Writing all plots to a multipage PDF: %s\n", pdf_path))
  grDevices::pdf(pdf_path, width = width, height = height); on.exit(try(grDevices::dev.off(), silent = TRUE), add = TRUE)
  for (nm in names(plots)) { p <- plots[[nm]]; try(print(p), silent = TRUE) }
  try(grDevices::dev.off(), silent = TRUE)
  cat("[CBAMM] Saving individual PNGs in:", normalizePath(save_dir, winslash = "/", mustWork = FALSE), "\n")
  for (nm in names(plots)) {
    p <- plots[[nm]]; fn <- file.path(save_dir, paste0("plot_", nm, ".png"))
    if (inherits(p, "ggplot")) try(ggplot2::ggsave(filename = fn, plot = p, width = width, height = height, dpi = dpi, units = "in"), silent = TRUE)
    else if (inherits(p, "plotly")) message(sprintf("[plotly] Skipping PNG export for '%s' (requires webshot/Chromote).", nm))
    else try({ grDevices::png(fn, width = width, height = height, units = "in", res = dpi); print(p); grDevices::dev.off() }, silent = TRUE)
  }
  cat("\n[CBAMM] Done. Open the PDF above if you still don't see figures.\n")
  invisible(list(pdf = pdf_path, dir = save_dir))
}
