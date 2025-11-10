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

## Services

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | React + TypeScript + Vite |
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

## Secret Management

**Local Development:**
- Use `.env` file (gitignored)
- Mock secrets are fine

**Production:**
- Use GCP Secret Manager (or similar)
- Never commit real secrets
- Document your strategy in k8s/ directory

## P1 Features ✅

The following production-ready features are included:

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

### Kubernetes Deployment
- **Helm chart** ready for staging and production
- **Local testing** with Minikube (free, no cloud costs!)
- Deployment configurations for all 4 services (API, Frontend, PostgreSQL, Redis)
- Environment-specific values files: `values-local.yaml`, `values-staging.yaml`, `values-prod.yaml`
- Test locally: `make k8s-local-setup && make deploy-local`
- Comprehensive documentation: `k8s/charts/wander/README.md` and `LOCAL_K8S_TESTING.md`

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

## Next Steps

- [ ] Customize API endpoints in `api/src/`
- [ ] Build UI components in `frontend/src/`
- [ ] Add more database migrations as needed
- [ ] Expand test coverage
- [ ] Set up CI/CD pipeline
- [ ] Configure production secrets (External Secrets, Vault, etc.)
- [ ] Deploy to staging: See `k8s/charts/wander/README.md`

## Support

- Check logs: `make logs`
- Reset environment: `make reset`
- Open issue on GitHub

## License

MIT
