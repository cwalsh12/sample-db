"""Step 2: clean raw.bin_pickups with pandas and write the result to staging.bin_pickups.

Every rule here comes from data/data_dict.md.
"""
import logging

import pandas as pd
from sqlalchemy import text

log = logging.getLogger(__name__)


def clean(raw):
    """Turn raw text columns into typed, tidy columns."""
    # Blank or whitespace-only text becomes a real missing value
    raw = raw.replace(r"^\s*$", pd.NA, regex=True)

    def tidy(col):
        """Trim spaces and lowercase, so ' Compost' and 'compost' match."""
        return raw[col].str.strip().str.lower()

    out = pd.DataFrame()
    out["pickup_id"] = raw["_source_row"]
    out["bin_id"] = pd.to_numeric(raw["bin_id"]).astype("Int64")  # Int64 (capital I) allows missing values
    out["weight_lbs"] = pd.to_numeric(raw["weight"]).round(2)
    out["bin_type"] = tidy("bin_type")
    out["location"] = raw["location"].str.strip()

    # "3/21/2022" + "8:58 PM" -> 2022-03-21 20:58:00
    out["pickup_at"] = pd.to_datetime(
        raw["pickup_date"] + " " + raw["pickup_time"],
        format="%m/%d/%Y %I:%M %p",
    )

    # Business rule 3: material only applies to recycling bins
    out["material"] = tidy("recycling_type").where(out["bin_type"] == "recycling")

    out["waste_category"] = tidy("waste_category")
    out["bin_color_hex"] = tidy("recycling_bin_color")
    out["bin_size"] = tidy("recycling_bin_size")
    out["_source_file"] = raw["_source_file"]
    out["_loaded_at"] = raw["_loaded_at"]
    return out


def find_invalid_reason(df):
    """Return the first business rule each row breaks, or <NA> if the row is valid."""
    rules = [
        (df["bin_id"].isna(), "missing bin_id"),
        (
            (df["bin_type"] == "compost") & (df["waste_category"] != "food waste"),
            "compost bin with non-food waste",
        ),
        (
            (df["bin_type"] == "recycling") & (df["waste_category"] == "hazardous waste"),
            "hazardous waste in recycling bin",
        ),
    ]
    reason = pd.Series(pd.NA, index=df.index, dtype="string")
    # Apply in reverse so that, when a row breaks several rules, the first rule wins
    for broken, message in reversed(rules):
        reason = reason.mask(broken, message)
    return reason


def transform(engine):
    with engine.connect() as conn:
        raw = pd.read_sql(text("SELECT * FROM raw.bin_pickups"), conn)

    staged = clean(raw)
    staged["invalid_reason"] = find_invalid_reason(staged)
    staged["is_valid"] = staged["invalid_reason"].isna()

    with engine.begin() as conn:
        conn.execute(text("TRUNCATE staging.bin_pickups"))
        staged.to_sql("bin_pickups", conn, schema="staging", if_exists="append", index=False)

    log.info(
        "staging.bin_pickups: %d rows (%d valid, %d flagged)",
        len(staged), staged["is_valid"].sum(), (~staged["is_valid"]).sum(),
    )
    return len(staged)
