#' Simulate CBAMM Data for Hazard Ratios
#'
#' Generate simulated meta-analysis data with log-hazard ratios for testing
#'
#' @param n_rct Number of RCT studies
#' @param n_obs Number of observational studies
#' @param n_mr Number of Mendelian randomization studies
#' @param true_log_hr True log hazard ratio
#' @param seed Random seed
#'
#' @return A tibble with simulated study data
#' @export
#'
#' @examples
#' # Simulate 20 RCTs and 15 observational studies
#' data <- simulate_cbamm_data(n_rct = 20, n_obs = 15, n_mr = 5)
#' head(data)
simulate_cbamm_data <- function(n_rct = 18, n_obs = 18, n_mr = 8,
                                true_log_hr = log(0.90), seed = 42) {
  set.seed(seed)
  N <- n_rct + n_obs + n_mr
  study_type <- factor(c(rep("RCT", n_rct), rep("OBS", n_obs), rep("MR", n_mr)),
                       levels = c("RCT","OBS","MR"))
  study_id <- sprintf("Study_%02d", seq_len(N))

  se <- numeric(N)
  se[study_type=="RCT"] <- runif(sum(study_type=="RCT"), 0.05, 0.15)
  se[study_type=="OBS"] <- runif(sum(study_type=="OBS"), 0.06, 0.18)
  se[study_type=="MR"]  <- runif(sum(study_type=="MR"),  0.10, 0.25)

  true_effect <- numeric(N)
  true_effect[study_type=="RCT"] <- rnorm(sum(study_type=="RCT"), true_log_hr,       0.05)
  true_effect[study_type=="OBS"] <- rnorm(sum(study_type=="OBS"), true_log_hr - 0.10, 0.08)
  true_effect[study_type=="MR"]  <- rnorm(sum(study_type=="MR"),  true_log_hr - 0.05, 0.12)

  yi <- rnorm(N, true_effect, se)

  grade <- character(N)
  grade[study_type=="RCT"] <- sample(c("High","Moderate"), sum(study_type=="RCT"), TRUE, prob=c(0.7,0.3))
  grade[study_type=="OBS"] <- sample(c("Moderate","Low","Very low"), sum(study_type=="OBS"), TRUE, prob=c(0.3,0.5,0.2))
  grade[study_type=="MR"]  <- sample(c("Low","Very low"), sum(study_type=="MR"),  TRUE, prob=c(0.6,0.4))
  grade <- factor(grade, levels = c("High","Moderate","Low","Very low"))

  neg_ctrl <- numeric(N)
  neg_ctrl[study_type=="OBS"] <- rnorm(sum(study_type=="OBS"), -0.08, 0.04)
  neg_ctrl[study_type!="OBS"] <- rnorm(sum(study_type!="OBS"),  0.00, 0.01)
  year <- sample(2010:2025, N, replace = TRUE)
  age_mean    <- round(rnorm(N, 68, 6), 1)
  female_pct <- pmax(0.15, pmin(0.85, rnorm(N, 0.42, 0.10)))
  bmi_mean    <- round(rnorm(N, 28.5, 2.5), 1)
  charlson    <- round(pmax(0, rnorm(N, 1.6, 0.6)), 1)
  tte_compliant <- integer(N)
  tte_compliant[study_type=="OBS"] <- rbinom(sum(study_type=="OBS"), 1, 0.65)
  tte_compliant[study_type!="OBS"] <- 1L

  tibble::tibble(study_id, study_type, yi, se, grade, neg_ctrl, year, age_mean,
                 female_pct, bmi_mean, charlson, tte_compliant)
}

#' Simulate Binary Outcome Data
#'
#' Generate simulated meta-analysis data with binary outcomes (events and totals)
#'
#' @param n Number of studies
#' @param measure Effect measure ("OR" or "RR")
#' @param seed Random seed
#'
#' @return A tibble with simulated binary outcome data
#' @export
#'
#' @examples
#' # Simulate 25 studies with binary outcomes for OR
#' data <- simulate_cbamm_binary(n = 25, measure = "OR")
#' head(data)
simulate_cbamm_binary <- function(n = 20, measure = "OR", seed = 123) {
  set.seed(seed)
  study_id <- sprintf("B%02d", 1:n)
  study_type <- sample(c("RCT","OBS"), n, replace = TRUE, prob = c(0.6,0.4))
  n_t <- sample(50:400, n, replace = TRUE)
  n_c <- sample(50:400, n, replace = TRUE)
  base_risk <- runif(n, 0.01, 0.20)  # include rare-event zone
  true_rr <- rlnorm(n, meanlog = log(0.90), sdlog = 0.15)
  p_c <- base_risk
  p_t <- pmin(0.9, p_c * true_rr)
  event_c <- rbinom(n, n_c, p_c)
  event_t <- rbinom(n, n_t, p_t)
  tibble::tibble(study_id, study_type,
                 event_t = event_t, n_t = n_t, event_c = event_c, n_c = n_c,
                 year = sample(2010:2025, n, TRUE))
}

#' Simulate Continuous Outcome Data
#'
#' Generate simulated meta-analysis data with continuous outcomes
#'
#' @param n Number of studies
#' @param measure Effect measure ("MD" or "SMD")
#' @param seed Random seed
#'
#' @return A tibble with simulated continuous outcome data
#' @export
#'
#' @examples
#' # Simulate 20 studies with continuous outcomes for SMD
#' data <- simulate_cbamm_continuous(n = 20, measure = "SMD")
#' head(data)
simulate_cbamm_continuous <- function(n = 20, measure = "SMD", seed = 321) {
  set.seed(seed)
  study_id <- sprintf("C%02d", 1:n)
  study_type <- sample(c("RCT","OBS"), n, replace = TRUE)
  n_t <- sample(30:200, n, TRUE)
  n_c <- sample(30:200, n, TRUE)
  mean_c <- rnorm(n, 10, 3)
  mean_t <- mean_c - rnorm(n, 0.4, 0.3)
  sd_t <- runif(n, 2, 5)
  sd_c <- runif(n, 2, 5)
  tibble::tibble(study_id, study_type, mean_t, sd_t, n_t, mean_c, sd_c, n_c,
                 year = sample(2010:2025, n, TRUE))
}
