# Udiddit

Udiddit is a PostgreSQL database design and migration case study. The project starts with a denormalized social-news dataset and refactors it into a normalized relational schema with constraints, indexes, migration scripts, example queries, and validation checks.

The original version came from Udacity's SQL Nanodegree, but this public version is organized as a portfolio project. The emphasis is on the database-design decisions, data-preserving migration strategy, and validation story behind the work.

## Project Highlights

- Replaces the denormalized starter schema with a five-table relational model.
- Adds named constraints and targeted indexes for moderation, lookup, activity, and scoring queries.
- Migrates the provided `bad_posts` and `bad_comments` data without losing posts, comments, topics, users, or votes.
- Includes example DQL for every project query plus a nested JSON comment-tree query as a stand-out item.
- Adds validation SQL for source-to-target counts, content rules, comment integrity, and vote integrity.
- Provides Docker Compose and Make commands so users can run the migration and validation flow locally.
- Publishes a lightweight GitHub Pages portfolio summary for quick inspection.

## Repository Layout

- `bad-db.sql` - supplied starter schema and data dump used for migration testing.
- `udiddit-a-social-news-aggregator-student-starter-template.docx` - supplied starter template.
- `udiddit-submission.docx` - completed supporting report.
- `sql/01_normalized_schema.sql` - normalized DDL with named constraints and indexes.
- `sql/02_migrate_data.sql` - migration DML from the bad schema into the normalized schema.
- `sql/03_dql_examples.sql` - example queries and stand-out JSON query.
- `sql/04_validation.sql` - focused validation checks for counts, constraints, and referential integrity.
- `sql/99_run_all.sql` - one-shot SQL runner for schema creation, migration, examples, and validation.
- `docker-compose.yml` - local PostgreSQL runtime.
- `Makefile` - convenience commands for resetting, migrating, validating, and inspecting the database.
- `docs/` - static GitHub Pages site.

## Design Notes

The normalized schema uses these tables:

- `users`
- `topics`
- `posts`
- `comments`
- `votes`

Implementation choices worth calling out:

1. The schema includes `last_logged_in_at` on `users` so the "hasn't logged in in the last year" query is supported.
2. The supplied dataset contains 152 legacy post titles longer than the stated 100-character product rule. To preserve the migrated source data exactly, the schema stores titles up to 150 characters and documents that mismatch instead of truncating the source material.
3. Comments include a self-reference so the model supports threaded replies, even though the starter data only provides top-level legacy comments.
4. Votes are converted from comma-separated text fields into one row per user/post vote, making scoring, uniqueness, and integrity checks enforceable in SQL.

## Running with Docker and Make

The fastest way to run the project locally is with Docker Compose:

```bash
docker compose up -d
make reset-db
```

`make reset-db` loads the starter dump, applies the normalized schema, migrates the data, runs the example queries, and executes validation checks.

Useful commands:

```bash
make up          # start PostgreSQL
make down        # stop PostgreSQL
make reset-db    # load bad-db.sql, migrate, run examples, and validate
make migrate     # apply schema and migration after bad-db.sql has been loaded
make validate    # run validation checks
make examples    # run example DQL queries
make psql        # open a psql shell inside the database container
```

## Running SQL Manually

Run the files in this order against PostgreSQL:

1. Load `bad-db.sql`
2. Run `sql/01_normalized_schema.sql`
3. Run `sql/02_migrate_data.sql`
4. Optionally run `sql/03_dql_examples.sql`
5. Run `sql/04_validation.sql`

The SQL was validated against the supplied starter data:

- `bad_posts`: 50,000 rows
- `bad_comments`: 100,000 rows
- migrated `users`: 11,077 rows
- migrated `topics`: 89 rows
- migrated `votes`: 499,710 rows

## GitHub Pages

The published project summary is available at:

[https://devin-thomas.github.io/udiddit/](https://devin-thomas.github.io/udiddit/)

## Supporting Report

The completed report preserves the original template formatting and includes:

- Part I schema analysis
- Part II normalized DDL
- Part III migration DML
- stand-out query examples

## Limitations

- The starter data does not include topic descriptions, topic creators, login timestamps, or threaded comments, so those fields are left nullable or migrated as top-level records where appropriate.
- The "latest" activity queries are indexed by descending surrogate key order because the supplied dataset does not include reliable creation timestamps.
