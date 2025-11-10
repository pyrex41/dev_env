# Wander Dev Environment

Zero-to-running local development environment in under 10 minutes.

## Quick Start

### Option 1: Interactive Setup (Recommended for First Time)

```bash
# Run the interactive setup script
./setup.sh
```

The script will:
- Check all prerequisites
- Help install missing dependencies
- Start Docker if needed
- Configure your environment
- Optionally start the services

### Option 2: Manual Start (If Already Setup)

```bash
# 1. Start everything
make dev
```

That's it! Visit http://localhost:3000 to see your app.

## Prerequisites

- **Colima** (recommended) or Docker Desktop 4.x+
- docker-compose 2.x+ (included with Docker)
- **8GB RAM minimum**
- **10GB free disk space**

Check prerequisites:
```bash
make prereqs
```

### First-Time Installation

If you don't have Docker/Colima installed yet:

**Option 1: Colima (Recommended - Lightweight)**
```bash
# Install via Homebrew (macOS)
brew install colima docker docker-compose

# Start Colima with optimal settings
colima start --cpu 4 --memory 8 --disk 60

# Verify
docker info
```

**Option 2: Docker Desktop**
```bash
# Install via Homebrew
brew install --cask docker

# Or download from https://www.docker.com/products/docker-desktop
# Then start Docker Desktop and wait for it to fully initialize
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make dev` | Start all services with health checks |
| `make down` | Stop and remove all containers/volumes |
| `make logs` | Tail logs from all services |
| `make reset` | Full teardown and fresh start |
| `make migrate` | Run database migrations |
| `make seed` | Load test data into database |
| `make test` | Run test suites (API + Frontend) |
| `make shell-api` | Open shell in API container |
| `make shell-db` | Open PostgreSQL shell |
| `make k8s-local-setup` | Set up local Kubernetes (Minikube) |
| `make deploy-local` | Deploy to local Minikube cluster |
| `make deploy-fks` | Deploy to Fly Kubernetes (FKS) |

## Services

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | React + TypeScript + Vite + Tailwind CSS v4 |
| API | http://localhost:8000 | Node + TypeScript + Express |
| API Health | http://localhost:8000/health | Health check endpoint |
| PostgreSQL | localhost:5432 | Database |
| Redis | localhost:6379 | Cache |
| Debug Port | localhost:9229 | Node.js debugger |

## Configuration

Environment variables are in `.env` (auto-created from `.env.example`).

**Important:** Change all `CHANGE_ME` values in `.env` before deploying to production.

## Hot Reload

Both frontend and API support hot reload:
- Edit files in `api/src/` or `frontend/src/`
- Changes apply automatically
- No rebuild needed

## Development Workflow

### 1. Daily Start
```bash
make dev
```

### 2. Make Changes
- Edit code in `api/src/` or `frontend/src/`
- Changes auto-reload

### 3. View Logs
```bash
make logs
```

### 4. Test
```bash
make test
```

### 5. Clean Shutdown
```bash
make down
```

## Package Manager (pnpm)

This project uses **pnpm** instead of npm for superior performance and efficiency.

### Why pnpm?
- ⚡ **3x faster** - Uses content-addressable storage
- 💾 **70% less disk space** - Shares packages across projects (100MB vs 300MB per project)
- 🔒 **Stricter dependency resolution** - Better reliability
- 📦 **100% npm compatible** - Drop-in replacement

### How it works
- **You don't need to install pnpm locally** - it runs inside Docker containers
- pnpm is enabled via Node.js corepack (built-in to Node 16+)
- `pnpm-lock.yaml` files ensure consistent installs across environments
- **Always commit lockfiles** to version control

### Adding/Removing Packages

**Method 1: Edit package.json, then rebuild**
```bash
# Edit api/package.json or frontend/package.json
make down
make dev  # Rebuilds with new dependencies
```

**Method 2: Use container shell**
```bash
make shell-api
pnpm add express        # Add package
pnpm remove lodash      # Remove package
exit
make down && make dev   # Rebuild to persist
```

## Project Structure

```
dev_env/
├── api/                    # Node/TypeScript API
│   ├── src/
│   ├── Dockerfile
│   ├── package.json
│   └── pnpm-lock.yaml
├── frontend/               # React/TypeScript Frontend
│   ├── src/
│   ├── Dockerfile
│   ├── package.json
│   └── pnpm-lock.yaml
├── k8s/                    # Kubernetes configs
│   └── charts/wander/
├── docker-compose.yml      # Service definitions
├── Makefile               # Developer commands
├── .env.example           # Config template
└── README.md
```

## Architecture

**Local Development:** Docker Compose (simple, fast)
**Deployment:** Kubernetes + Helm (scalable, production-ready)

Services start in order:
1. PostgreSQL + Redis (databases)
2. API (waits for databases)
3. Frontend (waits for API)

Health checks ensure each service is ready before the next starts.

## Features

### Database Migrations
- **Automatic execution** on API startup using `node-pg-migrate`
- Initial schema includes `users` and `posts` tables with foreign keys
- Run manually: `make migrate`
- Migrations located in: `api/src/migrations/`

### Seed Data System
- TypeScript seed runners with type safety
- Idempotent seeding (can run multiple times safely)
- **Default seed data**: 5 test users + 8 posts
- Run seeds: `make seed`
- Seeds located in: `api/src/seeds/`

### Testing Infrastructure (Vitest)
- **API tests**: 9 tests (health checks + database)
- **Frontend tests**: 5 tests (component + integration)
- Run tests: `make test`
- Tests located in: `api/src/__tests__/` and `frontend/src/__tests__/`
- Unified testing framework across API and frontend

## Kubernetes Deployment

Production-ready Helm charts with three deployment options:

### Option 1: Local Testing with Minikube (Free)

Test your Kubernetes deployment locally - **no cloud costs!**

```bash
# Setup (first time only, ~10 minutes)
make k8s-local-setup

# Deploy (~5 minutes)
make deploy-local

# Access services
minikube service wander-local-frontend -n wander-local
minikube service wander-local-api -n wander-local
```

**What it does:**
- Installs Minikube + kubectl (if needed)
- Starts local K8s cluster (4 CPUs, 8GB RAM)
- Builds Docker images locally
- Deploys with Helm using `values-local.yaml`

**When to use:** Validate Helm charts before production deployment

**Cleanup:**
```bash
helm uninstall wander-local -n wander-local  # Remove deployment
minikube stop  # Stop cluster (free up resources)
```

### Option 2: Fly.io Kubernetes (FKS)

Deploy to Fly.io's managed Kubernetes service (beta).

```bash
# Setup (first time, ~20 minutes)
./scripts/fks-setup.sh

# Build and push images
fly auth docker
docker build -t registry.fly.io/<your-org>/wander-api:latest ./api
docker push registry.fly.io/<your-org>/wander-api:latest
docker build -t registry.fly.io/<your-org>/wander-frontend:latest ./frontend
docker push registry.fly.io/<your-org>/wander-frontend:latest

# Deploy (~10 minutes)
make deploy-fks

# Get service URLs
kubectl get svc -n wander-fks
```

**What `fks-setup.sh` does:**
- Creates FKS cluster: `fly ext k8s create`
- Sets up WireGuard VPN for cluster access
- Creates Fly Postgres database
- Configures Kubernetes secrets
- Updates image registry references

**FKS Adaptations (Beta Limitations):**
- ❌ No init containers → Migrations run as separate Job
- ❌ No HPA → Fixed replicas, scale manually with kubectl
- ❌ No multi-container pods → Single container per pod
- ✅ LoadBalancer services → Get public Fly.io IPs
- ✅ External databases → Fly Postgres + Upstash Redis

**When to use:** Demo K8s deployment on Fly.io platform

**Cost:** FKS has costs - check Fly.io pricing. Recommended: create → demo → destroy

**Cleanup:**
```bash
helm uninstall wander-fks -n wander-fks  # Remove deployment
fly ext k8s destroy <cluster-name>  # Delete cluster
```

### Option 3: Cloud Kubernetes (Production)

Deploy to GKE, EKS, AKS, or DigitalOcean Kubernetes.

```bash
# Deploy to staging
helm upgrade --install wander ./k8s/charts/wander \
  --namespace staging \
  --create-namespace \
  --values ./k8s/charts/wander/values-staging.yaml

# Deploy to production
helm upgrade --install wander ./k8s/charts/wander \
  --namespace production \
  --create-namespace \
  --values ./k8s/charts/wander/values-prod.yaml
```

**Production values include:**
- Horizontal Pod Autoscaling (3-20 pods)
- High-availability Redis (2 replicas)
- Resource limits (10Gi+ for production)
- Ingress with TLS/HTTPS
- External Secrets support

**When to use:** Production deployments

### Kubernetes Deployment Comparison

| Method | Setup Time | Cost | Best For |
|--------|------------|------|----------|
| **Minikube** | 10 min | $0 | Testing Helm charts locally |
| **FKS** | 30 min | $$$ | Demo K8s on Fly.io |
| **GKE/EKS/AKS** | 20 min | $$$$ | Production K8s |

### Kubernetes Files

```
k8s/charts/wander/
├── Chart.yaml              # Metadata and dependencies
├── values.yaml             # Default (development)
├── values-local.yaml       # Minikube local testing
├── values-fks.yaml         # Fly Kubernetes
├── values-staging.yaml     # Staging environment
├── values-prod.yaml        # Production with HA
├── templates/              # Deployments, services, configs
└── README.md               # Helm chart documentation

k8s/fks-migration-job.yaml  # Migration Job for FKS
scripts/fks-setup.sh        # FKS interactive setup
```

## Database Schema

After running `make dev`, the following tables are automatically created:

### Users Table
- `id` (serial, primary key)
- `email` (unique, indexed)
- `username` (unique)
- `password_hash`
- `created_at`, `updated_at` (timestamps)

### Posts Table
- `id` (serial, primary key)
- `user_id` (foreign key → users.id)
- `title`
- `content` (text)
- `status` (draft/published/archived)
- `created_at`, `updated_at` (timestamps with indexes)

## Troubleshooting

### Port Conflicts

**Problem:** Port already in use

**Solution:**
```bash
# Find process using port
lsof -ti:3000  # or :8000, :5432, :6379

# Kill process or change port in .env
```

### Docker Not Running

**Problem:** Cannot connect to Docker daemon

**Solution:**
```bash
# Start Colima
colima start

# Check status
colima status

# Then run your environment
make dev
```

### Colima Management

This project uses **Colima** instead of Docker Desktop for lightweight, CLI-based container management.

**Common Commands:**
```bash
# Start Colima
colima start

# Stop Colima
colima stop

# Restart Colima
colima restart

# Check status
colima status

# View logs
colima logs

# Delete and recreate (cleans everything)
colima delete && colima start --cpu 4 --memory 8 --disk 60
```

**Why Colima?**
- 🚀 Faster and more stable than Docker Desktop
- 💾 Uses ~1GB RAM vs Docker Desktop's 2-4GB
- ⚡ Native Apple Silicon performance (macOS Virtualization.Framework)
- 🔧 100% Docker CLI compatible - no changes to your workflow
- 🆓 Free and open source

### Services Not Healthy

**Problem:** Services stuck in "starting" state

**Solution:**
```bash
# Check logs
make logs

# Full reset
make reset
make dev
```

### Database Connection Issues

**Problem:** API can't connect to PostgreSQL

**Solution:**
```bash
# Verify PostgreSQL is healthy
docker compose ps postgres

# Check logs
docker compose logs postgres

# Reset if needed
make reset
```

### Minikube Issues

**Problem:** Minikube won't start

**Solution:**
```bash
# Delete and recreate
minikube delete
minikube start --cpus=4 --memory=8192 --disk-size=40g
```

**Problem:** Pods stuck in "ImagePullBackOff"

**Solution:**
```bash
# Rebuild images in Minikube's Docker daemon
eval $(minikube docker-env)
docker build -t wander-api:local ./api
docker build -t wander-frontend:local ./frontend

# Restart deployment
kubectl rollout restart deployment/wander-local-api -n wander-local
```

**Problem:** Can't access Minikube services

**Solution:**
```bash
# Get service URL
minikube service wander-local-frontend -n wander-local --url

# Or open in browser
minikube service wander-local-frontend -n wander-local
```

### FKS Issues

**Problem:** Can't connect to FKS cluster

**Solution:**
```bash
# Verify WireGuard is active (check WireGuard app)

# Or use fly proxy
fly proxy 6443:6443 -a <cluster-name>

# Verify kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig-fks.yaml
kubectl get nodes
```

**Problem:** Image pull errors on FKS

**Solution:**
```bash
# Re-authenticate with Fly registry
fly auth docker

# Rebuild and push
docker build -t registry.fly.io/<org>/wander-api:latest ./api
docker push registry.fly.io/<org>/wander-api:latest
```

## Secret Management

**Local Development:**
- Use `.env` file (gitignored, auto-created from `.env.example` with `CHANGE_ME` placeholders)
- Run `./scripts/validate-secrets.sh` to check for unresolved placeholders
- Mock secrets are fine for dev; update for staging/prod

**Kubernetes (Staging/Production):**
- Use External Secrets Operator (recommended for gitops)
- Or Sealed Secrets (encrypt secrets in repo)
- Or cloud provider secret managers (GCP Secret Manager, AWS Secrets Manager, Azure Key Vault)
- Example Sealed Secret for JWT_SECRET:
  ```
  apiVersion: bitnami.com/v1alpha1
  kind: SealedSecret
  metadata:
    name: wander-api-secrets
    namespace: production
  spec:
    encryptedData:
      JWT_SECRET: AgC2... (encrypted value)
  ```
- Never commit real secrets; use `helm --set` only for testing

## Next Steps

- [ ] Customize API endpoints in `api/src/`
- [ ] Build UI components in `frontend/src/`
- [ ] Add more database migrations as needed
- [ ] Expand test coverage
- [ ] Set up CI/CD pipeline (GitHub Actions, GitLab CI)
- [ ] Configure production secrets
- [ ] Deploy to staging with Helm
- [ ] Set up monitoring (Prometheus + Grafana)

## Support

- Check logs: `make logs`
- Reset environment: `make reset`
- View all commands: `make help`
- Open issue on GitHub

## License

MIT
