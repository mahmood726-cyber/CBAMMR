# Script to create example datasets for CBAMMR
# Run this to generate .rda files in data/ directory

# Create data directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

# ============================================================================
# BCG Vaccine Dataset
# ============================================================================
bcg_vaccine <- data.frame(
  study = c("Aronson", "Ferguson & Simes", "Rosenthal et al", "Hart & Sutherland",
            "Frimodt-Moller et al", "Stein & Aronson", "Vandiviere et al",
            "TPT Madras", "Coetzee & Berjak", "Rosenthal et al", "Comstock et al",
            "Comstock & Webster", "Levine et al"),
  tpos = c(4, 6, 3, 62, 33, 180, 8, 505, 29, 17, 186, 5, 27),
  tneg = c(119, 300, 228, 13536, 5036, 1361, 2537, 87886, 7470, 1699, 50448, 2493, 16886),
  cpos = c(11, 29, 11, 248, 47, 372, 10, 499, 45, 65, 141, 3, 29),
  cneg = c(128, 274, 209, 12619, 5761, 1079, 619, 87892, 7232, 1600, 27197, 2338, 17825),
  latitude = c(44, 55, 42, 52, 13, 44, 19, 13, 27, 42, 18, 33, 33),
  year = c(1948, 1949, 1960, 1977, 1973, 1969, 1970, 1980, 1968, 1961, 1976, 1980, 1968)
)

save(bcg_vaccine, file = "data/bcg_vaccine.rda", compress = "bzip2")


# ============================================================================
# Aspirin for MI Dataset
# ============================================================================
aspirin_mi <- data.frame(
  study = c("MRC-1", "CDP", "MRC-2", "GASP", "PARIS", "AMIS", "ISIS-2"),
  d_aspirin = c(49, 44, 102, 32, 85, 246, 1570),
  n_aspirin = c(615, 758, 832, 317, 810, 2267, 8587),
  d_control = c(67, 64, 126, 38, 52, 219, 1720),
  n_control = c(624, 771, 850, 309, 406, 2257, 8600)
)

save(aspirin_mi, file = "data/aspirin_mi.rda", compress = "bzip2")


# ============================================================================
# Magnesium for MI Dataset
# ============================================================================
magnesium_mi <- data.frame(
  study = c("Morton", "Rasmussen", "Smith", "Abraham", "Feldstedt", "Shechter",
            "Ceremuzynski", "Bertschat", "Singh", "Pereira", "Schechter", "Golf",
            "LIMIT-2", "Thogersen", "Woods", "ISIS-4"),
  d_treat = c(1, 9, 2, 1, 10, 1, 1, 1, 6, 1, 2, 8, 90, 4, 4, 2216),
  n_treat = c(40, 135, 200, 48, 150, 59, 25, 22, 76, 27, 107, 71, 1159, 56, 28, 29011),
  d_control = c(2, 23, 7, 1, 8, 9, 3, 9, 11, 7, 1, 20, 118, 17, 8, 2103),
  n_control = c(36, 135, 200, 46, 148, 56, 23, 21, 75, 27, 108, 64, 1157, 58, 28, 29039)
)

save(magnesium_mi, file = "data/magnesium_mi.rda", compress = "bzip2")


# ============================================================================
# Smoking Cessation Dataset
# ============================================================================
smoking_cessation <- data.frame(
  study = c("Hurt 1997", "Jorenby 1999", "Tønnesen 2003", "Tonstad 2003", "González 2004",
            "Simon 2004", "Aubin 2004", "Swan 2003", "Cox 2004", "Nides 2006",
            "Killen 2006", "Zellweger 2005", "Hays 2001", "Cox 2012", "Anthenelli 2016",
            "Rose 1994", "Hall 1998", "Hayford 1999", "Ahluwalia 2002", "Dale 2001",
            "Brown 2007", "Dalsgarð 2004", "Evins 2001", "George 2002", "Evins 2005",
            "McClure 2013", "Uyar 2007", "Rigotti 2006"),
  year = c(1997, 1999, 2003, 2003, 2004, 2004, 2004, 2003, 2004, 2006,
           2006, 2005, 2001, 2012, 2016, 1994, 1998, 1999, 2002, 2001,
           2007, 2004, 2001, 2002, 2005, 2013, 2007, 2006),
  quit_treat = c(44, 156, 145, 160, 19, 37, 53, 105, 81, 103,
                 9, 24, 71, 110, 294, 8, 40, 13, 21, 17,
                 32, 5, 7, 13, 9, 26, 34, 14),
  n_treat = c(153, 245, 290, 298, 64, 110, 199, 158, 205, 251,
              50, 110, 228, 255, 694, 28, 76, 42, 85, 48,
              100, 26, 18, 28, 19, 73, 127, 75),
  quit_control = c(19, 73, 95, 87, 6, 24, 25, 42, 32, 75,
                   3, 14, 45, 66, 255, 3, 18, 3, 7, 4,
                   17, 2, 2, 1, 2, 12, 20, 5),
  n_control = c(153, 244, 295, 305, 63, 113, 201, 161, 217, 264,
                50, 108, 236, 250, 681, 28, 76, 42, 85, 48,
                100, 28, 18, 29, 19, 72, 124, 75)
)

save(smoking_cessation, file = "data/smoking_cessation.rda", compress = "bzip2")


# ============================================================================
# Teacher Expectancy Dataset
# ============================================================================
teacher_expectancy <- data.frame(
  study = c("Rosenthal", "Conn", "Jose", "Pellegrini", "Pellegrini", "Evans", "Rosenthal",
            "Fielder", "Claiborn", "Kester", "Maxwell", "Carter", "Flowers", "Keshock",
            "Henrikson", "Fine", "Grieger", "Rosenthal", "Meichenbaum"),
  yi = c(0.03, 0.12, -0.14, 1.18, 0.26, -0.06, -0.02, -0.32, -0.27,
         0.80, 0.54, 0.18, -0.02, 0.23, 0.23, -0.18, -0.06, 0.30, 0.07),
  vi = c(0.125, 0.147, 0.167, 0.373, 0.369, 0.103, 0.103, 0.220, 0.164,
         0.251, 0.302, 0.223, 0.289, 0.290, 0.159, 0.167, 0.139, 0.103, 0.219),
  weeks = c(2, 21, 19, 0, 0, 3, 0, 17, 7, 7, 0, 0, 19, 52, 17, 1, 18, 1, 24)
)

save(teacher_expectancy, file = "data/teacher_expectancy.rda", compress = "bzip2")


# ============================================================================
# Estrogen CHD Dataset
# ============================================================================
estrogen_chd <- data.frame(
  study = c("Hammond", "Rosenberg", "Bain", "Pfeffer", "Talbott", "Pfeffer", "Ross",
            "Adam", "Szklo", "Rosenberg", "Bush", "Criqui", "Henderson", "Petitti", "Sullivan"),
  yi = c(-0.40, 0.11, -0.47, -0.51, -0.36, 0.00, 0.00, -0.28, -0.48,
         -0.47, -0.69, -0.47, -0.36, 0.14, -0.51),
  vi = c(0.034, 0.077, 0.085, 0.106, 0.108, 0.050, 0.063, 0.119, 0.165,
         0.071, 0.084, 0.106, 0.077, 0.148, 0.045)
)

save(estrogen_chd, file = "data/estrogen_chd.rda", compress = "bzip2")


# ============================================================================
# Tobacco Lung Cancer Dataset
# ============================================================================
set.seed(12345)
tobacco_lung_cancer <- data.frame(
  study = paste("Study", 1:37),
  yi = c(0.18, 0.26, 0.41, 0.36, 0.28, 0.16, 0.22, 0.31, 0.19, 0.15,
         0.29, 0.33, 0.24, 0.21, 0.27, 0.38, 0.20, 0.25, 0.30, 0.23,
         0.17, 0.34, 0.28, 0.22, 0.26, 0.19, 0.32, 0.24, 0.29, 0.21,
         0.35, 0.27, 0.20, 0.31, 0.25, 0.28, 0.23),
  vi = c(0.012, 0.015, 0.020, 0.018, 0.014, 0.010, 0.013, 0.017, 0.011, 0.009,
         0.016, 0.019, 0.013, 0.012, 0.015, 0.021, 0.011, 0.014, 0.016, 0.013,
         0.010, 0.019, 0.015, 0.012, 0.014, 0.011, 0.018, 0.013, 0.016, 0.012,
         0.020, 0.015, 0.011, 0.017, 0.014, 0.015, 0.013)
)

save(tobacco_lung_cancer, file = "data/tobacco_lung_cancer.rda", compress = "bzip2")


# ============================================================================
# Exercise Depression Dataset
# ============================================================================
exercise_depression <- data.frame(
  study = paste("Study", 1:23),
  yi = c(-0.82, -0.54, -0.68, -0.91, -0.45, -0.73, -0.59, -0.86, -0.62, -0.48,
         -0.75, -0.67, -0.53, -0.79, -0.58, -0.71, -0.64, -0.50, -0.77, -0.61,
         -0.69, -0.55, -0.74),
  vi = c(0.045, 0.038, 0.042, 0.051, 0.036, 0.044, 0.039, 0.048, 0.040, 0.037,
         0.046, 0.043, 0.038, 0.047, 0.039, 0.044, 0.041, 0.037, 0.046, 0.040,
         0.043, 0.038, 0.045),
  duration = c(8, 12, 6, 16, 10, 14, 8, 12, 10, 8,
               14, 12, 8, 16, 10, 12, 10, 8, 14, 10,
               12, 8, 14),
  intensity = c("moderate", "high", "low", "high", "moderate", "high", "moderate",
                "high", "moderate", "low", "high", "moderate", "moderate", "high",
                "moderate", "high", "moderate", "low", "high", "moderate",
                "high", "moderate", "high")
)

save(exercise_depression, file = "data/exercise_depression.rda", compress = "bzip2")


# ============================================================================
# Bariatric Surgery Dataset
# ============================================================================
bariatric_surgery <- data.frame(
  study = c("Mingrone 2012", "Schauer 2012", "Ikramuddin 2013", "Dixon 2008",
            "O'Brien 2006", "Courcoulas 2014", "Liang 2013", "Mingrone 2015",
            "Halperin 2014", "Wentworth 2014", "Muller-Stich 2015", "Cummings 2016"),
  year = c(2012, 2012, 2013, 2008, 2006, 2014, 2013, 2015, 2014, 2014, 2015, 2016),
  yi = c(-23.4, -20.5, -18.3, -14.2, -11.8, -19.2, -16.5, -22.1,
         -17.8, -15.9, -19.6, -21.3),
  vi = c(4.2, 3.8, 3.5, 2.9, 2.5, 3.6, 3.2, 4.0, 3.4, 3.1, 3.7, 4.1),
  duration = c(24, 12, 12, 24, 24, 12, 12, 60, 12, 24, 12, 12),
  surgery_type = c("RYGB", "RYGB", "RYGB", "AGB", "AGB", "RYGB", "SG",
                   "RYGB", "SG", "AGB", "RYGB", "RYGB")
)

save(bariatric_surgery, file = "data/bariatric_surgery.rda", compress = "bzip2")


# ============================================================================
# Probiotics Diarrhea Dataset
# ============================================================================
set.seed(54321)
probiotics_diarrhea <- data.frame(
  study = paste("Study", 1:31),
  d_probiotic = c(5, 12, 8, 15, 9, 6, 11, 7, 10, 13,
                  8, 14, 6, 9, 11, 7, 12, 8, 10, 14,
                  9, 7, 13, 10, 8, 11, 9, 12, 7, 10, 8),
  n_probiotic = c(50, 80, 65, 100, 75, 55, 85, 60, 70, 90,
                  65, 95, 58, 72, 82, 62, 88, 68, 76, 94,
                  74, 61, 91, 77, 66, 84, 73, 87, 63, 78, 67),
  d_control = c(12, 23, 17, 28, 19, 13, 22, 15, 20, 25,
                17, 26, 14, 18, 21, 15, 24, 16, 19, 27,
                18, 14, 24, 20, 16, 22, 18, 23, 15, 20, 16),
  n_control = c(50, 80, 65, 100, 75, 55, 85, 60, 70, 90,
                65, 95, 58, 72, 82, 62, 88, 68, 76, 94,
                74, 61, 91, 77, 66, 84, 73, 87, 63, 78, 67)
)

save(probiotics_diarrhea, file = "data/probiotics_diarrhea.rda", compress = "bzip2")


message("All datasets created successfully!")
message("Datasets saved to data/ directory")
