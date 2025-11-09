BANK := @
SHELL := /bin/bash
BACKEND_DIR := backend
DOCKER_COMPOSE := docker compose
ENV_FILE ?= .env.dev
NODE_RUN := cd $(BACKEND_DIR) && npm

define RUN_BACKEND
cd $(BACKEND_DIR) && $(1)
endef

define RUN_BACKEND_WITH_ENV
set -a; \
if [ -f $(ENV_FILE) ]; then . $(ENV_FILE); fi; \
set +a; \
cd $(BACKEND_DIR) && $(1)
endef

.PHONY: help install dev stop lint lint-fix format format-fix build clean prisma-generate prisma-migrate prisma-baseline prisma-push seed test docker-build-dev docker-build-prod docker-run-prod db-create-user db-reset

help:
	@echo "Available targets:"
	@echo "  install             Install backend dependencies via npm"
	@echo "  dev                 Start backend and PostgreSQL containers with dev profile"
	@echo "  stop                Stop all running compose services"
	@echo "  lint                Run ESLint checks"
	@echo "  lint-fix            Run ESLint with automatic fixes"
	@echo "  format              Run Prettier in check mode"
	@echo "  format-fix          Run Prettier with automatic formatting"
	@echo "  build               Compile TypeScript project and generate Prisma client"
	@echo "  clean               Remove build artifacts"
	@echo "  prisma-generate     Generate Prisma client"
	@echo "  prisma-migrate      Apply Prisma migrations using DATABASE_URL"
	@echo "  prisma-baseline     Baseline existing migrations (mark as applied)"
	@echo "  prisma-push         Push Prisma schema without migrations"
	@echo "  seed                Seed database with sample data"
	@echo "  test                Run project tests (placeholder)"
	@echo "  docker-build-dev    Build development Docker image"
	@echo "  docker-build-prod   Build production Docker image"
	@echo "  docker-run-prod     Run production Docker container"
	@echo "  db-create-user      Create tung_user role in PostgreSQL"
	@echo "  db-reset            Reset database (WARNING: deletes all data)"

install:
	@echo "Installing backend dependencies..."
	@cd $(BACKEND_DIR) && npm install

dev:
	@echo "Starting development stack with profile 'dev'..."
	@$(DOCKER_COMPOSE) --env-file $(ENV_FILE) --profile dev up --build

stop:
	@echo "Stopping compose services..."
	@$(DOCKER_COMPOSE) --env-file $(ENV_FILE) down

lint:
	@echo "Running ESLint..."
	@$(call RUN_BACKEND,npm run lint)

lint-fix:
	@echo "Running ESLint with fixes..."
	@$(call RUN_BACKEND,npm run lint:fix)

format:
	@echo "Running Prettier check..."
	@$(call RUN_BACKEND,npm run format)

format-fix:
	@echo "Running Prettier format..."
	@$(call RUN_BACKEND,npm run format:fix)

build:
	@echo "Building backend project..."
	@$(call RUN_BACKEND,npm run prisma:generate)
	@$(call RUN_BACKEND,npm run build)

clean:
	@echo "Cleaning build artifacts..."
	@$(call RUN_BACKEND,npm run clean)

prisma-generate:
	@echo "Generating Prisma client..."
	@$(call RUN_BACKEND,npm run prisma:generate)

prisma-migrate:
	@echo "Applying Prisma migrations..."
	@bash -c 'set -a; \
	if [ -f $(ENV_FILE) ]; then . $(ENV_FILE); fi; \
	set +a; \
	export DATABASE_URL="$${DATABASE_URL/db:5432/localhost:5432}"; \
	cd $(BACKEND_DIR) && npm run prisma:migrate'

prisma-baseline:
	@echo "Baselining Prisma migrations..."
	@bash -c 'set -a; \
	if [ -f $(ENV_FILE) ]; then . $(ENV_FILE); fi; \
	set +a; \
	export DATABASE_URL="$${DATABASE_URL/db:5432/localhost:5432}"; \
	cd $(BACKEND_DIR) && \
	for migration in prisma/migrations/*/; do \
		if [ -d "$$migration" ] && [ -f "$$migration/migration.sql" ]; then \
			migration_name=$$(basename "$$migration"); \
			echo "Marking migration $$migration_name as applied..."; \
			npx prisma migrate resolve --applied "$$migration_name" || true; \
		fi; \
	done'

prisma-push:
	@echo "Pushing Prisma schema..."
	@bash -c 'set -a; \
	if [ -f $(ENV_FILE) ]; then . $(ENV_FILE); fi; \
	set +a; \
	export DATABASE_URL="$${DATABASE_URL/db:5432/localhost:5432}"; \
	cd $(BACKEND_DIR) && npm run prisma:push'

seed:
	@echo "Seeding database..."
	@bash -c '$(call RUN_BACKEND_WITH_ENV,npm run seed)'

test:
	@echo "Tests are not configured yet. Add your test runner command here."

docker-build-dev:
	@echo "Building development Docker image..."
	@docker build --target development -t tung-backend:dev $(BACKEND_DIR)

docker-build-prod:
	@echo "Building production Docker image..."
	@docker build --target production -t tung-backend:prod $(BACKEND_DIR)

docker-run-prod:
	@echo "Running production Docker container..."
	@docker run --rm --env-file .env.prod -p 8080:3000 --name tung-backend tung-backend:prod

db-create-user:
	@echo "Creating tung_user role in PostgreSQL..."
	@bash -c 'set -a; \
	if [ -f $(ENV_FILE) ]; then . $(ENV_FILE); fi; \
	set +a; \
	docker compose --env-file $(ENV_FILE) exec -T db psql -U $$POSTGRES_USER -d $$POSTGRES_DB -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '\''tung_user'\'') THEN CREATE ROLE tung_user WITH LOGIN PASSWORD '\''$$POSTGRES_PASSWORD'\''; GRANT ALL PRIVILEGES ON DATABASE $$POSTGRES_DB TO tung_user; ALTER DATABASE $$POSTGRES_DB OWNER TO tung_user; END IF; END \$\$;" || echo "Note: If container is not running, start it first with 'make dev'"'

db-reset:
	@echo "WARNING: This will delete all database data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DOCKER_COMPOSE) --env-file $(ENV_FILE) down -v; \
		echo "Database volume removed. Run 'make dev' to recreate."; \
	else \
		echo "Cancelled."; \
	fi

