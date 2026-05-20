# Africa Data Atlas — Cardiology

An open, reproducible dataset and toolkit assembling cardiovascular-health
information for the 54 African countries from authoritative public sources:

- **ClinicalTrials.gov** — registered cardiology trials with African sites
- **World Bank Open Data** — health-system, mortality, and economic indicators
- **WHO Global Health Observatory (GHO)** — risk-factor and disease-burden indicators
- **Hooks for additional sources** — IHME GBD, Our World in Data, HDX

The repository ships fetch scripts that pull the latest data from each source,
plus a builder that merges everything into per-country profiles for analysis.

> **Status**: scaffolding — fetch scripts are ready to run. Run `make fetch`
> in any environment with normal internet access to populate `data/`.

## Repository layout

```
.
├── data/
│   ├── raw/                  # untouched API responses (JSON)
│   │   ├── clinicaltrials/
│   │   ├── worldbank/
│   │   └── who_gho/
│   └── processed/            # cleaned CSVs and merged profiles
├── docs/
│   └── sources.md            # catalog of indicators and endpoints
├── scripts/
│   ├── fetch_clinicaltrials.py
│   ├── fetch_worldbank.py
│   ├── fetch_who_gho.py
│   ├── build_atlas.py
│   └── countries.py          # canonical list of 54 African countries
├── Makefile
├── requirements.txt
└── LICENSE
```

## Quick start

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Fetch everything (writes to data/raw/)
make fetch

# Build merged country profiles (writes data/processed/)
make build

# Or run individual fetchers
python scripts/fetch_clinicaltrials.py
python scripts/fetch_worldbank.py
python scripts/fetch_who_gho.py
```

## Country coverage

All 54 sovereign African states plus Western Sahara as observed by the African
Union. See `scripts/countries.py` for ISO-3166 alpha-2/alpha-3 codes and WHO
region groupings.

## Indicators tracked

| Domain | Examples |
|---|---|
| Mortality | CVD deaths per 100k, premature NCD mortality (30–70), stroke mortality |
| Risk factors | Hypertension prevalence, mean SBP, obesity, smoking, diabetes |
| Health system | Physicians per 1k, health expenditure per capita, hospital beds |
| Demographics | Population, GDP per capita, life expectancy |
| Research | Active and completed cardiology trials per country |

Full indicator catalog: [`docs/sources.md`](docs/sources.md).

## License

Code: Apache 2.0 (see `LICENSE`).
Data: subject to the terms of each upstream provider — see `docs/sources.md`.
