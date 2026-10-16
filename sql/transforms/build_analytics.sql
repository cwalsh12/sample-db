-- build_analytics.sql
-- Rebuilds analytics.fact_pickups from staging.bin_pickups.
-- Run by etl/run_pipeline.py as etl_writer, inside one transaction: if anything fails,
-- nothing changes and the old data stays in place.
--
-- This is a "full refresh": empty the table, then reload everything.
-- Running it twice gives the same result, so it is safe to re-run.

TRUNCATE analytics.fact_pickups;

INSERT INTO analytics.fact_pickups (
    pickup_id, pickup_at, pickup_date, weight_lbs, bin_type, bin_size,
    material, waste_category, has_location, is_valid, invalid_reason
)
SELECT
    pickup_id,
    pickup_at,
    pickup_at::date,
    weight_lbs,
    bin_type,
    bin_size,
    material,
    waste_category,
    location IS NOT NULL,
    is_valid,
    invalid_reason
FROM staging.bin_pickups;
