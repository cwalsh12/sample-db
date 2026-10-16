"""Runs the whole pipeline in order: CSV -> raw -> staging -> analytics.

Run from the project root with the virtual environment active:
    python etl/run_pipeline.py
"""
import logging

from sqlalchemy import text

from db import PROJECT_ROOT, get_engine
from extract_load import extract_load
from transform import transform

SQL_TRANSFORMS = PROJECT_ROOT / "sql" / "transforms"

log = logging.getLogger("pipeline")


def run_sql_file(engine, path):
    """Run one SQL file inside a transaction (all of it succeeds, or none of it does)."""
    with engine.begin() as conn:
        conn.exec_driver_sql(path.read_text())
    log.info("ran %s", path.relative_to(PROJECT_ROOT))


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(name)-12s %(message)s")
    engine = get_engine()

    extract_load(engine)                                  # CSV     -> raw       (Python)
    transform(engine)                                     # raw     -> staging   (Python)
    for path in sorted(SQL_TRANSFORMS.glob("*.sql")):     # staging -> analytics (SQL)
        run_sql_file(engine, path)

    with engine.connect() as conn:
        rows = conn.execute(text("SELECT count(*) FROM analytics.fact_pickups")).scalar_one()
    log.info("done: analytics.fact_pickups has %d rows", rows)


if __name__ == "__main__":
    main()
