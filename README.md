# Udiddit

This repository contains a submission-ready solution for the Udiddit database design project from Udacity's SQL Nanodegree. The work normalizes the supplied starter schema, migrates the provided data into a relational design, and documents the project in the completed Word template required for submission.

## Project Highlights

- Replaces the denormalized starter schema with a five-table relational model.
- Adds named constraints and targeted indexes for the required moderation and activity queries.
- Migrates the provided `bad_posts` and `bad_comments` data without losing posts, comments, topics, users, or votes.
- Includes example DQL for every query in the rubric plus a nested JSON comment query as a stand-out item.
- Publishes a lightweight GitHub Pages portfolio summary for quick review.

## Repository Layout

- `bad-db.sql` - supplied starter schema and data dump used for migration testing.
- `udiddit-a-social-news-aggregator-student-starter-template.docx` - supplied starter template.
- `udiddit-submission.docx` - completed submission document.
- `sql/01_normalized_schema.sql` - normalized DDL with named constraints and indexes.
- `sql/02_migrate_data.sql` - migration DML from the bad schema into the normalized schema.
- `sql/03_dql_examples.sql` - rubric-aligned example queries and stand-out JSON query.
- `sql/04_validation.sql` - focused validation checks for counts, constraints, and referential integrity.
- `docs/` - static GitHub Pages site.

## Design Notes

The normalized schema uses these tables:

- `users`
- `topics`
- `posts`
- `comments`
- `votes`

Two implementation choices are worth calling out:

1. The schema includes `last_logged_in_at` on `users` so the "hasn't logged in in the last year" query is supported.
2. The supplied dataset contains 152 legacy post titles longer than the stated 100-character product rule. To preserve the migrated source data exactly, the schema stores titles up to 150 characters and calls out that mismatch in the submission document instead of truncating the source material.

## Running the SQL

Run the files in this order against PostgreSQL:

1. Load `bad-db.sql`
2. Run `sql/01_normalized_schema.sql`
3. Run `sql/02_migrate_data.sql`
4. Optionally run `sql/03_dql_examples.sql`
5. Run `sql/04_validation.sql`

The SQL was validated locally against a PostgreSQL-compatible engine using the supplied starter data:

- `bad_posts`: 50,000 rows
- `bad_comments`: 100,000 rows
- migrated `users`: 11,077 rows
- migrated `topics`: 89 rows
- migrated `votes`: 499,710 rows

## GitHub Pages

The published project summary is intended to be available at:

[https://devin-thomas.github.io/udiddit/](https://devin-thomas.github.io/udiddit/)

## Submission Notes

The completed submission document preserves the starter template formatting and includes:

- Part I schema analysis
- Part II normalized DDL
- Part III migration DML
- stand-out query examples

## Limitations

- The starter data does not include topic descriptions, topic creators, login timestamps, or threaded comments, so those fields are left nullable or migrated as top-level records where appropriate.
- The "latest" activity queries are indexed by descending surrogate key order because the supplied dataset does not include reliable creation timestamps.
