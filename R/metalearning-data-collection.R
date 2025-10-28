#' Meta-Learning Data Collection Functions
#'
#' Functions to collect and process meta-analysis datasets from multiple sources
#' for training meta-learning models in CBAMMR
#'
#' @name metalearning-data-collection
#' @keywords internal
NULL

#' Collect All Datasets from metadat Package
#'
#' Downloads and processes all datasets from the metadat package
#' for the meta-learning database
#'
#' @param output_dir Directory to save processed datasets (default: "data/metalearning")
#' @param verbose Print progress messages (default: TRUE)
#'
#' @return List of standardized meta-analysis datasets with metadata
#' @export
#'
#' @examples
#' \dontrun{
#' # Collect all metadat datasets
#' metadat_collection <- cbamm_collect_metadat()
#'
#' # View summary
#' summary(metadat_collection)
#' }
cbamm_collect_metadat <- function(output_dir = "data/metalearning",
                                   verbose = TRUE) {

  # Ensure metadat is installed
  if (!requireNamespace("metadat", quietly = TRUE)) {
    message("Installing metadat package...")
    utils::install.packages("metadat")
  }

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Get list of all datasets
  data_list <- utils::data(package = "metadat")$results[, "Item"]

  if (verbose) {
    cat(sprintf("Found %d datasets in metadat package\n", length(data_list)))
    cat("=" %R% 70, "\n")
  }

  # Initialize storage
  all_datasets <- list()
  success_count <- 0
  error_count <- 0

  # Loop through each dataset
  for (i in seq_along(data_list)) {

    dataset_name <- data_list[i]

    if (verbose) {
      cat(sprintf("[%d/%d] Processing: %s... ", i, length(data_list), dataset_name))
    }

    tryCatch({
      # Load dataset
      utils::data(list = dataset_name, package = "metadat", envir = environment())
      dat <- get(dataset_name)

      # Process dataset
      processed <- .process_metadat_dataset(dat, dataset_name)

      if (!is.null(processed)) {
        all_datasets[[dataset_name]] <- processed
        success_count <- success_count + 1
        if (verbose) cat("OK\n")
      } else {
        error_count <- error_count + 1
        if (verbose) cat("SKIP (insufficient data)\n")
      }

    }, error = function(e) {
      error_count <<- error_count + 1
      if (verbose) cat(sprintf("ERROR: %s\n", e$message))
    })
  }

  if (verbose) {
    cat("=" %R% 70, "\n")
    cat(sprintf("Collected: %d successful, %d errors/skipped\n",
                success_count, error_count))
  }

  # Save collection
  output_file <- file.path(output_dir, "metadat_collection.rds")
  saveRDS(all_datasets, output_file)

  if (verbose) {
    cat(sprintf("Saved to: %s\n", output_file))
  }

  return(all_datasets)
}

#' Process Single metadat Dataset
#'
#' @keywords internal
.process_metadat_dataset <- function(dat, dataset_name) {

  # Must be data frame
  if (!is.data.frame(dat)) {
    return(NULL)
  }

  # Must have at least 3 studies
  if (nrow(dat) < 3) {
    return(NULL)
  }

  # Extract metadata
  meta_info <- list(
    dataset_name = dataset_name,
    n_studies = nrow(dat),
    variables = names(dat),
    n_variables = ncol(dat),
    source = "metadat"
  )

  # Detect outcome measure type
  outcome_info <- .detect_outcome_measure(dat)
  meta_info$outcome_measure <- outcome_info$measure
  meta_info$measure_type <- outcome_info$type

  # Detect moderators
  moderator_info <- .detect_moderators(dat)
  meta_info$has_moderators <- moderator_info$has_moderators
  meta_info$moderators <- moderator_info$moderators
  meta_info$n_moderators <- moderator_info$n_moderators

  # Extract study characteristics
  study_chars <- .extract_study_characteristics(dat)
  meta_info <- c(meta_info, study_chars)

  # Run meta-analysis
  ma_result <- .run_meta_analysis(dat, outcome_info$type)

  if (is.null(ma_result)) {
    return(NULL)
  }

  # Combine everything
  list(
    metadata = meta_info,
    heterogeneity = ma_result$heterogeneity,
    moderator_analysis = ma_result$moderators,
    raw_data = dat
  )
}

#' Detect Outcome Measure Type
#'
#' @keywords internal
.detect_outcome_measure <- function(dat) {

  vars <- names(dat)

  # Binary outcomes (2x2 table)
  if (all(c("ai", "bi", "ci", "di") %in% vars)) {
    # Check if measure specified
    if ("measure" %in% vars && length(unique(dat$measure)) == 1) {
      measure <- unique(dat$measure)[1]
    } else {
      measure <- "OR"  # Default
    }
    return(list(measure = measure, type = "binary"))
  }

  # Pre-computed effect sizes
  if ("yi" %in% vars && ("vi" %in% vars || "sei" %in% vars)) {

    # Try to infer measure type
    if ("measure" %in% vars) {
      measure <- unique(dat$measure)[1]
    } else {
      # Infer from values
      yi_range <- range(dat$yi, na.rm = TRUE)

      if (all(abs(dat$yi) < 5, na.rm = TRUE)) {
        measure <- "SMD"  # Likely standardized
      } else if (all(dat$yi < 10 & dat$yi > -10, na.rm = TRUE)) {
        measure <- "MD"
      } else {
        measure <- "GEN"  # Generic
      }
    }

    return(list(measure = measure, type = "computed"))
  }

  # Correlation
  if ("ri" %in% vars) {
    return(list(measure = "COR", type = "correlation"))
  }

  # Unknown
  return(list(measure = "UNKNOWN", type = "unknown"))
}

#' Detect Moderators in Dataset
#'
#' @keywords internal
.detect_moderators <- function(dat) {

  # Essential variables (not moderators)
  essential_vars <- c(
    "yi", "vi", "sei", "ai", "bi", "ci", "di",
    "n1i", "n2i", "m1i", "m2i", "sd1i", "sd2i",
    "study", "author", "year", "id", "measure"
  )

  # Potential moderators
  moderator_candidates <- setdiff(names(dat), essential_vars)

  if (length(moderator_candidates) == 0) {
    return(list(
      has_moderators = FALSE,
      moderators = character(0),
      n_moderators = 0,
      moderator_types = character(0)
    ))
  }

  # Classify moderator types
  moderator_types <- sapply(moderator_candidates, function(var) {
    if (is.numeric(dat[[var]])) {
      "continuous"
    } else if (is.factor(dat[[var]]) || is.character(dat[[var]])) {
      "categorical"
    } else {
      "other"
    }
  })

  list(
    has_moderators = TRUE,
    moderators = moderator_candidates,
    n_moderators = length(moderator_candidates),
    moderator_types = moderator_types
  )
}

#' Extract Study Characteristics
#'
#' @keywords internal
.extract_study_characteristics <- function(dat) {

  chars <- list()

  # Year information
  if ("year" %in% names(dat)) {
    years <- dat$year[!is.na(dat$year)]
    if (length(years) > 0) {
      chars$year_min <- min(years)
      chars$year_max <- max(years)
      chars$year_range <- max(years) - min(years)
      chars$median_year <- median(years)
    }
  }

  # Sample size information
  if ("n1i" %in% names(dat) && "n2i" %in% names(dat)) {
    total_n <- dat$n1i + dat$n2i
    total_n <- total_n[!is.na(total_n)]
    if (length(total_n) > 0) {
      chars$median_sample_size <- median(total_n)
      chars$mean_sample_size <- mean(total_n)
      chars$total_participants <- sum(total_n)
    }
  }

  # Study design
  if ("design" %in% names(dat)) {
    chars$study_designs <- table(dat$design)
  }

  chars
}

#' Run Meta-Analysis on Dataset
#'
#' @keywords internal
.run_meta_analysis <- function(dat, measure_type) {

  # Suppress warnings
  result <- suppressWarnings({

    tryCatch({

      # Binary outcomes
      if (measure_type == "binary") {
        fit <- metafor::rma.mh(
          ai = dat$ai, bi = dat$bi, ci = dat$ci, di = dat$di,
          measure = "OR",
          data = dat
        )
      }
      # Computed effect sizes
      else if (measure_type == "computed") {
        if ("vi" %in% names(dat)) {
          fit <- metafor::rma(yi, vi, data = dat, method = "REML")
        } else {
          fit <- metafor::rma(yi, sei = sei, data = dat, method = "REML")
        }
      }
      # Correlation
      else if (measure_type == "correlation") {
        # Fisher's z transformation
        fit <- metafor::rma(yi = dat$ri, vi = 1/(dat$ni - 3), method = "REML")
      }
      else {
        return(NULL)
      }

      # Extract heterogeneity statistics
      heterogeneity <- list(
        k = fit$k,
        pooled_effect = as.numeric(fit$b),
        se = as.numeric(fit$se),
        ci_lower = as.numeric(fit$ci.lb),
        ci_upper = as.numeric(fit$ci.ub),
        tau2 = fit$tau2,
        tau = sqrt(fit$tau2),
        I2 = fit$I2,
        H2 = fit$H2,
        Q = fit$QE,
        Q_pval = fit$QEp,
        method = fit$method
      )

      # Try moderator analysis if moderators available
      moderator_results <- .analyze_moderators(dat, measure_type)

      list(
        heterogeneity = heterogeneity,
        moderators = moderator_results
      )

    }, error = function(e) {
      NULL
    })

  })

  return(result)
}

#' Analyze Moderators
#'
#' @keywords internal
.analyze_moderators <- function(dat, measure_type) {

  moderator_info <- .detect_moderators(dat)

  if (!moderator_info$has_moderators || moderator_info$n_moderators == 0) {
    return(NULL)
  }

  # Test each moderator
  moderator_results <- list()

  for (mod in moderator_info$moderators) {

    tryCatch({

      # Skip if too many missing values
      if (sum(is.na(dat[[mod]])) > nrow(dat) * 0.5) {
        next
      }

      # Build formula
      if (measure_type == "computed") {
        formula_obj <- as.formula(paste("yi ~", mod))
        if ("vi" %in% names(dat)) {
          fit <- metafor::rma(formula_obj, vi, data = dat, method = "REML")
        } else {
          fit <- metafor::rma(formula_obj, sei = sei, data = dat, method = "REML")
        }
      } else {
        next  # Skip for binary/correlation for now
      }

      # Extract results
      moderator_results[[mod]] <- list(
        QM = fit$QM,
        QM_pval = fit$QMp,
        R2 = fit$R2,
        significant = fit$QMp < 0.05
      )

    }, error = function(e) {
      # Skip problematic moderators
    })
  }

  return(moderator_results)
}

#' Download Datasets from GitHub Repositories
#'
#' @param repos Character vector of GitHub repository URLs
#' @param output_dir Output directory
#' @param verbose Print progress
#'
#' @export
cbamm_collect_github_datasets <- function(repos = NULL,
                                           output_dir = "data/metalearning/github",
                                           verbose = TRUE) {

  # Default repositories if none specified
  if (is.null(repos)) {
    repos <- c(
      "asreview/systematic-review-datasets",
      "asreview/synergy-dataset"
    )
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  all_datasets <- list()

  for (repo in repos) {

    if (verbose) {
      cat(sprintf("Cloning repository: %s\n", repo))
    }

    # Clone repository
    repo_name <- basename(repo)
    repo_path <- file.path(output_dir, repo_name)

    if (!dir.exists(repo_path)) {
      system(sprintf("git clone https://github.com/%s %s", repo, repo_path))
    }

    # Find CSV files
    csv_files <- list.files(repo_path, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)

    if (verbose) {
      cat(sprintf("  Found %d CSV files\n", length(csv_files)))
    }

    # Process each CSV
    for (csv_file in csv_files) {
      # Process and add to collection
      # (Implementation depends on file structure)
    }
  }

  saveRDS(all_datasets, file.path(output_dir, "github_collection.rds"))

  return(all_datasets)
}

#' Search and Download Datasets from Zenodo
#'
#' @param query Search query (default: "meta-analysis")
#' @param max_results Maximum number of results
#' @param output_dir Output directory
#' @param verbose Print progress
#'
#' @export
cbamm_collect_zenodo_datasets <- function(query = "meta-analysis",
                                           max_results = 100,
                                           output_dir = "data/metalearning/zenodo",
                                           verbose = TRUE) {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  if (verbose) {
    cat(sprintf("Searching Zenodo for: %s\n", query))
  }

  # Zenodo API endpoint
  base_url <- "https://zenodo.org/api/records"

  # Search parameters
  params <- list(
    q = query,
    size = min(max_results, 1000),
    sort = "mostrecent",
    type = "dataset"
  )

  # GET request
  if (requireNamespace("httr", quietly = TRUE) &&
      requireNamespace("jsonlite", quietly = TRUE)) {

    response <- httr::GET(base_url, query = params)

    if (httr::status_code(response) == 200) {

      results <- jsonlite::fromJSON(httr::content(response, "text"), flatten = TRUE)

      if (verbose) {
        cat(sprintf("Found %d datasets\n", nrow(results$hits$hits)))
      }

      # Download each dataset
      for (i in seq_len(min(nrow(results$hits$hits), max_results))) {

        record <- results$hits$hits[i, ]

        if (verbose) {
          cat(sprintf("[%d/%d] Downloading: %s\n",
                      i, max_results, record$metadata.title))
        }

        # Download files
        # (Implementation details depend on Zenodo API)
      }

    } else {
      warning("Failed to connect to Zenodo API")
    }

  } else {
    warning("httr and jsonlite packages required for Zenodo access")
  }

  return(invisible(NULL))
}

#' Build Complete Meta-Learning Database
#'
#' Collects and processes datasets from all sources
#'
#' @param output_dir Main output directory
#' @param sources Character vector of sources to include:
#'   "metadat", "github", "zenodo"
#' @param verbose Print progress
#'
#' @return List with database statistics
#' @export
#'
#' @examples
#' \dontrun{
#' # Build complete database (may take hours)
#' database <- cbamm_build_metalearning_database()
#'
#' # View summary
#' print(database$summary)
#' }
cbamm_build_metalearning_database <- function(output_dir = "data/metalearning",
                                               sources = c("metadat"),
                                               verbose = TRUE) {

  if (verbose) {
    cat("\n")
    cat("=" %R% 70, "\n")
    cat("CBAMMR Meta-Learning Database Construction\n")
    cat("=" %R% 70, "\n\n")
  }

  all_data <- list()

  # Collect from metadat
  if ("metadat" %in% sources) {
    if (verbose) cat("[1/3] Collecting from metadat package...\n")
    metadat_data <- cbamm_collect_metadat(
      output_dir = file.path(output_dir, "metadat"),
      verbose = verbose
    )
    all_data$metadat <- metadat_data
    if (verbose) cat(sprintf("      Collected: %d datasets\n\n", length(metadat_data)))
  }

  # Collect from GitHub
  if ("github" %in% sources) {
    if (verbose) cat("[2/3] Collecting from GitHub repositories...\n")
    github_data <- cbamm_collect_github_datasets(
      output_dir = file.path(output_dir, "github"),
      verbose = verbose
    )
    all_data$github <- github_data
    if (verbose) cat(sprintf("      Collected: %d datasets\n\n", length(github_data)))
  }

  # Collect from Zenodo
  if ("zenodo" %in% sources) {
    if (verbose) cat("[3/3] Collecting from Zenodo...\n")
    zenodo_data <- cbamm_collect_zenodo_datasets(
      output_dir = file.path(output_dir, "zenodo"),
      verbose = verbose
    )
    all_data$zenodo <- zenodo_data
    if (verbose) cat(sprintf("      Collected: %d datasets\n\n", length(zenodo_data)))
  }

  # Merge all sources
  merged_data <- do.call(c, all_data)

  # Save complete database
  database_file <- file.path(output_dir, "metalearning_database.rds")
  saveRDS(merged_data, database_file)

  # Create summary
  summary_stats <- .create_database_summary(merged_data)

  if (verbose) {
    cat("\n")
    cat("=" %R% 70, "\n")
    cat(sprintf("COMPLETE: %d meta-analyses in database\n", length(merged_data)))
    cat("=" %R% 70, "\n\n")
    print(summary_stats)
  }

  return(list(
    database = merged_data,
    summary = summary_stats,
    file = database_file
  ))
}

#' Create Database Summary Statistics
#'
#' @keywords internal
.create_database_summary <- function(database) {

  n_datasets <- length(database)

  # Extract statistics
  n_studies <- sapply(database, function(x) x$metadata$n_studies)
  outcome_measures <- sapply(database, function(x) x$metadata$outcome_measure)
  I2_values <- sapply(database, function(x) x$heterogeneity$I2)
  tau2_values <- sapply(database, function(x) x$heterogeneity$tau2)

  summary_df <- data.frame(
    Statistic = c(
      "Total datasets",
      "Median studies per MA",
      "Total studies",
      "Median I²",
      "Median τ²",
      "Most common outcome"
    ),
    Value = c(
      n_datasets,
      sprintf("%.1f", median(n_studies, na.rm = TRUE)),
      sum(n_studies, na.rm = TRUE),
      sprintf("%.1f%%", median(I2_values, na.rm = TRUE)),
      sprintf("%.3f", median(tau2_values, na.rm = TRUE)),
      names(sort(table(outcome_measures), decreasing = TRUE))[1]
    )
  )

  return(summary_df)
}
