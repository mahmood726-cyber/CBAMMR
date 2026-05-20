"""Merge fetched data into per-country cardiology profiles.

Reads:
  data/processed/worldbank_indicators.csv
  data/processed/who_gho_indicators.csv
  data/raw/clinicaltrials/_summary.json

Writes:
  data/processed/country_profiles.csv   wide format, latest value per indicator
  data/processed/country_profiles.json  same data, JSON-keyed by iso3
"""

from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path

from countries import iter_countries

ROOT = Path(__file__).resolve().parent.parent
PROC = ROOT / "data" / "processed"
CT_SUMMARY = ROOT / "data" / "raw" / "clinicaltrials" / "_summary.json"


def latest_per_indicator(csv_path: Path, key_code: str = "indicator_code",
                         key_value: str = "value") -> dict[str, dict[str, float]]:
    """Return {iso3: {indicator_code: latest_value}}."""
    best: dict[str, dict[str, tuple[int, float]]] = defaultdict(dict)
    if not csv_path.exists():
        return {}
    with csv_path.open() as f:
        for row in csv.DictReader(f):
            iso3 = row.get("iso3")
            code = row.get(key_code)
            year_raw = row.get("year")
            val_raw = row.get(key_value)
            if not iso3 or not code or not year_raw or val_raw in (None, ""):
                continue
            try:
                year = int(year_raw)
                value = float(val_raw)
            except (TypeError, ValueError):
                continue
            cur = best[iso3].get(code)
            if cur is None or year > cur[0]:
                best[iso3][code] = (year, value)
    return {iso: {c: v for c, (_, v) in inds.items()} for iso, inds in best.items()}


def main() -> None:
    PROC.mkdir(parents=True, exist_ok=True)

    wb = latest_per_indicator(PROC / "worldbank_indicators.csv",
                              key_value="value")
    who = latest_per_indicator(PROC / "who_gho_indicators.csv",
                               key_value="value_numeric")
    ct = {}
    if CT_SUMMARY.exists():
        ct = json.loads(CT_SUMMARY.read_text())

    indicator_codes: set[str] = set()
    for src in (wb, who):
        for inds in src.values():
            indicator_codes.update(inds.keys())
    indicator_codes = sorted(indicator_codes)

    profiles = {}
    rows = []
    for c in iter_countries():
        iso3 = c["iso3"]
        profile = {
            "iso2": c["iso2"],
            "iso3": iso3,
            "country": c["name"],
            "who_region": c["who_region"],
            "clinicaltrials_count": ct.get(iso3, {}).get("studies"),
        }
        for code in indicator_codes:
            profile[code] = wb.get(iso3, {}).get(code) or who.get(iso3, {}).get(code)
        profiles[iso3] = profile
        rows.append(profile)

    out_csv = PROC / "country_profiles.csv"
    fields = ["iso2", "iso3", "country", "who_region", "clinicaltrials_count"] + indicator_codes
    with out_csv.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

    out_json = PROC / "country_profiles.json"
    out_json.write_text(json.dumps(profiles, indent=2))

    print(f"Wrote {out_csv.relative_to(ROOT)} and {out_json.relative_to(ROOT)}")
    print(f"  {len(rows)} countries × {len(indicator_codes)} indicators")


if __name__ == "__main__":
    main()
