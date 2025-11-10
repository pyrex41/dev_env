# Zero-to-Running Developer Environment - Implementation PRD

**Project:** Wander Dev Environment
**Timeline:** 2 weeks
**Approach:** Docker Compose (local) + Kubernetes (deploy)

---

## Objective

Enable developers to run `make dev` and have a fully functional local environment in under 10 minutes. Separate deployment concerns to Kubernetes for staging/production.

## Core Principles

1. **Local simplicity** - Docker Compose only, no K8s complexity
2. **Production parity** - K8s configs mirror local service definitions
3. **Zero configuration** - Works out-of-box with sensible defaults
4. **Clear feedback** - Obvious success/failure states

---

## Features

### P0 - Must Have

**Local Development**
- [ ] `make dev` - Start all services with health checks
- [ ] `make down` - Clean shutdown, remove containers/volumes
- [ ] `make logs` - Tail logs from all services
- [ ] Auto-generate `.env` from `.env.example` if missing
- [ ] Service dependency ordering (DB/Redis → API → Frontend)
- [ ] Health checks confirm services are ready before completion
- [ ] Hot reload enabled for frontend and API

**Services**
- [ ] PostgreSQL 16 with persistent volume
- [ ] Redis 7 for caching
- [ ] Node/TypeScript API with exposed debug port (9229)
- [ ] React/TypeScript frontend with Vite dev server
- [ ] All services on host network for easy access

**Configuration**
- [ ] `.env.example` (committed) with all required variables
- [ ] `.env` (gitignored) for local overrides
- [ ] Mock secrets with clear "CHANGE ME" indicators
- [ ] Port configuration via environment variables

**Documentation**
- [ ] README with quickstart (< 50 lines)
- [ ] Prerequisites check script
- [ ] Troubleshooting common issues (port conflicts, Docker not running)

### P1 - Should Have

**Local Development**
- [ ] `make seed` - Load test data into database
- [ ] `make reset` - Full teardown and fresh start
- [ ] `make test` - Run test suites in containers
- [ ] Automatic dependency check (Docker, docker-compose installed)
- [ ] Graceful error messages for missing dependencies

**Deployment (K8s/GKE)**
- [ ] Helm chart for service definitions
- [ ] `values-staging.yaml` and `values-prod.yaml`
- [ ] `make deploy-staging` - Deploy to staging cluster
- [ ] ConfigMaps for non-sensitive config
- [ ] Secret management strategy documented (not implemented)
- [ ] Horizontal Pod Autoscaling for API

**Developer Experience**
- [ ] Colored console output for readability
- [ ] Progress indicators during startup
- [ ] Service URLs displayed after successful startup
- [ ] Database migrations run automatically on API startup

### P2 - Nice to Have

- [ ] `make profile-minimal` - Start subset of services (API + DB only)
- [ ] Pre-commit hooks for linting
- [ ] Docker layer caching optimization
- [ ] `make shell-api` / `make shell-db` - Jump into container shells
- [ ] GitHub Actions workflow for K8s deployment
- [ ] Local HTTPS with self-signed certs

---

## Technical Approach

### Local Environment (Docker Compose)

```
project/
├── docker-compose.yml          # Service definitions
├── Makefile                    # Developer commands
├── .env.example                # Template configuration
├── .env                        # Local config (gitignored)
├── api/
│   ├── Dockerfile             # Multi-stage build
│   └── src/
├── frontend/
│   ├── Dockerfile
│   └── src/
└── docs/
    └── SETUP.md
```

**Key Decisions:**
- Use `depends_on` with `condition: service_healthy` for ordering
- Mount source code as volumes for hot reload
- Expose debug ports for IDE attachment
- Use named volumes for data persistence

### Deployment (Kubernetes)

```
k8s/
└── charts/
    └── wander/
        ├── Chart.yaml
        ├── values-staging.yaml
        ├── values-prod.yaml
        └── templates/
            ├── api-deployment.yaml
            ├── api-service.yaml
            ├── frontend-deployment.yaml
            ├── frontend-service.yaml
            ├── postgres-statefulset.yaml
            ├── redis-deployment.yaml
            └── ingress.yaml
```

**Key Decisions:**
- Helm for templating and environment management
- StatefulSet for PostgreSQL with persistent volumes
- ClusterIP services internally, Ingress for external access
- Separate staging/prod by values files, not namespaces

---

## Success Criteria

- [ ] New developer can run `make dev` and see "✅ Environment ready!" in < 10 minutes
- [ ] All services accessible at documented URLs
- [ ] Hot reload works for frontend and API code changes
- [ ] `make down` leaves no orphaned containers/volumes
- [ ] K8s deployment to staging succeeds via `make deploy-staging`
- [ ] Documentation covers 90% of setup issues without Slack messages

---

## Out of Scope

- CI/CD pipeline (mentioned but not implemented)
- Production secret management (document approach only)
- Database backup/restore procedures
- Monitoring/observability setup
- Multi-environment local profiles (staging/prod replicas locally)
- Windows-specific compatibility (document limitations)

---

## Dependencies

**Required:**
- Docker Desktop 4.x+ or Docker Engine 20.x+
- docker-compose 2.x+
- kubectl 1.28+ (for deployment only)
- Helm 3.x+ (for deployment only)
- GKE cluster (for deployment only)

**Assumed:**
- Developers have basic terminal/command-line skills
- Git installed and repository cloned
- Network access to Docker Hub and package registries

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Port conflicts on developer machines | Health checks detect failures, docs explain how to override ports |
| Platform differences (Mac/Linux) | Test on both, document known issues |
| Large Docker images slow first startup | Multi-stage builds, layer caching, document expected first-run time |
| K8s deployment secrets management | Document pattern using GCP Secret Manager, don't implement in v1 |
