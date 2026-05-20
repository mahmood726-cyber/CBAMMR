"""Fetch WHO Global Health Observatory (GHO) cardiology indicators.

API: https://www.who.int/data/gho/info/gho-odata-api
Base: https://ghoapi.azureedge.net/api/

The GHO returns one row per (country, year, sex, age-group). We persist the
raw OData response per indicator and emit a long-format CSV filtered to the
African countries listed in countries.py.

Output:
  data/raw/who_gho/<INDICATOR>.json
  data/processed/who_gho_indicators.csv
"""

from __future__ import annotations

import csv
import json
import time
from pathlib import Path

import requests

from countries import iso3_codes

BASE = "https://ghoapi.azureedge.net/api"
TIMEOUT = 60
RETRIES = 3

# Curated cardiology / NCD-risk indicators. Codes from the GHO Indicator list.
INDICATORS = {
    "NCDMORT3070":           "Probability (%) of dying between 30 and 70 from CVD, cancer, diabetes, CRD",
    "BP_04":                 "Mean systolic blood pressure (age-standardized)",
    "BP_03":                 "Raised blood pressure (SBP>=140 or DBP>=90), age-standardized (%)",
    "NCD_HYP_PREVALENCE_A":  "Prevalence of hypertension among adults aged 30-79",
    "NCD_BMI_30A":           "Prevalence of obesity among adults (BMI>=30), age-standardized (%)",
    "NCD_BMI_25A":           "Prevalence of overweight among adults (BMI>=25), age-standardized (%)",
    "NCD_GLUC_04":           "Mean fasting blood glucose (mmol/L), age-standardized",
    "NCD_CHOL_MEANTC":       "Mean total cholesterol (age-standardized)",
    "M_Est_smk_curr_std":    "Estimate of current tobacco smoking prevalence (age-standardized)",
    "SA_0000001688":         "Total alcohol per capita (15+) consumption, in litres of pure alcohol",
    "PHE_HHAIR_PROP_POP_CLEAN_FUELS": "Population with primary reliance on clean fuels (%)",
    "WHOSIS_000001":         "Life expectancy at birth (years)",
    "WHOSIS_000015":         "Life expectancy at age 60 (years)",
    "HWF_0001":              "Medical doctors (per 10 000 population)",
    "HWF_0006":              "Nursing and midwifery personnel (per 10 000 population)",
}

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw" / "who_gho"
PROC_DIR = ROOT / "data" / "processed"


def get(url: str) -> dict:
    last_err = None
    for attempt in range(RETRIES):
        try:
            r = requests.get(url, timeout=TIMEOUT,
                             headers={"User-Agent": "africa-data-atlas/0.1",
                                      "Accept": "application/json"})
            r.raise_for_status()
            return r.json()
        except requests.RequestException as e:
            last_err = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"WHO GHO fetch failed: {url} :: {last_err}")


def fetch_indicator(code: str) -> list[dict]:
    """Return all data rows for an indicator, paging through OData."""
    out: list[dict] = []
    url = f"{BASE}/{code}"
    while url:
        body = get(url)
        out.extend(body.get("value", []))
        url = body.get("@odata.nextLink")
    return out


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROC_DIR.mkdir(parents=True, exist_ok=True)

    african = set(iso3_codes())
    rows = []

    for code, label in INDICATORS.items():
        print(f"Fetching {code}  {label}")
        data = fetch_indicator(code)
        (RAW_DIR / f"{code}.json").write_text(json.dumps(data, indent=2))

        for rec in data:
            iso3 = rec.get("SpatialDim")
            if iso3 not in african:
                continue
            rows.append({
                "iso3": iso3,
                "indicator_code": code,
                "indicator_name": label,
                "year": rec.get("TimeDim"),
                "sex": rec.get("Dim1"),
                "value_numeric": rec.get("NumericValue"),
                "value_display": rec.get("Value"),
                "low": rec.get("Low"),
                "high": rec.get("High"),
            })

    out_csv = PROC_DIR / "who_gho_indicators.csv"
    fields = ["iso3", "indicator_code", "indicator_name", "year", "sex",
              "value_numeric", "value_display", "low", "high"]
    with out_csv.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows):,} rows to {out_csv.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
