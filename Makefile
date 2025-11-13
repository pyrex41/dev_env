.PHONY: help install doctor dev down restart reset logs logs-api logs-frontend logs-db logs-redis \
        migrate migrate-rollback seed shell-db shell-api setup-vscode setup-hooks test test-api test-frontend \
        lint validate-secrets health prereqs clean nuke \
        k8s-setup k8s-deploy k8s-teardown gke-prereqs gke-setup gke-deploy gke-teardown

# Color output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Detect Docker Compose command (v1 vs v2)
COMPOSE_CMD := $(shell command -v docker-compose >/dev/null 2>&1 && echo "docker-compose" || echo "docker compose")

##@ General

help: ## Display this help message
	@echo "$(CYAN)Zero-to-Running Developer Environment$(NC)"
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

install: ## Install dependencies for all services
	@echo "$(CYAN)Installing dependencies...$(NC)"
	@cd api && pnpm install
	@cd frontend && pnpm install
	@echo ""
	@echo "$(GREEN)✓ Dependencies installed$(NC)"
	@echo ""
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  1. cp .env.local.example .env"
	@echo "  2. make dev"

doctor: ## Diagnose environment and common issues
	@echo "$(CYAN)Running diagnostics...$(NC)"
	@echo ""
	@echo "$(YELLOW)Prerequisites:$(NC)"
	@command -v docker >/dev/null 2>&1 && echo "$(GREEN)✓ Docker installed$(NC)" || echo "$(RED)✗ Docker not found$(NC) - Install from: https://docs.docker.com/get-docker/"
	@docker info >/dev/null 2>&1 && echo "$(GREEN)✓ Docker running$(NC)" || echo "$(RED)✗ Docker not running$(NC) - Run: open -a Docker (macOS) or sudo service docker start (Linux)"
	@command -v pnpm >/dev/null 2>&1 && echo "$(GREEN)✓ pnpm installed$(NC)" || echo "$(YELLOW)⚠ pnpm not found$(NC) - Install: npm install -g pnpm"
	@echo ""
	@echo "$(YELLOW)Port Availability:$(NC)"
	@if ! command -v lsof >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠ lsof not found - skipping port checks$(NC)"; \
		echo "  Install: apt-get install lsof (Linux) or included in macOS"; \
	else \
		for port in 3000 5432 6379 8000 9229; do \
			if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then \
				CONTAINER=$$(docker ps --format '{{.Names}}:{{.Ports}}' 2>/dev/null | grep ":$$port->" | cut -d: -f1 | head -1); \
				if [ -n "$$CONTAINER" ] && echo "$$CONTAINER" | grep -q "wander_"; then \
					echo "$(GREEN)✓ Port $$port in use by $$CONTAINER$(NC)"; \
				else \
					PROC=$$(lsof -t -i:$$port | head -1); \
					PROC_NAME=$$(ps -p $$PROC -o comm= 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "unknown"); \
					echo "$(RED)✗ Port $$port IN USE by $$PROC_NAME (PID $$PROC)$(NC) - Run: kill $$PROC"; \
				fi; \
			else \
				echo "$(GREEN)✓ Port $$port available$(NC)"; \
			fi; \
		done; \
	fi
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@[ -f .env ] && echo "$(GREEN)✓ .env file exists$(NC)" || echo "$(RED)✗ .env missing$(NC) - Run: cp .env.local.example .env"
	@[ -f .env ] && ! grep -q "CHANGE_ME" .env && echo "$(GREEN)✓ No CHANGE_ME placeholders$(NC)" || echo "$(YELLOW)⚠ Found CHANGE_ME in .env$(NC) - Run: cp .env.local.example .env"
	@echo ""
	@echo "$(YELLOW)Disk Space:$(NC)"
	@df -h / | awk 'NR==2 {print "  Available: " $$4 " (" $$5 " used)"}'
	@echo ""
	@echo "$(YELLOW)Docker Resources:$(NC)"
	@docker info 2>/dev/null | grep -E "(CPUs|Total Memory)" | sed 's/^/  /' || echo "  Unable to check (Docker not running)"

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
	@$(COMPOSE_CMD) up -d
	@echo ""
	@echo "$(GREEN)✓ Services starting...$(NC)"
	@echo "$(CYAN)Waiting for health checks to pass...$(NC)"
	@sleep 5
	@$(MAKE) health

down: ## Stop all services (keeps data volumes)
	@echo "$(CYAN)Stopping all services...$(NC)"
	@$(COMPOSE_CMD) down
	@echo "$(GREEN)✓ Services stopped$(NC)"

restart: down dev ## Quick restart (down + dev)

reset: ## Nuclear option - stop, remove volumes, and restart fresh
	@echo "$(YELLOW)⚠ This will DELETE all data volumes!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "$(CYAN)Resetting environment...$(NC)"
	@$(COMPOSE_CMD) down -v
	@echo "$(GREEN)✓ Volumes removed$(NC)"
	@$(MAKE) dev

##@ Logs & Monitoring

logs: ## Tail logs from all services
	@$(COMPOSE_CMD) logs -f

logs-api: ## Tail logs from API service only
	@$(COMPOSE_CMD) logs -f api

logs-frontend: ## Tail logs from frontend service only
	@$(COMPOSE_CMD) logs -f frontend

logs-db: ## Tail logs from PostgreSQL
	@$(COMPOSE_CMD) logs -f postgres

logs-redis: ## Tail logs from Redis
	@$(COMPOSE_CMD) logs -f redis

health: ## Check health status of all services
	@echo "$(CYAN)Checking service health...$(NC)"
	@echo ""
	@POSTGRES_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_postgres 2>/dev/null || echo "not running"); \
	REDIS_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_redis 2>/dev/null || echo "not running"); \
	API_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_api 2>/dev/null || echo "not running"); \
	FRONTEND_STATUS=$$(docker inspect --format='{{.State.Health.Status}}' wander_frontend 2>/dev/null || echo "not running"); \
	\
	if [ "$$POSTGRES_STATUS" = "healthy" ]; then \
		echo "$(GREEN)✓ PostgreSQL:$(NC) healthy"; \
	else \
		echo "$(RED)✗ PostgreSQL:$(NC) $$POSTGRES_STATUS"; \
		echo "  → Check: make logs-db"; \
		echo "  → Fix: Verify POSTGRES_PASSWORD in .env"; \
	fi; \
	\
	if [ "$$REDIS_STATUS" = "healthy" ]; then \
		echo "$(GREEN)✓ Redis:$(NC)      healthy"; \
	else \
		echo "$(RED)✗ Redis:$(NC)      $$REDIS_STATUS"; \
		echo "  → Check: make logs-redis"; \
		echo "  → Fix: Verify REDIS_PASSWORD in .env"; \
	fi; \
	\
	if [ "$$API_STATUS" = "healthy" ]; then \
		echo "$(GREEN)✓ API:$(NC)         healthy"; \
	else \
		echo "$(RED)✗ API:$(NC)         $$API_STATUS"; \
		echo "  → Check: make logs-api"; \
		echo "  → Fix: Check DATABASE_URL and run 'make migrate'"; \
	fi; \
	\
	if [ "$$FRONTEND_STATUS" = "healthy" ]; then \
		echo "$(GREEN)✓ Frontend:$(NC)    healthy"; \
	else \
		echo "$(RED)✗ Frontend:$(NC)    $$FRONTEND_STATUS"; \
		echo "  → Check: make logs-frontend"; \
		echo "  → Fix: Verify VITE_API_URL=http://localhost:8000"; \
	fi; \
	\
	if [ "$$POSTGRES_STATUS" = "healthy" ] && [ "$$REDIS_STATUS" = "healthy" ] && \
	   [ "$$API_STATUS" = "healthy" ] && [ "$$FRONTEND_STATUS" = "healthy" ]; then \
		echo ""; \
		echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"; \
		echo "$(GREEN)✅ All Systems Operational!$(NC)"; \
		echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"; \
		echo ""; \
		echo "$(CYAN)🌐 Frontend:$(NC)  http://localhost:3000"; \
		echo "$(CYAN)🔌 API:$(NC)       http://localhost:8000"; \
		echo "$(CYAN)💚 Health:$(NC)    http://localhost:8000/health"; \
		echo ""; \
		echo "$(CYAN)🗄️  Database:$(NC)  postgres://wander_user@localhost:5432/wander"; \
		echo "$(CYAN)⚡ Redis:$(NC)     redis://localhost:6379"; \
		echo ""; \
		echo "$(YELLOW)Next steps:$(NC)"; \
		echo "  make seed      # Load sample data"; \
		echo "  make logs      # View all logs"; \
		echo "  make test      # Run test suite"; \
		exit 0; \
	else \
		echo ""; \
		echo "$(YELLOW)⚠️  Some services need attention$(NC)"; \
		echo ""; \
		echo "Run $(CYAN)make doctor$(NC) for diagnostics"; \
		exit 1; \
	fi

##@ Database Management

migrate: ## Run database migrations
	@echo "$(CYAN)Running migrations...$(NC)"
	@$(COMPOSE_CMD) exec api pnpm run migrate
	@echo "$(GREEN)✓ Migrations complete$(NC)"

migrate-rollback: ## Rollback last migration
	@echo "$(CYAN)Rolling back last migration...$(NC)"
	@$(COMPOSE_CMD) exec api pnpm run migrate:down
	@echo "$(GREEN)✓ Rollback complete$(NC)"

seed: ## Load seed data into database
	@echo "$(CYAN)Loading seed data...$(NC)"
	@$(COMPOSE_CMD) exec api pnpm run seed
	@echo "$(GREEN)✓ Seed data loaded$(NC)"

shell-db: ## Open PostgreSQL shell
	@echo "$(CYAN)Opening PostgreSQL shell...$(NC)"
	@$(COMPOSE_CMD) exec postgres psql -U wander_user -d wander

##@ Development Workflow

setup-vscode: ## Setup VS Code workspace (extensions, debugger, settings)
	@echo "$(CYAN)Setting up VS Code workspace...$(NC)"
	@mkdir -p .vscode
	@echo "$(YELLOW)Creating VS Code configuration files...$(NC)"
	@cat > .vscode/extensions.json <<-'EOF'
	{
	  "recommendations": [
	    "dbaeumer.vscode-eslint",
	    "esbenp.prettier-vscode",
	    "ms-azuretools.vscode-docker",
	    "ms-vscode.vscode-typescript-next"
	  ]
	}
	EOF
	@cat > .vscode/launch.json <<-'EOF'
	{
	  "version": "0.2.0",
	  "configurations": [
	    {
	      "type": "node",
	      "request": "attach",
	      "name": "Attach to API (Docker)",
	      "port": 9229,
	      "restart": true,
	      "sourceMaps": true,
	      "skipFiles": ["<node_internals>/**"],
	      "localRoot": "$${workspaceFolder}/api",
	      "remoteRoot": "/app"
	    }
	  ]
	}
	EOF
	@cat > .vscode/settings.json <<-'EOF'
	{
	  "editor.formatOnSave": true,
	  "editor.defaultFormatter": "esbenp.prettier-vscode",
	  "typescript.tsdk": "node_modules/typescript/lib",
	  "[typescript]": {
	    "editor.defaultFormatter": "esbenp.prettier-vscode"
	  },
	  "[typescriptreact]": {
	    "editor.defaultFormatter": "esbenp.prettier-vscode"
	  }
	}
	EOF
	@echo ""
	@echo "$(GREEN)✓ VS Code workspace configured!$(NC)"
	@echo ""
	@echo "$(CYAN)What was created:$(NC)"
	@echo "  .vscode/extensions.json  - Recommended extensions"
	@echo "  .vscode/launch.json      - API debugger config (port 9229)"
	@echo "  .vscode/settings.json    - Format on save settings"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Restart VS Code or reload window"
	@echo "  2. Install recommended extensions when prompted"
	@echo "  3. Press F5 to attach debugger to API"

setup-hooks: ## Install optional pre-commit hooks (runs lint & test before commits)
	@echo "$(CYAN)Setting up pre-commit hooks...$(NC)"
	@if [ ! -f package.json ]; then \
		echo "$(RED)Error: package.json not found$(NC)"; \
		exit 1; \
	fi
	@command -v pnpm >/dev/null 2>&1 || { echo "$(RED)Error: pnpm not found. Install with: npm install -g pnpm$(NC)"; exit 1; }
	@echo "$(YELLOW)This will install husky and lint-staged for pre-commit hooks$(NC)"
	@if ! pnpm install || ! pnpm prepare; then \
		echo "$(RED)✗ Hook setup failed - cleaning up$(NC)"; \
		rm -rf node_modules .husky; \
		exit 1; \
	fi
	@mkdir -p .husky
	@echo '#!/usr/bin/env sh' > .husky/pre-commit
	@echo '. "$$(dirname -- "$$0")/_/husky.sh"' >> .husky/pre-commit
	@echo '' >> .husky/pre-commit
	@echo 'make lint && make test' >> .husky/pre-commit
	@chmod +x .husky/pre-commit
	@echo ""
	@echo "$(GREEN)✓ Pre-commit hooks installed!$(NC)"
	@echo ""
	@echo "$(CYAN)What this does:$(NC)"
	@echo "  - Runs 'make lint' before each commit"
	@echo "  - Runs 'make test' before each commit"
	@echo "  - Blocks commit if either fails"
	@echo ""
	@echo "$(YELLOW)To disable:$(NC) rm -rf .husky"

test: test-api test-frontend ## Run all tests

test-api: ## Run API tests
	@echo "$(CYAN)Running API tests...$(NC)"
	@$(COMPOSE_CMD) exec api pnpm run test

test-frontend: ## Run frontend tests
	@echo "$(CYAN)Running frontend tests...$(NC)"
	@$(COMPOSE_CMD) exec frontend pnpm run test

shell-api: ## Open shell in API container
	@echo "$(CYAN)Opening API container shell...$(NC)"
	@$(COMPOSE_CMD) exec api sh

lint: ## Run linters on all code
	@echo "$(CYAN)Running linters...$(NC)"
	@$(COMPOSE_CMD) exec api pnpm run lint
	@$(COMPOSE_CMD) exec frontend pnpm run lint
	@echo "$(GREEN)✓ Linting complete$(NC)"

##@ Cleanup

clean: down ## Stop services and remove volumes (fresh start)
	@echo "$(CYAN)Cleaning up...$(NC)"
	@$(COMPOSE_CMD) down -v
	@echo "$(GREEN)✓ Volumes removed$(NC)"

nuke: ## Remove everything (images, volumes, containers)
	@echo "$(RED)⚠ This will remove ALL Docker images and volumes!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "$(CYAN)Nuking environment...$(NC)"
	@$(COMPOSE_CMD) down -v --rmi all
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

##@ Google Kubernetes Engine (GKE)

gke-prereqs: ## Check GKE prerequisites
	@echo "$(CYAN)Checking GKE prerequisites...$(NC)"
	@echo ""
	@if command -v gcloud >/dev/null 2>&1; then \
		echo "$(GREEN)✓ gcloud installed$(NC)"; \
		gcloud version | grep "Google Cloud SDK"; \
	else \
		echo "$(RED)✗ gcloud not installed$(NC)"; \
		echo ""; \
		echo "Install options:"; \
		echo "  1. Manual: ./scripts/install-gcloud-manual.sh"; \
		echo "  2. Then restart terminal or run: source ~/.zshrc"; \
		echo ""; \
		exit 1; \
	fi
	@echo ""
	@if command -v kubectl >/dev/null 2>&1; then \
		echo "$(GREEN)✓ kubectl installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ kubectl not installed$(NC)"; \
		echo "  Install: brew install kubectl"; \
	fi
	@echo ""
	@if command -v helm >/dev/null 2>&1; then \
		echo "$(GREEN)✓ helm installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ helm not installed$(NC)"; \
		echo "  Install: brew install helm"; \
	fi

gke-setup: ## Setup GKE cluster
	@echo "$(CYAN)Setting up GKE cluster...$(NC)"
	@if [ -f scripts/gke-setup.sh ]; then \
		./scripts/gke-setup.sh; \
	else \
		echo "$(RED)Error: scripts/gke-setup.sh not found$(NC)"; \
		exit 1; \
	fi

gke-finish: ## Finish GKE setup (if cluster already exists)
	@echo "$(CYAN)Finishing GKE setup (cluster exists)...$(NC)"
	@if [ -f scripts/gke-finish-setup.sh ]; then \
		./scripts/gke-finish-setup.sh; \
	else \
		echo "$(RED)Error: scripts/gke-finish-setup.sh not found$(NC)"; \
		exit 1; \
	fi

gke-deploy: ## Deploy to GKE (builds images, pushes to GCR, deploys)
	@echo "$(CYAN)Deploying to GKE...$(NC)"
	@if [ -f scripts/gke-deploy.sh ]; then \
		./scripts/gke-deploy.sh; \
	else \
		echo "$(RED)Error: scripts/gke-deploy.sh not found$(NC)"; \
		exit 1; \
	fi

gke-teardown: ## Delete GKE cluster and all resources
	@echo "$(YELLOW)⚠ This will delete the entire GKE cluster and all data!$(NC)"
	@read -p "Continue? (y/N): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ] || [ "$$CONFIRM" = "Y" ]; then \
		echo "$(CYAN)Deleting GKE cluster...$(NC)"; \
		gcloud container clusters delete wander-cluster --zone us-central1-a --quiet; \
		echo "$(GREEN)✓ GKE cluster deleted$(NC)"; \
	else \
		echo "$(CYAN)Aborted$(NC)"; \
	fi
