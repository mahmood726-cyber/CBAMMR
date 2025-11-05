#' Advanced Effect Size Conversion Module
#'
#' Comprehensive effect size conversion supporting 10+ conversion types:
#' 1. Mean & SE → Cohen's d / Hedges' g
#' 2. Unstandardized regression coefficient → Cohen's d
#' 3. Standardized regression coefficient (beta) → Cohen's d
#' 4. Point-biserial correlation → Cohen's d
#' 5. One-Way ANOVA F-value → Cohen's d / Hedges' g
#' 6. Two-Sample t-Test → Cohen's d
#' 7. p-value → SE
#' 8. Chi-squared → Effect size
#' 9. Pool groups (combine means/SDs)
#' 10. NNT → Cohen's d
#'
#' @name mod_effect_conversion
#' @rdname mod_effect_conversion
#'
#' @import esc
#' @import dmetar
NULL

#' @describeIn mod_effect_conversion Convert means and SE to effect size
#' @param grp1m Numeric. Group 1 mean
#' @param grp1se Numeric. Group 1 standard error
#' @param grp1n Integer. Group 1 sample size
#' @param grp2m Numeric. Group 2 mean
#' @param grp2se Numeric. Group 2 standard error
#' @param grp2n Integer. Group 2 sample size
#' @param es_type Character. "d" for Cohen's d or "g" for Hedges' g
#' @export
#' @examples
#' \dontrun{
#' cbamm_convert_means(
#'   grp1m = 8.5, grp1se = 1.5, grp1n = 50,
#'   grp2m = 11, grp2se = 1.8, grp2n = 60,
#'   es_type = "d"
#' )
#' }
cbamm_convert_means <- function(grp1m, grp1se, grp1n, grp2m, grp2se, grp2n, es_type = "d") {
  # Validate inputs
  if (any(c(grp1n, grp2n) < 1)) {
    stop("Sample sizes must be >= 1")
  }

  # Convert SE to SD
  grp1sd <- grp1se * sqrt(grp1n)
  grp2sd <- grp2se * sqrt(grp2n)

  # Use esc package for conversion
  result <- esc::esc_mean_sd(
    grp1m = grp1m, grp1sd = grp1sd, grp1n = grp1n,
    grp2m = grp2m, grp2sd = grp2sd, grp2n = grp2n,
    es.type = es_type
  )

  # Enhance output
  result$conversion_type <- "Mean & SE"
  result$inputs <- list(
    grp1 = list(mean = grp1m, se = grp1se, sd = grp1sd, n = grp1n),
    grp2 = list(mean = grp2m, se = grp2se, sd = grp2sd, n = grp2n)
  )

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Convert unstandardized regression coefficient to effect size
#' @param b Numeric. Unstandardized regression coefficient
#' @param sdy Numeric. Standard deviation of outcome variable
#' @param grp1n Integer. Group 1 sample size
#' @param grp2n Integer. Group 2 sample size
#' @param es_type Character. "d" for Cohen's d or "g" for Hedges' g
#' @export
cbamm_convert_regression <- function(b, sdy, grp1n, grp2n, es_type = "d") {
  if (sdy <= 0) {
    stop("SD of y must be positive")
  }

  result <- esc::esc_B(
    b = b, sdy = sdy,
    grp1n = grp1n, grp2n = grp2n,
    es.type = es_type
  )

  result$conversion_type <- "Unstandardized Regression Coefficient"
  result$inputs <- list(b = b, sdy = sdy, grp1n = grp1n, grp2n = grp2n)

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Convert standardized regression coefficient (beta) to effect size
#' @param beta Numeric. Standardized regression coefficient
#' @param sdy Numeric. Standard deviation of outcome variable
#' @param grp1n Integer. Group 1 sample size
#' @param grp2n Integer. Group 2 sample size
#' @param es_type Character. "d" for Cohen's d or "g" for Hedges' g
#' @export
cbamm_convert_beta <- function(beta, sdy, grp1n, grp2n, es_type = "d") {
  result <- esc::esc_beta(
    beta = beta, sdy = sdy,
    grp1n = grp1n, grp2n = grp2n,
    es.type = es_type
  )

  result$conversion_type <- "Standardized Regression Coefficient (beta)"
  result$inputs <- list(beta = beta, sdy = sdy, grp1n = grp1n, grp2n = grp2n)

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Convert point-biserial correlation to effect size
#' @param rpb Numeric. Point-biserial correlation
#' @param grp1n Integer. Group 1 sample size
#' @param grp2n Integer. Group 2 sample size
#' @param es_type Character. "d" for Cohen's d or "g" for Hedges' g
#' @export
cbamm_convert_rpb <- function(rpb, grp1n, grp2n, es_type = "d") {
  if (abs(rpb) > 1) {
    stop("Point-biserial correlation must be between -1 and 1")
  }

  result <- esc::esc_rpb(
    rpb = rpb,
    grp1n = grp1n, grp2n = grp2n,
    es.type = es_type
  )

  result$conversion_type <- "Point-Biserial Correlation"
  result$inputs <- list(rpb = rpb, grp1n = grp1n, grp2n = grp2n)

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Convert one-way ANOVA F-value to effect size
#' @param f Numeric. F-value from one-way ANOVA
#' @param grp1n Integer. Group 1 sample size
#' @param grp2n Integer. Group 2 sample size
#' @param es_type Character. "d" for Cohen's d or "g" for Hedges' g
#' @export
cbamm_convert_f <- function(f, grp1n, grp2n, es_type = "g") {
  if (f < 0) {
    stop("F-value must be non-negative")
  }

  result <- esc::esc_f(
    f = f,
    grp1n = grp1n, grp2n = grp2n,
    es.type = es_type
  )

  result$conversion_type <- "One-Way ANOVA F-value"
  result$inputs <- list(f = f, grp1n = grp1n, grp2n = grp2n)

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Convert two-sample t-test to effect size
#' @param t Numeric. t-value from two-sample t-test
#' @param grp1n Integer. Group 1 sample size
#' @param grp2n Integer. Group 2 sample size
#' @param es_type Character. "d" for Cohen's d or "g" for Hedges' g
#' @export
cbamm_convert_t <- function(t, grp1n, grp2n, es_type = "d") {
  result <- esc::esc_t(
    t = t,
    grp1n = grp1n, grp2n = grp2n,
    es.type = es_type
  )

  result$conversion_type <- "Two-Sample t-Test"
  result$inputs <- list(t = t, grp1n = grp1n, grp2n = grp2n)

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Convert p-value to standard error
#' @param effect_size Numeric. Effect size (e.g., mean difference, OR, RR)
#' @param p Numeric. p-value
#' @param n Integer. Total sample size
#' @param effect_size_type Character. Type of effect size ("difference", "ratio", "or")
#' @export
cbamm_convert_pvalue <- function(effect_size, p, n, effect_size_type = "difference") {
  if (p <= 0 || p >= 1) {
    stop("p-value must be between 0 and 1")
  }
  if (n < 1) {
    stop("Sample size must be >= 1")
  }

  # Calculate SE from p-value using z-score
  z <- abs(qnorm(p / 2))

  if (effect_size_type == "difference") {
    se <- abs(effect_size / z)
  } else if (effect_size_type %in% c("ratio", "or", "rr")) {
    # For log-scale effect sizes
    se <- abs(log(effect_size) / z)
  } else {
    stop("effect_size_type must be 'difference', 'ratio', or 'or'")
  }

  result <- list(
    effect_size = effect_size,
    se = se,
    p = p,
    z = z,
    ci.lo = effect_size - 1.96 * se,
    ci.hi = effect_size + 1.96 * se,
    conversion_type = "p-value to SE",
    inputs = list(effect_size = effect_size, p = p, n = n, type = effect_size_type)
  )

  class(result) <- c("cbamm_conversion", "list")
  return(result)
}

#' @describeIn mod_effect_conversion Convert chi-squared test to effect size
#' @param chisq Numeric. Chi-squared value
#' @param totaln Integer. Total sample size
#' @param es_type Character. Effect size type ("cox.or", "cox.log", "logit", "d")
#' @export
cbamm_convert_chisq <- function(chisq, totaln, es_type = "cox.or") {
  if (chisq < 0) {
    stop("Chi-squared must be non-negative")
  }
  if (totaln < 1) {
    stop("Total n must be >= 1")
  }

  result <- esc::esc_chisq(
    chisq = chisq,
    totaln = totaln,
    es.type = es_type
  )

  result$conversion_type <- "Chi-squared Test"
  result$inputs <- list(chisq = chisq, totaln = totaln)

  class(result) <- c("cbamm_conversion", class(result))
  return(result)
}

#' @describeIn mod_effect_conversion Pool means and SDs from multiple groups
#' @param n1 Integer. Group 1 sample size
#' @param n2 Integer. Group 2 sample size
#' @param m1 Numeric. Group 1 mean
#' @param m2 Numeric. Group 2 mean
#' @param sd1 Numeric. Group 1 SD
#' @param sd2 Numeric. Group 2 SD
#' @export
cbamm_pool_groups <- function(n1, n2, m1, m2, sd1, sd2) {
  if (any(c(n1, n2) < 1)) {
    stop("Sample sizes must be >= 1")
  }
  if (any(c(sd1, sd2) < 0)) {
    stop("SDs must be non-negative")
  }

  # Use dmetar package for pooling
  result <- dmetar::pool.groups(
    n1 = n1, n2 = n2,
    m1 = m1, m2 = m2,
    sd1 = sd1, sd2 = sd2
  )

  result$conversion_type <- "Pool Groups"
  result$inputs <- list(
    grp1 = list(n = n1, mean = m1, sd = sd1),
    grp2 = list(n = n2, mean = m2, sd = sd2)
  )

  class(result) <- c("cbamm_conversion", "list")
  return(result)
}

#' @describeIn mod_effect_conversion Convert NNT to Cohen's d
#' @param d Numeric. Cohen's d (effect size)
#' @param CER Numeric. Control event rate (proportion, 0-1)
#' @export
cbamm_convert_nnt <- function(d, CER) {
  if (CER < 0 || CER > 1) {
    stop("CER (control event rate) must be between 0 and 1")
  }

  # Use dmetar package
  result <- dmetar::se.from.p(
    d = d,
    CER = CER
  )

  result$conversion_type <- "NNT to Cohen's d"
  result$inputs <- list(d = d, CER = CER)

  class(result) <- c("cbamm_conversion", "list")
  return(result)
}

#' @describeIn mod_effect_conversion Comprehensive effect size conversion with auto-detection
#' @param data Data frame or list containing conversion parameters
#' @param conversion_type Character. Type of conversion to perform
#' @param ... Additional parameters passed to specific conversion functions
#' @export
#' @examples
#' \dontrun{
#' # Single conversion
#' cbamm_convert_es(
#'   conversion_type = "means",
#'   grp1m = 8.5, grp1se = 1.5, grp1n = 50,
#'   grp2m = 11, grp2se = 1.8, grp2n = 60
#' )
#'
#' # Batch conversion from data frame
#' batch_data <- data.frame(
#'   grp1m = c(8.5, 7.2, 9.1),
#'   grp1se = c(1.5, 1.3, 1.7),
#'   grp1n = c(50, 45, 55),
#'   grp2m = c(11, 10.5, 12),
#'   grp2se = c(1.8, 1.6, 1.9),
#'   grp2n = c(60, 50, 65)
#' )
#'
#' results <- cbamm_convert_es(
#'   data = batch_data,
#'   conversion_type = "means",
#'   es_type = "d"
#' )
#' }
cbamm_convert_es <- function(data = NULL, conversion_type, ...) {

  # Available conversion types
  conv_types <- c(
    "means", "regression", "beta", "rpb", "f", "t",
    "pvalue", "chisq", "pool", "nnt"
  )

  if (!conversion_type %in% conv_types) {
    stop(sprintf("conversion_type must be one of: %s", paste(conv_types, collapse = ", ")))
  }

  # If data is provided, perform batch conversion
  if (!is.null(data)) {
    if (!is.data.frame(data)) {
      stop("data must be a data frame for batch conversion")
    }

    message(sprintf("Performing batch conversion: %s (%d rows)", conversion_type, nrow(data)))

    results <- list()
    for (i in 1:nrow(data)) {
      row_data <- as.list(data[i, ])

      tryCatch({
        results[[i]] <- switch(
          conversion_type,
          "means" = cbamm_convert_means(
            grp1m = row_data$grp1m, grp1se = row_data$grp1se, grp1n = row_data$grp1n,
            grp2m = row_data$grp2m, grp2se = row_data$grp2se, grp2n = row_data$grp2n,
            es_type = row_data$es_type %||% "d"
          ),
          "regression" = cbamm_convert_regression(
            b = row_data$b, sdy = row_data$sdy,
            grp1n = row_data$grp1n, grp2n = row_data$grp2n,
            es_type = row_data$es_type %||% "d"
          ),
          "beta" = cbamm_convert_beta(
            beta = row_data$beta, sdy = row_data$sdy,
            grp1n = row_data$grp1n, grp2n = row_data$grp2n,
            es_type = row_data$es_type %||% "d"
          ),
          "rpb" = cbamm_convert_rpb(
            rpb = row_data$rpb,
            grp1n = row_data$grp1n, grp2n = row_data$grp2n,
            es_type = row_data$es_type %||% "d"
          ),
          "f" = cbamm_convert_f(
            f = row_data$f,
            grp1n = row_data$grp1n, grp2n = row_data$grp2n,
            es_type = row_data$es_type %||% "g"
          ),
          "t" = cbamm_convert_t(
            t = row_data$t,
            grp1n = row_data$grp1n, grp2n = row_data$grp2n,
            es_type = row_data$es_type %||% "d"
          ),
          "pvalue" = cbamm_convert_pvalue(
            effect_size = row_data$effect_size,
            p = row_data$p,
            n = row_data$n,
            effect_size_type = row_data$effect_size_type %||% "difference"
          ),
          "chisq" = cbamm_convert_chisq(
            chisq = row_data$chisq,
            totaln = row_data$totaln,
            es_type = row_data$es_type %||% "cox.or"
          ),
          "pool" = cbamm_pool_groups(
            n1 = row_data$n1, n2 = row_data$n2,
            m1 = row_data$m1, m2 = row_data$m2,
            sd1 = row_data$sd1, sd2 = row_data$sd2
          ),
          "nnt" = cbamm_convert_nnt(
            d = row_data$d,
            CER = row_data$CER
          )
        )
        results[[i]]$row <- i
      }, error = function(e) {
        warning(sprintf("Row %d failed: %s", i, e$message))
        results[[i]] <- list(row = i, error = e$message)
      })
    }

    class(results) <- c("cbamm_conversion_batch", "list")
    message(sprintf("✅ Batch conversion complete: %d/%d successful", sum(sapply(results, function(x) is.null(x$error))), nrow(data)))
    return(results)

  } else {
    # Single conversion
    args <- list(...)

    result <- switch(
      conversion_type,
      "means" = do.call(cbamm_convert_means, args),
      "regression" = do.call(cbamm_convert_regression, args),
      "beta" = do.call(cbamm_convert_beta, args),
      "rpb" = do.call(cbamm_convert_rpb, args),
      "f" = do.call(cbamm_convert_f, args),
      "t" = do.call(cbamm_convert_t, args),
      "pvalue" = do.call(cbamm_convert_pvalue, args),
      "chisq" = do.call(cbamm_convert_chisq, args),
      "pool" = do.call(cbamm_pool_groups, args),
      "nnt" = do.call(cbamm_convert_nnt, args)
    )

    return(result)
  }
}

#' @describeIn mod_effect_conversion Print method for cbamm_conversion objects
#' @param x A cbamm_conversion object
#' @param ... Additional arguments
#' @export
print.cbamm_conversion <- function(x, ...) {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat(sprintf("  CBAMMR Effect Size Conversion: %s\n", x$conversion_type))
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat("Inputs:\n")
  print(x$inputs)
  cat("\n")

  cat("Results:\n")
  if (!is.null(x$es)) {
    cat(sprintf("  Effect Size (ES):  %.4f\n", x$es))
  }
  if (!is.null(x$se)) {
    cat(sprintf("  Standard Error:    %.4f\n", x$se))
  }
  if (!is.null(x$ci.lo) && !is.null(x$ci.hi)) {
    cat(sprintf("  95%% CI:            [%.4f, %.4f]\n", x$ci.lo, x$ci.hi))
  }
  if (!is.null(x$var)) {
    cat(sprintf("  Variance:          %.4f\n", x$var))
  }
  if (!is.null(x$totaln)) {
    cat(sprintf("  Total N:           %d\n", x$totaln))
  }

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}

#' @describeIn mod_effect_conversion Print method for batch conversion results
#' @param x A cbamm_conversion_batch object
#' @param ... Additional arguments
#' @export
print.cbamm_conversion_batch <- function(x, ...) {
  n_total <- length(x)
  n_success <- sum(sapply(x, function(item) is.null(item$error)))
  n_failed <- n_total - n_success

  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  CBAMMR Batch Effect Size Conversion Results\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  cat(sprintf("Total conversions:     %d\n", n_total))
  cat(sprintf("Successful:            %d (%.1f%%)\n", n_success, 100 * n_success / n_total))
  cat(sprintf("Failed:                %d (%.1f%%)\n", n_failed, 100 * n_failed / n_total))
  cat("\n")

  if (n_success > 0) {
    cat("Summary of successful conversions:\n")
    es_values <- sapply(x, function(item) if (is.null(item$error) && !is.null(item$es)) item$es else NA)
    es_values <- es_values[!is.na(es_values)]

    if (length(es_values) > 0) {
      cat(sprintf("  Mean ES:   %.4f\n", mean(es_values, na.rm = TRUE)))
      cat(sprintf("  Median ES: %.4f\n", median(es_values, na.rm = TRUE)))
      cat(sprintf("  Range ES:  [%.4f, %.4f]\n", min(es_values, na.rm = TRUE), max(es_values, na.rm = TRUE)))
    }
  }

  if (n_failed > 0) {
    cat("\nFailed conversions:\n")
    failed_rows <- sapply(x, function(item) if (!is.null(item$error)) item$row else NA)
    failed_rows <- failed_rows[!is.na(failed_rows)]
    cat(sprintf("  Rows: %s\n", paste(failed_rows, collapse = ", ")))
  }

  cat("\n═══════════════════════════════════════════════════════════════\n")

  invisible(x)
}
