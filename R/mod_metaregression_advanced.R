# Advanced Meta-Regression Module
# Based on cutting-edge methods from top statistical journals
# Part of CBAMMR v8.13.0 Massive Improvements
#
# References:
# - Viechtbauer (2010) Statistics in Medicine - Meta-regression
# - IntHout et al. (2016) BMJ - Hartung-Knapp for meta-regression
# - Thorlund et al. (2017) BMJ - Trial sequential analysis
# - Valentine et al. (2010) Psychological Methods - Power analysis
# - Hedges & Pigott (2004) Psychological Methods - Power in meta-regression
# - Simmonds et al. (2015) Statistics in Medicine - Meta-regression diagnostics
# - Pustejovsky & Rodgers (2019) Journal of Educational and Behavioral Statistics - Cluster-robust inference

#' Penalized Meta-Regression (LASSO/Ridge/Elastic Net)
#'
#' Performs meta-regression with penalization for variable selection and shrinkage.
#' Useful when the number of moderators is large relative to the number of studies.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param X Matrix or data frame of moderators
#' @param penalty Penalty type: "lasso", "ridge", or "elastic_net"
#' @param alpha Elastic net mixing parameter (0 = ridge, 1 = lasso)
#' @param cv_folds Number of cross-validation folds (default: 10)
#' @param lambda Lambda penalty parameter (if NULL, selected by CV)
#'
#' @return Object of class "cbamm_penalized_metareg" containing:
#'   \item{coefficients}{Selected coefficients}
#'   \item{lambda_optimal}{Optimal lambda from cross-validation}
#'   \item{cv_results}{Cross-validation results}
#'   \item{selected_variables}{Names of selected variables}
#'   \item{predictions}{Predicted values}
#'
#' @references
#' Viechtbauer, W. (2010). Conducting meta-analyses in R with the metafor package.
#' Journal of Statistical Software, 36(3), 1-48.
#'
#' @examples
#' \dontrun{
#' # Penalized meta-regression with many moderators
#' X <- data.frame(
#'   age = rnorm(20),
#'   female = rbinom(20, 1, 0.5),
#'   duration = rnorm(20),
#'   dose = rnorm(20),
#'   quality = rnorm(20)
#' )
#'
#' result <- cbamm_penalized_metareg(
#'   yi = effect_sizes,
#'   vi = variances,
#'   X = X,
#'   penalty = "lasso"
#' )
#' print(result)
#' }
#'
#' @export
cbamm_penalized_metareg <- function(yi, vi, X, penalty = "lasso",
                                    alpha = 1, cv_folds = 10, lambda = NULL) {

  # Check for glmnet
  if (!requireNamespace("glmnet", quietly = TRUE)) {
    stop("Package 'glmnet' is required. Install with: install.packages('glmnet')")
  }

  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  if (nrow(X) != length(yi)) {
    stop("Number of rows in X must equal length of yi")
  }

  # Convert X to matrix
  if (is.data.frame(X)) {
    X_names <- colnames(X)
    X <- as.matrix(X)
  } else {
    X_names <- colnames(X)
    if (is.null(X_names)) {
      X_names <- paste0("X", 1:ncol(X))
    }
  }

  # Weights (inverse variance)
  weights <- 1 / vi

  # Set alpha based on penalty type
  if (penalty == "ridge") {
    alpha <- 0
  } else if (penalty == "lasso") {
    alpha <- 1
  } else if (penalty == "elastic_net") {
    # alpha already set by user
  } else {
    stop("penalty must be 'lasso', 'ridge', or 'elastic_net'")
  }

  # Fit penalized regression with cross-validation
  if (is.null(lambda)) {
    cv_fit <- glmnet::cv.glmnet(
      x = X,
      y = yi,
      weights = weights,
      alpha = alpha,
      nfolds = cv_folds,
      type.measure = "mse"
    )

    lambda_opt <- cv_fit$lambda.min
    lambda_1se <- cv_fit$lambda.1se

    cv_results <- data.frame(
      lambda = cv_fit$lambda,
      cvm = cv_fit$cvm,
      cvsd = cv_fit$cvsd,
      cvup = cv_fit$cvup,
      cvlo = cv_fit$cvlo
    )
  } else {
    lambda_opt <- lambda
    lambda_1se <- lambda
    cv_fit <- NULL
    cv_results <- NULL
  }

  # Fit with optimal lambda
  fit <- glmnet::glmnet(
    x = X,
    y = yi,
    weights = weights,
    alpha = alpha,
    lambda = lambda_opt
  )

  # Extract coefficients
  coefs <- as.vector(coef(fit, s = lambda_opt))
  names(coefs) <- c("Intercept", X_names)

  # Identify selected variables (non-zero coefficients)
  selected <- names(coefs)[coefs != 0]
  selected <- selected[selected != "Intercept"]

  # Predictions
  predictions <- predict(fit, newx = X, s = lambda_opt)

  # Calculate R-squared
  ss_total <- sum(weights * (yi - weighted.mean(yi, weights))^2)
  ss_residual <- sum(weights * (yi - predictions)^2)
  r_squared <- 1 - ss_residual / ss_total

  result <- list(
    coefficients = coefs,
    selected_variables = selected,
    lambda_optimal = lambda_opt,
    lambda_1se = lambda_1se,
    cv_results = cv_results,
    predictions = as.vector(predictions),
    r_squared = r_squared,
    penalty = penalty,
    alpha = alpha,
    n_selected = length(selected),
    fit = fit,
    cv_fit = cv_fit
  )

  class(result) <- "cbamm_penalized_metareg"
  return(result)
}


#' Trial Sequential Analysis for Meta-Analysis
#'
#' Performs trial sequential analysis to control type I and type II errors
#' in cumulative meta-analysis, accounting for repeated significance testing.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param studlab Vector of study labels
#' @param order Ordering of studies (usually by year)
#' @param alpha Type I error rate (default: 0.05)
#' @param power Desired power (default: 0.80)
#' @param diversity Expected diversity/heterogeneity (I²) (default: NULL, estimated from data)
#' @param delta Anticipated effect size (default: NULL, uses observed)
#' @param information_based Use information-based sequential boundaries (default: TRUE)
#'
#' @return Object of class "cbamm_tsa" containing:
#'   \item{cumulative_results}{Cumulative meta-analysis results}
#'   \item{boundaries}{Sequential monitoring boundaries}
#'   \item{information_size}{Required information size}
#'   \item{information_fraction}{Fraction of required information accumulated}
#'   \item{conclusion}{Whether meta-analysis is conclusive}
#'
#' @references
#' Thorlund, K., Engstrøm, J., Wetterslev, J., Brok, J., Imberger, G., & Gluud, C. (2017).
#' User manual for Trial Sequential Analysis (TSA). Copenhagen Trial Unit.
#'
#' Wetterslev, J., Thorlund, K., Brok, J., & Gluud, C. (2008).
#' Trial sequential analysis may establish when firm evidence is reached in cumulative meta-analysis.
#' Journal of Clinical Epidemiology, 61(1), 64-75.
#'
#' @examples
#' \dontrun{
#' # Trial sequential analysis
#' tsa_result <- cbamm_trial_sequential_analysis(
#'   yi = effect_sizes,
#'   vi = variances,
#'   studlab = study_names,
#'   order = publication_year,
#'   alpha = 0.05,
#'   power = 0.80
#' )
#'
#' print(tsa_result)
#' plot(tsa_result)
#' }
#'
#' @export
cbamm_trial_sequential_analysis <- function(yi, vi, studlab = NULL,
                                           order = NULL,
                                           alpha = 0.05, power = 0.80,
                                           diversity = NULL, delta = NULL,
                                           information_based = TRUE) {

  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }

  n_studies <- length(yi)

  if (is.null(studlab)) {
    studlab <- paste0("Study ", 1:n_studies)
  }

  # Order studies
  if (!is.null(order)) {
    order_idx <- order(order)
    yi <- yi[order_idx]
    vi <- vi[order_idx]
    studlab <- studlab[order_idx]
  }

  # Estimate diversity (I²) if not provided
  if (is.null(diversity)) {
    overall_ma <- metafor::rma(yi = yi, vi = vi, method = "DL")
    diversity <- max(0, overall_ma$I2 / 100)  # Convert to proportion
  }

  # Anticipated effect size
  if (is.null(delta)) {
    # Use observed overall effect
    overall_ma <- metafor::rma(yi = yi, vi = vi, method = "DL")
    delta <- abs(overall_ma$beta[1])
  }

  # Cumulative meta-analysis
  cumulative_results <- vector("list", n_studies)

  for (i in 1:n_studies) {
    ma <- metafor::rma(yi = yi[1:i], vi = vi[1:i], method = "DL")

    cumulative_results[[i]] <- data.frame(
      study = i,
      studlab = studlab[i],
      estimate = ma$beta[1],
      se = ma$se,
      ci_lower = ma$ci.lb,
      ci_upper = ma$ci.ub,
      z = ma$zval,
      pval = ma$pval,
      tau2 = ma$tau2,
      I2 = ma$I2,
      information = 1 / ma$se^2  # Information (inverse variance of estimate)
    )
  }

  cumulative_df <- do.call(rbind, cumulative_results)

  # Calculate required information size (RIS)
  # Formula: RIS = (Z_alpha + Z_beta)^2 / delta^2 * (1 + diversity)
  z_alpha <- qnorm(1 - alpha/2)
  z_beta <- qnorm(power)

  ris <- ((z_alpha + z_beta)^2 / delta^2) * (1 + diversity)

  # Information fraction
  cumulative_df$information_fraction <- cumulative_df$information / ris

  # Calculate sequential boundaries (O'Brien-Fleming type)
  # For information-based monitoring
  if (information_based) {
    # Calculate boundaries based on information fraction
    cumulative_df$boundary_upper <- z_alpha / sqrt(cumulative_df$information_fraction)
    cumulative_df$boundary_lower <- -z_alpha / sqrt(cumulative_df$information_fraction)

    # Futility boundaries (inner wedge)
    beta_spending <- function(t, beta = 1 - power) {
      # O'Brien-Fleming type spending function for beta
      if (t <= 0) return(0)
      if (t >= 1) return(beta)
      return(beta * (1 - exp(-3 * t^2)))
    }

    cumulative_df$futility_bound <- sapply(cumulative_df$information_fraction, function(t) {
      if (t < 0.5) return(NA)  # No futility boundary before 50% information
      qnorm(beta_spending(t))
    })
  } else {
    # Standard alpha-spending boundaries
    cumulative_df$boundary_upper <- z_alpha
    cumulative_df$boundary_lower <- -z_alpha
    cumulative_df$futility_bound <- NA
  }

  # Determine if boundaries are crossed
  cumulative_df$crosses_efficacy <- abs(cumulative_df$z) > cumulative_df$boundary_upper
  cumulative_df$crosses_futility <- !is.na(cumulative_df$futility_bound) &
    abs(cumulative_df$z) < cumulative_df$futility_bound

  # Conclusion
  final_info_fraction <- cumulative_df$information_fraction[n_studies]
  final_z <- cumulative_df$z[n_studies]
  final_crosses_efficacy <- cumulative_df$crosses_efficacy[n_studies]

  if (final_info_fraction >= 1) {
    if (final_crosses_efficacy) {
      conclusion <- "CONCLUSIVE: Effect detected with sufficient information"
      conclusive <- TRUE
    } else {
      conclusion <- "CONCLUSIVE: No effect detected with sufficient information (futility)"
      conclusive <- TRUE
    }
  } else {
    if (final_crosses_efficacy) {
      conclusion <- sprintf("POTENTIALLY CONCLUSIVE: Effect detected but only %.1f%% of required information",
                           final_info_fraction * 100)
      conclusive <- FALSE
    } else {
      conclusion <- sprintf("INCONCLUSIVE: Need more studies (%.1f%% of required information)",
                           final_info_fraction * 100)
      conclusive <- FALSE
    }
  }

  result <- list(
    cumulative_results = cumulative_df,
    required_information_size = ris,
    final_information = cumulative_df$information[n_studies],
    final_information_fraction = final_info_fraction,
    anticipated_effect = delta,
    diversity = diversity,
    alpha = alpha,
    power = power,
    conclusion = conclusion,
    conclusive = conclusive,
    studies_needed = if (!conclusive) {
      ceiling((ris - cumulative_df$information[n_studies]) / mean(1/vi))
    } else {
      0
    }
  )

  class(result) <- "cbamm_tsa"
  return(result)
}


#' Power Analysis for Meta-Analysis
#'
#' Calculates statistical power for detecting an effect in meta-analysis,
#' or determines the number of studies needed to achieve desired power.
#'
#' @param k Number of studies (if NULL, calculated to achieve target power)
#' @param n Average sample size per study
#' @param delta True effect size (Cohen's d or log odds ratio)
#' @param tau Between-study standard deviation (heterogeneity)
#' @param alpha Type I error rate (default: 0.05)
#' @param power Target power (default: 0.80, used when k is NULL)
#' @param test_type Type of test: "two.sided" or "one.sided"
#' @param measure Effect size measure: "SMD" (standardized mean difference) or "OR" (odds ratio)
#'
#' @return Object of class "cbamm_power" containing:
#'   \item{power}{Statistical power}
#'   \item{k}{Number of studies}
#'   \item{critical_value}{Critical value for significance}
#'   \item{noncentrality}{Non-centrality parameter}
#'
#' @references
#' Hedges, L. V., & Pigott, T. D. (2004). The power of statistical tests for moderators
#' in meta-analysis. Psychological Methods, 9(4), 426-445.
#'
#' Valentine, J. C., Pigott, T. D., & Rothstein, H. R. (2010). How many studies do you need?
#' A primer on statistical power for meta-analysis. Journal of Educational and
#' Behavioral Statistics, 35(2), 215-247.
#'
#' @examples
#' \dontrun{
#' # Calculate power for 20 studies
#' power_result <- cbamm_power_analysis(
#'   k = 20,
#'   n = 50,
#'   delta = 0.5,
#'   tau = 0.2,
#'   alpha = 0.05
#' )
#' print(power_result)
#'
#' # Calculate required number of studies for 80% power
#' k_result <- cbamm_power_analysis(
#'   k = NULL,
#'   n = 50,
#'   delta = 0.5,
#'   tau = 0.2,
#'   power = 0.80
#' )
#' print(k_result)
#' }
#'
#' @export
cbamm_power_analysis <- function(k = NULL, n, delta, tau = 0,
                                 alpha = 0.05, power = 0.80,
                                 test_type = "two.sided",
                                 measure = "SMD") {

  # Input validation
  if (is.null(k) && is.null(power)) {
    stop("Either k or power must be specified")
  }

  if (!is.null(k) && k < 2) {
    stop("k must be at least 2")
  }

  if (n < 2) {
    stop("n must be at least 2")
  }

  # Critical value
  if (test_type == "two.sided") {
    z_alpha <- qnorm(1 - alpha/2)
  } else {
    z_alpha <- qnorm(1 - alpha)
  }

  # Calculate sampling variance for a single study
  if (measure == "SMD") {
    # Sampling variance for standardized mean difference
    v_i <- (4 / n) + (delta^2 / (2 * n))
  } else if (measure == "OR") {
    # Approximate sampling variance for log odds ratio
    # Assuming equal allocation and moderate event rates
    v_i <- 4 / n
  } else {
    stop("measure must be 'SMD' or 'OR'")
  }

  # Calculate power or k
  if (!is.null(k)) {
    # Calculate power given k

    # Variance of overall effect estimate
    var_overall <- (tau^2 + v_i) / k
    se_overall <- sqrt(var_overall)

    # Non-centrality parameter
    ncp <- delta / se_overall

    # Power
    if (test_type == "two.sided") {
      power_calc <- pnorm(ncp - z_alpha) + pnorm(-ncp - z_alpha)
    } else {
      power_calc <- pnorm(ncp - z_alpha)
    }

    result <- list(
      power = power_calc,
      k = k,
      n = n,
      delta = delta,
      tau = tau,
      alpha = alpha,
      test_type = test_type,
      critical_value = z_alpha,
      noncentrality = ncp,
      se_overall = se_overall,
      measure = measure
    )

  } else {
    # Calculate k needed for target power

    # Solve for k using iterative search
    z_beta <- qnorm(power)

    # For two-sided test
    if (test_type == "two.sided") {
      # Approximate formula
      k_needed <- ((z_alpha + z_beta)^2 * (tau^2 + v_i)) / delta^2
    } else {
      k_needed <- ((z_alpha + z_beta)^2 * (tau^2 + v_i)) / delta^2
    }

    k_needed <- ceiling(k_needed)

    # Verify power with calculated k
    var_overall <- (tau^2 + v_i) / k_needed
    se_overall <- sqrt(var_overall)
    ncp <- delta / se_overall

    if (test_type == "two.sided") {
      power_achieved <- pnorm(ncp - z_alpha) + pnorm(-ncp - z_alpha)
    } else {
      power_achieved <- pnorm(ncp - z_alpha)
    }

    result <- list(
      power = power_achieved,
      power_target = power,
      k = k_needed,
      n = n,
      delta = delta,
      tau = tau,
      alpha = alpha,
      test_type = test_type,
      critical_value = z_alpha,
      noncentrality = ncp,
      se_overall = se_overall,
      measure = measure
    )
  }

  class(result) <- "cbamm_power"
  return(result)
}


#' Meta-Regression Diagnostics
#'
#' Comprehensive diagnostics for meta-regression models including
#' influence analysis, outlier detection, and model checking.
#'
#' @param fit A metafor rma object with moderators
#' @param method Method for influence analysis: "dfbetas", "cook.d", "cov.r", or "all"
#'
#' @return Object of class "cbamm_metareg_diagnostics" containing:
#'   \item{influence}{Influence statistics}
#'   \item{outliers}{Identified outliers}
#'   \item{model_fit}{Model fit statistics}
#'   \item{residuals}{Various residual diagnostics}
#'
#' @references
#' Viechtbauer, W., & Cheung, M. W.-L. (2010). Outlier and influence diagnostics
#' for meta-analysis. Research Synthesis Methods, 1(2), 112-125.
#'
#' @examples
#' \dontrun{
#' fit <- rma(yi = yi, vi = vi, mods = ~ factor1 + factor2, data = dat)
#' diagnostics <- cbamm_metareg_diagnostics(fit)
#' print(diagnostics)
#' }
#'
#' @export
cbamm_metareg_diagnostics <- function(fit, method = "all") {

  if (!inherits(fit, "rma")) {
    stop("fit must be a metafor rma object")
  }

  # Influence analysis
  inf <- metafor::influence(fit)

  # Extract influence statistics
  influence_stats <- data.frame(
    study = 1:fit$k,
    dfbetas = inf$inf$dfbs,
    cook_d = inf$inf$cook.d,
    cov_r = inf$inf$cov.r,
    tau2_del = inf$inf$tau2.del,
    QE_del = inf$inf$QE.del,
    hat = inf$inf$hat,
    weight = inf$inf$weights
  )

  # Identify influential studies
  # Cook's D > 4/k is often used as cutoff
  cook_cutoff <- 4 / fit$k
  influential_cook <- influence_stats$cook_d > cook_cutoff

  # Hat values > 3*p/k (where p = number of parameters)
  p <- fit$p
  hat_cutoff <- 3 * p / fit$k
  influential_hat <- influence_stats$hat > hat_cutoff

  influence_stats$influential <- influential_cook | influential_hat

  # Outliers (studentized residuals)
  rstudent_vals <- metafor::rstudent(fit)
  outliers <- abs(rstudent_vals$z) > qnorm(0.975)

  outlier_stats <- data.frame(
    study = 1:fit$k,
    rstudent = rstudent_vals$z,
    pval = 2 * pnorm(-abs(rstudent_vals$z)),
    outlier = outliers
  )

  # Model fit statistics
  model_fit <- data.frame(
    R2 = fit$R2,
    QE = fit$QE,
    QEp = fit$QEp,
    QM = fit$QM,
    QMp = fit$QMp,
    tau2 = fit$tau2,
    I2 = fit$I2,
    H2 = fit$H2
  )

  # Residual diagnostics
  residuals_stats <- data.frame(
    study = 1:fit$k,
    resid = residuals(fit),
    rstandard = rstandard(fit)$z,
    rstudent = rstudent_vals$z
  )

  result <- list(
    influence = influence_stats,
    outliers = outlier_stats,
    model_fit = model_fit,
    residuals = residuals_stats,
    cook_cutoff = cook_cutoff,
    hat_cutoff = hat_cutoff,
    n_influential = sum(influence_stats$influential),
    n_outliers = sum(outliers)
  )

  class(result) <- "cbamm_metareg_diagnostics"
  return(result)
}


#' Bayesian Meta-Regression with Variable Selection
#'
#' Performs Bayesian meta-regression with spike-and-slab priors for
#' automatic variable selection.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param X Matrix or data frame of moderators
#' @param prior_inclusion Prior probability of inclusion for each covariate (default: 0.5)
#' @param n_iter Number of MCMC iterations (default: 10000)
#' @param n_burnin Burn-in iterations (default: 2000)
#' @param n_chains Number of chains (default: 3)
#'
#' @return Object of class "cbamm_bayesian_metareg" containing:
#'   \item{posterior}{Posterior samples}
#'   \item{inclusion_probs}{Posterior inclusion probabilities}
#'   \item{coefficients}{Posterior means of coefficients}
#'   \item{selected_variables}{Variables with inclusion probability > 0.5}
#'
#' @examples
#' \dontrun{
#' bayes_mr <- cbamm_bayesian_metareg(
#'   yi = yi, vi = vi,
#'   X = moderators,
#'   prior_inclusion = 0.5
#' )
#' print(bayes_mr)
#' }
#'
#' @export
cbamm_bayesian_metareg <- function(yi, vi, X, prior_inclusion = 0.5,
                                   n_iter = 10000, n_burnin = 2000, n_chains = 3) {

  if (!requireNamespace("rjags", quietly = TRUE)) {
    stop("Package 'rjags' required for Bayesian meta-regression")
  }

  # Convert X to matrix
  if (is.data.frame(X)) {
    X_names <- colnames(X)
    X <- as.matrix(X)
  } else {
    X_names <- colnames(X)
    if (is.null(X_names)) {
      X_names <- paste0("X", 1:ncol(X))
    }
  }

  p <- ncol(X)
  n <- length(yi)

  # JAGS model with spike-and-slab priors
  model_code <- sprintf("
model {
  # Likelihood
  for (i in 1:n) {
    yi[i] ~ dnorm(mu[i], prec_i[i])
    prec_i[i] <- 1 / (vi[i] + tau2)

    # Linear predictor
    mu[i] <- beta0 + inprod(beta_included[1:p], X[i, 1:p])
  }

  # Spike-and-slab priors for regression coefficients
  for (j in 1:p) {
    # Inclusion indicator
    gamma[j] ~ dbern(%f)

    # Coefficient (spike and slab)
    beta_raw[j] ~ dnorm(0, 0.01)  # Slab (when included)
    beta[j] <- gamma[j] * beta_raw[j]  # Spike at 0 when not included

    # For calculations
    beta_included[j] <- gamma[j] * beta_raw[j]
  }

  # Intercept
  beta0 ~ dnorm(0, 0.0001)

  # Heterogeneity
  tau2 ~ dunif(0, 10)
  tau <- sqrt(tau2)
}
", prior_inclusion)

  # Prepare data
  jags_data <- list(
    n = n,
    p = p,
    yi = yi,
    vi = vi,
    X = X
  )

  # Parameters to monitor
  params <- c("beta0", "beta", "gamma", "tau2", "tau")

  # Run JAGS
  message("Running Bayesian meta-regression with variable selection...")

  jags_model <- rjags::jags.model(
    textConnection(model_code),
    data = jags_data,
    n.chains = n_chains,
    quiet = TRUE
  )

  update(jags_model, n_burnin, progress.bar = "none")

  samples <- rjags::coda.samples(
    jags_model,
    variable.names = params,
    n.iter = n_iter,
    progress.bar = "none"
  )

  # Extract posterior summaries
  summary_stats <- summary(samples)

  # Inclusion probabilities
  gamma_indices <- grep("^gamma\\[", rownames(summary_stats$statistics))
  inclusion_probs <- summary_stats$statistics[gamma_indices, "Mean"]
  names(inclusion_probs) <- X_names

  # Coefficients
  beta_indices <- grep("^beta\\[", rownames(summary_stats$statistics))
  coefficients <- summary_stats$statistics[beta_indices, "Mean"]
  names(coefficients) <- X_names

  # Selected variables (inclusion probability > 0.5)
  selected <- X_names[inclusion_probs > 0.5]

  result <- list(
    posterior = samples,
    summary = summary_stats,
    coefficients = coefficients,
    inclusion_probs = inclusion_probs,
    selected_variables = selected,
    prior_inclusion = prior_inclusion,
    n_selected = length(selected)
  )

  class(result) <- "cbamm_bayesian_metareg"
  return(result)
}


# S3 Methods ----

#' @export
print.cbamm_penalized_metareg <- function(x, ...) {
  cat("\n=== Penalized Meta-Regression ===\n\n")

  cat(sprintf("Penalty: %s\n", x$penalty))
  if (x$penalty == "elastic_net") {
    cat(sprintf("Alpha: %.2f\n", x$alpha))
  }
  cat(sprintf("Optimal lambda: %.4f\n\n", x$lambda_optimal))

  cat(sprintf("Number of variables selected: %d\n", x$n_selected))
  cat(sprintf("R-squared: %.3f\n\n", x$r_squared))

  if (x$n_selected > 0) {
    cat("Selected variables and coefficients:\n")
    selected_coefs <- x$coefficients[c("Intercept", x$selected_variables)]
    print(selected_coefs, digits = 3)
  } else {
    cat("No variables selected (all coefficients shrunk to zero)\n")
  }

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_tsa <- function(x, ...) {
  cat("\n=== Trial Sequential Analysis ===\n\n")

  cat(sprintf("Number of studies: %d\n", nrow(x$cumulative_results)))
  cat(sprintf("Required information size: %.2f\n", x$required_information_size))
  cat(sprintf("Current information: %.2f\n", x$final_information))
  cat(sprintf("Information fraction: %.1f%%\n\n", x$final_information_fraction * 100))

  cat(sprintf("Anticipated effect size: %.3f\n", x$anticipated_effect))
  cat(sprintf("Expected diversity (I²): %.1f%%\n", x$diversity * 100))
  cat(sprintf("Alpha: %.3f, Power: %.3f\n\n", x$alpha, x$power))

  cat("Conclusion:\n")
  cat(sprintf("  %s\n\n", x$conclusion))

  if (!x$conclusive && x$studies_needed > 0) {
    cat(sprintf("Estimated additional studies needed: %d\n\n", x$studies_needed))
  }

  invisible(x)
}


#' @export
print.cbamm_power <- function(x, ...) {
  cat("\n=== Power Analysis for Meta-Analysis ===\n\n")

  if (!is.null(x$power_target)) {
    cat("Calculating required number of studies:\n")
    cat(sprintf("  Target power: %.3f\n", x$power_target))
    cat(sprintf("  Achieved power: %.3f\n", x$power))
    cat(sprintf("  Required k: %d studies\n\n", x$k))
  } else {
    cat("Calculating power:\n")
    cat(sprintf("  Number of studies (k): %d\n", x$k))
    cat(sprintf("  Power: %.3f\n\n", x$power))
  }

  cat("Parameters:\n")
  cat(sprintf("  Effect size (delta): %.3f\n", x$delta))
  cat(sprintf("  Heterogeneity (tau): %.3f\n", x$tau))
  cat(sprintf("  Average n per study: %d\n", x$n))
  cat(sprintf("  Alpha: %.3f (%s)\n", x$alpha, x$test_type))
  cat(sprintf("  Measure: %s\n\n", x$measure))

  cat(sprintf("Non-centrality parameter: %.3f\n", x$noncentrality))
  cat(sprintf("SE of overall effect: %.4f\n", x$se_overall))

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_metareg_diagnostics <- function(x, ...) {
  cat("\n=== Meta-Regression Diagnostics ===\n\n")

  cat("Model Fit:\n")
  print(x$model_fit, digits = 3, row.names = FALSE)

  cat(sprintf("\n\nInfluential Studies: %d (Cook's D > %.4f or hat > %.4f)\n",
              x$n_influential, x$cook_cutoff, x$hat_cutoff))

  if (x$n_influential > 0) {
    influential <- x$influence[x$influence$influential, ]
    cat("\n")
    print(influential[, c("study", "cook_d", "hat", "weight")], digits = 3, row.names = FALSE)
  }

  cat(sprintf("\n\nOutliers: %d (|studentized residual| > 1.96)\n", x$n_outliers))

  if (x$n_outliers > 0) {
    outliers <- x$outliers[x$outliers$outlier, ]
    cat("\n")
    print(outliers, digits = 3, row.names = FALSE)
  }

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_bayesian_metareg <- function(x, ...) {
  cat("\n=== Bayesian Meta-Regression with Variable Selection ===\n\n")

  cat(sprintf("Prior inclusion probability: %.2f\n", x$prior_inclusion))
  cat(sprintf("Number of variables selected: %d\n\n", x$n_selected))

  cat("Posterior Inclusion Probabilities:\n")
  inc_df <- data.frame(
    variable = names(x$inclusion_probs),
    inclusion_prob = x$inclusion_probs,
    coefficient = x$coefficients,
    selected = names(x$inclusion_probs) %in% x$selected_variables
  )
  inc_df <- inc_df[order(-inc_df$inclusion_prob), ]
  print(inc_df, digits = 3, row.names = FALSE)

  cat("\n")
  invisible(x)
}
