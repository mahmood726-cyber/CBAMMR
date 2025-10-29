#' Bayesian Methods for CBAMMR
#'
#' Distribution-free Bayesian methods for meta-analysis
#'
#' @name bayesian-methods
#' @keywords internal
NULL

#' Bayesian Bootstrap for Meta-Analysis
#'
#' Performs Bayesian bootstrap to obtain posterior distribution of the pooled
#' effect size. Unlike frequentist bootstrap, Bayesian bootstrap assigns random
#' weights from a Dirichlet distribution, providing a full posterior distribution.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param n_boot Number of bootstrap samples (default: 10000)
#' @param prior_weight Prior weight for the Dirichlet distribution (default: 1, uniform)
#' @param conf_level Confidence level for credible intervals (default: 0.95)
#'
#' @return An object of class "cbamm_bayesian_bootstrap" containing:
#' \describe{
#'   \item{posterior_mean}{Posterior mean of the effect size}
#'   \item{posterior_median}{Posterior median}
#'   \item{posterior_sd}{Posterior standard deviation}
#'   \item{credible_interval}{Bayesian credible interval}
#'   \item{posterior_samples}{Vector of posterior samples}
#'   \item{conf_level}{Confidence level used}
#'   \item{n_boot}{Number of bootstrap samples}
#'   \item{prior_weight}{Prior weight used}
#' }
#'
#' @details
#' The Bayesian bootstrap (Rubin, 1981) is a Bayesian analog of the bootstrap.
#' Instead of resampling with replacement, it assigns random weights to observations
#' drawn from a Dirichlet distribution.
#'
#' **Advantages:**
#' - Full posterior distribution
#' - Incorporates prior information
#' - Natural uncertainty quantification
#' - More principled than frequentist bootstrap
#'
#' **When to use:**
#' - When you want a Bayesian interpretation
#' - For decision-theoretic approaches
#' - When incorporating prior knowledge
#' - For full posterior inference
#'
#' @references
#' Rubin DB. (1981). The Bayesian bootstrap. *The Annals of Statistics*, 9(1), 130-134.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' result <- cbamm_bayesian_bootstrap(yi, vi, n_boot = 5000)
#' print(result)
#' plot(result)
#' }
cbamm_bayesian_bootstrap <- function(yi, vi, n_boot = 10000,
                                     prior_weight = 1, conf_level = 0.95) {
  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }
  if (n_boot < 100) {
    stop("n_boot must be at least 100")
  }
  if (prior_weight <= 0) {
    stop("prior_weight must be positive")
  }
  if (conf_level <= 0 || conf_level >= 1) {
    stop("conf_level must be between 0 and 1")
  }

  n <- length(yi)
  posterior_samples <- numeric(n_boot)

  # Precision weights
  precision <- 1 / vi

  # Bayesian bootstrap
  for (i in seq_len(n_boot)) {
    # Draw Dirichlet weights
    alpha <- rep(prior_weight, n)
    dirichlet_weights <- rgamma(n, shape = alpha, rate = 1)
    dirichlet_weights <- dirichlet_weights / sum(dirichlet_weights)

    # Weighted average with Dirichlet weights and precision
    combined_weights <- dirichlet_weights * precision
    posterior_samples[i] <- sum(combined_weights * yi) / sum(combined_weights)
  }

  # Posterior summaries
  posterior_mean <- mean(posterior_samples)
  posterior_median <- median(posterior_samples)
  posterior_sd <- sd(posterior_samples)

  # Credible interval
  alpha_level <- (1 - conf_level) / 2
  credible_interval <- quantile(posterior_samples,
                                probs = c(alpha_level, 1 - alpha_level))

  # Prepare output
  result <- list(
    posterior_mean = posterior_mean,
    posterior_median = posterior_median,
    posterior_sd = posterior_sd,
    credible_interval = as.numeric(credible_interval),
    posterior_samples = posterior_samples,
    conf_level = conf_level,
    n_boot = n_boot,
    prior_weight = prior_weight,
    n_studies = n
  )

  class(result) <- "cbamm_bayesian_bootstrap"
  return(result)
}


#' @export
print.cbamm_bayesian_bootstrap <- function(x, ...) {
  cat("\nBayesian Bootstrap Meta-Analysis\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Posterior Summary:\n")
  cat("  Mean:   ", sprintf("%.4f", x$posterior_mean), "\n")
  cat("  Median: ", sprintf("%.4f", x$posterior_median), "\n")
  cat("  SD:     ", sprintf("%.4f", x$posterior_sd), "\n\n")

  cat(sprintf("%d%% Credible Interval: [%.4f, %.4f]\n",
              x$conf_level * 100,
              x$credible_interval[1],
              x$credible_interval[2]))

  cat("\nSampling Details:\n")
  cat("  Bootstrap samples:", format(x$n_boot, big.mark = ","), "\n")
  cat("  Prior weight:", x$prior_weight, "\n")
  cat("  Number of studies:", x$n_studies, "\n\n")

  cat("Interpretation:\n")
  if (x$credible_interval[1] > 0) {
    cat("  Strong evidence for positive effect (credible interval excludes 0)\n")
  } else if (x$credible_interval[2] < 0) {
    cat("  Strong evidence for negative effect (credible interval excludes 0)\n")
  } else {
    cat("  Credible interval includes 0 - effect uncertain\n")
  }

  invisible(x)
}


#' Bayesian Meta-Regression with Weakly Informative Priors
#'
#' Performs Bayesian meta-regression using simple MCMC with weakly informative priors.
#' Useful for exploring moderator effects with principled prior specification.
#'
#' @param yi Vector of effect sizes
#' @param vi Vector of sampling variances
#' @param X Design matrix for moderators (including intercept)
#' @param n_iter Number of MCMC iterations (default: 5000)
#' @param n_burnin Number of burn-in iterations (default: 1000)
#' @param prior_sd Prior standard deviation for regression coefficients (default: 10)
#'
#' @return An object of class "cbamm_bayesian_metareg" containing:
#' \describe{
#'   \item{beta_posterior}{Matrix of posterior samples for regression coefficients}
#'   \item{tau2_posterior}{Vector of posterior samples for heterogeneity}
#'   \item{beta_mean}{Posterior means of coefficients}
#'   \item{beta_ci}{95% credible intervals for coefficients}
#'   \item{tau2_mean}{Posterior mean of tau-squared}
#' }
#'
#' @details
#' Uses Metropolis-Hastings MCMC with weakly informative priors:
#' - Beta ~ Normal(0, prior_sd^2)
#' - Tau^2 ~ Inverse-Gamma(0.001, 0.001)
#'
#' **Advantages over frequentist meta-regression:**
#' - Full posterior distributions
#' - Incorporates prior knowledge
#' - Natural handling of uncertainty
#' - Can make probability statements
#'
#' @references
#' Sutton AJ, Abrams KR. (2001). Bayesian methods in meta-analysis and evidence synthesis.
#' *Statistical Methods in Medical Research*, 10(4), 277-303.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' yi <- c(0.5, 0.3, 0.7, 0.4, 0.6)
#' vi <- c(0.05, 0.04, 0.06, 0.05, 0.04)
#' X <- cbind(1, c(0, 0.5, 1, 0.3, 0.8))  # Intercept + moderator
#' result <- cbamm_bayesian_metareg(yi, vi, X, n_iter = 2000)
#' print(result)
#' }
cbamm_bayesian_metareg <- function(yi, vi, X, n_iter = 5000, n_burnin = 1000,
                                   prior_sd = 10) {
  # Input validation
  if (length(yi) != length(vi)) {
    stop("yi and vi must have the same length")
  }
  if (nrow(X) != length(yi)) {
    stop("Number of rows in X must equal length of yi")
  }
  if (n_iter < 1000) {
    stop("n_iter should be at least 1000")
  }
  if (n_burnin >= n_iter) {
    stop("n_burnin must be less than n_iter")
  }

  n <- length(yi)
  p <- ncol(X)

  # Initialize parameters
  beta <- rep(0, p)
  tau2 <- var(yi)

  # Storage for posterior samples
  n_save <- n_iter - n_burnin
  beta_posterior <- matrix(NA, nrow = n_save, ncol = p)
  tau2_posterior <- numeric(n_save)

  # MCMC
  accept_count <- 0
  save_idx <- 1

  for (iter in 1:n_iter) {
    # Update beta (Gibbs step)
    mu <- X %*% beta
    total_var <- vi + tau2
    W <- diag(1 / total_var)

    # Posterior precision and mean
    V_beta <- solve(t(X) %*% W %*% X + diag(1 / prior_sd^2, p))
    m_beta <- V_beta %*% (t(X) %*% W %*% yi)

    # Draw from multivariate normal
    beta <- m_beta + t(chol(V_beta)) %*% rnorm(p)

    # Update tau2 (Metropolis-Hastings)
    tau2_proposal <- tau2 * exp(rnorm(1, 0, 0.1))

    # Log-likelihood
    ll_current <- sum(dnorm(yi, mean = X %*% beta, sd = sqrt(vi + tau2), log = TRUE))
    ll_proposal <- sum(dnorm(yi, mean = X %*% beta, sd = sqrt(vi + tau2_proposal), log = TRUE))

    # Log-prior (inverse-gamma)
    lp_current <- -0.001 * log(tau2) - 0.001 / tau2
    lp_proposal <- -0.001 * log(tau2_proposal) - 0.001 / tau2_proposal

    # Accept/reject
    log_ratio <- ll_proposal + lp_proposal - ll_current - lp_current +
                 log(tau2_proposal) - log(tau2)  # Jacobian
    if (log(runif(1)) < log_ratio) {
      tau2 <- tau2_proposal
      if (iter > n_burnin) accept_count <- accept_count + 1
    }

    # Save after burn-in
    if (iter > n_burnin) {
      beta_posterior[save_idx, ] <- beta
      tau2_posterior[save_idx] <- tau2
      save_idx <- save_idx + 1
    }
  }

  # Posterior summaries
  beta_mean <- colMeans(beta_posterior)
  beta_ci <- apply(beta_posterior, 2, quantile, probs = c(0.025, 0.975))
  tau2_mean <- mean(tau2_posterior)
  tau2_ci <- quantile(tau2_posterior, probs = c(0.025, 0.975))

  # Acceptance rate
  acceptance_rate <- accept_count / n_save

  result <- list(
    beta_posterior = beta_posterior,
    tau2_posterior = tau2_posterior,
    beta_mean = beta_mean,
    beta_ci = beta_ci,
    tau2_mean = tau2_mean,
    tau2_ci = tau2_ci,
    acceptance_rate = acceptance_rate,
    n_iter = n_iter,
    n_burnin = n_burnin,
    n_studies = n,
    n_moderators = p
  )

  class(result) <- "cbamm_bayesian_metareg"
  return(result)
}


#' @export
print.cbamm_bayesian_metareg <- function(x, ...) {
  cat("\nBayesian Meta-Regression\n")
  cat("═══════════════════════════════════════\n\n")

  cat("Regression Coefficients:\n")
  for (i in 1:x$n_moderators) {
    cat(sprintf("  Beta[%d]: %.4f [%.4f, %.4f]\n",
                i, x$beta_mean[i], x$beta_ci[1, i], x$beta_ci[2, i]))
  }

  cat(sprintf("\nHeterogeneity (tau²): %.4f [%.4f, %.4f]\n",
              x$tau2_mean, x$tau2_ci[1], x$tau2_ci[2]))

  cat("\nMCMC Details:\n")
  cat("  Total iterations:", format(x$n_iter, big.mark = ","), "\n")
  cat("  Burn-in:", format(x$n_burnin, big.mark = ","), "\n")
  cat("  Acceptance rate:", sprintf("%.1f%%", x$acceptance_rate * 100), "\n")
  cat("  Number of studies:", x$n_studies, "\n")

  invisible(x)
}
