# Wander Zero-to-Running Developer Environment

**Clone → Single Command → Running App in <10 Minutes**

A complete multi-service development environment that "just works" on any machine.

---

## 🚀 Quick Start - Choose Your Path

### For Local Development (Recommended) 👈

**This is what you want for daily development work on Mac or Linux:**

```bash
# 1. Clone the repo
git clone <your-repo-url>
cd wander-dev-env

# 2. Run interactive setup (installs Docker if needed)
./setup.sh

# 3. Start developing!
make dev
```

**Or if you already have Docker:**
```bash
cp .env.local.example .env && make dev
```

**Visit http://localhost:3000** to see your app running!

**Why this approach?**
- ⚡ **Fast**: Services start in ~10 seconds, hot reload works instantly
- 🐛 **Easy debugging**: Direct access to all services
- 💻 **Native performance**: No container-in-container overhead
- 🔧 **IDE friendly**: VSCode, debuggers, and linters work seamlessly

---

### For Fly.io Deployment Only 🚀

**Only use this if you're deploying to Fly.io's cloud platform:**

See [`fly_minimal/README.md`](fly_minimal/README.md) for deployment instructions.

**Note**: The fly_minimal setup is NOT recommended for local development. It's optimized for cloud deployment, not daily coding work.

---

## 📊 Setup Options Comparison

| Feature | **Native Setup** (setup.sh) | fly_minimal (Fly.io) |
|---------|-------------|------------------|
| **Best for** | ✅ Daily development | ✅ Cloud deployment |
| **Startup time** | ~10 seconds | ~30-60 seconds |
| **Hot reload** | ✅ Instant | ⚠️ Slow (nested containers) |
| **IDE integration** | ✅ Perfect | ⚠️ Complex |
| **Debugging** | ✅ Direct access | ⚠️ Port forwarding needed |
| **Resource usage** | 2-4 GB RAM | 6-8 GB RAM |
| **File watching** | ✅ Native FS | ⚠️ Multiple layers |
| **Performance** | ✅ Native | ⚠️ Container overhead |
| **Use when** | Coding on Mac/Linux | Deploying to Fly.io |

**TL;DR**: Use `./setup.sh` and `make dev` for local development. Only use `fly_minimal` when deploying to Fly.io.

---

## 🎯 What You Get (With Local Setup)

### Three Commands to Running App

```bash
git clone <your-repo-url>
cd wander-dev-env
./setup.sh
```

**The setup script will:**
- ✅ Check Docker is installed (installs if missing)
- ✅ Start Docker daemon (Colima on Mac, native on Linux)
- ✅ Validate your configuration
- ✅ Start all services (Frontend, API, PostgreSQL, Redis)
- ✅ Run database migrations
- ✅ Verify everything is healthy

**Total time:** 5-10 minutes ⏱️

---

## 📋 What You Get

| Service | URL | Stack |
|---------|-----|-------|
| **Frontend** | http://localhost:3000 | React 18 + TypeScript + Vite + Tailwind CSS v4 |
| **API** | http://localhost:8000 | Node.js + TypeScript + Express |
| **Database** | localhost:5432 | PostgreSQL 16 |
| **Cache** | localhost:6379 | Redis 7 |
| **Health Check** | http://localhost:8000/health | Service status endpoint |
| **Debugger** | localhost:9229 | Node.js inspector |

**Features:**
- 🔄 Hot reload for both frontend and API
- 🏥 Automatic health checks
- 📊 Structured error messages with troubleshooting hints
- 🔒 Secure defaults for local development
- 🐳 Fully containerized (no global npm installs)
- ⚡ Optimized startup (<60 seconds)

---

## 📖 Documentation

- **[Quick Start](#quick-start)** - Get running in 3 commands
- **[Available Commands](#available-commands)** - All `make` targets
- **[Configuration](#configuration)** - Environment variables
- **[Development Workflow](#development-workflow)** - Day-to-day usage
- **[Troubleshooting](#troubleshooting)** - Common issues
- **[Deployment](#deployment)** - Production deployment options
- **[Architecture](#architecture)** - System design

---

## Prerequisites

**Required:**
- Docker (Colima or Docker Desktop)
- 8GB RAM minimum
- 10GB free disk space

**Check if you're ready:**
```bash
make prereqs
```

### First-Time Docker Setup

**macOS (Recommended: Colima)**
```bash
# Install
brew install colima docker docker-compose

# Start with optimal settings
colima start --cpu 4 --memory 8 --disk 60

# Verify
docker info
```

**macOS (Alternative: Docker Desktop)**
```bash
brew install --cask docker
# Start Docker Desktop from Applications
```

**Linux**
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in
```

---

## 🎯 Available Commands

Run `make help` to see all commands with descriptions.

### Local Development

| Command | Description |
|---------|-------------|
| `make dev` | Start all services (checks prerequisites, validates config) |
| `make down` | Stop services (keeps data) |
| `make restart` | Quick restart (down + dev) |
| `make reset` | Nuclear option - fresh start, deletes all data |
| `make health` | Check if all services are healthy |

### Logs & Monitoring

| Command | Description |
|---------|-------------|
| `make logs` | Tail logs from all services |
| `make logs-api` | View API logs only |
| `make logs-frontend` | View frontend logs only |
| `make logs-db` | View PostgreSQL logs |
| `make logs-redis` | View Redis logs |

### Database

| Command | Description |
|---------|-------------|
| `make migrate` | Run database migrations |
| `make migrate-rollback` | Rollback last migration |
| `make seed` | Load test data |
| `make shell-db` | Open PostgreSQL shell |

### Testing

| Command | Description |
|---------|-------------|
| `make test` | Run all tests (API + frontend) |
| `make test-api` | Run API tests only |
| `make test-frontend` | Run frontend tests only |
| `make lint` | Run linters on all code |

### Development Tools

| Command | Description |
|---------|-------------|
| `make shell-api` | Open shell in API container |
| `make validate-secrets` | Check .env for CHANGE_ME values |

### Cleanup

| Command | Description |
|---------|-------------|
| `make clean` | Stop services and remove volumes |
| `make nuke` | Remove everything (images, volumes, containers) |

### Deployment

| Command | Description |
|---------|-------------|
| `make k8s-setup` | Setup local Kubernetes (Minikube) |
| `make k8s-deploy` | Deploy to local K8s |
| `make fly-deploy` | Deploy to Fly.io Kubernetes (production demo) |

---

## ⚙️ Configuration

### Environment Variables

Configuration is in `.env` file. Two options:

**Option 1: Quick Start (Recommended for Local Dev)**
```bash
cp .env.local.example .env
```
Uses safe defaults. Start immediately with `make dev`.

**Option 2: Custom Configuration**
```bash
cp .env.example .env
# Edit .env and replace CHANGE_ME values
make validate-secrets  # Verify no CHANGE_ME left
make dev
```

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | (required) | PostgreSQL password |
| `REDIS_PASSWORD` | (required) | Redis password |
| `API_SECRET` | (required) | API encryption key |
| `JWT_SECRET` | (required) | JWT token secret |
| `API_PORT` | 8000 | API HTTP port |
| `FRONTEND_PORT` | 3000 | Frontend dev server port |
| `NODE_ENV` | development | Environment (development/production/test) |

**Security Note:**
- `.env` is git-ignored
- Never commit secrets
- Use simple passwords for local dev (e.g., `dev_password_123`)
- Generate strong secrets for production

---

## 💻 Development Workflow

### Daily Workflow

```bash
# Morning: Start services
make dev

# Check everything is healthy
make health

# View logs while developing
make logs-api  # or logs-frontend

# Run tests before committing
make test

# Evening: Stop services
make down
```

### Adding a New Feature

```bash
# 1. Start fresh
make reset

# 2. Create database migration (if needed)
cd api
pnpm run migrate:create add_users_table

# 3. Edit migration file in api/src/migrations/
# 4. Run migration
make migrate

# 5. Add seed data (optional)
# Edit api/src/seed.ts
make seed

# 6. Develop feature
# Files hot-reload automatically

# 7. Run tests
make test

# 8. Check API in browser
open http://localhost:8000/health
```

### Debugging

**API Debugging (Node Inspector)**
```bash
# 1. Attach debugger to port 9229
# VS Code: Add to launch.json:
{
  "type": "node",
  "request": "attach",
  "name": "Attach to API",
  "port": 9229,
  "address": "localhost",
  "restart": true,
  "sourceMaps": true
}

# 2. Set breakpoints in api/src/
# 3. Start debugging in VS Code
```

**Database Inspection**
```bash
# Open psql shell
make shell-db

# Run queries
SELECT * FROM users;
\dt  # List tables
\q   # Quit
```

**Container Shell Access**
```bash
# API container
make shell-api

# Then run commands:
pnpm run test
pnpm run lint
env  # See environment variables
```

---

## 🐛 Troubleshooting

### Services Won't Start

**Problem:** `make dev` fails

**Solutions:**
```bash
# 1. Check Docker is running
docker info

# 2. Check prerequisites
make prereqs

# 3. View detailed logs
make logs

# 4. Try fresh start
make reset
```

### Port Conflicts

**Problem:** Port already in use (3000, 8000, 5432, 6379)

**Solutions:**
```bash
# Find what's using the port
lsof -ti:3000  # Replace with your port

# Kill the process
kill $(lsof -ti:3000)

# Or change port in .env
FRONTEND_PORT=3001
```

### Database Connection Failed

**Problem:** API can't connect to PostgreSQL

**Solutions:**
```bash
# 1. Check PostgreSQL is healthy
make health

# 2. Check logs
make logs-db

# 3. Verify password in .env
make validate-secrets

# 4. Reset database
make reset
```

### Services "Unhealthy"

**Problem:** `make health` shows services are unhealthy

**Solutions:**
```bash
# 1. Wait longer (first start takes ~60s)
sleep 30 && make health

# 2. Check specific service logs
make logs-api     # API issues
make logs-frontend # Frontend issues

# 3. View detailed error messages
docker ps  # Check container status
```

### "CHANGE_ME" Errors

**Problem:** Error about CHANGE_ME values in .env

**Solutions:**
```bash
# Option 1: Use safe defaults
rm .env
cp .env.local.example .env
make dev

# Option 2: Set custom values
make validate-secrets  # Shows which values need changing
# Edit .env and replace CHANGE_ME values
make dev
```

### Docker Out of Space

**Problem:** No space left on device

**Solutions:**
```bash
# Clean up Docker
docker system prune -a --volumes

# Or nuke everything
make nuke

# Then restart
make dev
```

### Still Stuck?

1. Check logs: `make logs`
2. Try fresh start: `make reset`
3. Verify Docker: `docker info`
4. Check GitHub Issues

---

## 🚢 Deployment

### Production Deployment Options

#### Option 1: Fly.io Kubernetes (Recommended)

Full Kubernetes deployment demonstrating production patterns:

```bash
# See detailed guide
cat DEPLOY_FLY_K8S.md

# Or run automated setup
make fly-deploy
```

**Features:**
- Multi-service orchestration
- External PostgreSQL (Fly Postgres)
- Redis cache (Upstash)
- Health checks & rolling updates
- Cost: ~$15/month (destroy after demo)

#### Option 2: Docker Compose (Simple)

Deploy to any VPS with Docker:

```bash
# On server
git clone <repo>
cd wander-dev-env
cp .env.example .env
# Edit .env with production secrets
docker-compose -f docker-compose.prod.yml up -d
```

#### Option 3: Fly Machines (Simplest)

Simpler than Kubernetes, auto-scaling:

```bash
fly launch --name wander-api
fly launch --name wander-frontend
# ~$5/month, automatic SSL
```

### Production Checklist

Before deploying to production:

- [ ] Change all passwords in `.env`
- [ ] Set `NODE_ENV=production`
- [ ] Enable HTTPS/SSL
- [ ] Set up database backups
- [ ] Configure monitoring (health checks)
- [ ] Set up log aggregation
- [ ] Review security (CORS, rate limiting)
- [ ] Test disaster recovery
- [ ] Document rollback procedure

---

## 🏗️ Architecture

### System Overview

```
┌──────────────┐
│   Frontend   │  React + Vite + Tailwind
│  :3000       │  Hot reload, TypeScript
└──────┬───────┘
       │ HTTP
       ↓
┌──────────────┐
│     API      │  Node + Express + TypeScript
│   :8000      │  REST endpoints, migrations
└──┬───────┬───┘
   │       │
   ↓       ↓
┌────┐  ┌─────┐
│ PG │  │Redis│  PostgreSQL 16 + Redis 7
│5432│  │6379 │  Persistent data + cache
└────┘  └─────┘
```

### Service Dependencies

```
PostgreSQL → Ready (10s)
    ↓
Redis → Ready (5s)
    ↓
API → Migrations → Ready (30s)
    ↓
Frontend → Ready (20s)
    ↓
All Healthy ✓ (~60s total)
```

### Development Stack

**Frontend:**
- React 18 (UI framework)
- TypeScript (type safety)
- Vite (build tool, HMR)
- Tailwind CSS v4 (styling)
- Vitest (testing)

**API:**
- Node.js 20 LTS
- Express (web framework)
- TypeScript
- node-pg-migrate (database migrations)
- Vitest (testing)
- pg (PostgreSQL client)
- redis (Redis client)

**Infrastructure:**
- Docker + Docker Compose
- PostgreSQL 16 (database)
- Redis 7 (cache)
- Kubernetes (production deployment option)

### Directory Structure

```
wander-dev-env/
├── api/                # Node.js API service
│   ├── src/
│   │   ├── index.ts      # Main entry point
│   │   ├── migrations/   # Database migrations
│   │   └── seed.ts       # Test data
│   ├── Dockerfile        # Multi-stage build
│   └── package.json
│
├── frontend/           # React frontend
│   ├── src/
│   │   ├── App.tsx       # Main component
│   │   └── main.tsx      # Entry point
│   ├── Dockerfile
│   └── package.json
│
├── k8s/                # Kubernetes configs
│   └── charts/wander/    # Helm chart
│
├── fly_minimal/        # Fly.io demo machine
│   ├── bootstrap.sh      # Zero-to-running script
│   ├── Dockerfile
│   └── README.md
│
├── scripts/            # Setup scripts
│   ├── setup.sh          # Interactive setup
│   ├── teardown.sh       # Cleanup
│   └── fks-setup.sh      # Fly K8s setup
│
├── .env.example        # Config template
├── .env.local.example  # Safe defaults
├── docker-compose.yml  # Service definitions
├── Makefile            # Development commands
└── README.md           # This file
```

---

## 🎓 Demo: Zero-to-Running on Clean Linux

Want to prove this works on a truly clean machine? Try our Fly.io demo:

```bash
# 1. Deploy minimal Linux machine to Fly.io
cd fly_minimal
fly deploy

# 2. SSH into fresh machine
fly ssh console

# 3. Run bootstrap script (installs everything)
curl -fsSL <your-bootstrap-url> | bash

# 4. Wait ~10 minutes
# 5. App running!
```

See `fly_minimal/README.md` for details.

---

## 🤝 Contributing

### Adding a New Service

1. Add service to `docker-compose.yml`
2. Add health check
3. Update `make health` command in Makefile
4. Add to README services table
5. Test with `make dev`

### Adding a Database Migration

```bash
cd api
pnpm run migrate:create your_migration_name
# Edit api/src/migrations/<timestamp>_your_migration_name.ts
make migrate
```

---

## 📝 License

[Your License Here]

---

## 🆘 Support

- **Issues:** GitHub Issues
- **Docs:** This README + `DEPLOY_FLY_K8S.md`
- **Commands:** `make help`

---

**Built with ❤️ by Wander Team**

**Time to running app:** <10 minutes ⏱️
**Supported platforms:** macOS, Linux, Windows (WSL2)
**Production ready:** Yes ✅
