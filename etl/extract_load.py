"""Step 1: copy the CSV into raw.bin_pickups exactly as it is."""
import logging

import pandas as pd
from sqlalchemy import text

from db import PROJECT_ROOT

CSV_PATH = PROJECT_ROOT / "data" / "MOCK_DATA.csv"

log = logging.getLogger(__name__)


def extract_load(engine):
    # dtype=str: don't let pandas guess types, keep everything as text.
    # keep_default_na=False: blank cells stay as "" instead of becoming NaN.
    # Raw should look exactly like the file.
    df = pd.read_csv(CSV_PATH, dtype=str, keep_default_na=False)

    df["_source_file"] = CSV_PATH.name
    df["_source_row"] = range(1, len(df) + 1)

    # Empty the table first so running the pipeline twice doesn't duplicate rows.
    # engine.begin() is a transaction: if the insert fails, the TRUNCATE is undone too.
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE raw.bin_pickups"))
        df.to_sql("bin_pickups", conn, schema="raw", if_exists="append", index=False)

    log.info("raw.bin_pickups: loaded %d rows from %s", len(df), CSV_PATH.name)
    return len(df)
