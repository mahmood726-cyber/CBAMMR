#' Example Meta-Analysis Datasets
#'
#' Collection of example datasets for demonstrating meta-analysis methods.
#' These datasets cover various outcome types and research domains.
#'
#' @format Various formats depending on the dataset
#' @name example-datasets
NULL

#' BCG Vaccine for Tuberculosis Prevention
#'
#' Results from 13 randomized controlled trials examining the efficacy of the
#' Bacillus Calmette-Guerin (BCG) vaccine for preventing tuberculosis.
#' This is a classic dataset used to demonstrate meta-analysis methods.
#'
#' @format A data frame with 13 rows and 7 variables:
#' \describe{
#'   \item{study}{Study identifier}
#'   \item{tpos}{Number of TB cases in vaccinated group}
#'   \item{tneg}{Number without TB in vaccinated group}
#'   \item{cpos}{Number of TB cases in control group}
#'   \item{cneg}{Number without TB in control group}
#'   \item{latitude}{Absolute latitude of study location}
#'   \item{year}{Year of study publication}
#' }
#'
#' @source Colditz et al. (1994). Efficacy of BCG vaccine in the prevention
#' of tuberculosis. *JAMA*, 271(9), 698-702.
#'
#' @examples
#' \dontrun{
#' data(bcg_vaccine)
#' head(bcg_vaccine)
#'
#' # Calculate log odds ratios
#' library(metafor)
#' dat <- escalc(measure="OR", ai=tpos, bi=tneg, ci=cpos, di=cneg,
#'               data=bcg_vaccine)
#' }
"bcg_vaccine"


#' Aspirin for Myocardial Infarction Prevention
#'
#' Results from 7 clinical trials examining aspirin for preventing
#' myocardial infarction (heart attack).
#'
#' @format A data frame with 7 rows and 5 variables:
#' \describe{
#'   \item{study}{Study name}
#'   \item{d_aspirin}{Events in aspirin group}
#'   \item{n_aspirin}{Total in aspirin group}
#'   \item{d_control}{Events in control group}
#'   \item{n_control}{Total in control group}
#' }
#'
#' @source Fleiss (1993). The statistical basis of meta-analysis.
#' *Statistical Methods in Medical Research*, 2(2), 121-145.
#'
#' @examples
#' \dontrun{
#' data(aspirin_mi)
#' head(aspirin_mi)
#' }
"aspirin_mi"


#' Magnesium for Myocardial Infarction
#'
#' Results from 16 trials examining intravenous magnesium for
#' mortality after acute myocardial infarction.
#'
#' @format A data frame with 16 rows and 5 variables:
#' \describe{
#'   \item{study}{Study identifier}
#'   \item{d_treat}{Deaths in treatment group}
#'   \item{n_treat}{Total in treatment group}
#'   \item{d_control}{Deaths in control group}
#'   \item{n_control}{Total in control group}
#' }
#'
#' @source Teo et al. (1991). Effects of intravenous magnesium in suspected
#' acute myocardial infarction. *BMJ*, 303, 1499-1503.
#'
#' @examples
#' \dontrun{
#' data(magnesium_mi)
#' head(magnesium_mi)
#' }
"magnesium_mi"


#' Antidepressants for Smoking Cessation
#'
#' Results from 28 trials examining antidepressants (bupropion) for
#' smoking cessation.
#'
#' @format A data frame with 28 rows and 6 variables:
#' \describe{
#'   \item{study}{Study name}
#'   \item{year}{Publication year}
#'   \item{quit_treat}{Quit in treatment group}
#'   \item{n_treat}{Total in treatment group}
#'   \item{quit_control}{Quit in control group}
#'   \item{n_control}{Total in control group}
#' }
#'
#' @source Hughes et al. (2014). Antidepressants for smoking cessation.
#' *Cochrane Database of Systematic Reviews*, 1, CD000031.
#'
#' @examples
#' \dontrun{
#' data(smoking_cessation)
#' head(smoking_cessation)
#' }
"smoking_cessation"


#' Teacher Expectancy on IQ
#'
#' Results from 19 studies examining the effect of teacher expectancies
#' on student IQ (Pygmalion effect). Standardized mean differences.
#'
#' @format A data frame with 19 rows and 4 variables:
#' \describe{
#'   \item{study}{Study identifier}
#'   \item{yi}{Standardized mean difference (effect size)}
#'   \item{vi}{Sampling variance}
#'   \item{weeks}{Duration of study in weeks}
#' }
#'
#' @source Raudenbush (1984). Magnitude of teacher expectancy effects on
#' pupil IQ as a function of the credibility of expectancy induction.
#' *Journal of Educational Psychology*, 76(1), 85-97.
#'
#' @examples
#' \dontrun{
#' data(teacher_expectancy)
#' head(teacher_expectancy)
#'
#' # Basic meta-analysis
#' result <- cbamm_permutation_test(teacher_expectancy$yi,
#'                                  teacher_expectancy$vi)
#' }
"teacher_expectancy"


#' Estrogen Therapy for Coronary Heart Disease
#'
#' Results from 15 observational studies on estrogen therapy and
#' coronary heart disease in women.
#'
#' @format A data frame with 15 rows and 3 variables:
#' \describe{
#'   \item{study}{Study name}
#'   \item{yi}{Log relative risk}
#'   \item{vi}{Sampling variance}
#' }
#'
#' @source Stampfer & Colditz (1991). Estrogen replacement therapy and
#' coronary heart disease. *Preventive Medicine*, 20(1), 47-63.
#'
#' @examples
#' \dontrun{
#' data(estrogen_chd)
#' head(estrogen_chd)
#' }
"estrogen_chd"


#' Environmental Tobacco Smoke and Lung Cancer
#'
#' Results from 37 studies examining the relationship between environmental
#' tobacco smoke exposure and lung cancer risk.
#'
#' @format A data frame with 37 rows and 3 variables:
#' \describe{
#'   \item{study}{Study name}
#'   \item{yi}{Log relative risk}
#'   \item{vi}{Sampling variance}
#' }
#'
#' @source Hackshaw et al. (1997). The accumulated evidence on lung cancer
#' and environmental tobacco smoke. *BMJ*, 315, 980-988.
#'
#' @examples
#' \dontrun{
#' data(tobacco_lung_cancer)
#' head(tobacco_lung_cancer)
#'
#' # Check for publication bias
#' cbamm_funnel_metafor(tobacco_lung_cancer$yi,
#'                     tobacco_lung_cancer$vi)
#' }
"tobacco_lung_cancer"


#' Exercise for Depression
#'
#' Results from 23 trials examining exercise interventions for
#' major depressive disorder. Standardized mean differences.
#'
#' @format A data frame with 23 rows and 5 variables:
#' \describe{
#'   \item{study}{Study identifier}
#'   \item{yi}{Standardized mean difference}
#'   \item{vi}{Sampling variance}
#'   \item{duration}{Exercise duration in weeks}
#'   \item{intensity}{Exercise intensity (low/moderate/high)}
#' }
#'
#' @source Cooney et al. (2013). Exercise for depression.
#' *Cochrane Database of Systematic Reviews*, 9, CD004366.
#'
#' @examples
#' \dontrun{
#' data(exercise_depression)
#' head(exercise_depression)
#'
#' # Meta-regression with duration
#' moderators <- matrix(exercise_depression$duration, ncol = 1)
#' result <- cbamm_bayesian_metareg(exercise_depression$yi,
#'                                  exercise_depression$vi,
#'                                  X = cbind(1, moderators),
#'                                  n_iter = 2000)
#' }
"exercise_depression"


#' Surgical versus Medical Treatment for Obesity
#'
#' Results from 12 trials comparing bariatric surgery vs medical
#' management for weight loss. Mean differences in kg.
#'
#' @format A data frame with 12 rows and 6 variables:
#' \describe{
#'   \item{study}{Study name}
#'   \item{year}{Publication year}
#'   \item{yi}{Mean difference in weight loss (kg)}
#'   \item{vi}{Sampling variance}
#'   \item{duration}{Follow-up duration in months}
#'   \item{surgery_type}{Type of surgery (RYGB/SG/AGB)}
#' }
#'
#' @source Gloy et al. (2013). Bariatric surgery versus non-surgical
#' treatment for obesity. *BMJ*, 347, f5934.
#'
#' @examples
#' \dontrun{
#' data(bariatric_surgery)
#' head(bariatric_surgery)
#'
#' # Cumulative meta-analysis
#' result <- cbamm_cumulative_metafor(bariatric_surgery$yi,
#'                                   bariatric_surgery$vi,
#'                                   order = order(bariatric_surgery$year))
#' }
"bariatric_surgery"


#' Probiotics for Antibiotic-Associated Diarrhea
#'
#' Results from 31 trials examining probiotics for preventing
#' antibiotic-associated diarrhea.
#'
#' @format A data frame with 31 rows and 5 variables:
#' \describe{
#'   \item{study}{Study identifier}
#'   \item{d_probiotic}{Diarrhea cases in probiotic group}
#'   \item{n_probiotic}{Total in probiotic group}
#'   \item{d_control}{Diarrhea cases in control group}
#'   \item{n_control}{Total in control group}
#' }
#'
#' @source Johnston et al. (2012). Probiotics for the prevention of
#' antibiotic-associated diarrhea. *Cochrane Database*, 9, CD004827.
#'
#' @examples
#' \dontrun{
#' data(probiotics_diarrhea)
#' head(probiotics_diarrhea)
#' }
"probiotics_diarrhea"
