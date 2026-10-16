# sample-db
Testing a sample PostgreSQL DB and monitoring tool

Practice pipeline: a CSV of bin pickups is loaded into PostgreSQL, cleaned with Python,
and shaped for Apache Superset. See [data/data_dict.md](data/data_dict.md) for the data and rules.

```
data/MOCK_DATA.csv ──► raw ──► staging ──► analytics ──► Superset
                   extract_load  transform   build_analytics.sql
                    (Python)     (Python)        (SQL)
```

## Layout

| Path | What it is |
|---|---|
| `docker-compose.yml` | The Postgres container |
| `.env.example` | Settings template. Copy to `.env` and fill in real values |
| `sql/setup/` | Builds the empty structure: schemas, roles, tables, views. Runs once |
| `sql/transforms/` | SQL steps of the pipeline. Runs on every load |
| `etl/` | Python steps of the pipeline. `run_pipeline.py` runs everything in order |

## Database roles

| Role | Can do |
|---|---|
| `admin` | Everything. Setup only |
| `etl_writer` | Read and write `raw`, `staging`, `analytics`. Cannot create or drop tables |
| `analyst` | Read `analytics` only (group role, cannot log in) |
| `superset_reader` | Member of `analyst`. Used by Superset |

## First-time setup

1. Copy `.env.example` to `.env` and replace every `change_me`.
2. Start Postgres. On an empty volume, the files in `sql/setup/` run automatically:
   ```
   docker compose up -d
   ```
3. Create the Python environment (use the Windows Python, `py`, not MSYS2's `python`):
   ```
   py -3.13 -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```
4. Run the pipeline:
   ```
   python etl/run_pipeline.py
   ```

## Useful commands

| Task | Command |
|---|---|
| Open psql as admin | `docker compose exec postgres psql -U admin -d sampledb` |
| Open psql as another role | `docker compose exec postgres psql -U superset_reader -d sampledb` |
| Rerun one setup file | `docker compose exec postgres psql -U admin -d sampledb -f /sql/setup/02_roles.sql` |
| Delete all data and rebuild from scratch | `docker compose down -v` then `docker compose up -d` |
