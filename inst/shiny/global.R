# Global variables and helper functions for CBAMMR Shiny App

# Required packages
required_packages <- c(
  "shiny", "bs4Dash", "CBAMMR", "DT", "plotly", "ggplot2",
  "shinyWidgets", "readr", "writexl", "shinyjs"
)

# Check and load packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(paste("Package", pkg, "is required but not installed."))
  }
  library(pkg, character.only = TRUE)
}

# Helper function to create high-resolution plots
save_highres_plot <- function(plot_obj, filename, width = 10, height = 8, dpi = 300, format = "png") {
  if (format == "png") {
    png(filename, width = width * dpi, height = height * dpi, res = dpi)
  } else if (format == "pdf") {
    pdf(filename, width = width, height = height)
  } else if (format == "svg") {
    svg(filename, width = width, height = height)
  }

  print(plot_obj)
  dev.off()
}

# Create example datasets
create_example_binary_or <- function() {
  set.seed(123)
  data <- simulate_cbamm_binary(n = 20, measure = "OR", true_effect = 0.70)
  data$age_mean <- rnorm(20, 60, 10)
  data$female_pct <- runif(20, 0.3, 0.7)
  data$study_type <- sample(c("RCT", "Obs"), 20, replace = TRUE, prob = c(0.6, 0.4))
  data
}

create_example_continuous_smd <- function() {
  set.seed(456)
  data <- simulate_cbamm_continuous(n = 18, measure = "SMD", true_effect = -0.40)
  data$age_mean <- rnorm(18, 60, 10)
  data$female_pct <- runif(18, 0.3, 0.7)
  data$study_type <- sample(c("RCT", "Obs"), 18, replace = TRUE, prob = c(0.7, 0.3))
  data
}

# Template data for downloads
binary_template <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Brown 2022"),
  ai = c(20, 30, 25),
  bi = c(80, 120, 95),
  ci = c(30, 40, 35),
  di = c(70, 110, 85),
  year = c(2020, 2021, 2022),
  age_mean = c(60, 65, 62),
  female_pct = c(0.45, 0.50, 0.48),
  study_type = c("RCT", "RCT", "Obs")
)

continuous_template <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Brown 2022"),
  yi = c(-0.40, -0.35, -0.42),
  sei = c(0.15, 0.18, 0.16),
  n1i = c(50, 60, 55),
  n2i = c(50, 60, 55),
  year = c(2020, 2021, 2022),
  age_mean = c(60, 65, 62),
  female_pct = c(0.45, 0.50, 0.48)
)

survival_template <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Brown 2022"),
  yi = c(log(0.70), log(0.75), log(0.68)),
  sei = c(0.12, 0.15, 0.13),
  n1i = c(100, 120, 110),
  n2i = c(100, 120, 110),
  year = c(2020, 2021, 2022)
)
