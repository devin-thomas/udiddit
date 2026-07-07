DB_CONTAINER := udiddit-postgres
DB_USER := udiddit
DB_NAME := udiddit
PSQL := docker compose exec -T db psql -v ON_ERROR_STOP=1 -U $(DB_USER) -d $(DB_NAME)

.PHONY: up down reset-db load-starter migrate examples validate psql logs

up:
	docker compose up -d

down:
	docker compose down

load-starter:
	$(PSQL) -f /workspace/bad-db.sql

migrate:
	$(PSQL) -f /workspace/sql/01_normalized_schema.sql
	$(PSQL) -f /workspace/sql/02_migrate_data.sql

examples:
	$(PSQL) -f /workspace/sql/03_dql_examples.sql

validate:
	$(PSQL) -f /workspace/sql/04_validation.sql

reset-db: up load-starter migrate examples validate

psql:
	docker compose exec db psql -U $(DB_USER) -d $(DB_NAME)

logs:
	docker compose logs -f db
