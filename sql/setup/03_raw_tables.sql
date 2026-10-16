-- 03_raw_tables.sql
-- raw.bin_pickups holds data/MOCK_DATA.csv exactly as it is.
-- Every column is text and there are no rules, so a bad row can never break the load.
-- Filled by etl/extract_load.py.

CREATE TABLE IF NOT EXISTS raw.bin_pickups (
    -- the 10 columns from the CSV, same names, all text
    bin_id               text,
    weight               text,
    bin_type             text,
    location             text,
    pickup_date          text,
    pickup_time          text,
    recycling_type       text,
    waste_category       text,
    recycling_bin_color  text,
    recycling_bin_size   text,

    -- load metadata, added by the pipeline (not in the CSV)
    _source_file         text        NOT NULL,
    _source_row          integer     NOT NULL,  -- data row number in the file (1 = first row after the header)
    _loaded_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE raw.bin_pickups IS 'Untouched copy of MOCK_DATA.csv';
