DB_CONTAINER := udiddit-postgres
DB_USER := udiddit
DB_NAME := udiddit
PSQL := docker compose exec -T db psql -v ON_ERROR_STOP=1 -U $(DB_USER) -d $(DB_NAME)

.PHONY: up down clean-db reset-db load-starter migrate examples validate run-all psql logs

up:
	docker compose up -d

down:
	docker compose down

clean-db:
	$(PSQL) -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;"

load-starter:
	$(PSQL) -f /workspace/bad-db.sql

migrate:
	$(PSQL) -f /workspace/sql/01_normalized_schema.sql
	$(PSQL) -f /workspace/sql/02_migrate_data.sql

examples:
	$(PSQL) -f /workspace/sql/03_dql_examples.sql

validate:
	$(PSQL) -f /workspace/sql/04_validation.sql

run-all:
	$(PSQL) -f /workspace/sql/99_run_all.sql

reset-db: up clean-db load-starter migrate examples validate

psql:
	docker compose exec db psql -U $(DB_USER) -d $(DB_NAME)

logs:
	docker compose logs -f db
