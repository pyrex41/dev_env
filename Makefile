.PHONY: help dev down logs reset seed test deploy-staging deploy-local deploy-fks k8s-local-setup shell-api shell-db shell-frontend prereqs migrate clean status

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
	@echo "$(BLUE)📡 Service URLs:$(NC)"
	@echo "  $(YELLOW)🎨 Frontend:$(NC)    http://localhost:$$(grep FRONTEND_PORT .env | cut -d '=' -f2 || echo 3000)"
	@echo "  $(YELLOW)🚀 API:$(NC)          http://localhost:$$(grep API_PORT .env | cut -d '=' -f2 || echo 8000)"
	@echo "  $(YELLOW)❤️  Health Check:$(NC) http://localhost:$$(grep API_PORT .env | cut -d '=' -f2 || echo 8000)/health"
	@echo "  $(YELLOW)🐛 Debug Port:$(NC)   localhost:$$(grep DEBUG_PORT .env | cut -d '=' -f2 || echo 9229)"
	@echo "  $(YELLOW)🗄️  PostgreSQL:$(NC)   localhost:$$(grep POSTGRES_PORT .env | cut -d '=' -f2 || echo 5432)"
	@echo "  $(YELLOW)⚡ Redis:$(NC)        localhost:$$(grep REDIS_PORT .env | cut -d '=' -f2 || echo 6379)"
	@echo ""
	@echo "$(BLUE)💡 Quick Tips:$(NC)"
	@echo "  • View logs:     $(YELLOW)make logs$(NC)"
	@echo "  • Run tests:     $(YELLOW)make test$(NC)"
	@echo "  • Load test data: $(YELLOW)make seed$(NC)"
	@echo "  • API shell:     $(YELLOW)make shell-api$(NC)"
	@echo "  • Full reset:    $(YELLOW)make reset$(NC)"
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

shell-frontend: ## Open shell in frontend container
	@$(DOCKER_COMPOSE) exec frontend sh

migrate: ## Run database migrations manually
	@echo "$(BLUE)Running database migrations...$(NC)"
	@$(DOCKER_COMPOSE) exec api pnpm run migrate
	@echo "$(GREEN)✓ Migrations complete$(NC)"

clean: ## Clean up Docker resources
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

status: ## Show status of all services
	@echo "$(BLUE)Service Status:$(NC)"
	@$(DOCKER_COMPOSE) ps

k8s-local-setup: ## Set up local Kubernetes testing with Minikube
	@echo "$(BLUE)Setting up local Kubernetes environment...$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 1: Install tools (if needed)$(NC)"
	@command -v minikube >/dev/null 2>&1 || { echo "  Installing minikube..."; brew install minikube; }
	@command -v kubectl >/dev/null 2>&1 || { echo "  Installing kubectl..."; brew install kubectl; }
	@echo "$(GREEN)✓ Tools installed$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 2: Start Minikube$(NC)"
	@minikube status >/dev/null 2>&1 || minikube start --cpus=4 --memory=8192 --disk-size=40g
	@echo "$(GREEN)✓ Minikube running$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 3: Build images$(NC)"
	@eval $$(minikube docker-env) && \
		docker build -t wander-api:local ./api && \
		docker build -t wander-frontend:local ./frontend
	@echo "$(GREEN)✓ Images built$(NC)"
	@echo ""
	@echo "$(GREEN)✅ Local K8s environment ready!$(NC)"
	@echo "$(BLUE)Next: Run 'make deploy-local' to deploy$(NC)"

deploy-local: ## Deploy to local Minikube cluster
	@echo "$(BLUE)Deploying to local Minikube...$(NC)"
	@echo ""
	@minikube status >/dev/null 2>&1 || { echo "$(RED)✗ Minikube not running$(NC)"; echo "$(YELLOW)Run 'make k8s-local-setup' first$(NC)"; exit 1; }
	@echo "$(YELLOW)Installing/upgrading Helm chart...$(NC)"
	@helm upgrade --install wander-local ./k8s/charts/wander \
		--namespace wander-local \
		--create-namespace \
		--values ./k8s/charts/wander/values-local.yaml \
		--wait \
		--timeout 5m
	@echo "$(GREEN)✓ Deployed to Minikube$(NC)"
	@echo ""
	@echo "$(BLUE)📡 Access your services:$(NC)"
	@echo "  $(YELLOW)Frontend:$(NC) minikube service wander-local-frontend -n wander-local --url"
	@echo "  $(YELLOW)API:$(NC)      minikube service wander-local-api -n wander-local --url"
	@echo ""
	@echo "$(BLUE)💡 Useful commands:$(NC)"
	@echo "  • View pods:        $(YELLOW)kubectl get pods -n wander-local$(NC)"
	@echo "  • View services:    $(YELLOW)kubectl get svc -n wander-local$(NC)"
	@echo "  • View logs (API):  $(YELLOW)kubectl logs -f -n wander-local -l app=wander-api$(NC)"
	@echo "  • Delete deploy:    $(YELLOW)helm uninstall wander-local -n wander-local$(NC)"
	@echo "  • Stop Minikube:    $(YELLOW)minikube stop$(NC)"

deploy-fks: ## Deploy to Fly Kubernetes (FKS)
	@echo "$(BLUE)Deploying to Fly Kubernetes...$(NC)"
	@echo ""
	@echo "$(YELLOW)Prerequisites check:$(NC)"
	@command -v flyctl >/dev/null 2>&1 || { echo "$(RED)✗ flyctl not installed$(NC)"; echo "  Install: brew install flyctl"; exit 1; }
	@kubectl config current-context | grep -q "fks-" || { echo "$(RED)✗ Not connected to FKS cluster$(NC)"; echo "  See FLY_KUBERNETES_SETUP.md"; exit 1; }
	@echo "$(GREEN)✓ Prerequisites OK$(NC)"
	@echo ""
	@echo "$(YELLOW)Running migrations...$(NC)"
	@kubectl apply -f k8s/fks-migration-job.yaml
	@kubectl wait --for=condition=complete job/wander-migrations -n wander-fks --timeout=5m || { echo "$(RED)✗ Migrations failed$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Migrations complete$(NC)"
	@echo ""
	@echo "$(YELLOW)Deploying Helm chart...$(NC)"
	@helm upgrade --install wander-fks ./k8s/charts/wander \
		--namespace wander-fks \
		--create-namespace \
		--values ./k8s/charts/wander/values-fks.yaml \
		--wait \
		--timeout 10m
	@echo "$(GREEN)✓ Deployed to FKS$(NC)"
	@echo ""
	@echo "$(BLUE)📡 Get service URLs:$(NC)"
	@echo "  $(YELLOW)kubectl get svc -n wander-fks$(NC)"
	@echo ""
	@echo "$(BLUE)💡 Useful commands:$(NC)"
	@echo "  • View pods:        $(YELLOW)kubectl get pods -n wander-fks$(NC)"
	@echo "  • View logs (API):  $(YELLOW)kubectl logs -l app=wander-api -n wander-fks$(NC)"
	@echo "  • Delete deploy:    $(YELLOW)helm uninstall wander-fks -n wander-fks$(NC)"

deploy-staging: ## Deploy to staging Kubernetes cluster
	@echo "$(BLUE)Deploying to staging...$(NC)"
	@helm upgrade --install wander ./k8s/charts/wander \
		--namespace staging \
		--create-namespace \
		--values ./k8s/charts/wander/values-staging.yaml
	@echo "$(GREEN)✓ Deployed to staging$(NC)"
