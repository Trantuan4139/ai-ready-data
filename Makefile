PY ?= python
DBT = dbt --no-use-colors
DBT_ARGS = --project-dir dbt --profiles-dir dbt
export DUCKDB_PATH ?= data/warehouse.duckdb

.PHONY: setup data ingest build pipeline docs ask context eval eval-gold test clean

setup:        ## install dependencies
	$(PY) -m pip install -r requirements.txt
data:         ## generate messy raw CSVs
	$(PY) scripts/generate_data.py
ingest:       ## load CSVs into raw schema
	$(PY) pipeline/ingest.py
build:        ## dbt seed + models + tests
	$(DBT) seed $(DBT_ARGS) && $(DBT) build $(DBT_ARGS)
pipeline:     ## everything end to end
	$(PY) pipeline/run.py
docs:         ## browse dbt docs + lineage
	$(DBT) docs generate $(DBT_ARGS) && $(DBT) docs serve $(DBT_ARGS)
context:      ## show exactly what the LLM sees
	$(PY) -m ai.ask --show-context
ask:          ## make ask Q="Net revenue by country"
	$(PY) -m ai.ask "$(Q)"
eval:         ## score the AI assistant (needs ANTHROPIC_API_KEY)
	$(PY) -m eval.run_eval
eval-gold:    ## check gold queries only (no API key needed)
	$(PY) -m eval.run_eval --gold-only
test:
	$(PY) -m pytest -q
clean:
	rm -rf data/raw data/*.duckdb dbt/target dbt/logs eval/report.md
