# Bayesian Analysis Functions for CBAMMR

#' Run Bayesian Meta-Analysis
#'
#' Fit Bayesian models with brms (with stacking) or JAGS fallback
#'
#' @param data Data frame with yi, se, and covariates
#' @param config Configuration object
#' @param features Feature availability list
#'
#' @return List with Bayesian results
#' @keywords internal
run_bayesian_analysis <- function(data, config, features) {
  if (!config$use_bayesian) { cat("\n=== BAYESIAN ANALYSIS ===\nSkipped (disabled)\n"); return(NULL) }
  w_ext <- dplyr::coalesce(data$analysis_weights_grade, data$analysis_weights)
  if (isTRUE(features$bayesian)) {
    cat("\n=== BAYESIAN (brms) with stacking ===\n")
    bayes_data <- data %>% dplyr::mutate(study_type_fct = factor(study_type, levels=c("RCT","OBS","MR")), grade_numeric  = as.numeric(grade), w = w_ext)
    priors1 <- if (!is.null(config$bayes_priors)) config$bayes_priors else c(brms::prior(normal(0, 0.3), class = Intercept), brms::prior(normal(0, 0.2), class = b), brms::prior(student_t(3, 0, 0.3), class = sd))
    priors2 <- if (!is.null(config$bayes_priors_alt)) config$bayes_priors_alt else c(brms::prior(normal(0, 0.5), class = Intercept), brms::prior(normal(0, 0.3), class = b), brms::prior(student_t(3, 0, 0.5), class = sd))
    m1 <- safe_try(
      brms::brm(yi | se(se) ~ 1 + study_type_fct + grade_numeric + (1|study_id),
                data = bayes_data, family = gaussian(), prior = priors1,
                chains = config$bayes_chains, iter = config$bayes_iter,
                warmup = config$bayes_warmup, cores = config$n_cores,
                control = list(adapt_delta=0.98), seed = 1001, weights = w,
                save_pars = brms::save_pars(all = TRUE)),
      context = "brms model 1 (conservative priors)",
      return_on_error = NULL
    )
    m2 <- safe_try(
      brms::brm(yi | se(se) ~ 1 + study_type_fct + grade_numeric + (1|study_id),
                data = bayes_data, family = gaussian(), prior = priors2,
                chains = config$bayes_chains, iter = config$bayes_iter,
                warmup = config$bayes_warmup, cores = config$n_cores,
                control = list(adapt_delta=0.98), seed = 1002, weights = w,
                save_pars = brms::save_pars(all = TRUE)),
      context = "brms model 2 (moderate priors)",
      return_on_error = NULL
    )
    fits <- list()
    if (!is.null(m1)) {
      fits$cons <- m1
      rhats <- safe_try(brms::rhat(m1), context = "checking R-hat for brms model 1", return_on_error = NULL, warn = FALSE)
      if (!is.null(rhats) && any(rhats > 1.05, na.rm=TRUE)) warning("High R-hat in brms model 1.")
    }
    if (!is.null(m2)) {
      fits$mod <- m2
      rhats <- safe_try(brms::rhat(m2), context = "checking R-hat for brms model 2", return_on_error = NULL, warn = FALSE)
      if (!is.null(rhats) && any(rhats > 1.05, na.rm=TRUE)) warning("High R-hat in brms model 2.")
    }
    if (length(fits)) {
      llist <- lapply(fits, function(f) loo::loo(f, pointwise=TRUE))
      if (length(llist) > 1 && all(sapply(llist, function(x) inherits(x, "loo")))) sw <- loo::loo_model_weights(llist, method="stacking") else { sw <- rep(1/length(fits), length(fits)); names(sw) <- names(fits) }
      cat("Stacking weights: ", paste(sprintf("%s=%.2f", names(sw), sw), collapse=", "), "\n", sep="")
      draws <- lapply(fits, function(f) posterior::as_draws_df(f)[,"b_Intercept"])
      M <- min(sapply(draws, length)); set.seed(2024); mix <- c()
      for (i in seq_along(draws)) { take <- max(1, round(M * sw[i])); mix <- c(mix, draws[[i]][sample(seq_len(length(draws[[i]])), size = take, replace = TRUE)]) }
      eff <- exp(mix)
      cat(sprintf("Bayesian (brms) baseline %s: %.3f (95%% CrI %.3f–%.3f)\n", .cbamm_measure_meta(config$effect_measure)$effect_label, median(eff), quantile(eff,0.025), quantile(eff,0.975)))
      return(list(engine="brms", weights=sw, draws=mix, summary=list(median=median(eff), cri=c(quantile(eff,c(.025,.975))))))
    } else message("[brms] models failed — switching to JAGS fallback.")
  } else cat("\n=== BAYESIAN (brms) ===\nSkipped (not available)\n")

  if (!requireNamespace("rjags", quietly = TRUE)) { cat("\n=== BAYESIAN (JAGS) ===\nSkipped (rjags not available)\n"); return(NULL) }
  cat("\n=== BAYESIAN (JAGS fallback) ===\n")
  requireNamespace("rjags", quietly = TRUE)
  dd <- data %>% dplyr::mutate(is_obs = as.integer(study_type=="OBS"), is_mr  = as.integer(study_type=="MR"), grade_num = as.numeric(grade), study_idx = as.integer(factor(study_id)), w = w_ext)
  jdat <- list(N = nrow(dd), S = max(dd$study_idx), yi = dd$yi, se = dd$se, w = as.numeric(dd$w), is_obs = dd$is_obs, is_mr = dd$is_mr, grade = dd$grade_num, study = dd$study_idx)
  model_string <- "
  model{
    for(i in 1:N){
      prec[i] <- w[i] / pow(se[i], 2)
      yi[i] ~ dnorm(eta[i], prec[i])
      eta[i] <- mu + b_obs * is_obs[i] + b_mr * is_mr[i] + b_grade * grade[i] + u[study[i]]
    }
    for(s in 1:S){ u[s] ~ dnorm(0, tau_u) }
    mu ~ dnorm(0, pow(0.5, -2))
    b_obs ~ dnorm(0, pow(0.3, -2))
    b_mr  ~ dnorm(0, pow(0.3, -2))
    b_grade ~ dnorm(0, pow(0.3, -2))
    sigma_u ~ dunif(0, 1); tau_u <- pow(sigma_u, -2)
  }"
  jm <- rjags::jags.model(textConnection(model_string), data = jdat, n.chains = config$bayes_chains, quiet = TRUE)
  update(jm, config$bayes_warmup, progress.bar="none")
  sm <- rjags::coda.samples(jm, c("mu","b_obs","b_mr","b_grade","sigma_u"), n.iter = max(1, config$bayes_iter - config$bayes_warmup), thin = 2, progress.bar="none")
  draws <- safe_try(
    as.matrix(sm),
    context = "converting JAGS samples to matrix",
    return_on_error = NULL,
    warn = FALSE
  )
  if (is.null(draws)) {
    draws <- safe_try(
      coda::as.matrix.mcmc.list(sm),
      context = "converting JAGS samples to matrix (coda method)",
      return_on_error = NULL
    )
  }
  if (is.null(draws)) {
    warning("Could not convert JAGS samples to matrix; skipping Bayesian plot.")
    return(list(engine="jags", draws_mu=NULL, summary=NULL))
  }
  eff <- exp(draws[,"mu"])
  cat(sprintf("Bayesian (JAGS) baseline %s: %.3f (95%% CrI %.3f–%.3f)\n", .cbamm_measure_meta(config$effect_measure)$effect_label, median(eff), quantile(eff,0.025), quantile(eff,0.975)))
  list(engine="jags", draws_mu=draws[,"mu"], summary=list(median=median(eff), cri=c(quantile(eff,c(.025,.975)))))
}
