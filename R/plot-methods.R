#' Plot Methods for CBAMMR Advanced Methods
#'
#' Visualization functions for advanced meta-analysis methods
#'
#' @name plot-methods
#' @keywords internal
NULL

#' Plot Permutation Test Results
#'
#' Creates a histogram of the permutation distribution with the observed
#' statistic marked.
#'
#' @param x An object of class "cbamm_permutation_test"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_histogram geom_vline annotate labs theme_minimal
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_permutation_test(yi, vi, n_perm = 1000)
#' plot(result)
#' }
plot.cbamm_permutation_test <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(statistic = x$perm_distribution)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = statistic)) +
    ggplot2::geom_histogram(bins = 50, fill = "#3498db", alpha = 0.7, color = "white") +
    ggplot2::geom_vline(xintercept = x$observed_stat, color = "#e74c3c",
                       linewidth = 1.5, linetype = "dashed") +
    ggplot2::annotate("text", x = x$observed_stat, y = Inf,
                     label = sprintf("Observed\n%.3f", x$observed_stat),
                     vjust = 1.5, color = "#e74c3c", fontface = "bold", size = 4) +
    ggplot2::labs(
      title = "Permutation Test: Null Distribution",
      subtitle = sprintf("P-value = %.4f (n = %d permutations)", x$pvalue, length(x$perm_distribution)),
      x = "Test Statistic",
      y = "Frequency"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40")
    )

  return(p)
}


#' Plot Bootstrap Confidence Interval
#'
#' Creates a histogram of the bootstrap distribution with confidence interval
#' bounds marked.
#'
#' @param x An object of class "cbamm_bootstrap_ci"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_histogram geom_vline annotate labs theme_minimal
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_bootstrap_ci(yi, vi, n_boot = 1000)
#' plot(result)
#' }
plot.cbamm_bootstrap_ci <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(estimate = x$boot_estimates)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = estimate)) +
    ggplot2::geom_histogram(bins = 50, fill = "#2ecc71", alpha = 0.7, color = "white") +
    ggplot2::geom_vline(xintercept = x$estimate, color = "#e74c3c",
                       linewidth = 1.5, linetype = "solid") +
    ggplot2::geom_vline(xintercept = x$ci[1], color = "#f39c12",
                       linewidth = 1, linetype = "dashed") +
    ggplot2::geom_vline(xintercept = x$ci[2], color = "#f39c12",
                       linewidth = 1, linetype = "dashed") +
    ggplot2::annotate("text", x = x$estimate, y = Inf,
                     label = sprintf("Estimate\n%.3f", x$estimate),
                     vjust = 1.5, color = "#e74c3c", fontface = "bold", size = 4) +
    ggplot2::annotate("rect", xmin = x$ci[1], xmax = x$ci[2],
                     ymin = 0, ymax = Inf, alpha = 0.1, fill = "#f39c12") +
    ggplot2::labs(
      title = "Bootstrap Distribution with Confidence Interval",
      subtitle = sprintf("%d%% CI: [%.3f, %.3f] (%s method)",
                        x$conf_level * 100, x$ci[1], x$ci[2], x$method),
      x = "Effect Size Estimate",
      y = "Frequency"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40")
    )

  return(p)
}


#' Plot Quantile Meta-Analysis Results
#'
#' Creates a forest plot showing effect estimates at different quantiles with
#' confidence intervals.
#'
#' @param x An object of class "cbamm_quantile_ma"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbarh geom_vline labs theme_minimal
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_quantile_ma(yi, vi)
#' plot(result)
#' }
plot.cbamm_quantile_ma <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- x$quantile_estimates
  df$quantile_label <- sprintf("%dth percentile", df$quantile * 100)

  p <- ggplot2::ggplot(df, ggplot2::aes(y = quantile_label, x = estimate)) +
    ggplot2::geom_vline(xintercept = 0, color = "gray50", linetype = "dashed", alpha = 0.5) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = ci_lower, xmax = ci_upper),
                           height = 0.2, color = "#3498db", linewidth = 0.8) +
    ggplot2::geom_point(size = 4, color = "#e74c3c") +
    ggplot2::labs(
      title = "Quantile Meta-Analysis: Heterogeneous Treatment Effects",
      subtitle = "Effect estimates across the outcome distribution",
      x = "Effect Size",
      y = "Quantile"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40"),
      panel.grid.major.y = ggplot2::element_blank()
    )

  return(p)
}


#' Plot Threshold Analysis Results
#'
#' Shows how the effect estimate changes with different bias values and marks
#' the decision threshold.
#'
#' @param x An object of class "cbamm_threshold_analysis"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_line geom_hline geom_vline geom_ribbon labs theme_minimal
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_threshold_analysis(yi, vi, decision_threshold = 0.3)
#' plot(result)
#' }
plot.cbamm_threshold_analysis <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(
    bias = x$bias_range,
    estimate = x$estimates,
    ci_lower = x$ci_lower,
    ci_upper = x$ci_upper
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = bias, y = estimate)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = ci_lower, ymax = ci_upper),
                        alpha = 0.2, fill = "#3498db") +
    ggplot2::geom_line(color = "#3498db", linewidth = 1.2) +
    ggplot2::geom_hline(yintercept = x$decision_threshold,
                       color = "#e74c3c", linewidth = 1, linetype = "dashed") +
    ggplot2::geom_vline(xintercept = x$threshold_bias,
                       color = "#f39c12", linewidth = 1, linetype = "dotted") +
    ggplot2::annotate("text", x = x$threshold_bias, y = Inf,
                     label = sprintf("Threshold bias\n%.3f", x$threshold_bias),
                     vjust = 1.2, color = "#f39c12", fontface = "bold", size = 3.5) +
    ggplot2::annotate("text", x = Inf, y = x$decision_threshold,
                     label = sprintf("Decision threshold: %.3f", x$decision_threshold),
                     hjust = 1.1, color = "#e74c3c", fontface = "bold", size = 3.5) +
    ggplot2::labs(
      title = "Threshold Analysis: Decision Robustness",
      subtitle = sprintf("Current estimate: %.3f | Bias needed to change decision: %.3f",
                        x$current_estimate, abs(x$threshold_bias)),
      x = "Bias",
      y = "Effect Estimate"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40")
    )

  return(p)
}


#' Plot Decision Curve Analysis
#'
#' Displays net benefit across different decision thresholds.
#'
#' @param x An object of class "cbamm_decision_curve"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_line geom_vline geom_point labs theme_minimal
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_decision_curve(yi, vi)
#' plot(result)
#' }
plot.cbamm_decision_curve <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(
    threshold = x$threshold_range,
    net_benefit_model = x$net_benefit_model,
    net_benefit_all = x$net_benefit_all,
    net_benefit_none = x$net_benefit_none
  )

  # Reshape for plotting
  df_long <- data.frame(
    threshold = rep(df$threshold, 3),
    net_benefit = c(df$net_benefit_model, df$net_benefit_all, df$net_benefit_none),
    strategy = rep(c("Model", "Treat All", "Treat None"), each = nrow(df))
  )

  p <- ggplot2::ggplot(df_long, ggplot2::aes(x = threshold, y = net_benefit,
                                             color = strategy, linetype = strategy)) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::geom_vline(xintercept = x$optimal_threshold,
                       color = "gray30", linewidth = 0.8, linetype = "dotted") +
    ggplot2::geom_point(data = data.frame(x = x$optimal_threshold, y = x$max_net_benefit),
                       ggplot2::aes(x = x, y = y), color = "#e74c3c", size = 4,
                       inherit.aes = FALSE) +
    ggplot2::annotate("text", x = x$optimal_threshold, y = x$max_net_benefit,
                     label = sprintf("Optimal\nthreshold: %.2f", x$optimal_threshold),
                     vjust = -1, color = "#e74c3c", fontface = "bold", size = 3.5) +
    ggplot2::scale_color_manual(values = c("Model" = "#3498db", "Treat All" = "#2ecc71",
                                           "Treat None" = "#95a5a6")) +
    ggplot2::scale_linetype_manual(values = c("Model" = "solid", "Treat All" = "dashed",
                                              "Treat None" = "dotted")) +
    ggplot2::labs(
      title = "Decision Curve Analysis",
      subtitle = sprintf("Optimal threshold: %.2f | Maximum net benefit: %.3f",
                        x$optimal_threshold, x$max_net_benefit),
      x = "Decision Threshold",
      y = "Net Benefit",
      color = "Strategy",
      linetype = "Strategy"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40"),
      legend.position = "right"
    )

  return(p)
}


#' Plot Treatment Ranking Probabilities
#'
#' Creates a rankogram showing the probability of each treatment being ranked
#' in each position, plus a SUCRA plot.
#'
#' @param x An object of class "cbamm_prob_best"
#' @param type Character indicating plot type: "rankogram" (default), "sucra", or "both"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object or list of ggplot2 objects if type = "both"
#' @export
#' @importFrom ggplot2 ggplot aes geom_tile geom_bar geom_text labs theme_minimal scale_fill_gradient
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_prob_best(yi, vi)
#' plot(result)
#' plot(result, type = "sucra")
#' }
plot.cbamm_prob_best <- function(x, type = c("rankogram", "sucra", "both"), ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  type <- match.arg(type)

  # Rankogram
  if (type %in% c("rankogram", "both")) {
    # Prepare data
    rank_matrix <- x$rank_probs
    n_treatments <- nrow(rank_matrix)

    df_rank <- data.frame(
      treatment = rep(rownames(rank_matrix), ncol(rank_matrix)),
      rank = rep(1:ncol(rank_matrix), each = n_treatments),
      probability = as.vector(rank_matrix)
    )

    p_rankogram <- ggplot2::ggplot(df_rank, ggplot2::aes(x = factor(rank), y = treatment,
                                                         fill = probability)) +
      ggplot2::geom_tile(color = "white", linewidth = 0.5) +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", probability)),
                        color = "white", fontface = "bold", size = 3) +
      ggplot2::scale_fill_gradient(low = "#ecf0f1", high = "#3498db",
                                   limits = c(0, 1), name = "Probability") +
      ggplot2::labs(
        title = "Rankogram: Treatment Ranking Probabilities",
        subtitle = "Probability of each treatment being ranked in each position",
        x = "Rank",
        y = "Treatment"
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 14),
        plot.subtitle = ggplot2::element_text(color = "gray40"),
        panel.grid = ggplot2::element_blank()
      )
  }

  # SUCRA plot
  if (type %in% c("sucra", "both")) {
    df_sucra <- data.frame(
      treatment = names(x$sucra),
      sucra = x$sucra
    )
    df_sucra$treatment <- factor(df_sucra$treatment,
                                 levels = df_sucra$treatment[order(df_sucra$sucra, decreasing = TRUE)])

    p_sucra <- ggplot2::ggplot(df_sucra, ggplot2::aes(x = treatment, y = sucra, fill = sucra)) +
      ggplot2::geom_bar(stat = "identity", color = "white", linewidth = 0.5) +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", sucra * 100)),
                        vjust = -0.5, fontface = "bold", size = 3.5) +
      ggplot2::scale_fill_gradient(low = "#e74c3c", high = "#2ecc71",
                                   limits = c(0, 1), name = "SUCRA") +
      ggplot2::labs(
        title = "SUCRA: Surface Under Cumulative Ranking",
        subtitle = "Higher SUCRA indicates better overall ranking",
        x = "Treatment",
        y = "SUCRA Score"
      ) +
      ggplot2::ylim(0, 1.1) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 14),
        plot.subtitle = ggplot2::element_text(color = "gray40"),
        axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
      )
  }

  if (type == "both") {
    if (requireNamespace("patchwork", quietly = TRUE)) {
      return(p_rankogram / p_sucra)
    } else {
      message("Package 'patchwork' not available. Returning list of plots instead.")
      return(list(rankogram = p_rankogram, sucra = p_sucra))
    }
  } else if (type == "rankogram") {
    return(p_rankogram)
  } else {
    return(p_sucra)
  }
}


#' Plot NNT Meta-Analysis Results
#'
#' Visualizes the Number Needed to Treat with confidence intervals and
#' baseline risk information.
#'
#' @param x An object of class "cbamm_nnt_meta"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbarh geom_vline annotate labs theme_minimal
#'
#' @examples
#' \dontrun{
#' yi <- log(c(0.7, 0.6, 0.8, 0.65, 0.75))
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_nnt_meta(yi, vi, baseline_risk = 0.3, measure = "OR")
#' plot(result)
#' }
plot.cbamm_nnt_meta <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(
    metric = c("NNT", "ARR (%)"),
    value = c(x$nnt, abs(x$arr) * 100),
    lower = c(x$nnt_ci[1], abs(x$arr_ci[1]) * 100),
    upper = c(x$nnt_ci[2], abs(x$arr_ci[2]) * 100)
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(y = metric, x = value)) +
    ggplot2::geom_vline(xintercept = 0, color = "gray50", linetype = "dashed", alpha = 0.5) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = lower, xmax = upper),
                           height = 0.2, color = "#3498db", linewidth = 1) +
    ggplot2::geom_point(size = 5, color = "#e74c3c") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f", value)),
                      vjust = -1.5, fontface = "bold", size = 4) +
    ggplot2::labs(
      title = "Number Needed to Treat (NNT) from Meta-Analysis",
      subtitle = sprintf("Baseline risk: %.1f%% | Measure: %s | Time: %g %s",
                        x$baseline_risk * 100, x$measure, x$time_horizon, x$time_unit),
      x = "Value",
      y = ""
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40"),
      panel.grid.major.y = ggplot2::element_blank()
    )

  # Add interpretation text
  p <- p + ggplot2::annotate("text", x = Inf, y = 0.5,
                            label = x$interpretation,
                            hjust = 1, vjust = 0, color = "gray30", size = 3,
                            lineheight = 0.9)

  return(p)
}


#' Plot EVPI Results
#'
#' Visualizes the Expected Value of Perfect Information over time with discounting.
#'
#' @param x An object of class "cbamm_evpi"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_bar geom_text labs theme_minimal scale_fill_gradient
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_evpi(yi, vi, benefit_per_unit = 1000, population_size = 100000)
#' plot(result)
#' }
plot.cbamm_evpi <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(
    metric = c("Per Person", "Total Population", "Annual", "NPV Total"),
    value = c(x$evpi_per_person, x$evpi_total / 1e6,
              x$evpi_total / x$time_horizon / 1e6,
              x$evpi_total / 1e6),
    label = c(
      sprintf("$%.2f", x$evpi_per_person),
      sprintf("$%.1fM", x$evpi_total / 1e6),
      sprintf("$%.1fM/year", x$evpi_total / x$time_horizon / 1e6),
      sprintf("$%.1fM NPV", x$evpi_total / 1e6)
    )
  )

  df$metric <- factor(df$metric, levels = c("Per Person", "Annual", "Total Population", "NPV Total"))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = metric, y = value, fill = value)) +
    ggplot2::geom_bar(stat = "identity", color = "white", linewidth = 0.8) +
    ggplot2::geom_text(ggplot2::aes(label = label), vjust = -0.5,
                      fontface = "bold", size = 4) +
    ggplot2::scale_fill_gradient(low = "#3498db", high = "#e74c3c", guide = "none") +
    ggplot2::labs(
      title = "Expected Value of Perfect Information (EVPI)",
      subtitle = sprintf("Population: %s | Horizon: %d years | Discount: %.1f%%",
                        format(x$population_size, big.mark = ",", scientific = FALSE),
                        x$time_horizon, x$discount_rate * 100),
      x = "",
      y = "Value ($ millions for population metrics)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40"),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )

  return(p)
}


#' Plot Individualized Treatment Effect
#'
#' Visualizes predicted treatment effects for different patient profiles.
#'
#' @param x An object of class "cbamm_individualized_effect"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbar geom_hline labs theme_minimal
#'
#' @examples
#' \dontrun{
#' # Requires moderators and patient profiles
#' # See function documentation for full example
#' }
plot.cbamm_individualized_effect <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(
    effect = x$predicted_effect,
    lower = x$pred_ci[1],
    upper = x$pred_ci[2],
    average = x$average_effect
  )

  # Create patient profile label
  profile_text <- paste(names(x$patient_profile), "=", x$patient_profile, collapse = ", ")

  p <- ggplot2::ggplot(df, ggplot2::aes(x = 1, y = effect)) +
    ggplot2::geom_hline(yintercept = df$average, color = "#95a5a6",
                       linetype = "dashed", linewidth = 1) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper),
                          width = 0.2, color = "#3498db", linewidth = 1.2) +
    ggplot2::geom_point(size = 6, color = "#e74c3c") +
    ggplot2::annotate("text", x = 1, y = df$average,
                     label = sprintf("Population average: %.3f", df$average),
                     hjust = -0.1, color = "#95a5a6", fontface = "italic", size = 3.5) +
    ggplot2::annotate("text", x = 1, y = effect,
                     label = sprintf("Individual: %.3f\n[%.3f, %.3f]",
                                    effect, df$lower, df$upper),
                     vjust = -2, color = "#e74c3c", fontface = "bold", size = 4) +
    ggplot2::labs(
      title = "Individualized Treatment Effect",
      subtitle = sprintf("Patient profile: %s", profile_text),
      y = "Predicted Effect",
      x = ""
    ) +
    ggplot2::scale_x_continuous(limits = c(0.5, 1.5), breaks = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40"),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )

  return(p)
}


#' Plot RMST Meta-Analysis Results
#'
#' Visualizes the Restricted Mean Survival Time difference with confidence intervals.
#'
#' @param x An object of class "cbamm_rmst_meta"
#' @param ... Additional arguments passed to plot
#'
#' @return A ggplot2 object
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbarh geom_vline annotate labs theme_minimal
#'
#' @examples
#' \dontrun{
#' # Requires RMST data
#' # See function documentation for full example
#' }
plot.cbamm_rmst_meta <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  df <- data.frame(
    y = 1,
    estimate = x$rmst_diff,
    lower = x$ci[1],
    upper = x$ci[2]
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = estimate, y = y)) +
    ggplot2::geom_vline(xintercept = 0, color = "gray50",
                       linetype = "dashed", linewidth = 1) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = lower, xmax = upper),
                           height = 0.2, color = "#3498db", linewidth = 1.5) +
    ggplot2::geom_point(size = 6, color = "#e74c3c") +
    ggplot2::annotate("text", x = df$estimate, y = 1.3,
                     label = sprintf("RMST difference: %.2f %s\n95%% CI: [%.2f, %.2f]",
                                    df$estimate, x$time_unit, df$lower, df$upper),
                     fontface = "bold", size = 4, color = "#2c3e50") +
    ggplot2::labs(
      title = "Restricted Mean Survival Time (RMST) Meta-Analysis",
      subtitle = sprintf("Time horizon: %.1f %s | I²: %.1f%% | τ²: %.3f",
                        x$time_horizon, x$time_unit, x$I2, x$tau2),
      x = sprintf("RMST Difference (%s)", x$time_unit),
      y = ""
    ) +
    ggplot2::scale_y_continuous(limits = c(0.5, 1.5), breaks = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(color = "gray40"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank()
    )

  # Add interpretation
  interp_y <- 0.7
  p <- p + ggplot2::annotate("text", x = 0, y = interp_y,
                            label = x$interpretation,
                            hjust = 0.5, color = "gray30", size = 3.5,
                            lineheight = 0.9)

  return(p)
}
