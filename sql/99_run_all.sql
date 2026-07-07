\echo 'Loading starter schema and data from bad-db.sql'
\i /workspace/bad-db.sql

\echo 'Creating normalized schema'
\i /workspace/sql/01_normalized_schema.sql

\echo 'Migrating source data into normalized schema'
\i /workspace/sql/02_migrate_data.sql

\echo 'Running example DQL queries'
\i /workspace/sql/03_dql_examples.sql

\echo 'Running validation checks'
\i /workspace/sql/04_validation.sql
