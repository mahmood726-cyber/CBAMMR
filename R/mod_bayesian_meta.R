# Bayesian Meta-Analysis Module
# Integrated from mahmood789's NMA Bayesian SMD and 786MIIIBayesianLLM apps
# Part of CBAMMR v8.12.0 Massive Improvements
#
# This module provides comprehensive Bayesian meta-analysis capabilities including:
# - Bayesian random-effects meta-analysis
# - Bayesian network meta-analysis
# - Prior specification and sensitivity analysis
# - MCMC diagnostics and convergence assessment
# - Posterior summaries with credible intervals
# - Bayesian model comparison (DIC, WAIC)

#' Bayesian Random-Effects Meta-Analysis
#'
#' Performs Bayesian random-effects meta-analysis using JAGS.
#'
#' @param yi Vector of effect sizes
#' @param sei Vector of standard errors
#' @param studlab Optional vector of study labels
#' @param prior_mean Prior mean for overall effect (default: 0)
#' @param prior_sd Prior SD for overall effect (default: 10, weakly informative)
#' @param prior_tau Prior for between-study heterogeneity (default: "uniform", alternatives: "half-normal", "half-cauchy")
#' @param tau_max Maximum value for tau prior (default: 2)
#' @param n_iter Number of MCMC iterations (default: 50000)
#' @param n_burnin Number of burn-in iterations (default: 10000)
#' @param n_chains Number of MCMC chains (default: 3)
#' @param n_thin Thinning interval (default: 5)
#'
#' @return Object of class "cbamm_bayesian_meta" containing:
#'   \item{posterior}{Posterior samples for parameters}
#'   \item{summary}{Posterior summaries (mean, median, 95% CrI)}
#'   \item{diagnostics}{MCMC diagnostics (Rhat, effective sample size)}
#'   \item{dic}{Deviance Information Criterion}
#'   \item{model_code}{JAGS model code}
#'   \item{data}{Original data}
#'   \item{priors}{Prior specifications}
#'
#' @examples
#' \dontrun{
#' # Bayesian meta-analysis
#' result <- cbamm_bayesian_meta(
#'   yi = c(0.3, 0.5, 0.2, 0.4),
#'   sei = c(0.1, 0.12, 0.09, 0.11),
#'   studlab = c("Study 1", "Study 2", "Study 3", "Study 4"),
#'   prior_tau = "half-cauchy"
#' )
#' print(result)
#' plot(result)
#' }
#'
#' @export
cbamm_bayesian_meta <- function(yi, sei, studlab = NULL,
                                 prior_mean = 0, prior_sd = 10,
                                 prior_tau = "uniform", tau_max = 2,
                                 n_iter = 50000, n_burnin = 10000,
                                 n_chains = 3, n_thin = 5) {

  # Check if rjags is available
  if (!requireNamespace("rjags", quietly = TRUE)) {
    stop("Package 'rjags' is required. Please install JAGS from https://mcmc-jags.sourceforge.io/ and then install.packages('rjags')")
  }

  # Input validation
  if (length(yi) != length(sei)) {
    stop("yi and sei must have the same length")
  }

  if (any(sei <= 0)) {
    stop("All standard errors must be positive")
  }

  # Study labels
  if (is.null(studlab)) {
    studlab <- paste0("Study ", seq_along(yi))
  }

  n_studies <- length(yi)

  # Create JAGS model code based on prior choice
  tau_prior_code <- switch(prior_tau,
    "uniform" = sprintf("tau ~ dunif(0, %f)", tau_max),
    "half-normal" = sprintf("tau ~ dnorm(0, 0.25)T(0,%f)", tau_max),
    "half-cauchy" = sprintf("tau <- abs(tau_raw)\ntau_raw ~ dt(0, 1, 1)T(-%f,%f)", tau_max, tau_max),
    stop("prior_tau must be 'uniform', 'half-normal', or 'half-cauchy'")
  )

  model_code <- sprintf("
model {
  # Likelihood
  for (i in 1:n) {
    yi[i] ~ dnorm(theta[i], prec_i[i])
    prec_i[i] <- 1 / (sei[i] * sei[i])

    # Random effects
    theta[i] ~ dnorm(mu, tau_prec)
  }

  # Priors
  mu ~ dnorm(%f, %f)
  %s
  tau_prec <- 1 / (tau * tau)
  tau2 <- tau * tau

  # I-squared (for monitoring)
  I2 <- tau2 / (tau2 + mean(sei[]) * mean(sei[]))
}
", prior_mean, 1/(prior_sd * prior_sd), tau_prior_code)

  # Prepare data for JAGS
  jags_data <- list(
    n = n_studies,
    yi = yi,
    sei = sei
  )

  # Parameters to monitor
  params <- c("mu", "tau", "tau2", "theta", "I2")

  # Run JAGS
  message("Running Bayesian meta-analysis with JAGS...")
  message(sprintf("  Iterations: %d (burn-in: %d)", n_iter, n_burnin))
  message(sprintf("  Chains: %d, Thinning: %d", n_chains, n_thin))

  jags_model <- rjags::jags.model(
    textConnection(model_code),
    data = jags_data,
    n.chains = n_chains,
    quiet = TRUE
  )

  # Burn-in
  update(jags_model, n_burnin, progress.bar = "none")

  # Sampling
  samples <- rjags::coda.samples(
    jags_model,
    variable.names = params,
    n.iter = n_iter,
    thin = n_thin,
    progress.bar = "none"
  )

  # Extract posterior summaries
  summary_stats <- summary(samples)

  # Calculate diagnostics
  gelman_diag <- coda::gelman.diag(samples, multivariate = FALSE)
  effectiveSize <- coda::effectiveSize(samples)

  # Extract DIC
  dic <- rjags::dic.samples(jags_model, n.iter = 1000, type = "pD", progress.bar = "none")

  # Create result object
  result <- list(
    posterior = samples,
    summary = summary_stats,
    diagnostics = list(
      gelman_rhat = gelman_diag$psrf,
      effective_size = effectiveSize
    ),
    dic = sum(dic$deviance) + sum(dic$penalty),
    model_code = model_code,
    data = data.frame(
      study = studlab,
      yi = yi,
      sei = sei
    ),
    priors = list(
      mu_mean = prior_mean,
      mu_sd = prior_sd,
      tau_type = prior_tau,
      tau_max = tau_max
    ),
    mcmc_settings = list(
      n_iter = n_iter,
      n_burnin = n_burnin,
      n_chains = n_chains,
      n_thin = n_thin
    )
  )

  class(result) <- "cbamm_bayesian_meta"
  return(result)
}


#' Bayesian Network Meta-Analysis
#'
#' Performs Bayesian network meta-analysis using JAGS with consistency model.
#'
#' @param data Data frame with arm-level data
#' @param studyvar Name of study variable
#' @param treatvar Name of treatment variable
#' @param mean_var Name of mean outcome variable
#' @param sd_var Name of standard deviation variable
#' @param n_var Name of sample size variable
#' @param reference Reference treatment (if NULL, uses first alphabetically)
#' @param prior_mean Prior mean for treatment effects (default: 0)
#' @param prior_sd Prior SD for treatment effects (default: 15)
#' @param prior_tau Prior for between-study heterogeneity (default: "uniform")
#' @param tau_max Maximum value for tau prior (default: 2)
#' @param n_iter Number of MCMC iterations (default: 50000)
#' @param n_burnin Number of burn-in iterations (default: 10000)
#' @param n_chains Number of MCMC chains (default: 3)
#'
#' @return Object of class "cbamm_bayesian_nma" containing posterior summaries,
#'   treatment rankings, and model diagnostics
#'
#' @examples
#' \dontrun{
#' # Bayesian NMA
#' result <- cbamm_bayesian_nma(
#'   data = nma_data,
#'   studyvar = "study",
#'   treatvar = "treatment",
#'   mean_var = "mean",
#'   sd_var = "sd",
#'   n_var = "n"
#' )
#' }
#'
#' @export
cbamm_bayesian_nma <- function(data, studyvar, treatvar, mean_var, sd_var, n_var,
                               reference = NULL,
                               prior_mean = 0, prior_sd = 15,
                               prior_tau = "uniform", tau_max = 2,
                               n_iter = 50000, n_burnin = 10000, n_chains = 3) {

  # Check if gemtc is available (BUGSnet alternative)
  if (!requireNamespace("rjags", quietly = TRUE)) {
    stop("Package 'rjags' is required for Bayesian NMA")
  }

  # Prepare data
  studies <- unique(data[[studyvar]])
  treatments <- sort(unique(data[[treatvar]]))
  n_studies <- length(studies)
  n_treatments <- length(treatments)

  # Set reference treatment
  if (is.null(reference)) {
    reference <- treatments[1]
  }

  if (!reference %in% treatments) {
    stop("Reference treatment not found in data")
  }

  # Create treatment indices
  treat_idx <- match(data[[treatvar]], treatments)
  study_idx <- match(data[[studyvar]], studies)

  # Calculate standardized mean differences
  study_list <- split(data, data[[studyvar]])

  # Prepare contrast-level data
  contrasts <- lapply(study_list, function(study_data) {
    if (nrow(study_data) < 2) return(NULL)

    # Get reference arm (first in study)
    ref_arm <- study_data[1, ]

    # Calculate contrasts vs reference
    contrasts_list <- lapply(2:nrow(study_data), function(i) {
      comp_arm <- study_data[i, ]

      # Calculate SMD
      pooled_sd <- sqrt(((ref_arm[[n_var]] - 1) * ref_arm[[sd_var]]^2 +
                          (comp_arm[[n_var]] - 1) * comp_arm[[sd_var]]^2) /
                         (ref_arm[[n_var]] + comp_arm[[n_var]] - 2))

      smd <- (comp_arm[[mean_var]] - ref_arm[[mean_var]]) / pooled_sd
      se_smd <- sqrt(1/ref_arm[[n_var]] + 1/comp_arm[[n_var]] +
                      smd^2 / (2 * (ref_arm[[n_var]] + comp_arm[[n_var]])))

      data.frame(
        study = ref_arm[[studyvar]],
        treat1 = ref_arm[[treatvar]],
        treat2 = comp_arm[[treatvar]],
        smd = smd,
        se = se_smd
      )
    })

    do.call(rbind, contrasts_list)
  })

  contrast_data <- do.call(rbind, contrasts)
  contrast_data$t1_idx <- match(contrast_data$treat1, treatments)
  contrast_data$t2_idx <- match(contrast_data$treat2, treatments)
  contrast_data$study_idx <- match(contrast_data$study, studies)

  # JAGS model for consistency NMA
  tau_prior_code <- switch(prior_tau,
    "uniform" = sprintf("tau ~ dunif(0, %f)", tau_max),
    "half-normal" = sprintf("tau ~ dnorm(0, 0.25)T(0,%f)", tau_max),
    "half-cauchy" = sprintf("tau <- abs(tau_raw)\ntau_raw ~ dt(0, 1, 1)T(-%f,%f)", tau_max, tau_max),
    stop("prior_tau must be 'uniform', 'half-normal', or 'half-cauchy'")
  )

  ref_idx <- which(treatments == reference)

  model_code <- sprintf("
model {
  # Likelihood
  for (i in 1:n_contrasts) {
    smd[i] ~ dnorm(delta[i], prec[i])
    prec[i] <- 1 / (se[i] * se[i])

    # Consistency model
    delta[i] <- d[t2[i]] - d[t1[i]] + sw[study_idx[i], t1[i]] - sw[study_idx[i], t2[i]]
  }

  # Random effects for multi-arm studies
  for (s in 1:n_studies) {
    for (t in 1:n_treats) {
      sw[s, t] ~ dnorm(0, tau_prec)
    }
  }

  # Treatment effects (relative to reference)
  d[%d] <- 0  # Reference treatment
  for (t in 1:n_treats) {
    d_prior[t] ~ dnorm(%f, %f)
  }
  for (t in 1:%d) {
    d[t] <- d_prior[t]
  }
  for (t in %d:n_treats) {
    d[t] <- d_prior[t]
  }

  # Heterogeneity prior
  %s
  tau_prec <- 1 / (tau * tau)
  tau2 <- tau * tau

  # Treatment rankings
  for (t in 1:n_treats) {
    for (t2 in 1:n_treats) {
      better[t, t2] <- step(d[t] - d[t2])
    }
    rank[t] <- n_treats + 1 - sum(better[t, ])
    best[t] <- equals(rank[t], 1)
  }

  # SUCRA (Surface Under Cumulative Ranking curve)
  for (t in 1:n_treats) {
    for (r in 1:(n_treats-1)) {
      cumrank[t, r] <- sum(better[t, ]) >= r
    }
    sucra[t] <- sum(cumrank[t, ]) / (n_treats - 1)
  }
}
", ref_idx, prior_mean, 1/(prior_sd * prior_sd), ref_idx - 1, ref_idx + 1, tau_prior_code)

  # Prepare data for JAGS
  jags_data <- list(
    n_contrasts = nrow(contrast_data),
    n_studies = n_studies,
    n_treats = n_treatments,
    smd = contrast_data$smd,
    se = contrast_data$se,
    t1 = contrast_data$t1_idx,
    t2 = contrast_data$t2_idx,
    study_idx = contrast_data$study_idx
  )

  # Parameters to monitor
  params <- c("d", "tau", "tau2", "rank", "sucra", "best")

  # Run JAGS
  message("Running Bayesian NMA with JAGS...")
  message(sprintf("  %d treatments, %d studies, %d contrasts",
                  n_treatments, n_studies, nrow(contrast_data)))

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

  # Extract summaries
  summary_stats <- summary(samples)

  # Treatment effects summary
  d_indices <- grep("^d\\[", rownames(summary_stats$statistics))
  treatment_effects <- data.frame(
    treatment = treatments,
    mean = summary_stats$statistics[d_indices, "Mean"],
    sd = summary_stats$statistics[d_indices, "SD"],
    lower_95 = summary_stats$quantiles[d_indices, "2.5%"],
    median = summary_stats$quantiles[d_indices, "50%"],
    upper_95 = summary_stats$quantiles[d_indices, "97.5%"]
  )

  # SUCRA scores
  sucra_indices <- grep("^sucra\\[", rownames(summary_stats$statistics))
  sucra_scores <- data.frame(
    treatment = treatments,
    sucra = summary_stats$statistics[sucra_indices, "Mean"]
  )
  sucra_scores <- sucra_scores[order(-sucra_scores$sucra), ]

  # Probability of being best
  best_indices <- grep("^best\\[", rownames(summary_stats$statistics))
  prob_best <- data.frame(
    treatment = treatments,
    prob_best = summary_stats$statistics[best_indices, "Mean"]
  )
  prob_best <- prob_best[order(-prob_best$prob_best), ]

  # DIC
  dic <- rjags::dic.samples(jags_model, n.iter = 1000, type = "pD", progress.bar = "none")

  result <- list(
    posterior = samples,
    summary = summary_stats,
    treatment_effects = treatment_effects,
    sucra_scores = sucra_scores,
    prob_best = prob_best,
    dic = sum(dic$deviance) + sum(dic$penalty),
    reference = reference,
    treatments = treatments,
    model_code = model_code,
    data = contrast_data
  )

  class(result) <- "cbamm_bayesian_nma"
  return(result)
}


#' Prior Sensitivity Analysis
#'
#' Performs sensitivity analysis by running Bayesian meta-analysis with different priors.
#'
#' @param yi Vector of effect sizes
#' @param sei Vector of standard errors
#' @param studlab Optional vector of study labels
#' @param prior_scenarios List of prior scenarios (default: skeptical, neutral, enthusiastic)
#' @param n_iter Number of MCMC iterations
#' @param n_burnin Number of burn-in iterations
#' @param n_chains Number of chains
#'
#' @return Object of class "cbamm_prior_sensitivity" with results for each scenario
#'
#' @examples
#' \dontrun{
#' sensitivity <- cbamm_prior_sensitivity(
#'   yi = c(0.3, 0.5, 0.2),
#'   sei = c(0.1, 0.12, 0.09)
#' )
#' }
#'
#' @export
cbamm_prior_sensitivity <- function(yi, sei, studlab = NULL,
                                    prior_scenarios = NULL,
                                    n_iter = 20000, n_burnin = 5000, n_chains = 3) {

  # Default prior scenarios
  if (is.null(prior_scenarios)) {
    prior_scenarios <- list(
      skeptical = list(prior_mean = 0, prior_sd = 0.5, prior_tau = "half-normal", tau_max = 0.5),
      neutral = list(prior_mean = 0, prior_sd = 10, prior_tau = "uniform", tau_max = 2),
      enthusiastic = list(prior_mean = 0.5, prior_sd = 1, prior_tau = "uniform", tau_max = 1)
    )
  }

  # Run analysis for each prior scenario
  results <- lapply(names(prior_scenarios), function(scenario_name) {
    message(sprintf("\nRunning scenario: %s", scenario_name))
    scenario <- prior_scenarios[[scenario_name]]

    result <- cbamm_bayesian_meta(
      yi = yi,
      sei = sei,
      studlab = studlab,
      prior_mean = scenario$prior_mean,
      prior_sd = scenario$prior_sd,
      prior_tau = scenario$prior_tau,
      tau_max = scenario$tau_max,
      n_iter = n_iter,
      n_burnin = n_burnin,
      n_chains = n_chains
    )

    list(
      scenario = scenario_name,
      parameters = scenario,
      result = result
    )
  })

  names(results) <- names(prior_scenarios)

  # Create comparison table
  comparison <- do.call(rbind, lapply(results, function(r) {
    summary_mu <- r$result$summary$statistics["mu", ]
    summary_tau <- r$result$summary$statistics["tau", ]

    data.frame(
      scenario = r$scenario,
      mu_mean = summary_mu["Mean"],
      mu_lower = r$result$summary$quantiles["mu", "2.5%"],
      mu_upper = r$result$summary$quantiles["mu", "97.5%"],
      tau_mean = summary_tau["Mean"],
      tau_lower = r$result$summary$quantiles["tau", "2.5%"],
      tau_upper = r$result$summary$quantiles["tau", "97.5%"],
      dic = r$result$dic
    )
  }))

  output <- list(
    results = results,
    comparison = comparison,
    data = data.frame(yi = yi, sei = sei, studlab = studlab %||% paste0("Study ", seq_along(yi)))
  )

  class(output) <- "cbamm_prior_sensitivity"
  return(output)
}


#' MCMC Convergence Diagnostics
#'
#' Comprehensive MCMC convergence diagnostics including trace plots,
#' Gelman-Rubin statistics, and effective sample sizes.
#'
#' @param fit Object of class "cbamm_bayesian_meta" or "cbamm_bayesian_nma"
#' @param parameters Parameters to check (default: main parameters)
#'
#' @return List with diagnostic plots and statistics
#'
#' @examples
#' \dontrun{
#' fit <- cbamm_bayesian_meta(yi = c(0.3, 0.5), sei = c(0.1, 0.12))
#' diagnostics <- cbamm_mcmc_diagnostics(fit)
#' }
#'
#' @export
cbamm_mcmc_diagnostics <- function(fit, parameters = NULL) {

  if (!inherits(fit, c("cbamm_bayesian_meta", "cbamm_bayesian_nma"))) {
    stop("fit must be of class 'cbamm_bayesian_meta' or 'cbamm_bayesian_nma'")
  }

  # Extract posterior samples
  posterior <- fit$posterior

  # Default parameters to check
  if (is.null(parameters)) {
    if (inherits(fit, "cbamm_bayesian_meta")) {
      parameters <- c("mu", "tau", "tau2")
    } else {
      parameters <- c("d", "tau", "tau2")
    }
  }

  # Filter samples for requested parameters
  param_pattern <- paste0("^(", paste(parameters, collapse = "|"), ")")
  all_vars <- colnames(posterior[[1]])
  selected_vars <- grep(param_pattern, all_vars, value = TRUE)

  # Calculate diagnostics
  gelman <- coda::gelman.diag(posterior[, selected_vars], multivariate = FALSE)
  ess <- coda::effectiveSize(posterior[, selected_vars])

  # Create diagnostic summary
  diagnostic_summary <- data.frame(
    parameter = selected_vars,
    rhat = gelman$psrf[, "Point est."],
    rhat_upper = gelman$psrf[, "Upper C.I."],
    ess = ess,
    convergence = ifelse(gelman$psrf[, "Point est."] < 1.1 & ess > 100, "PASS", "WARN")
  )

  # Autocorrelation
  autocorr <- lapply(selected_vars, function(param) {
    coda::autocorr(posterior[, param], lags = c(0, 1, 5, 10, 50))
  })
  names(autocorr) <- selected_vars

  result <- list(
    summary = diagnostic_summary,
    gelman_rubin = gelman,
    effective_size = ess,
    autocorrelation = autocorr,
    posterior = posterior
  )

  class(result) <- "cbamm_mcmc_diagnostics"
  return(result)
}


#' Posterior Predictive Check
#'
#' Generates posterior predictive distributions and checks model fit.
#'
#' @param fit Bayesian meta-analysis fit object
#' @param n_pred Number of posterior predictive samples (default: 1000)
#'
#' @return Object with posterior predictive distributions and p-values
#'
#' @export
cbamm_posterior_predictive <- function(fit, n_pred = 1000) {

  if (!inherits(fit, "cbamm_bayesian_meta")) {
    stop("fit must be of class 'cbamm_bayesian_meta'")
  }

  # Extract posterior samples
  posterior <- fit$posterior
  posterior_matrix <- as.matrix(posterior)

  # Get mu and tau samples
  mu_samples <- posterior_matrix[, "mu"]
  tau_samples <- posterior_matrix[, "tau"]

  # Sample from posterior
  n_samples <- length(mu_samples)
  sample_idx <- sample(n_samples, n_pred, replace = TRUE)

  # Generate posterior predictive samples
  pred_samples <- rnorm(n_pred,
                        mean = mu_samples[sample_idx],
                        sd = tau_samples[sample_idx])

  # Calculate posterior predictive p-values for observed data
  observed_yi <- fit$data$yi
  ppv <- sapply(observed_yi, function(y) {
    mean(abs(pred_samples - mean(pred_samples)) >= abs(y - mean(pred_samples)))
  })

  result <- list(
    predictive_samples = pred_samples,
    predictive_mean = mean(pred_samples),
    predictive_sd = sd(pred_samples),
    predictive_quantiles = quantile(pred_samples, probs = c(0.025, 0.25, 0.5, 0.75, 0.975)),
    pp_pvalues = data.frame(
      study = fit$data$study,
      yi = observed_yi,
      pp_pvalue = ppv,
      flag = ifelse(ppv < 0.05, "outlier", "ok")
    )
  )

  class(result) <- "cbamm_posterior_predictive"
  return(result)
}


#' Comprehensive Bayesian Meta-Analysis
#'
#' Performs complete Bayesian meta-analysis workflow including main analysis,
#' sensitivity analysis, diagnostics, and posterior predictive checks.
#'
#' @param yi Vector of effect sizes
#' @param sei Vector of standard errors
#' @param studlab Optional vector of study labels
#' @param prior_mean Prior mean (default: 0)
#' @param prior_sd Prior SD (default: 10)
#' @param prior_tau Prior for tau (default: "uniform")
#' @param sensitivity Perform prior sensitivity analysis (default: TRUE)
#' @param diagnostics Perform MCMC diagnostics (default: TRUE)
#' @param predictive Perform posterior predictive checks (default: TRUE)
#' @param n_iter Number of iterations (default: 50000)
#' @param n_burnin Burn-in (default: 10000)
#' @param n_chains Number of chains (default: 3)
#'
#' @return Comprehensive analysis object with all results
#'
#' @examples
#' \dontrun{
#' result <- cbamm_bayesian_analyze(
#'   yi = c(0.3, 0.5, 0.2, 0.4, 0.6),
#'   sei = c(0.1, 0.12, 0.09, 0.11, 0.13),
#'   studlab = paste0("Study ", 1:5)
#' )
#' print(result)
#' }
#'
#' @export
cbamm_bayesian_analyze <- function(yi, sei, studlab = NULL,
                                   prior_mean = 0, prior_sd = 10, prior_tau = "uniform",
                                   sensitivity = TRUE, diagnostics = TRUE, predictive = TRUE,
                                   n_iter = 50000, n_burnin = 10000, n_chains = 3) {

  message("=== Comprehensive Bayesian Meta-Analysis ===\n")

  # Main analysis
  message("1. Running main Bayesian meta-analysis...")
  main_fit <- cbamm_bayesian_meta(
    yi = yi,
    sei = sei,
    studlab = studlab,
    prior_mean = prior_mean,
    prior_sd = prior_sd,
    prior_tau = prior_tau,
    n_iter = n_iter,
    n_burnin = n_burnin,
    n_chains = n_chains
  )

  result <- list(main = main_fit)

  # Sensitivity analysis
  if (sensitivity) {
    message("\n2. Running prior sensitivity analysis...")
    sens_result <- cbamm_prior_sensitivity(
      yi = yi,
      sei = sei,
      studlab = studlab,
      n_iter = 20000,
      n_burnin = 5000,
      n_chains = n_chains
    )
    result$sensitivity <- sens_result
  }

  # Diagnostics
  if (diagnostics) {
    message("\n3. Computing MCMC diagnostics...")
    diag_result <- cbamm_mcmc_diagnostics(main_fit)
    result$diagnostics <- diag_result
  }

  # Posterior predictive
  if (predictive) {
    message("\n4. Performing posterior predictive checks...")
    pred_result <- cbamm_posterior_predictive(main_fit)
    result$predictive <- pred_result
  }

  message("\n=== Analysis Complete ===")

  class(result) <- "cbamm_bayesian_analyze"
  return(result)
}


# S3 Methods ----

#' @export
print.cbamm_bayesian_meta <- function(x, ...) {
  cat("\n=== Bayesian Random-Effects Meta-Analysis ===\n\n")

  cat("Data:\n")
  cat(sprintf("  Number of studies: %d\n", nrow(x$data)))

  cat("\nPriors:\n")
  cat(sprintf("  Overall effect: N(%g, %g)\n", x$priors$mu_mean, x$priors$mu_sd))
  cat(sprintf("  Heterogeneity: %s (max = %g)\n", x$priors$tau_type, x$priors$tau_max))

  cat("\nMCMC Settings:\n")
  cat(sprintf("  Iterations: %d (burn-in: %d)\n", x$mcmc_settings$n_iter, x$mcmc_settings$n_burnin))
  cat(sprintf("  Chains: %d, Thinning: %d\n", x$mcmc_settings$n_chains, x$mcmc_settings$n_thin))

  cat("\nPosterior Summaries:\n")
  cat("\nOverall Effect (mu):\n")
  mu_stats <- x$summary$statistics["mu", ]
  mu_quant <- x$summary$quantiles["mu", ]
  cat(sprintf("  Mean: %.3f, SD: %.3f\n", mu_stats["Mean"], mu_stats["SD"]))
  cat(sprintf("  95%% CrI: [%.3f, %.3f]\n", mu_quant["2.5%"], mu_quant["97.5%"]))

  cat("\nHeterogeneity (tau):\n")
  tau_stats <- x$summary$statistics["tau", ]
  tau_quant <- x$summary$quantiles["tau", ]
  cat(sprintf("  Mean: %.3f, SD: %.3f\n", tau_stats["Mean"], tau_stats["SD"]))
  cat(sprintf("  95%% CrI: [%.3f, %.3f]\n", tau_quant["2.5%"], tau_quant["97.5%"]))

  if ("I2" %in% rownames(x$summary$statistics)) {
    I2_stats <- x$summary$statistics["I2", ]
    cat(sprintf("\nI-squared: %.1f%%\n", I2_stats["Mean"] * 100))
  }

  cat("\nConvergence Diagnostics:\n")
  rhat_mu <- x$diagnostics$gelman_rhat["mu", "Point est."]
  ess_mu <- x$diagnostics$effective_size["mu"]
  cat(sprintf("  Rhat (mu): %.3f %s\n", rhat_mu, ifelse(rhat_mu < 1.1, "[GOOD]", "[CHECK]")))
  cat(sprintf("  Effective sample size (mu): %.0f\n", ess_mu))

  cat(sprintf("\nDIC: %.2f\n", x$dic))

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_bayesian_nma <- function(x, ...) {
  cat("\n=== Bayesian Network Meta-Analysis ===\n\n")

  cat(sprintf("Number of treatments: %d\n", length(x$treatments)))
  cat(sprintf("Reference treatment: %s\n", x$reference))
  cat(sprintf("Number of contrasts: %d\n\n", nrow(x$data)))

  cat("Treatment Effects (vs. reference):\n")
  print(x$treatment_effects, digits = 3, row.names = FALSE)

  cat("\n\nSUCRA Scores (Treatment Rankings):\n")
  print(head(x$sucra_scores, 10), digits = 3, row.names = FALSE)

  cat("\n\nProbability of Being Best Treatment:\n")
  print(head(x$prob_best, 5), digits = 3, row.names = FALSE)

  cat(sprintf("\n\nDIC: %.2f\n", x$dic))

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_prior_sensitivity <- function(x, ...) {
  cat("\n=== Prior Sensitivity Analysis ===\n\n")

  cat("Scenarios compared:\n")
  print(x$comparison, digits = 3, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  - Similar results across scenarios indicate robustness\n")
  cat("  - Large differences suggest prior sensitivity\n")
  cat("  - Choose scenario based on substantive knowledge\n\n")

  invisible(x)
}


#' @export
print.cbamm_mcmc_diagnostics <- function(x, ...) {
  cat("\n=== MCMC Convergence Diagnostics ===\n\n")

  print(x$summary, digits = 3, row.names = FALSE)

  cat("\nInterpretation:\n")
  cat("  - Rhat < 1.1: Good convergence\n")
  cat("  - ESS > 100: Adequate sample size\n")
  cat("  - All PASS: Analysis is reliable\n\n")

  invisible(x)
}


#' @export
print.cbamm_posterior_predictive <- function(x, ...) {
  cat("\n=== Posterior Predictive Check ===\n\n")

  cat("Predictive Distribution:\n")
  cat(sprintf("  Mean: %.3f\n", x$predictive_mean))
  cat(sprintf("  SD: %.3f\n", x$predictive_sd))
  cat("\n  Quantiles:\n")
  print(x$predictive_quantiles, digits = 3)

  cat("\n\nOutlier Detection (PP p-value < 0.05):\n")
  outliers <- x$pp_pvalues[x$pp_pvalues$flag == "outlier", ]
  if (nrow(outliers) > 0) {
    print(outliers, row.names = FALSE, digits = 3)
  } else {
    cat("  No outliers detected\n")
  }

  cat("\n")
  invisible(x)
}


#' @export
print.cbamm_bayesian_analyze <- function(x, ...) {
  cat("\n======================================\n")
  cat("  COMPREHENSIVE BAYESIAN ANALYSIS\n")
  cat("======================================\n")

  cat("\n1. MAIN ANALYSIS:\n")
  print(x$main)

  if (!is.null(x$sensitivity)) {
    cat("\n2. SENSITIVITY ANALYSIS:\n")
    print(x$sensitivity)
  }

  if (!is.null(x$diagnostics)) {
    cat("\n3. MCMC DIAGNOSTICS:\n")
    print(x$diagnostics)
  }

  if (!is.null(x$predictive)) {
    cat("\n4. POSTERIOR PREDICTIVE CHECK:\n")
    print(x$predictive)
  }

  cat("\n======================================\n")
  cat("  ANALYSIS COMPLETE\n")
  cat("======================================\n\n")

  invisible(x)
}


# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x
