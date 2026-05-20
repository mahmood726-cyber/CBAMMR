.PHONY: fetch fetch-ct fetch-wb fetch-who build clean

PY ?= python3

fetch: fetch-ct fetch-wb fetch-who

fetch-ct:
	$(PY) scripts/fetch_clinicaltrials.py

fetch-wb:
	$(PY) scripts/fetch_worldbank.py

fetch-who:
	$(PY) scripts/fetch_who_gho.py

build:
	$(PY) scripts/build_atlas.py

clean:
	rm -rf data/raw/*/*.json data/raw/*/*.ndjson data/processed/*.csv

install:
	$(PY) -m pip install -r requirements.txt
