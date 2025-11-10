.PHONY: help dev down restart reset logs logs-api logs-frontend logs-db logs-redis \
        migrate migrate-rollback seed shell-db shell-api test test-api test-frontend \
        lint validate-secrets health prereqs clean nuke \
        k8s-setup k8s-deploy k8s-teardown fly-deploy

# Color output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(CYAN)Zero-to-Running Developer Environment$(NC)"
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Local Development (Docker Compose)

prereqs: ## Check if required tools are installed
	@echo "$(CYAN)Checking prerequisites...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)✗ Docker not found. Please install Docker Desktop or Colima.$(NC)"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "$(RED)✗ Docker is not running. Please start Docker.$(NC)"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || command -v docker compose >/dev/null 2>&1 || { echo "$(RED)✗ docker-compose not found.$(NC)"; exit 1; }
	@echo "$(GREEN)✓ All prerequisites met$(NC)"

validate-secrets: ## Validate .env secrets
	@echo "$(CYAN)Validating secrets...$(NC)"
	@if [ -f scripts/validate-secrets.sh ]; then \
		./scripts/validate-secrets.sh; \
	else \
		echo "$(YELLOW)Warning: validate-secrets.sh not found. Skipping.$(NC)"; \
	fi

dev: prereqs validate-secrets ## Start all services (frontend, API, DB, Redis)
	@echo "$(CYAN)Starting all services...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)No .env file found.$(NC)"; \
		echo ""; \
		echo "Choose an option:"; \
		echo "  1. Use safe defaults for local dev: cp .env.local.example .env && make dev"; \
		echo "  2. Use custom values: cp .env.example .env (then edit and run make dev)"; \
		echo ""; \
		echo "$(CYAN)💡 Quick start:$(NC) cp .env.local.example .env && make dev"; \
		exit 1; \
	fi
	@docker-compose up -d
	@echo ""
	@echo "$(GREEN)✓ Services starting...$(NC)"
	@echo "$(CYAN)Waiting for health checks to pass...$(NC)"
	@sleep 5
	@$(MAKE) health

down: ## Stop all services (keeps data volumes)
	@echo "$(CYAN)Stopping all services...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

restart: down dev ## Quick restart (down + dev)

reset: ## Nuclear option - stop, remove volumes, and restart fresh
	@echo "$(YELLOW)⚠ This will DELETE all data volumes!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "$(CYAN)Resetting environment...$(NC)"
	@docker-compose down -v
	@echo "$(GREEN)✓ Volumes removed$(NC)"
	@$(MAKE) dev

##@ Logs & Monitoring

logs: ## Tail logs from all services
	@docker-compose logs -f

logs-api: ## Tail logs from API service only
	@docker-compose logs -f api

logs-frontend: ## Tail logs from frontend service only
	@docker-compose logs -f frontend

logs-db: ## Tail logs from PostgreSQL
	@docker-compose logs -f postgres

logs-redis: ## Tail logs from Redis
	@docker-compose logs -f redis

health: ## Check health status of all services
	@echo "$(CYAN)Checking service health...$(NC)"
	@echo ""
	@POSTGRES_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_postgres 2>/dev/null || echo "not running"); \
	REDIS_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_redis 2>/dev/null || echo "not running"); \
	API_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_api 2>/dev/null || echo "not running"); \
	FRONTEND_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_frontend 2>/dev/null || echo "not running"); \
	\
	if [ "$$POSTGRES_STATUS" = "healthy" ]; then echo "$(GREEN)✓ PostgreSQL:$(NC) healthy"; else echo "$(RED)✗ PostgreSQL:$(NC) $$POSTGRES_STATUS"; fi; \
	if [ "$$REDIS_STATUS" = "healthy" ]; then echo "$(GREEN)✓ Redis:$(NC)      healthy"; else echo "$(RED)✗ Redis:$(NC)      $$REDIS_STATUS"; fi; \
	if [ "$$API_STATUS" = "healthy" ]; then echo "$(GREEN)✓ API:$(NC)         healthy"; else echo "$(RED)✗ API:$(NC)         $$API_STATUS"; fi; \
	if [ "$$FRONTEND_STATUS" = "healthy" ]; then echo "$(GREEN)✓ Frontend:$(NC)    healthy"; else echo "$(RED)✗ Frontend:$(NC)    $$FRONTEND_STATUS"; fi; \
	\
	if [ "$$POSTGRES_STATUS" = "healthy" ] && [ "$$REDIS_STATUS" = "healthy" ] && [ "$$API_STATUS" = "healthy" ] && [ "$$FRONTEND_STATUS" = "healthy" ]; then \
		echo ""; \
		echo "$(GREEN)✓ All services are healthy!$(NC)"; \
		echo "$(CYAN)Frontend:$(NC) http://localhost:3000"; \
		echo "$(CYAN)API:$(NC)      http://localhost:8000"; \
		echo "$(CYAN)API Health:$(NC) http://localhost:8000/health"; \
		exit 0; \
	else \
		echo ""; \
		echo "$(YELLOW)⚠ Some services are unhealthy. Check logs with:$(NC)"; \
		echo "  make logs-api"; \
		echo "  make logs-frontend"; \
		exit 1; \
	fi

##@ Database Management

migrate: ## Run database migrations
	@echo "$(CYAN)Running migrations...$(NC)"
	@docker-compose exec api pnpm run migrate
	@echo "$(GREEN)✓ Migrations complete$(NC)"

migrate-rollback: ## Rollback last migration
	@echo "$(CYAN)Rolling back last migration...$(NC)"
	@docker-compose exec api pnpm run migrate:down
	@echo "$(GREEN)✓ Rollback complete$(NC)"

seed: ## Load seed data into database
	@echo "$(CYAN)Loading seed data...$(NC)"
	@docker-compose exec api pnpm run seed
	@echo "$(GREEN)✓ Seed data loaded$(NC)"

shell-db: ## Open PostgreSQL shell
	@echo "$(CYAN)Opening PostgreSQL shell...$(NC)"
	@docker-compose exec postgres psql -U wander_user -d wander

##@ Development Workflow

test: test-api test-frontend ## Run all tests

test-api: ## Run API tests
	@echo "$(CYAN)Running API tests...$(NC)"
	@docker-compose exec api pnpm run test

test-frontend: ## Run frontend tests
	@echo "$(CYAN)Running frontend tests...$(NC)"
	@docker-compose exec frontend pnpm run test

shell-api: ## Open shell in API container
	@echo "$(CYAN)Opening API container shell...$(NC)"
	@docker-compose exec api sh

lint: ## Run linters on all code
	@echo "$(CYAN)Running linters...$(NC)"
	@docker-compose exec api pnpm run lint
	@docker-compose exec frontend pnpm run lint
	@echo "$(GREEN)✓ Linting complete$(NC)"

##@ Cleanup

clean: down ## Stop services and remove volumes (fresh start)
	@echo "$(CYAN)Cleaning up...$(NC)"
	@docker-compose down -v
	@echo "$(GREEN)✓ Volumes removed$(NC)"

nuke: ## Remove everything (images, volumes, containers)
	@echo "$(RED)⚠ This will remove ALL Docker images and volumes!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "$(CYAN)Nuking environment...$(NC)"
	@docker-compose down -v --rmi all
	@echo "$(GREEN)✓ Everything removed$(NC)"

##@ Kubernetes Deployment

k8s-setup: ## Setup local Kubernetes (Minikube)
	@echo "$(CYAN)Setting up local Kubernetes...$(NC)"
	@if [ -f scripts/k8s-setup.sh ]; then \
		./scripts/k8s-setup.sh; \
	else \
		echo "$(RED)Error: scripts/k8s-setup.sh not found$(NC)"; \
		exit 1; \
	fi

k8s-deploy: ## Deploy to Kubernetes (local or cloud)
	@echo "$(CYAN)Deploying to Kubernetes...$(NC)"
	@cd k8s/charts/wander && helm upgrade --install wander . -f values.yaml
	@echo "$(GREEN)✓ Deployed to Kubernetes$(NC)"

k8s-teardown: ## Remove Kubernetes deployment
	@echo "$(CYAN)Removing Kubernetes deployment...$(NC)"
	@helm uninstall wander || echo "$(YELLOW)Helm release not found$(NC)"
	@echo "$(GREEN)✓ Kubernetes deployment removed$(NC)"

fly-deploy: ## Deploy to Fly.io Kubernetes (production demo)
	@echo "$(CYAN)Deploying to Fly.io Kubernetes...$(NC)"
	@echo ""
	@echo "$(YELLOW)This will guide you through deploying to Fly.io K8s (FKS)$(NC)"
	@echo ""
	@echo "$(CYAN)📖 Full guide:$(NC) DEPLOY_FLY_K8S.md"
	@echo ""
	@read -p "Continue with automated setup? (y/N): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ] || [ "$$CONFIRM" = "Y" ]; then \
		if [ -f scripts/fks-setup.sh ]; then \
			./scripts/fks-setup.sh; \
		else \
			echo "$(RED)Error: scripts/fks-setup.sh not found$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(CYAN)Aborted. See DEPLOY_FLY_K8S.md for manual steps.$(NC)"; \
	fi
