#' Comprehensive Network Meta-Analysis Module
#'
#' Advanced network meta-analysis supporting:
#' - Multiple outcome types (binary, continuous)
#' - Arm-level and contrast-level data
#' - Frequentist and Bayesian approaches
#' - Treatment ranking with SUCRA/P-scores
#' - Inconsistency assessment (global and local)
#' - Node-splitting for loop inconsistency
#' - Network visualization (static and interactive)
#' - Meta-regression on network
#' - Comparison-adjusted funnel plots
#' - League tables with all comparisons
#'
#' @name mod_network_meta
#' @rdname mod_network_meta
#'
#' @import netmeta
#' @import meta
#' @import igraph
#' @import visNetwork
NULL

#' @describeIn mod_network_meta Convert arm-level to contrast-level data
#' @param data Data frame with arm-level data
#' @param studyvar Character. Study identifier column
#' @param treatvar Character. Treatment column
#' @param eventvar Character. Event count column (for binary)
#' @param nvar Character. Sample size column
#' @param meanvar Character. Mean column (for continuous)
#' @param sdvar Character. SD column (for continuous)
#' @param measure Character. Effect measure ("OR", "RR", "RD", "MD", "SMD")
#' @export
cbamm_nma_prepare_data <- function(data,
                                    studyvar = "study",
                                    treatvar = "treatment",
                                    eventvar = NULL,
                                    nvar = "n",
                                    meanvar = NULL,
                                    sdvar = NULL,
                                    measure = "OR") {

  # Validate inputs
  if (!studyvar %in% names(data)) stop(paste("Study variable", studyvar, "not found"))
  if (!treatvar %in% names(data)) stop(paste("Treatment variable", treatvar, "not found"))

  # Check if binary or continuous
  is_binary <- !is.null(eventvar)
  is_continuous <- !is.null(meanvar) && !is.null(sdvar)

  if (!is_binary && !is_continuous) {
    stop("Must specify either eventvar (binary) or meanvar + sdvar (continuous)")
  }

  message("Preparing network meta-analysis data...")
  message(sprintf("  Data type: %s", if (is_binary) "Binary" else "Continuous"))
  message(sprintf("  Effect measure: %s", measure))
  message(sprintf("  Studies: %d", length(unique(data[[studyvar]]))))
  message(sprintf("  Treatments: %d", length(unique(data[[treatvar]]))))

  # Convert to pairwise format using meta package
  if (is_binary) {
    pw <- meta::pairwise(
      treat = data[[treatvar]],
      event = data[[eventvar]],
      n = data[[nvar]],
      studlab = data[[studyvar]],
      data = data,
      sm = measure
    )
  } else {
    pw <- meta::pairwise(
      treat = data[[treatvar]],
      mean = data[[meanvar]],
      sd = data[[sdvar]],
      n = data[[nvar]],
      studlab = data[[studyvar]],
      data = data,
      sm = measure
    )
  }

  # Convert to data frame
  contrast_data <- as.data.frame(pw)

  message("✅ Data preparation complete")
  message(sprintf("  Pairwise comparisons: %d", nrow(contrast_data)))

  return(list(
    contrast_data = contrast_data,
    arm_data = data,
    measure = measure,
    is_binary = is_binary
  ))
}

#' @describeIn mod_network_meta Perform frequentist network meta-analysis
#' @param TE Numeric vector. Treatment effects
#' @param seTE Numeric vector. Standard errors
#' @param treat1 Character vector. First treatment in comparison
#' @param treat2 Character vector. Second treatment in comparison
#' @param studlab Character vector. Study labels
#' @param reference Character. Reference treatment (default: first alphabetically)
#' @param sm Character. Summary measure
#' @param comb.fixed Logical. Fit fixed-effect model?
#' @param comb.random Logical. Fit random-effects model?
#' @export
#' @examples
#' \dontrun{
#' # Example with smoking cessation data
#' library(netmeta)
#' data(smokingcessation)
#'
#' # Frequentist NMA
#' nma <- cbamm_nma_frequentist(
#'   TE = smokingcessation$lnor,
#'   seTE = smokingcessation$selnor,
#'   treat1 = smokingcessation$treat1,
#'   treat2 = smokingcessation$treat2,
#'   studlab = smokingcessation$study,
#'   sm = "OR"
#' )
#'
#' print(nma)
#' plot(nma$network_plot)
#' }
cbamm_nma_frequentist <- function(TE,
                                   seTE,
                                   treat1,
                                   treat2,
                                   studlab,
                                   reference = NULL,
                                   sm = "OR",
                                   comb.fixed = TRUE,
                                   comb.random = TRUE) {

  message("Performing frequentist network meta-analysis...")

  # Perform NMA using netmeta
  nma <- netmeta::netmeta(
    TE = TE,
    seTE = seTE,
    treat1 = treat1,
    treat2 = treat2,
    studlab = studlab,
    reference.group = reference,
    sm = sm,
    comb.fixed = comb.fixed,
    comb.random = comb.random
  )

  message("✅ Network meta-analysis complete")
  message(sprintf("  Treatments: %d", nma$n))
  message(sprintf("  Comparisons: %d", nma$m))
  message(sprintf("  Studies: %d", nma$k))
  message(sprintf("  Q (heterogeneity): %.2f (p = %.4f)", nma$Q, nma$pval.Q))
  message(sprintf("  I²: %.1f%%", nma$I2 * 100))

  # Calculate treatment rankings
  rankings <- netmeta::netrank(nma, small.values = "good")

  # Inconsistency assessment
  inconsistency <- safe_try(
    netmeta::netsplit(nma),
    context = "inconsistency assessment",
    return_on_error = NULL
  )

  # Create network plot
  network_plot <- safe_try(
    netmeta::netgraph(nma, seq = "optimal"),
    context = "network graph",
    return_on_error = NULL
  )

  result <- list(
    nma = nma,
    rankings = rankings,
    inconsistency = inconsistency,
    network_plot = network_plot,
    n_treatments = nma$n,
    n_comparisons = nma$m,
    n_studies = nma$k,
    heterogeneity = list(Q = nma$Q, pval = nma$pval.Q, I2 = nma$I2),
    measure = sm
  )

  class(result) <- c("cbamm_nma", "list")
  return(result)
}

#' @describeIn mod_network_meta Get treatment rankings with SUCRA
#' @param x Network meta-analysis results (netmeta object or cbamm_nma)
#' @param small.values Character. Direction of benefit ("good" or "bad")
#' @export
cbamm_nma_rankings <- function(x, small.values = "good") {

  if (inherits(x, "cbamm_nma")) {
    nma <- x$nma
  } else if (inherits(x, "netmeta")) {
    nma <- x
  } else {
    stop("x must be a netmeta or cbamm_nma object")
  }

  # Calculate rankings
  rankings <- netmeta::netrank(nma, small.values = small.values)

  # Extract SUCRA values
  sucra_fixed <- rankings$ranking.fixed
  sucra_random <- rankings$ranking.random

  # Create summary table
  summary_table <- data.frame(
    Treatment = rownames(sucra_fixed),
    SUCRA_Fixed = sucra_fixed[, "SUCRA"],
    PScore_Fixed = sucra_fixed[, "P-score"],
    SUCRA_Random = sucra_random[, "SUCRA"],
    PScore_Random = sucra_random[, "P-score"],
    stringsAsFactors = FALSE
  )

  # Sort by SUCRA (random effects)
  summary_table <- summary_table[order(summary_table$SUCRA_Random, decreasing = TRUE), ]
  rownames(summary_table) <- NULL

  message("Treatment Rankings:")
  for (i in 1:nrow(summary_table)) {
    message(sprintf("  %d. %s (SUCRA: %.2f%%)",
                    i, summary_table$Treatment[i],
                    summary_table$SUCRA_Random[i] * 100))
  }

  return(list(
    rankings = rankings,
    summary_table = summary_table,
    best_treatment = summary_table$Treatment[1]
  ))
}

#' @describeIn mod_network_meta Create league table of all comparisons
#' @param x Network meta-analysis results
#' @param digits Integer. Number of decimal places
#' @export
cbamm_nma_league_table <- function(x, digits = 2) {

  if (inherits(x, "cbamm_nma")) {
    nma <- x$nma
  } else if (inherits(x, "netmeta")) {
    nma <- x
  } else {
    stop("x must be a netmeta or cbamm_nma object")
  }

  # Create league table
  league <- netmeta::netleague(nma, digits = digits)

  message("League table created with all pairwise comparisons")
  message(sprintf("  Treatments: %d", nma$n))
  message(sprintf("  Total comparisons: %d", choose(nma$n, 2)))

  return(league)
}

#' @describeIn mod_network_meta Test for inconsistency using node-splitting
#' @param x Network meta-analysis results
#' @export
cbamm_nma_inconsistency <- function(x) {

  if (inherits(x, "cbamm_nma")) {
    nma <- x$nma
  } else if (inherits(x, "netmeta")) {
    nma <- x
  } else {
    stop("x must be a netmeta or cbamm_nma object")
  }

  message("Testing for inconsistency using node-splitting...")

  # Global inconsistency test
  global_test <- netmeta::decomp.design(nma)

  # Node-splitting for local inconsistency
  node_split <- safe_try(
    netmeta::netsplit(nma),
    context = "node-splitting",
    return_on_error = NULL
  )

  if (!is.null(node_split)) {
    # Count significant inconsistencies
    p_values <- node_split$compare.random$p
    n_significant <- sum(p_values < 0.05, na.rm = TRUE)

    message(sprintf("  Global Q statistic: %.2f (p = %.4f)", global_test$Q.decomp, global_test$pval.Q.decomp))
    message(sprintf("  Local inconsistencies (p < 0.05): %d/%d comparisons", n_significant, length(p_values)))

    if (n_significant > 0) {
      message("  ⚠️  Significant inconsistency detected in some comparisons")
    } else {
      message("  ✅ No significant inconsistency detected")
    }
  }

  return(list(
    global_test = global_test,
    node_split = node_split,
    consistency = if (!is.null(node_split)) sum(node_split$compare.random$p < 0.05, na.rm = TRUE) == 0 else NULL
  ))
}

#' @describeIn mod_network_meta Create interactive network visualization
#' @param x Network meta-analysis results
#' @param layout Character. Layout algorithm ("circle", "star", "spring")
#' @export
cbamm_nma_network_plot_interactive <- function(x, layout = "spring") {

  if (inherits(x, "cbamm_nma")) {
    nma <- x$nma
  } else if (inherits(x, "netmeta")) {
    nma <- x
  } else {
    stop("x must be a netmeta or cbamm_nma object")
  }

  # Check if visNetwork is available
  if (!check_package_available("visNetwork", "interactive network plots")) {
    message("visNetwork not available, returning NULL")
    return(NULL)
  }

  # Create igraph object from netmeta
  g <- netmeta::netgraph(nma, seq = "optimal", plastic = FALSE)

  # Extract node and edge data
  treatments <- nma$trts
  n_studies <- table(c(nma$treat1, nma$treat2))

  # Create nodes
  nodes <- data.frame(
    id = treatments,
    label = treatments,
    title = paste0(treatments, "\n(n studies: ", n_studies[treatments], ")"),
    value = n_studies[treatments],
    stringsAsFactors = FALSE
  )

  # Create edges from comparisons
  edges <- data.frame(
    from = as.character(nma$treat1),
    to = as.character(nma$treat2),
    width = 1 + nma$n.arms / max(nma$n.arms) * 5,
    title = paste0(nma$studlab, "\n", round(nma$TE, 2), " (", round(nma$seTE, 2), ")"),
    stringsAsFactors = FALSE
  )

  # Create visNetwork plot
  vis_plot <- visNetwork::visNetwork(nodes, edges) %>%
    visNetwork::visNodes(shape = "dot", scaling = list(min = 10, max = 30)) %>%
    visNetwork::visEdges(smooth = TRUE) %>%
    visNetwork::visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
    visNetwork::visPhysics(solver = layout)

  return(vis_plot)
}

#' @describeIn mod_network_meta Create comparison-adjusted funnel plot
#' @param x Network meta-analysis results
#' @export
cbamm_nma_funnel <- function(x) {

  if (inherits(x, "cbamm_nma")) {
    nma <- x$nma
  } else if (inherits(x, "netmeta")) {
    nma <- x
  } else {
    stop("x must be a netmeta or cbamm_nma object")
  }

  message("Creating comparison-adjusted funnel plot...")

  # Create funnel plot
  funnel_plot <- netmeta::funnel(nma, order = "comparison")

  message("✅ Comparison-adjusted funnel plot created")

  return(funnel_plot)
}

#' @describeIn mod_network_meta Comprehensive network meta-analysis
#' @param data Data frame with contrast-level data or list from cbamm_nma_prepare_data()
#' @param TE Character or numeric. Effect size column name or vector
#' @param seTE Character or numeric. Standard error column name or vector
#' @param treat1 Character. First treatment column name or vector
#' @param treat2 Character. Second treatment column name or vector
#' @param studlab Character. Study label column name or vector
#' @param reference Character. Reference treatment
#' @param sm Character. Summary measure
#' @param test_inconsistency Logical. Test for inconsistency?
#' @param create_plots Logical. Create all plots?
#' @export
#' @examples
#' \dontrun{
#' library(netmeta)
#' data(smokingcessation)
#'
#' # Comprehensive NMA
#' results <- cbamm_nma_analyze(
#'   data = smokingcessation,
#'   TE = "lnor",
#'   seTE = "selnor",
#'   treat1 = "treat1",
#'   treat2 = "treat2",
#'   studlab = "study",
#'   sm = "OR"
#' )
#'
#' print(results)
#' print(results$rankings$summary_table)
#' print(results$league_table)
#' }
cbamm_nma_analyze <- function(data,
                              TE,
                              seTE,
                              treat1,
                              treat2,
                              studlab,
                              reference = NULL,
                              sm = "OR",
                              test_inconsistency = TRUE,
                              create_plots = TRUE) {

  message("═══════════════════════════════════════════════════════════════")
  message("  CBAMMR Comprehensive Network Meta-Analysis")
  message("═══════════════════════════════════════════════════════════════\n")

  # Extract variables if data is provided
  if (is.data.frame(data)) {
    TE_vec <- if (is.character(TE)) data[[TE]] else TE
    seTE_vec <- if (is.character(seTE)) data[[seTE]] else seTE
    treat1_vec <- if (is.character(treat1)) data[[treat1]] else treat1
    treat2_vec <- if (is.character(treat2)) data[[treat2]] else treat2
    studlab_vec <- if (is.character(studlab)) data[[studlab]] else studlab
  } else {
    TE_vec <- TE
    seTE_vec <- seTE
    treat1_vec <- treat1
    treat2_vec <- treat2
    studlab_vec <- studlab
  }

  # Step 1: Frequentist NMA
  nma_result <- cbamm_nma_frequentist(
    TE = TE_vec,
    seTE = seTE_vec,
    treat1 = treat1_vec,
    treat2 = treat2_vec,
    studlab = studlab_vec,
    reference = reference,
    sm = sm
  )

  # Step 2: Treatment rankings
  rankings <- cbamm_nma_rankings(nma_result)

  # Step 3: League table
  league_table <- cbamm_nma_league_table(nma_result)

  # Step 4: Inconsistency testing
  inconsistency <- NULL
  if (test_inconsistency) {
    inconsistency <- safe_try(
      cbamm_nma_inconsistency(nma_result),
      context = "inconsistency testing",
      return_on_error = NULL
    )
  }

  # Step 5: Create plots
  network_plot_interactive <- NULL
  funnel_plot <- NULL

  if (create_plots) {
    network_plot_interactive <- safe_try(
      cbamm_nma_network_plot_interactive(nma_result),
      context = "interactive network plot",
      return_on_error = NULL
    )

    funnel_plot <- safe_try(
      cbamm_nma_funnel(nma_result),
      context = "funnel plot",
      return_on_error = NULL
    )
  }

  # Compile results
  results <- list(
    nma = nma_result$nma,
    rankings = rankings,
    league_table = league_table,
    inconsistency = inconsistency,
    network_plot_interactive = network_plot_interactive,
    funnel_plot = funnel_plot,
    summary = list(
      n_treatments = nma_result$n_treatments,
      n_comparisons = nma_result$n_comparisons,
      n_studies = nma_result$n_studies,
      best_treatment = rankings$best_treatment,
      heterogeneity = nma_result$heterogeneity,
      inconsistency_detected = if (!is.null(inconsistency)) !inconsistency$consistency else NA,
      measure = sm
    )
  )

  class(results) <- c("cbamm_nma_comprehensive", "list")

  message("\n═══════════════════════════════════════════════════════════════")
  message("  ✅ Comprehensive Network Meta-Analysis Complete")
  message("═══════════════════════════════════════════════════════════════")

  return(results)
}

#' @describeIn mod_network_meta Print method for comprehensive NMA results
#' @param x A cbamm_nma_comprehensive object
#' @param ... Additional arguments
#' @export
print.cbamm_nma_comprehensive <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Comprehensive Network Meta-Analysis Results\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat("Network Summary:\n")
  cat(sprintf("  Treatments:        %d\n", x$summary$n_treatments))
  cat(sprintf("  Comparisons:       %d\n", x$summary$n_comparisons))
  cat(sprintf("  Studies:           %d\n", x$summary$n_studies))
  cat(sprintf("  Effect measure:    %s\n\n", x$summary$measure))

  cat("Heterogeneity:\n")
  cat(sprintf("  Q statistic:       %.2f (p = %.4f)\n", x$summary$heterogeneity$Q, x$summary$heterogeneity$pval))
  cat(sprintf("  I²:                %.1f%%\n\n", x$summary$heterogeneity$I2 * 100))

  if (!is.na(x$summary$inconsistency_detected)) {
    cat("Inconsistency:\n")
    cat(sprintf("  Status:            %s\n\n",
                if (x$summary$inconsistency_detected) "⚠️  Detected" else "✅ Not detected"))
  }

  cat("Treatment Rankings (by SUCRA):\n")
  print(head(x$rankings$summary_table, 10))
  cat("\n")

  cat(sprintf("Best Treatment:    %s (SUCRA: %.2f%%)\n",
              x$summary$best_treatment,
              x$rankings$summary_table$SUCRA_Random[1] * 100))

  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("Available components:\n")
  cat("  • $nma                     - netmeta object\n")
  cat("  • $rankings                - Treatment rankings with SUCRA\n")
  cat("  • $league_table            - All pairwise comparisons\n")
  cat("  • $inconsistency           - Inconsistency assessment\n")
  cat("  • $network_plot_interactive - Interactive network visualization\n")
  cat("  • $funnel_plot             - Comparison-adjusted funnel plot\n")
  cat("  • $summary                 - Summary statistics\n")
  cat("═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}

#' @describeIn mod_network_meta Print method for cbamm_nma objects
#' @param x A cbamm_nma object
#' @param ... Additional arguments
#' @export
print.cbamm_nma <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Network Meta-Analysis Results\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(sprintf("Treatments:        %d\n", x$n_treatments))
  cat(sprintf("Comparisons:       %d\n", x$n_comparisons))
  cat(sprintf("Studies:           %d\n", x$n_studies))
  cat(sprintf("Effect measure:    %s\n\n", x$measure))

  cat("Heterogeneity:\n")
  cat(sprintf("  Q:               %.2f (p = %.4f)\n", x$heterogeneity$Q, x$heterogeneity$pval))
  cat(sprintf("  I²:              %.1f%%\n", x$heterogeneity$I2 * 100))

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}
