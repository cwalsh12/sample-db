-- 05_analytics.sql
-- Tables shaped for Superset.
--   dim_* = lookup tables ("dimensions"): fixed lists you filter and group by
--   fact_pickups = one row per pickup with the numbers you chart ("facts")

-- Lookup tables. These are reference data, so they are filled here, not by the pipeline.
CREATE TABLE IF NOT EXISTS analytics.dim_bin_type (
    bin_type     text PRIMARY KEY,
    description  text NOT NULL
);

INSERT INTO analytics.dim_bin_type (bin_type, description) VALUES
    ('waste',     'General waste going to landfill'),
    ('compost',   'Food and organic waste'),
    ('recycling', 'Paper, plastic, glass and metal')
ON CONFLICT (bin_type) DO NOTHING;

CREATE TABLE IF NOT EXISTS analytics.dim_bin_size (
    bin_size   text     PRIMARY KEY,
    size_rank  smallint NOT NULL UNIQUE  -- sort by this, not by name (alphabetical would be large, medium, small)
);

INSERT INTO analytics.dim_bin_size (bin_size, size_rank) VALUES
    ('small',  1),
    ('medium', 2),
    ('large',  3)
ON CONFLICT (bin_size) DO NOTHING;

-- Fact table. Rebuilt by sql/transforms/build_analytics.sql on every pipeline run.
-- Street addresses and bin colors are left out on purpose: dashboards don't need them,
-- and Superset can only ever see what is in this schema.
CREATE TABLE IF NOT EXISTS analytics.fact_pickups (
    pickup_id       integer       PRIMARY KEY,
    pickup_at       timestamp     NOT NULL,
    pickup_date     date          NOT NULL,
    weight_lbs      numeric(6,2)  NOT NULL,
    bin_type        text          NOT NULL REFERENCES analytics.dim_bin_type (bin_type),
    bin_size        text          NOT NULL REFERENCES analytics.dim_bin_size (bin_size),
    material        text,
    waste_category  text          NOT NULL,
    has_location    boolean       NOT NULL,
    is_valid        boolean       NOT NULL,
    invalid_reason  text
);

COMMENT ON TABLE analytics.fact_pickups IS 'One row per bin pickup, ready for charts';
