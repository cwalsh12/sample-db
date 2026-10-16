-- 02_roles.sql
-- Creates the database roles and decides who can see and change what.
--
--   etl_writer      (login)  used by the Python pipeline; reads/writes raw, staging, analytics
--   analyst         (group)  read-only access to the analytics schema
--   superset_reader (login)  member of analyst; used by Superset
--
-- Passwords are NOT written here, so this file is safe to commit.
-- They are read from environment variables that docker-compose.yml passes in from .env.
-- This file must be run with psql (it uses psql commands like \getenv and \gexec).

\getenv etl_password ETL_PASSWORD
\getenv superset_password SUPERSET_READER_PASSWORD

-- 1. Create the roles, only if they don't exist yet (so the file can be re-run).
--    \gexec runs the text that the SELECT returns as a SQL command.
SELECT 'CREATE ROLE analyst NOLOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analyst')
\gexec

SELECT 'CREATE ROLE etl_writer LOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'etl_writer')
\gexec

SELECT 'CREATE ROLE superset_reader LOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'superset_reader')
\gexec

ALTER ROLE etl_writer      PASSWORD :'etl_password';
ALTER ROLE superset_reader PASSWORD :'superset_password';

-- superset_reader gets every permission that analyst has
GRANT analyst TO superset_reader;

-- 2. Lock down the defaults. Out of the box, every role (PUBLIC) can connect
--    to the database. Remove that, then allow only our roles.
--    :"DBNAME" is filled in by psql with the current database name.
REVOKE ALL ON DATABASE :"DBNAME" FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE :"DBNAME" TO etl_writer, analyst;

-- 3. Schema access: USAGE lets a role look inside a schema.
--    It still needs table privileges (step 4) to read or write anything.
GRANT USAGE ON SCHEMA raw, staging, analytics TO etl_writer;
GRANT USAGE ON SCHEMA analytics TO analyst;

-- 4. Table privileges for tables (and views) created from now on in these schemas.
--    Without this, every new table would need its own GRANT.
ALTER DEFAULT PRIVILEGES IN SCHEMA raw, staging, analytics
    GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON TABLES TO etl_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics
    GRANT SELECT ON TABLES TO analyst;

-- 5. The same privileges for tables that already exist (matters when re-running this file).
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA raw, staging, analytics TO etl_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analyst;
