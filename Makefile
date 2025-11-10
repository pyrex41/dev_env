.PHONY: help dev down logs reset seed test deploy-staging shell-api shell-db prereqs

# Colors for output
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
BLUE=\033[0;34m
NC=\033[0m # No Color

# Detect Docker Compose command (v1 or v2)
DOCKER_COMPOSE := $(shell command -v docker-compose 2>/dev/null)
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := docker compose
endif

help: ## Show this help message
	@echo "$(BLUE)Wander Dev Environment$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

prereqs: ## Check prerequisites
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)✗ Docker is not installed$(NC)"; echo "$(YELLOW)  Install: brew install --cask docker$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker installed$(NC)"
	@docker info >/dev/null 2>&1 || { echo "$(RED)✗ Docker daemon is not running$(NC)"; echo "$(YELLOW)  Start Docker Desktop or run: open -a Docker$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker daemon is running$(NC)"
	@$(DOCKER_COMPOSE) version >/dev/null 2>&1 || { echo "$(RED)✗ Docker Compose is not available$(NC)"; echo "$(YELLOW)  Install: brew install docker-compose$(NC)"; echo "$(YELLOW)  Or see INSTALL.md for other options$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker Compose available ($(DOCKER_COMPOSE))$(NC)"
	@echo "$(GREEN)All prerequisites satisfied!$(NC)"

.env:
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Creating .env from .env.example...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)✓ .env file created$(NC)"; \
		echo "$(YELLOW)⚠ Please update .env with your configuration$(NC)"; \
	fi

dev: prereqs .env ## Start all services with health checks
	@echo "$(BLUE)Starting Wander development environment...$(NC)"
	@echo ""
	@$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "$(YELLOW)Waiting for services to be healthy...$(NC)"
	@echo ""
	@echo "$(BLUE)› PostgreSQL...$(NC)"
	@timeout 60 sh -c 'until $(DOCKER_COMPOSE) ps postgres | grep -q "healthy"; do sleep 2; done' && echo "$(GREEN)  ✓ PostgreSQL ready$(NC)" || { echo "$(RED)  ✗ PostgreSQL failed to start$(NC)"; exit 1; }
	@echo "$(BLUE)› Redis...$(NC)"
	@timeout 60 sh -c 'until $(DOCKER_COMPOSE) ps redis | grep -q "healthy"; do sleep 2; done' && echo "$(GREEN)  ✓ Redis ready$(NC)" || { echo "$(RED)  ✗ Redis failed to start$(NC)"; exit 1; }
	@echo "$(BLUE)› API...$(NC)"
	@timeout 90 sh -c 'until $(DOCKER_COMPOSE) ps api | grep -q "healthy"; do sleep 2; done' && echo "$(GREEN)  ✓ API ready$(NC)" || { echo "$(RED)  ✗ API failed to start$(NC)"; exit 1; }
	@echo "$(BLUE)› Frontend...$(NC)"
	@timeout 60 sh -c 'until $(DOCKER_COMPOSE) ps frontend | grep -q "healthy"; do sleep 2; done' && echo "$(GREEN)  ✓ Frontend ready$(NC)" || { echo "$(RED)  ✗ Frontend failed to start$(NC)"; exit 1; }
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)✅ Environment ready!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(BLUE)Service URLs:$(NC)"
	@echo "  $(YELLOW)Frontend:$(NC)  http://localhost:$$(grep FRONTEND_PORT .env | cut -d '=' -f2 || echo 3000)"
	@echo "  $(YELLOW)API:$(NC)       http://localhost:$$(grep API_PORT .env | cut -d '=' -f2 || echo 8000)"
	@echo "  $(YELLOW)API Debug:$(NC) localhost:$$(grep DEBUG_PORT .env | cut -d '=' -f2 || echo 9229)"
	@echo "  $(YELLOW)PostgreSQL:$(NC) localhost:$$(grep POSTGRES_PORT .env | cut -d '=' -f2 || echo 5432)"
	@echo "  $(YELLOW)Redis:$(NC)     localhost:$$(grep REDIS_PORT .env | cut -d '=' -f2 || echo 6379)"
	@echo ""

down: ## Stop and remove all containers and volumes
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes
	@echo "$(GREEN)✓ All services stopped and volumes removed$(NC)"

logs: ## Tail logs from all services
	@$(DOCKER_COMPOSE) logs -f

reset: down ## Full teardown and fresh start
	@echo "$(YELLOW)Performing full reset...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)✓ Environment reset complete$(NC)"
	@echo "$(BLUE)Run 'make dev' to start fresh$(NC)"

seed: ## Load test data into database
	@echo "$(BLUE)Loading test data...$(NC)"
	@$(DOCKER_COMPOSE) exec api pnpm run seed
	@echo "$(GREEN)✓ Test data loaded$(NC)"

test: ## Run test suites in containers
	@echo "$(BLUE)Running test suites...$(NC)"
	@$(DOCKER_COMPOSE) exec api pnpm test
	@$(DOCKER_COMPOSE) exec frontend pnpm test
	@echo "$(GREEN)✓ Tests complete$(NC)"

shell-api: ## Open shell in API container
	@$(DOCKER_COMPOSE) exec api sh

shell-db: ## Open PostgreSQL shell
	@$(DOCKER_COMPOSE) exec postgres psql -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) -d $$(grep POSTGRES_DB .env | cut -d '=' -f2)

deploy-staging: ## Deploy to staging Kubernetes cluster
	@echo "$(BLUE)Deploying to staging...$(NC)"
	@helm upgrade --install wander ./k8s/charts/wander \
		--namespace staging \
		--create-namespace \
		--values ./k8s/charts/wander/values-staging.yaml
	@echo "$(GREEN)✓ Deployed to staging$(NC)"
