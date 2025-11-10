# Wander Dev Environment

Zero-to-running local development environment in under 10 minutes.

## Quick Start

```bash
# 1. Clone and enter directory
git clone <repository-url>
cd dev_env

# 2. Start everything
make dev
```

That's it! Visit http://localhost:3000 to see your app.

## Prerequisites

- Docker Desktop 4.x+ (or Docker Engine 20.x+)
- docker-compose 2.x+
- 8GB RAM minimum

Check prerequisites:
```bash
make prereqs
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make dev` | Start all services with health checks |
| `make down` | Stop and remove all containers/volumes |
| `make logs` | Tail logs from all services |
| `make reset` | Full teardown and fresh start |
| `make seed` | Load test data into database |
| `make test` | Run test suites |
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
1. Start Docker Desktop
2. Wait for it to fully initialize
3. Run `make dev` again

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

## Project Structure

```
dev_env/
├── api/                    # Node/TypeScript API
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── frontend/               # React/TypeScript Frontend
│   ├── src/
│   ├── Dockerfile
│   └── package.json
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

## Next Steps

- [ ] Customize API endpoints in `api/src/`
- [ ] Build UI components in `frontend/src/`
- [ ] Add database migrations
- [ ] Set up CI/CD pipeline
- [ ] Configure production secrets
- [ ] Deploy to staging with `make deploy-staging`

## Support

- Check logs: `make logs`
- Reset environment: `make reset`
- Open issue on GitHub

## License

MIT
