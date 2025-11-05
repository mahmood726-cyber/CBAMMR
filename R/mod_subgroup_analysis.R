#' Comprehensive Subgroup Analysis Module
#'
#' Advanced subgroup analysis with interaction tests, forest plots by subgroup,
#' mixed-effects meta-regression, and comprehensive visualizations.
#'
#' @name mod_subgroup_analysis
#' @family CBAMMR Modules
#'
#' @references
#' Borenstein et al. (2013). *Introduction to Meta-Analysis*. Wiley.
#' Deeks et al. (2001). BMJ 323:101-105. - Interaction tests in meta-analysis
#' Thompson & Higgins (2002). Statistics in Medicine 21:1539-1558. - Subgroup analysis
#' Higgins & Thompson (2004). Statistics in Medicine 23:1663-1682. - Controlling Type I errors
#'
NULL


#' Comprehensive Subgroup Meta-Analysis
#'
#' Performs comprehensive subgroup analysis with interaction tests, subgroup-specific
#' heterogeneity assessment, and multiple comparison adjustments.
#'
#' @param yi Effect size estimates
#' @param vi Sampling variances
#' @param subgroup Vector of subgroup indicators (factor or character)
#' @param studlab Study labels
#' @param method Meta-analysis method: "REML", "DL", "ML", "EB", etc.
#' @param test_interaction Perform interaction test between subgroups (default: TRUE)
#' @param adjust_multiple Adjustment method for multiple comparisons: "none", "bonferroni",
#'   "holm", "hochberg", "hommel", "BY", "fdr"
#' @param mixed_effects Use mixed-effects model with subgroup as moderator (default: TRUE)
#'
#' @return List containing:
#'   \item{overall}{Overall meta-analysis ignoring subgroups}
#'   \item{subgroups}{Subgroup-specific meta-analyses}
#'   \item{interaction_test}{Test for differences between subgroups}
#'   \item{mixed_effects}{Mixed-effects meta-regression results}
#'   \item{pairwise_comparisons}{All pairwise subgroup comparisons}
#'   \item{heterogeneity_comparison}{Comparison of heterogeneity across subgroups}
#'
#' @details
#' Implements comprehensive subgroup analysis following Cochrane Handbook recommendations:
#' - Subgroup-specific random-effects meta-analysis
#' - Q-test for interaction (between-subgroup heterogeneity)
#' - Mixed-effects meta-regression with subgroup as moderator
#' - Pairwise comparisons between all subgroups
#' - Adjustments for multiple testing
#' - Assessment of within-subgroup and between-subgroup heterogeneity
#'
#' @export
#' @examples
#' \dontrun{
#' # Example with 3 subgroups
#' set.seed(123)
#' yi <- c(rnorm(10, 0.3, 0.2), rnorm(10, 0.5, 0.2), rnorm(10, 0.7, 0.2))
#' vi <- runif(30, 0.01, 0.05)
#' subgroup <- factor(rep(c("Low risk", "Medium risk", "High risk"), each = 10))
#' studlab <- paste0("Study ", 1:30)
#'
#' result <- cbamm_subgroup_analysis(
#'   yi = yi,
#'   vi = vi,
#'   subgroup = subgroup,
#'   studlab = studlab,
#'   method = "REML",
#'   adjust_multiple = "holm"
#' )
#'
#' print(result)
#' plot(result)
#' }
cbamm_subgroup_analysis <- function(yi, vi, subgroup, studlab = NULL,
                                   method = "REML",
                                   test_interaction = TRUE,
                                   adjust_multiple = "holm",
                                   mixed_effects = TRUE) {

  # Input validation
  if (length(yi) != length(vi) || length(yi) != length(subgroup)) {
    stop("yi, vi, and subgroup must have the same length")
  }

  if (is.null(studlab)) {
    studlab <- paste0("Study", 1:length(yi))
  }

  # Convert subgroup to factor
  subgroup <- as.factor(subgroup)
  subgroup_levels <- levels(subgroup)
  n_subgroups <- length(subgroup_levels)

  if (n_subgroups < 2) {
    stop("Need at least 2 subgroups for subgroup analysis")
  }

  cat("="  %R% 70, "\n")
  cat("COMPREHENSIVE SUBGROUP ANALYSIS\n")
  cat("=" %R% 70, "\n\n")
  cat(sprintf("Number of studies: %d\n", length(yi)))
  cat(sprintf("Number of subgroups: %d\n", n_subgroups))
  cat(sprintf("Subgroups: %s\n", paste(subgroup_levels, collapse = ", ")))
  cat("\n")

  # 1. Overall meta-analysis (ignoring subgroups)
  overall <- metafor::rma(yi = yi, vi = vi, method = method)

  cat("Overall Effect (all studies combined):\n")
  cat(sprintf("  Estimate: %.4f (95%% CI: %.4f to %.4f), p = %.4f\n",
              overall$b[1], overall$ci.lb, overall$ci.ub, overall$pval))
  cat(sprintf("  Heterogeneity: Q = %.2f, df = %d, p = %.4f\n",
              overall$QE, overall$k - 1, overall$QEp))
  cat(sprintf("  I² = %.1f%%, τ² = %.4f\n\n", overall$I2, overall$tau2))

  # 2. Subgroup-specific meta-analyses
  subgroup_results <- list()

  cat("Subgroup-Specific Results:\n")
  cat("-" %R% 70, "\n")

  for (sg in subgroup_levels) {
    idx <- subgroup == sg
    n_studies_sg <- sum(idx)

    if (n_studies_sg < 2) {
      warning(sprintf("Subgroup '%s' has only %d study. Skipping.", sg, n_studies_sg))
      next
    }

    sg_fit <- metafor::rma(yi = yi[idx], vi = vi[idx], method = method)

    subgroup_results[[sg]] <- list(
      subgroup = sg,
      n_studies = n_studies_sg,
      estimate = sg_fit$b[1],
      se = sg_fit$se,
      ci_lb = sg_fit$ci.lb,
      ci_ub = sg_fit$ci.ub,
      pval = sg_fit$pval,
      tau2 = sg_fit$tau2,
      I2 = sg_fit$I2,
      Q = sg_fit$QE,
      Qp = sg_fit$QEp,
      model = sg_fit
    )

    cat(sprintf("\n%s (k = %d):\n", sg, n_studies_sg))
    cat(sprintf("  Estimate: %.4f (95%% CI: %.4f to %.4f), p = %.4f\n",
                sg_fit$b[1], sg_fit$ci.lb, sg_fit$ci.ub, sg_fit$pval))
    cat(sprintf("  Heterogeneity: τ² = %.4f, I² = %.1f%%\n",
                sg_fit$tau2, sg_fit$I2))
  }

  cat("\n")

  # 3. Test for interaction (Q-test between subgroups)
  interaction_test <- NULL

  if (test_interaction && n_subgroups >= 2) {
    cat("Test for Subgroup Differences (Interaction Test):\n")
    cat("-" %R% 70, "\n")

    # Mixed-effects model with subgroup as categorical moderator
    subgroup_numeric <- as.numeric(subgroup) - 1  # Convert to 0/1/2...
    mod_subgroup <- metafor::rma(yi = yi, vi = vi, mods = ~ subgroup, method = method)

    # Q-test for moderators (interaction test)
    Q_between <- mod_subgroup$QM
    df_between <- mod_subgroup$m
    p_between <- mod_subgroup$QMp

    # Calculate within-subgroup heterogeneity
    Q_within <- overall$QE - Q_between
    df_within <- (overall$k - 1) - df_between

    interaction_test <- list(
      Q_between = Q_between,
      df_between = df_between,
      p_between = p_between,
      Q_within = Q_within,
      df_within = df_within,
      R2 = max(0, (overall$QE - mod_subgroup$QE) / overall$QE)  # Proportion explained
    )

    cat(sprintf("  Q (between subgroups) = %.2f, df = %d, p = %.4f\n",
                Q_between, df_between, p_between))
    cat(sprintf("  Q (within subgroups) = %.2f, df = %d\n",
                Q_within, df_within))
    cat(sprintf("  R² (% heterogeneity explained) = %.1f%%\n", 100 * interaction_test$R2))

    if (p_between < 0.05) {
      cat("  ✓ Significant difference between subgroups (p < 0.05)\n")
    } else {
      cat("  ✗ No significant difference between subgroups (p ≥ 0.05)\n")
    }
    cat("\n")
  }

  # 4. Mixed-effects meta-regression
  mixed_effects_result <- NULL

  if (mixed_effects) {
    mod_mixed <- metafor::rma(yi = yi, vi = vi, mods = ~ subgroup, method = method)

    mixed_effects_result <- list(
      model = mod_mixed,
      coefficients = coef(mod_mixed),
      se = mod_mixed$se,
      pval = mod_mixed$pval,
      ci_lb = mod_mixed$ci.lb,
      ci_ub = mod_mixed$ci.ub,
      tau2 = mod_mixed$tau2,
      I2 = mod_mixed$I2,
      R2 = max(0, (overall$tau2 - mod_mixed$tau2) / overall$tau2)
    )

    cat("Mixed-Effects Meta-Regression (Subgroup as Moderator):\n")
    cat("-" %R% 70, "\n")
    cat(sprintf("  Residual heterogeneity: τ² = %.4f, I² = %.1f%%\n",
                mod_mixed$tau2, mod_mixed$I2))
    cat(sprintf("  R² = %.1f%% (heterogeneity explained by subgroup)\n",
                100 * mixed_effects_result$R2))
    cat("\n")
  }

  # 5. Pairwise comparisons between subgroups
  pairwise_comparisons <- NULL

  if (n_subgroups >= 2) {
    cat("Pairwise Comparisons Between Subgroups:\n")
    cat("-" %R% 70, "\n")

    pairwise_list <- list()
    p_values <- c()

    for (i in 1:(n_subgroups - 1)) {
      for (j in (i + 1):n_subgroups) {
        sg1 <- subgroup_levels[i]
        sg2 <- subgroup_levels[j]

        if (is.null(subgroup_results[[sg1]]) || is.null(subgroup_results[[sg2]])) {
          next
        }

        # Difference in estimates
        diff <- subgroup_results[[sg1]]$estimate - subgroup_results[[sg2]]$estimate

        # Standard error of difference
        se_diff <- sqrt(subgroup_results[[sg1]]$se^2 + subgroup_results[[sg2]]$se^2)

        # Z-test
        z <- diff / se_diff
        p <- 2 * pnorm(-abs(z))

        # CI for difference
        ci_lb_diff <- diff - 1.96 * se_diff
        ci_ub_diff <- diff + 1.96 * se_diff

        pairwise_list[[paste0(sg1, "_vs_", sg2)]] <- list(
          subgroup1 = sg1,
          subgroup2 = sg2,
          difference = diff,
          se = se_diff,
          z = z,
          p = p,
          ci_lb = ci_lb_diff,
          ci_ub = ci_ub_diff
        )

        p_values <- c(p_values, p)

        cat(sprintf("  %s vs %s:\n", sg1, sg2))
        cat(sprintf("    Difference: %.4f (95%% CI: %.4f to %.4f)\n",
                    diff, ci_lb_diff, ci_ub_diff))
        cat(sprintf("    Z = %.3f, p = %.4f", z, p))

        if (p < 0.05) {
          cat(" *\n")
        } else {
          cat("\n")
        }
      }
    }

    # Adjust for multiple comparisons
    if (adjust_multiple != "none" && length(p_values) > 0) {
      p_adjusted <- p.adjust(p_values, method = adjust_multiple)

      cat(sprintf("\n  Adjustment for multiple comparisons: %s method\n", adjust_multiple))
      cat("  Adjusted p-values: ", paste(sprintf("%.4f", p_adjusted), collapse = ", "), "\n")

      # Add adjusted p-values to pairwise list
      idx <- 1
      for (comp_name in names(pairwise_list)) {
        pairwise_list[[comp_name]]$p_adjusted <- p_adjusted[idx]
        idx <- idx + 1
      }
    }

    pairwise_comparisons <- pairwise_list
    cat("\n")
  }

  # 6. Heterogeneity comparison across subgroups
  heterogeneity_comparison <- data.frame(
    Subgroup = names(subgroup_results),
    k = sapply(subgroup_results, function(x) x$n_studies),
    tau2 = sapply(subgroup_results, function(x) x$tau2),
    I2 = sapply(subgroup_results, function(x) x$I2),
    Q = sapply(subgroup_results, function(x) x$Q),
    Qp = sapply(subgroup_results, function(x) x$Qp),
    stringsAsFactors = FALSE
  )

  cat("Heterogeneity Comparison Across Subgroups:\n")
  cat("-" %R% 70, "\n")
  print(heterogeneity_comparison, row.names = FALSE)
  cat("\n")

  cat("=" %R% 70, "\n")
  cat("Analysis complete. Use plot() to visualize results.\n")
  cat("=" %R% 70, "\n\n")

  # Return comprehensive results
  result <- list(
    overall = overall,
    subgroups = subgroup_results,
    interaction_test = interaction_test,
    mixed_effects = mixed_effects_result,
    pairwise_comparisons = pairwise_comparisons,
    heterogeneity_comparison = heterogeneity_comparison,
    data = data.frame(
      studlab = studlab,
      yi = yi,
      vi = vi,
      subgroup = subgroup
    ),
    method = method,
    n_subgroups = n_subgroups
  )

  class(result) <- c("cbamm_subgroup", "list")
  return(result)
}


#' Plot Subgroup Analysis Results
#'
#' Creates forest plots stratified by subgroup with overall effect and subgroup effects.
#'
#' @param x Object of class cbamm_subgroup
#' @param type Plot type: "forest" (default), "forest_overall", "heterogeneity", "comparison"
#' @param ... Additional arguments passed to plotting functions
#'
#' @export
#' @method plot cbamm_subgroup
plot.cbamm_subgroup <- function(x, type = "forest", ...) {

  if (type == "forest") {
    # Forest plot stratified by subgroup
    plot_forest_by_subgroup(x, ...)

  } else if (type == "forest_overall") {
    # Forest plot with overall and subgroup estimates
    plot_forest_with_subgroups(x, ...)

  } else if (type == "heterogeneity") {
    # Heterogeneity comparison plot
    plot_heterogeneity_comparison(x, ...)

  } else if (type == "comparison") {
    # Pairwise comparison plot
    plot_pairwise_comparisons(x, ...)

  } else {
    stop("Unknown plot type. Choose from: 'forest', 'forest_overall', 'heterogeneity', 'comparison'")
  }
}


#' @keywords internal
plot_forest_by_subgroup <- function(x, ...) {
  # Forest plot with studies grouped by subgroup
  data <- x$data

  # Create forest plot using metafor
  metafor::forest(
    x$overall$yi,
    vi = x$overall$vi,
    slab = data$studlab,
    ilab = data$subgroup,
    ilab.xpos = -4,
    main = "Forest Plot by Subgroup",
    xlab = "Effect Size",
    ...
  )
}


#' @keywords internal
plot_forest_with_subgroups <- function(x, ...) {
  # Forest plot showing subgroup-specific estimates and overall estimate

  sg_names <- names(x$subgroups)
  n_sg <- length(sg_names)

  estimates <- c(sapply(x$subgroups, function(s) s$estimate), x$overall$b[1])
  ci_lb <- c(sapply(x$subgroups, function(s) s$ci_lb), x$overall$ci.lb)
  ci_ub <- c(sapply(x$subgroups, function(s) s$ci_ub), x$overall$ci.ub)
  labels <- c(sg_names, "Overall")

  # Create plot
  par(mar = c(5, 8, 4, 2))
  plot(estimates, n_sg:1, xlim = range(c(ci_lb, ci_ub)),
       ylim = c(0, n_sg + 1), yaxt = "n", ylab = "",
       xlab = "Effect Size", main = "Subgroup and Overall Estimates",
       pch = c(rep(15, n_sg), 18), cex = c(rep(1.5, n_sg), 2),
       col = c(rep("blue", n_sg), "red"))

  # Add CIs
  segments(ci_lb, (n_sg + 1):1, ci_ub, (n_sg + 1):1,
           lwd = 2, col = c(rep("blue", n_sg), "red"))

  # Add labels
  axis(2, at = (n_sg + 1):1, labels = labels, las = 1)

  # Add reference line at 0
  abline(v = 0, lty = 2, col = "gray")
}


#' @keywords internal
plot_heterogeneity_comparison <- function(x, ...) {
  # Bar plot comparing heterogeneity across subgroups

  het_data <- x$heterogeneity_comparison

  par(mfrow = c(1, 2), mar = c(8, 4, 3, 2))

  # I² comparison
  barplot(het_data$I2, names.arg = het_data$Subgroup,
          main = "I² by Subgroup", ylab = "I² (%)",
          las = 2, col = "lightblue", ylim = c(0, 100))
  abline(h = c(25, 50, 75), lty = 2, col = "gray")

  # τ² comparison
  barplot(het_data$tau2, names.arg = het_data$Subgroup,
          main = "τ² by Subgroup", ylab = "τ²",
          las = 2, col = "lightgreen")

  par(mfrow = c(1, 1))
}


#' @keywords internal
plot_pairwise_comparisons <- function(x, ...) {
  # Plot pairwise differences between subgroups

  if (is.null(x$pairwise_comparisons) || length(x$pairwise_comparisons) == 0) {
    stop("No pairwise comparisons available")
  }

  comp_names <- names(x$pairwise_comparisons)
  n_comp <- length(comp_names)

  diffs <- sapply(x$pairwise_comparisons, function(c) c$difference)
  ci_lb <- sapply(x$pairwise_comparisons, function(c) c$ci_lb)
  ci_ub <- sapply(x$pairwise_comparisons, function(c) c$ci_ub)
  p_vals <- sapply(x$pairwise_comparisons, function(c) c$p)

  # Colors based on significance
  colors <- ifelse(p_vals < 0.05, "red", "gray")

  par(mar = c(5, 12, 4, 2))
  plot(diffs, n_comp:1, xlim = range(c(ci_lb, ci_ub)),
       ylim = c(0, n_comp + 1), yaxt = "n", ylab = "",
       xlab = "Difference in Effect Size",
       main = "Pairwise Subgroup Comparisons",
       pch = 19, cex = 1.5, col = colors)

  # Add CIs
  segments(ci_lb, n_comp:1, ci_ub, n_comp:1, lwd = 2, col = colors)

  # Add labels
  axis(2, at = n_comp:1, labels = comp_names, las = 1, cex.axis = 0.8)

  # Add reference line at 0
  abline(v = 0, lty = 2, col = "black", lwd = 2)

  # Add legend
  legend("topright", legend = c("Significant (p < 0.05)", "Not significant"),
         col = c("red", "gray"), pch = 19, cex = 0.8)
}


#' Print Subgroup Analysis Results
#'
#' @export
#' @method print cbamm_subgroup
print.cbamm_subgroup <- function(x, ...) {
  cat("=" %R% 70, "\n")
  cat("CBAMMR Comprehensive Subgroup Analysis\n")
  cat("=" %R% 70, "\n\n")

  cat(sprintf("Number of studies: %d\n", nrow(x$data)))
  cat(sprintf("Number of subgroups: %d\n", x$n_subgroups))
  cat(sprintf("Method: %s\n\n", x$method))

  cat("Overall Effect:\n")
  cat(sprintf("  Estimate: %.4f (95%% CI: %.4f to %.4f)\n",
              x$overall$b[1], x$overall$ci.lb, x$overall$ci.ub))
  cat(sprintf("  I² = %.1f%%, τ² = %.4f\n\n", x$overall$I2, x$overall$tau2))

  cat("Subgroup Results:\n")
  for (sg_name in names(x$subgroups)) {
    sg <- x$subgroups[[sg_name]]
    cat(sprintf("  %s (k=%d): %.4f (%.4f to %.4f)\n",
                sg_name, sg$n_studies, sg$estimate, sg$ci_lb, sg$ci_ub))
  }

  if (!is.null(x$interaction_test)) {
    cat(sprintf("\nInteraction Test: Q = %.2f, df = %d, p = %.4f\n",
                x$interaction_test$Q_between,
                x$interaction_test$df_between,
                x$interaction_test$p_between))

    if (x$interaction_test$p_between < 0.05) {
      cat("✓ Significant difference between subgroups\n")
    } else {
      cat("✗ No significant difference between subgroups\n")
    }
  }

  cat("\n")
  cat("Use plot() to visualize results\n")
  cat("=" %R% 70, "\n")

  invisible(x)
}


# Helper for string repetition
`%R%` <- function(x, n) {
  paste(rep(x, n), collapse = "")
}
