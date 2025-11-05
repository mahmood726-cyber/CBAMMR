#' Advanced Risk of Bias Assessment Module
#'
#' Comprehensive multi-tool risk of bias assessment supporting:
#' - ROB 2 (RCTs)
#' - ROBINS-I (Non-randomized interventions)
#' - QUADAS-2 (Diagnostic test accuracy)
#' - ROB 1 (Original Cochrane tool)
#' - NOS (Newcastle-Ottawa Scale for observational studies)
#'
#' Features:
#' - Traffic light plots (study-level visualization)
#' - Summary stacked bar charts with percentages
#' - Frequency distribution analysis
#' - K-means clustering analysis
#' - Export functionality (CSV, Excel, PNG, PDF)
#' - Interactive data tables
#' - Bootstrap validation support
#'
#' @name mod_rob_assessment
#' @rdname mod_rob_assessment
#'
#' @import shiny
#' @import ggplot2
#' @import DT
#' @import dplyr
#' @import tidyr
#' @import scales
#' @import plotly
NULL

#' @describeIn mod_rob_assessment Get domain columns for specific ROB tool
#' @param data Data frame containing ROB assessments
#' @param tool Character. One of "ROB2", "ROBINS-I", "QUADAS-2", "ROB1", "NOS"
#' @export
get_rob_domain_cols <- function(data, tool) {
  if (tool == "ROB2") {
    return(intersect(names(data), c("Randomization", "Deviations", "Missing", "Measurement", "Selection")))
  } else if (tool == "ROBINS-I") {
    return(intersect(names(data), c("Confounding", "Selection", "Classification", "Deviations", "Missing", "Measurement", "Reporting")))
  } else if (tool == "QUADAS-2") {
    return(intersect(names(data), c("PatientSelection", "IndexTest", "ReferenceStandard", "FlowTiming")))
  } else if (tool == "ROB1") {
    return(intersect(names(data), c("RandomSequence", "AllocationConcealment", "BlindingParticipants", "BlindingOutcome", "IncompleteOutcome", "SelectiveReporting")))
  } else if (tool == "NOS") {
    return(intersect(names(data), c("Selection", "Comparability", "Outcome")))
  } else {
    # Fallback for unknown tool
    return(setdiff(names(data), c("Study", "Overall", "Weight")))
  }
}

#' @describeIn mod_rob_assessment Convert categorical judgments to numeric scores
#' @param x Character vector of categorical judgments
#' @param tool Character. ROB tool name
#' @export
convert_rob_to_numeric <- function(x, tool) {
  if (tool == "ROB2") {
    ifelse(x == "Low", 1,
           ifelse(x == "Some concerns", 2,
                  ifelse(x == "High", 3, NA)))
  } else if (tool == "ROBINS-I") {
    ifelse(x == "Low", 1,
           ifelse(x == "Moderate", 2,
                  ifelse(x == "Serious", 3,
                         ifelse(x == "Critical", 4,
                                ifelse(x == "No information", 5, NA)))))
  } else if (tool == "QUADAS-2") {
    ifelse(x == "Low", 1,
           ifelse(x == "Unclear", 2,
                  ifelse(x == "High", 3, NA)))
  } else if (tool == "ROB1") {
    ifelse(x == "Low", 1,
           ifelse(x == "Unclear", 2,
                  ifelse(x == "High", 3, NA)))
  } else if (tool == "NOS") {
    ifelse(x == "Good", 1,
           ifelse(x == "Fair", 2,
                  ifelse(x == "Poor", 3, NA)))
  } else {
    NA
  }
}

#' @describeIn mod_rob_assessment Get color palette for ROB tool
#' @param tool Character. ROB tool name
#' @export
get_rob_palette <- function(tool) {
  if (tool == "ROB2") {
    c("Low" = "#66c2a5", "Some concerns" = "#fc8d62", "High" = "#8da0cb")
  } else if (tool == "ROBINS-I") {
    c("Low" = "#66c2a5", "Moderate" = "#fc8d62",
      "Serious" = "#8da0cb", "Critical" = "#e78ac3",
      "No information" = "#a6d854")
  } else if (tool == "QUADAS-2") {
    c("Low" = "#66c2a5", "High" = "#8da0cb", "Unclear" = "#fc8d62")
  } else if (tool == "ROB1") {
    c("Low" = "#66c2a5", "Unclear" = "#fc8d62", "High" = "#8da0cb")
  } else if (tool == "NOS") {
    c("Good" = "#66c2a5", "Fair" = "#fc8d62", "Poor" = "#8da0cb")
  } else {
    c("Low" = "#66c2a5", "Unclear" = "#fc8d62", "High" = "#8da0cb")
  }
}

#' @describeIn mod_rob_assessment Create summary stacked bar chart
#' @param data Data frame containing ROB assessments
#' @param tool Character. ROB tool name
#' @param overall Logical. Include overall judgment?
#' @param interactive Logical. Return interactive plotly plot?
#' @export
cbamm_rob_summary_plot <- function(data, tool, overall = FALSE, interactive = FALSE) {
  domain_cols <- get_rob_domain_cols(data, tool)

  plot_data <- data.frame()
  for (domain in domain_cols) {
    counts <- table(data[[domain]])
    percentages <- as.numeric(counts) / sum(counts)
    temp_df <- data.frame(
      Domain = domain,
      Level = names(counts),
      Percentage = percentages,
      Count = as.numeric(counts),
      stringsAsFactors = FALSE
    )
    plot_data <- rbind(plot_data, temp_df)
  }

  if (overall && "Overall" %in% names(data)) {
    counts <- table(data$Overall)
    percentages <- as.numeric(counts) / sum(counts)
    temp_df <- data.frame(
      Domain = "Overall",
      Level = names(counts),
      Percentage = percentages,
      Count = as.numeric(counts),
      stringsAsFactors = FALSE
    )
    plot_data <- rbind(plot_data, temp_df)
  }

  palette <- get_rob_palette(tool)
  plot_data$Level <- factor(plot_data$Level, levels = names(palette))

  p <- ggplot(plot_data, aes(x = Domain, y = Percentage, fill = Level,
                              text = paste0(Domain, "\n", Level, ": ",
                                          Count, " (", round(Percentage * 100, 1), "%)"))) +
    geom_bar(stat = "identity", position = "stack") +
    scale_fill_manual(values = palette, drop = FALSE) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    ) +
    labs(
      title = paste("Risk of Bias Summary -", tool),
      y = "Percentage", x = "",
      fill = "Judgment"
    ) +
    scale_y_continuous(labels = percent_format(accuracy = 1))

  if (interactive) {
    return(ggplotly(p, tooltip = "text"))
  } else {
    return(p)
  }
}

#' @describeIn mod_rob_assessment Create traffic light plot (study-level)
#' @param data Data frame containing ROB assessments with "Study" column
#' @param tool Character. ROB tool name
#' @param point_size Numeric. Size of points in plot
#' @param interactive Logical. Return interactive plotly plot?
#' @export
cbamm_rob_traffic_light <- function(data, tool, point_size = 10, interactive = FALSE) {
  domain_cols <- get_rob_domain_cols(data, tool)

  plot_data <- data.frame(
    Study = character(),
    Domain = character(),
    Judgment = character(),
    stringsAsFactors = FALSE
  )

  for (i in 1:nrow(data)) {
    for (domain in domain_cols) {
      plot_data <- rbind(plot_data, data.frame(
        Study = data$Study[i],
        Domain = domain,
        Judgment = as.character(data[i, domain]),
        stringsAsFactors = FALSE
      ))
    }
    if ("Overall" %in% names(data)) {
      plot_data <- rbind(plot_data, data.frame(
        Study = data$Study[i],
        Domain = "Overall",
        Judgment = as.character(data$Overall[i]),
        stringsAsFactors = FALSE
      ))
    }
  }

  palette <- get_rob_palette(tool)
  plot_data$Judgment <- factor(plot_data$Judgment, levels = names(palette))

  p <- ggplot(plot_data, aes(x = Domain, y = Study, color = Judgment,
                              text = paste0(Study, "\n", Domain, ": ", Judgment))) +
    geom_point(size = point_size / 5) +
    scale_color_manual(values = palette, drop = FALSE) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    ) +
    labs(
      title = paste("Risk of Bias Traffic Light -", tool),
      x = "", y = "Study",
      color = "Judgment"
    )

  if (interactive) {
    return(ggplotly(p, tooltip = "text"))
  } else {
    return(p)
  }
}

#' @describeIn mod_rob_assessment Create frequency distribution plot by domain
#' @param data Data frame containing ROB assessments
#' @param tool Character. ROB tool name
#' @export
cbamm_rob_frequency_plot <- function(data, tool) {
  domain_cols <- get_rob_domain_cols(data, tool)

  plot_data <- pivot_longer(
    data,
    cols = all_of(domain_cols),
    names_to = "Domain",
    values_to = "Judgment"
  )

  # Set factor levels based on tool
  if (tool == "ROB2") {
    lev <- c("Low", "Some concerns", "High")
  } else if (tool == "ROBINS-I") {
    lev <- c("Low", "Moderate", "Serious", "Critical", "No information")
  } else if (tool == "QUADAS-2") {
    lev <- c("Low", "High", "Unclear")
  } else if (tool == "ROB1") {
    lev <- c("Low", "Unclear", "High")
  } else if (tool == "NOS") {
    lev <- c("Good", "Fair", "Poor")
  } else {
    lev <- NULL
  }

  if (!is.null(lev)) {
    plot_data$Judgment <- factor(plot_data$Judgment, levels = lev)
  }

  palette <- get_rob_palette(tool)

  ggplot(plot_data, aes(x = Judgment, fill = Judgment)) +
    geom_bar() +
    facet_wrap(~Domain, scales = "free_y") +
    scale_fill_manual(values = palette, drop = FALSE) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    ) +
    labs(
      title = paste("Frequency Distribution by Domain -", tool),
      x = "Judgment", y = "Count",
      fill = "Judgment"
    )
}

#' @describeIn mod_rob_assessment Perform k-means clustering analysis on ROB data
#' @param data Data frame containing ROB assessments
#' @param tool Character. ROB tool name
#' @param num_clusters Integer. Number of clusters for k-means
#' @export
cbamm_rob_cluster_analysis <- function(data, tool, num_clusters = 3) {
  df <- data
  domain_cols <- get_rob_domain_cols(df, tool)

  # Convert categorical to numeric
  for (col in domain_cols) {
    df[[col]] <- convert_rob_to_numeric(df[[col]], tool)
  }

  # Remove incomplete cases
  df_complete <- df[complete.cases(df[, domain_cols]), ]

  if (nrow(df_complete) < 2) {
    warning("Insufficient complete cases for clustering")
    return(NULL)
  }

  # Perform k-means
  set.seed(123)  # For reproducibility
  km <- kmeans(df_complete[, domain_cols], centers = num_clusters, nstart = 25)
  df_complete$Cluster <- factor(km$cluster)

  # Create visualization using first two domains
  if (length(domain_cols) >= 2) {
    p <- ggplot(df_complete, aes_string(x = domain_cols[1], y = domain_cols[2],
                                        color = "Cluster", label = "Study")) +
      geom_point(size = 3) +
      geom_text(vjust = -0.5, size = 3) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.position = "bottom"
      ) +
      labs(
        title = paste("K-means Clustering (k =", num_clusters, ")"),
        subtitle = paste("Based on", tool, "assessments"),
        x = domain_cols[1], y = domain_cols[2]
      )

    return(list(
      plot = p,
      clusters = df_complete$Cluster,
      centers = km$centers,
      size = km$size,
      withinss = km$withinss,
      tot.withinss = km$tot.withinss,
      betweenss = km$betweenss
    ))
  } else {
    warning("Need at least 2 domains for visualization")
    return(NULL)
  }
}

#' @describeIn mod_rob_assessment Create summary table for export
#' @param data Data frame containing ROB assessments
#' @param tool Character. ROB tool name
#' @param overall Logical. Include overall judgment?
#' @export
cbamm_rob_summary_table <- function(data, tool, overall = FALSE) {
  domain_cols <- get_rob_domain_cols(data, tool)

  summary_list <- lapply(domain_cols, function(domain) {
    cnts <- table(data[[domain]])
    pct <- round(100 * as.numeric(cnts) / sum(cnts), 1)
    data.frame(
      Domain = domain,
      Level = names(cnts),
      Count = as.numeric(cnts),
      Percentage = pct,
      stringsAsFactors = FALSE
    )
  })

  summary_df <- do.call(rbind, summary_list)

  if (overall && "Overall" %in% names(data)) {
    cnts <- table(data$Overall)
    pct <- round(100 * as.numeric(cnts) / sum(cnts), 1)
    overall_df <- data.frame(
      Domain = "Overall",
      Level = names(cnts),
      Count = as.numeric(cnts),
      Percentage = pct,
      stringsAsFactors = FALSE
    )
    summary_df <- rbind(summary_df, overall_df)
  }

  summary_df
}

#' @describeIn mod_rob_assessment Comprehensive ROB analysis
#' @param data Data frame containing ROB assessments with "Study" column
#' @param tool Character. One of "ROB2", "ROBINS-I", "QUADAS-2", "ROB1", "NOS"
#' @param include_overall Logical. Include overall judgment in plots?
#' @param interactive Logical. Generate interactive plots?
#' @param cluster_analysis Logical. Perform k-means clustering?
#' @param num_clusters Integer. Number of clusters if clustering requested
#' @export
#' @examples
#' \dontrun{
#' # Example ROB2 data
#' rob_data <- data.frame(
#'   Study = paste0("Study ", 1:10),
#'   Randomization = sample(c("Low", "Some concerns", "High"), 10, replace = TRUE),
#'   Deviations = sample(c("Low", "Some concerns", "High"), 10, replace = TRUE),
#'   Missing = sample(c("Low", "Some concerns", "High"), 10, replace = TRUE),
#'   Measurement = sample(c("Low", "Some concerns", "High"), 10, replace = TRUE),
#'   Selection = sample(c("Low", "Some concerns", "High"), 10, replace = TRUE),
#'   Overall = sample(c("Low", "Some concerns", "High"), 10, replace = TRUE)
#' )
#'
#' # Run comprehensive analysis
#' results <- cbamm_rob_analyze(rob_data, tool = "ROB2", interactive = TRUE)
#'
#' # View plots
#' print(results$summary_plot)
#' print(results$traffic_light)
#' print(results$frequency_plot)
#'
#' # View summary table
#' print(results$summary_table)
#' }
cbamm_rob_analyze <- function(data,
                              tool = c("ROB2", "ROBINS-I", "QUADAS-2", "ROB1", "NOS"),
                              include_overall = TRUE,
                              interactive = FALSE,
                              cluster_analysis = TRUE,
                              num_clusters = 3) {

  tool <- match.arg(tool)

  # Validate data
  if (!"Study" %in% names(data)) {
    stop("Data must contain a 'Study' column")
  }

  domain_cols <- get_rob_domain_cols(data, tool)
  if (length(domain_cols) == 0) {
    stop(paste("No valid domain columns found for", tool))
  }

  message(sprintf("Performing comprehensive ROB analysis with %s", tool))
  message(sprintf("  Studies: %d", nrow(data)))
  message(sprintf("  Domains: %d (%s)", length(domain_cols), paste(domain_cols, collapse = ", ")))

  # Generate all plots
  summary_plot <- cbamm_rob_summary_plot(data, tool, include_overall, interactive)
  traffic_light <- cbamm_rob_traffic_light(data, tool, interactive = interactive)
  frequency_plot <- cbamm_rob_frequency_plot(data, tool)

  # Generate summary table
  summary_table <- cbamm_rob_summary_table(data, tool, include_overall)

  # Optional clustering
  cluster_results <- NULL
  if (cluster_analysis) {
    cluster_results <- safe_try(
      cbamm_rob_cluster_analysis(data, tool, num_clusters),
      context = "k-means clustering",
      return_on_error = NULL
    )
  }

  # Compile results
  results <- list(
    tool = tool,
    n_studies = nrow(data),
    domains = domain_cols,
    summary_plot = summary_plot,
    traffic_light = traffic_light,
    frequency_plot = frequency_plot,
    summary_table = summary_table,
    cluster_results = cluster_results,
    data = data
  )

  class(results) <- c("cbamm_rob", "list")

  message("✅ ROB analysis complete")

  return(results)
}

#' @describeIn mod_rob_assessment Print method for cbamm_rob objects
#' @param x A cbamm_rob object
#' @param ... Additional arguments
#' @export
print.cbamm_rob <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat(sprintf("  CBAMMR Risk of Bias Analysis (%s)\n", x$tool))
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(sprintf("Studies analyzed:  %d\n", x$n_studies))
  cat(sprintf("Domains assessed:  %d\n", length(x$domains)))
  cat(sprintf("Domains:           %s\n\n", paste(x$domains, collapse = ", ")))

  cat("Summary Statistics:\n")
  print(x$summary_table)
  cat("\n")

  if (!is.null(x$cluster_results)) {
    cat(sprintf("Clustering:        %d clusters identified\n", length(unique(x$cluster_results$clusters))))
    cat(sprintf("Between SS:        %.2f\n", x$cluster_results$betweenss))
    cat(sprintf("Total within SS:   %.2f\n", x$cluster_results$tot.withinss))
    cat(sprintf("Cluster sizes:     %s\n", paste(x$cluster_results$size, collapse = ", ")))
  }

  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("Available components:\n")
  cat("  • $summary_plot      - Stacked bar chart\n")
  cat("  • $traffic_light     - Study-level visualization\n")
  cat("  • $frequency_plot    - Frequency by domain\n")
  cat("  • $summary_table     - Summary statistics table\n")
  cat("  • $cluster_results   - K-means clustering (if performed)\n")
  cat("  • $data              - Original data\n")
  cat("═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}
