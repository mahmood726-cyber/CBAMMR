"""Fetch cardiology-related clinical trials with African sites from ClinicalTrials.gov.

Uses the v2 REST API (https://clinicaltrials.gov/data-api/api).

Output:
  data/raw/clinicaltrials/<country_slug>.ndjson   one study per line
  data/raw/clinicaltrials/_summary.json           per-country counts

Re-runnable: existing files are overwritten.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Iterator

import requests

from countries import iter_countries

API = "https://clinicaltrials.gov/api/v2/studies"
PAGE_SIZE = 100
TIMEOUT = 60
RETRIES = 3
SLEEP_BETWEEN = 0.3  # seconds, be polite

CARDIOLOGY_QUERY = (
    "AREA[ConditionSearch]("
    "cardiovascular OR cardiology OR \"heart disease\" OR \"coronary artery\" "
    "OR hypertension OR \"myocardial infarction\" OR arrhythmia OR \"atrial fibrillation\" "
    "OR \"heart failure\" OR stroke OR \"rheumatic heart\" OR cardiomyopathy"
    ")"
)

OUT_DIR = Path(__file__).resolve().parent.parent / "data" / "raw" / "clinicaltrials"


def fetch_country(name: str) -> Iterator[dict]:
    """Yield every study with a site in `name` matching the cardiology query."""
    token = None
    while True:
        params = {
            "query.cond": CARDIOLOGY_QUERY,
            "query.locn": f'AREA[LocationCountry]"{name}"',
            "pageSize": PAGE_SIZE,
            "format": "json",
        }
        if token:
            params["pageToken"] = token

        data = _get(params)
        for study in data.get("studies", []):
            yield study

        token = data.get("nextPageToken")
        if not token:
            return
        time.sleep(SLEEP_BETWEEN)


def _get(params: dict) -> dict:
    last_err = None
    for attempt in range(RETRIES):
        try:
            r = requests.get(API, params=params, timeout=TIMEOUT,
                             headers={"User-Agent": "africa-data-atlas/0.1"})
            r.raise_for_status()
            return r.json()
        except requests.RequestException as e:
            last_err = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"ClinicalTrials.gov request failed: {last_err}")


def slugify(name: str) -> str:
    return name.lower().replace(" ", "_").replace("'", "").replace(",", "")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary = {}

    for c in iter_countries():
        name = c["name"]
        out = OUT_DIR / f"{slugify(name)}.ndjson"
        count = 0
        with out.open("w") as f:
            for study in fetch_country(name):
                f.write(json.dumps(study) + "\n")
                count += 1
        summary[c["iso3"]] = {"country": name, "studies": count}
        print(f"{c['iso3']}  {name:35s}  {count:5d} studies")

    (OUT_DIR / "_summary.json").write_text(json.dumps(summary, indent=2))
    total = sum(v["studies"] for v in summary.values())
    print(f"\nTotal studies across Africa: {total}")


if __name__ == "__main__":
    main()
