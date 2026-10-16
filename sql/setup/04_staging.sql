-- 04_staging.sql
-- staging.bin_pickups holds the cleaned, typed version of raw.bin_pickups.
-- Filled by etl/transform.py. The CHECK constraints are a safety net: if the
-- Python cleaning misses something, the insert fails instead of storing bad data.

CREATE TABLE IF NOT EXISTS staging.bin_pickups (
    pickup_id       integer       PRIMARY KEY,  -- = raw._source_row, so every row traces back to its CSV line
    bin_id          integer,                    -- 29 rows have no bin_id
    weight_lbs      numeric(6,2)  NOT NULL CHECK (weight_lbs > 0),
    bin_type        text          NOT NULL CHECK (bin_type IN ('waste', 'compost', 'recycling')),
    location        text,
    pickup_at       timestamp     NOT NULL,     -- pickup_date + pickup_time combined
    material        text          CHECK (material IN ('paper', 'plastic', 'glass', 'metal')),  -- only for recycling bins
    waste_category  text          NOT NULL CHECK (waste_category IN ('non-recyclable', 'food waste', 'hazardous waste')),
    bin_color_hex   char(7)       CHECK (bin_color_hex ~ '^#[0-9a-f]{6}$'),
    bin_size        text          NOT NULL CHECK (bin_size IN ('small', 'medium', 'large')),

    -- business rule results (see data/data_dict.md)
    is_valid        boolean       NOT NULL,
    invalid_reason  text,

    _source_file    text          NOT NULL,
    _loaded_at      timestamptz   NOT NULL
);

COMMENT ON TABLE staging.bin_pickups IS 'Cleaned bin pickups, one row per pickup';
