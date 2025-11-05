# Input Validation Helper Functions
# Centralized validation logic to improve error messages and reduce duplication

#' Validate Meta-Analysis Input Data
#'
#' Comprehensive validation of effect sizes and variances for meta-analysis
#'
#' @param yi Numeric vector of effect sizes
#' @param vi Numeric vector of variances
#' @param sei Optional numeric vector of standard errors
#' @param allow_na Logical; allow NA values?
#'
#' @return Invisible TRUE if validation passes, stops with error otherwise
#' @keywords internal
validate_meta_inputs <- function(yi, vi = NULL, sei = NULL, allow_na = FALSE) {
  # Check yi
  if (missing(yi)) {
    stop("Argument 'yi' is required")
  }

  if (!is.numeric(yi)) {
    stop("'yi' must be a numeric vector")
  }

  if (length(yi) < MIN_STUDIES_META) {
    stop(sprintf(ERROR_MSG_INSUFFICIENT_DATA, MIN_STUDIES_META))
  }

  if (!allow_na && any(is.na(yi))) {
    stop("'yi' contains NA values. Set allow_na=TRUE if this is intentional")
  }

  if (!allow_na && !all(is.finite(yi))) {
    stop("'yi' contains non-finite values (Inf, -Inf, or NaN)")
  }

  # Check vi or sei
  if (!is.null(vi)) {
    if (!is.numeric(vi)) {
      stop("'vi' must be a numeric vector")
    }

    if (length(vi) != length(yi)) {
      stop(sprintf("'vi' and 'yi' must have the same length (vi=%d, yi=%d)",
                   length(vi), length(yi)))
    }

    if (!allow_na && any(is.na(vi))) {
      stop("'vi' contains NA values")
    }

    if (any(vi[!is.na(vi)] <= 0)) {
      stop("'vi' must contain only positive values")
    }

    if (!all(is.finite(vi[!is.na(vi)]))) {
      stop("'vi' contains non-finite values")
    }
  }

  if (!is.null(sei)) {
    if (!is.numeric(sei)) {
      stop("'sei' must be a numeric vector")
    }

    if (length(sei) != length(yi)) {
      stop(sprintf("'sei' and 'yi' must have the same length (sei=%d, yi=%d)",
                   length(sei), length(yi)))
    }

    if (!allow_na && any(is.na(sei))) {
      stop("'sei' contains NA values")
    }

    if (any(sei[!is.na(sei)] <= 0)) {
      stop("'sei' must contain only positive values")
    }

    if (!all(is.finite(sei[!is.na(sei)]))) {
      stop("'sei' contains non-finite values")
    }
  }

  invisible(TRUE)
}


#' Validate Data Frame for Meta-Analysis
#'
#' Check that a data frame contains required columns with valid data
#'
#' @param data Data frame to validate
#' @param required_cols Character vector of required column names
#' @param numeric_cols Character vector of columns that must be numeric
#' @param positive_cols Character vector of columns that must be positive
#'
#' @return Invisible TRUE if validation passes, stops with error otherwise
#' @keywords internal
validate_meta_data <- function(data,
                                required_cols = NULL,
                                numeric_cols = NULL,
                                positive_cols = NULL) {
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame")
  }

  if (nrow(data) == 0) {
    stop("'data' is empty (0 rows)")
  }

  # Check required columns exist
  if (!is.null(required_cols)) {
    missing_cols <- setdiff(required_cols, names(data))
    if (length(missing_cols) > 0) {
      stop(sprintf(ERROR_MSG_MISSING_COLUMN, paste(missing_cols, collapse = "', '")))
    }
  }

  # Check numeric columns
  if (!is.null(numeric_cols)) {
    for (col in numeric_cols) {
      if (col %in% names(data) && !is.numeric(data[[col]])) {
        stop(sprintf(ERROR_MSG_NON_NUMERIC, col))
      }
    }
  }

  # Check positive columns
  if (!is.null(positive_cols)) {
    for (col in positive_cols) {
      if (col %in% names(data)) {
        vals <- data[[col]][!is.na(data[[col]])]
        if (any(vals <= 0)) {
          stop(sprintf(ERROR_MSG_NON_POSITIVE, col))
        }
      }
    }
  }

  invisible(TRUE)
}


#' Validate Configuration Object
#'
#' Check that a configuration object has required structure
#'
#' @param config Configuration list
#' @param required_fields Character vector of required field names
#'
#' @return Invisible TRUE if validation passes, stops with error otherwise
#' @keywords internal
validate_config <- function(config, required_fields = NULL) {
  if (!is.list(config)) {
    stop("'config' must be a list. Use setup_cbamm() to create valid configuration")
  }

  if (!is.null(required_fields)) {
    missing_fields <- setdiff(required_fields, names(config))
    if (length(missing_fields) > 0) {
      stop(sprintf("Configuration missing required fields: %s",
                   paste(missing_fields, collapse = ", ")))
    }
  }

  invisible(TRUE)
}


#' Safe Namespace Check and Load
#'
#' Check if package is available and provide helpful error message if not
#'
#' @param package Character; package name
#' @param function_name Character; name of function requiring the package
#' @param quietly Logical; suppress messages?
#'
#' @return Logical; TRUE if package is available
#' @keywords internal
check_package_available <- function(package, function_name = NULL, quietly = TRUE) {
  available <- requireNamespace(package, quietly = quietly)

  if (!available) {
    msg <- sprintf("Package '%s' required but not installed.", package)
    if (!is.null(function_name)) {
      msg <- sprintf("%s Function '%s' requires '%s'.", msg, function_name, package)
    }
    msg <- sprintf("%s\nInstall with: install.packages('%s')", msg, package)
    stop(msg)
  }

  invisible(available)
}


#' Validate Effect Measure
#'
#' Check that effect measure is supported
#'
#' @param measure Character; effect measure (HR, OR, RR, etc.)
#'
#' @return Invisible TRUE if valid, stops with error otherwise
#' @keywords internal
validate_effect_measure <- function(measure) {
  valid_measures <- c("HR", "RR", "OR", "RD", "MD", "SMD", "COR", "PETO",
                      "MH", "ZCOR", "PHI", "RTET", "IRSD", "IRR")

  if (!is.character(measure) || length(measure) != 1) {
    stop("'measure' must be a single character string")
  }

  measure_upper <- toupper(measure)
  if (!measure_upper %in% valid_measures) {
    stop(sprintf("Effect measure '%s' not recognized. Valid options: %s",
                 measure, paste(valid_measures, collapse = ", ")))
  }

  invisible(TRUE)
}


#' Validate Sample Size
#'
#' Check that sample size is sufficient for analysis type
#'
#' @param n_studies Integer; number of studies
#' @param analysis_type Character; type of analysis
#' @param warning_only Logical; issue warning instead of error?
#'
#' @return Invisible TRUE if valid
#' @keywords internal
validate_sample_size <- function(n_studies,
                                  analysis_type = "meta-analysis",
                                  warning_only = FALSE) {
  threshold <- switch(analysis_type,
    "meta-analysis" = MIN_STUDIES_META,
    "subgroup" = MIN_STUDIES_SUBGROUP,
    "regression" = MIN_STUDIES_REGRESSION,
    "publication-bias" = MIN_STUDIES_PUB_BIAS,
    MIN_STUDIES_META  # default
  )

  if (n_studies < threshold) {
    msg <- sprintf("Insufficient studies for %s: %d found, %d required",
                   analysis_type, n_studies, threshold)

    if (warning_only) {
      warning(msg)
    } else {
      stop(msg)
    }
  }

  # Warn if sample is small but sufficient
  if (n_studies < SMALL_MA_THRESHOLD && n_studies >= threshold) {
    warning(sprintf(WARN_MSG_SMALL_SAMPLE, n_studies))
  }

  invisible(TRUE)
}


#' Safe Model Prediction with Error Handling
#'
#' Wrapper for metafor::predict() with informative error messages
#'
#' @param fit metafor model object
#' @param transf Optional transformation function
#' @param context Character; context for error message
#'
#' @return Prediction object or NULL if fails
#' @keywords internal
safe_predict <- function(fit, transf = NULL, context = "") {
  if (is.null(fit)) {
    warning("Cannot predict from NULL model")
    return(NULL)
  }

  if (!inherits(fit, c("rma.uni", "rma.mv", "rma.mh", "rma.peto"))) {
    warning("fit is not a recognized metafor model object")
    return(NULL)
  }

  result <- tryCatch(
    {
      if (is.null(transf)) {
        metafor::predict(fit)
      } else {
        metafor::predict(fit, transf = transf)
      }
    },
    error = function(e) {
      msg <- sprintf("Prediction failed%s: %s",
                     ifelse(context != "", paste0(" for ", context), ""),
                     conditionMessage(e))
      warning(msg)
      NULL
    }
  )

  return(result)
}


#' Safe Try-Catch with Informative Messages
#'
#' Replacement for try(..., silent=TRUE) with better error handling
#'
#' @param expr Expression to evaluate
#' @param context Character; context for error message
#' @param return_on_error Value to return on error (default NULL)
#' @param warn Logical; issue warning on error?
#'
#' @return Result of expr or return_on_error
#' @keywords internal
safe_try <- function(expr, context = "", return_on_error = NULL, warn = TRUE) {
  result <- tryCatch(
    expr,
    error = function(e) {
      if (warn) {
        msg <- sprintf("Operation failed%s: %s",
                       ifelse(context != "", paste0(" (", context, ")"), ""),
                       conditionMessage(e))
        warning(msg, call. = FALSE)
      }
      return_on_error
    }
  )

  return(result)
}
