"""Fetch World Bank indicators relevant to cardiovascular health for all African countries.

API docs: https://datahelpdesk.worldbank.org/knowledgebase/articles/889392

Output:
  data/raw/worldbank/<INDICATOR>.json    raw response per indicator
  data/processed/worldbank_indicators.csv  long-format: iso3, indicator, year, value
"""

from __future__ import annotations

import csv
import json
import time
from pathlib import Path

import requests

from countries import iso3_codes

API = "https://api.worldbank.org/v2/country/{codes}/indicator/{ind}"
PER_PAGE = 20000
TIMEOUT = 60
RETRIES = 3

INDICATORS = {
    # Mortality / disease burden
    "SH.DYN.NCOM.ZS": "Mortality from CVD, cancer, diabetes, CRD between 30-70 (%)",
    "SH.DTH.NCOM.ZS": "Cause of death, by non-communicable diseases (% of total)",
    "SH.DTH.COMM.ZS": "Cause of death, by communicable diseases (% of total)",
    "SP.DYN.LE00.IN": "Life expectancy at birth, total (years)",

    # Health system
    "SH.MED.PHYS.ZS": "Physicians (per 1,000 people)",
    "SH.MED.NUMW.P3": "Nurses and midwives (per 1,000 people)",
    "SH.MED.BEDS.ZS": "Hospital beds (per 1,000 people)",
    "SH.XPD.CHEX.PC.CD": "Current health expenditure per capita (current US$)",
    "SH.XPD.CHEX.GD.ZS": "Current health expenditure (% of GDP)",

    # Risk factors
    "SH.PRV.SMOK": "Smoking prevalence, total (ages 15+)",
    "SH.STA.DIAB.ZS": "Diabetes prevalence (% of population ages 20 to 79)",
    "SH.STA.OWAD.ZS": "Prevalence of overweight (% of adults)",

    # Demographics / economy
    "SP.POP.TOTL": "Population, total",
    "SP.POP.65UP.TO.ZS": "Population ages 65 and above (% of total)",
    "NY.GDP.PCAP.CD": "GDP per capita (current US$)",
    "SI.POV.GINI": "Gini index",
}

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw" / "worldbank"
PROC_DIR = ROOT / "data" / "processed"


def fetch_indicator(indicator: str, codes: list[str]) -> list[dict]:
    """Return the data array for one indicator across all requested countries."""
    url = API.format(codes=";".join(codes), ind=indicator)
    params = {"format": "json", "per_page": PER_PAGE}
    last_err = None
    for attempt in range(RETRIES):
        try:
            r = requests.get(url, params=params, timeout=TIMEOUT,
                             headers={"User-Agent": "africa-data-atlas/0.1"})
            r.raise_for_status()
            body = r.json()
            # World Bank returns [meta, data]
            if isinstance(body, list) and len(body) == 2:
                return body[1] or []
            return []
        except requests.RequestException as e:
            last_err = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"World Bank fetch failed for {indicator}: {last_err}")


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROC_DIR.mkdir(parents=True, exist_ok=True)

    codes = iso3_codes()
    rows = []

    for ind, label in INDICATORS.items():
        print(f"Fetching {ind}  {label}")
        data = fetch_indicator(ind, codes)
        (RAW_DIR / f"{ind}.json").write_text(json.dumps(data, indent=2))
        for rec in data:
            if rec.get("value") is None:
                continue
            rows.append({
                "iso3": rec["countryiso3code"],
                "country": rec["country"]["value"],
                "indicator_code": ind,
                "indicator_name": label,
                "year": int(rec["date"]),
                "value": rec["value"],
            })

    out_csv = PROC_DIR / "worldbank_indicators.csv"
    with out_csv.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else
                                ["iso3", "country", "indicator_code", "indicator_name", "year", "value"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows):,} rows to {out_csv.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
