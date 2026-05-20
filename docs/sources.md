# Data sources

## ClinicalTrials.gov

- **API**: https://clinicaltrials.gov/api/v2/studies (REST v2)
- **Docs**: https://clinicaltrials.gov/data-api/api
- **License**: public domain (U.S. government work)
- **What we pull**: every registered study whose condition field matches a
  cardiology query (cardiovascular, coronary, hypertension, heart failure,
  stroke, arrhythmia, cardiomyopathy, rheumatic heart, etc.) AND has at least
  one site in an African country.
- **Refresh cadence**: re-running `scripts/fetch_clinicaltrials.py` fetches
  the latest snapshot.

## World Bank Open Data

- **API**: https://api.worldbank.org/v2
- **Docs**: https://datahelpdesk.worldbank.org/knowledgebase/articles/889392
- **License**: CC BY 4.0
- **Indicators tracked**:

| Code | Indicator |
|---|---|
| `SH.DYN.NCOM.ZS` | Mortality from CVD/cancer/diabetes/CRD between 30–70 (%) |
| `SH.DTH.NCOM.ZS` | Cause of death, NCDs (% of total) |
| `SH.DTH.COMM.ZS` | Cause of death, communicable diseases (% of total) |
| `SP.DYN.LE00.IN` | Life expectancy at birth |
| `SH.MED.PHYS.ZS` | Physicians per 1,000 |
| `SH.MED.NUMW.P3` | Nurses and midwives per 1,000 |
| `SH.MED.BEDS.ZS` | Hospital beds per 1,000 |
| `SH.XPD.CHEX.PC.CD` | Current health expenditure per capita (US$) |
| `SH.XPD.CHEX.GD.ZS` | Current health expenditure (% GDP) |
| `SH.PRV.SMOK` | Smoking prevalence (15+) |
| `SH.STA.DIAB.ZS` | Diabetes prevalence (20–79) |
| `SH.STA.OWAD.ZS` | Overweight prevalence (adults) |
| `SP.POP.TOTL` | Population, total |
| `SP.POP.65UP.TO.ZS` | Population 65+ (%) |
| `NY.GDP.PCAP.CD` | GDP per capita (US$) |
| `SI.POV.GINI` | Gini index |

## WHO Global Health Observatory (GHO)

- **API**: https://ghoapi.azureedge.net/api/  (OData)
- **Docs**: https://www.who.int/data/gho/info/gho-odata-api
- **License**: CC BY-NC-SA 3.0 IGO
- **Indicators tracked**:

| Code | Indicator |
|---|---|
| `NCDMORT3070` | Probability of dying 30–70 from major NCDs (%) |
| `BP_03` | Raised BP prevalence (SBP≥140 or DBP≥90) |
| `BP_04` | Mean systolic BP |
| `NCD_HYP_PREVALENCE_A` | Hypertension prevalence, 30–79 |
| `NCD_BMI_30A` | Obesity prevalence (adults) |
| `NCD_BMI_25A` | Overweight prevalence (adults) |
| `NCD_GLUC_04` | Mean fasting blood glucose |
| `NCD_CHOL_MEANTC` | Mean total cholesterol |
| `M_Est_smk_curr_std` | Current tobacco smoking prevalence |
| `SA_0000001688` | Total alcohol per capita (15+) |
| `PHE_HHAIR_PROP_POP_CLEAN_FUELS` | Clean cooking fuels access (%) |
| `WHOSIS_000001` | Life expectancy at birth |
| `WHOSIS_000015` | Life expectancy at age 60 |
| `HWF_0001` | Medical doctors per 10,000 |
| `HWF_0006` | Nurses and midwives per 10,000 |

## Planned additions

- **IHME Global Burden of Disease** — DALYs and age-standardized CVD mortality
  (requires GBD Results Tool downloads; not a public REST API).
- **Our World in Data** — packaged CSVs (CC BY 4.0).
- **PAN-AFRICAN SoCAT / Pan-African Society of Cardiology** — registry data
  where openly published.
- **Demographic and Health Surveys (DHS)** — country-level BP/cholesterol
  prevalence from the STATcompiler API (registration required).

Open an issue or PR if you want a new source wired up.
