# Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────┐
│                      User Browser                        │
└────────────────────┬─────────────────────────────────────┘
                     │ HTTP
                     ↓
┌────────────────────────────────────────────────────────────┐
│                      Frontend (React)                      │
│  Port 3000 | Vite Dev Server | TypeScript | Tailwind v4   │
└────────────────────┬───────────────────────────────────────┘
                     │ REST API
                     ↓
┌────────────────────────────────────────────────────────────┐
│                   API (Node.js/Express)                    │
│  Port 8000 | TypeScript | Hot Reload | Debug Port 9229    │
└─────────┬────────────────────────┬─────────────────────────┘
          │                        │
          │ SQL                    │ Cache
          ↓                        ↓
┌─────────────────┐      ┌──────────────────┐
│  PostgreSQL 16  │      │     Redis 7      │
│   Port 5432     │      │   Port 6379      │
│  Persistent DB  │      │  Session Cache   │
└─────────────────┘      └──────────────────┘
```

### Service Communication

**Network Topology:**
- All services on `wander_network` bridge network
- Services communicate via container names (DNS resolution)
- Database: `postgres:5432` (internal), `localhost:5432` (host)
- Redis: `redis:6379` (internal), `localhost:6379` (host)
- API: `api:8000` (internal), `localhost:8000` (host)
- Frontend: `frontend:3000` (internal), `localhost:3000` (host)

**Health Check Flow:**
```
1. PostgreSQL starts → health check passes (pg_isready)
2. Redis starts → health check passes (redis-cli ping)
3. API starts → waits for DB/Redis healthy → runs migrations → health check passes (curl /health)
4. Frontend starts → waits for API healthy → health check passes (curl /)
```

### Technology Stack Details

**Frontend:**
- **React 18** - UI framework with concurrent features
- **TypeScript** - Type safety and better DX
- **Vite** - Fast build tool with HMR (Hot Module Replacement)
- **Tailwind CSS v4** - Utility-first CSS framework
- **Vitest** - Fast unit testing

**API:**
- **Node.js 20 LTS** - Runtime environment
- **Express** - Web framework
- **TypeScript** - Type safety
- **node-pg-migrate** - Database migrations
- **pg** - PostgreSQL client
- **redis** - Redis client
- **Vitest** - Testing framework

**Infrastructure:**
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration
- **PostgreSQL 16** - Relational database
- **Redis 7** - In-memory cache
- **Kubernetes** - Production orchestration (optional)

### Directory Structure

```
wander-dev-env/
├── api/                          # Node.js API service
│   ├── src/
│   │   ├── index.ts              # Main entry point, Express server
│   │   ├── migrations/           # Database migrations
│   │   │   └── <timestamp>_*.ts  # Migration files
│   │   ├── seeds/                # Test data
│   │   │   ├── run.ts            # Seed runner
│   │   │   ├── 01-users.ts       # User seed data
│   │   │   └── 02-posts.ts       # Post seed data
│   │   └── __tests__/            # API tests
│   │       ├── setup.ts          # Test configuration
│   │       ├── health.test.ts    # Health check tests
│   │       └── database.test.ts  # Database tests
│   ├── Dockerfile                # Multi-stage build
│   ├── package.json              # Dependencies
│   └── tsconfig.json             # TypeScript config
│
├── frontend/                     # React frontend
│   ├── src/
│   │   ├── main.tsx              # Entry point
│   │   ├── App.tsx               # Root component
│   │   ├── components/           # Reusable components
│   │   └── __tests__/            # Frontend tests
│   ├── Dockerfile                # Multi-stage build
│   ├── package.json              # Dependencies
│   ├── vite.config.ts            # Vite configuration
│   └── tailwind.config.js        # Tailwind configuration
│
├── k8s/                          # Kubernetes configurations
│   └── charts/wander/            # Helm chart
│       ├── Chart.yaml            # Helm metadata
│       ├── values.yaml           # Configuration values
│       └── templates/            # K8s resource templates
│
├── scripts/                      # Automation scripts
│   ├── setup.sh                  # Interactive setup
│   ├── teardown.sh               # Interactive cleanup
│   ├── gke-setup.sh              # GKE cluster setup
│   ├── gke-deploy.sh             # GKE deployment
│   ├── gke-finish-setup.sh       # GKE post-deployment
│   ├── enable-gke-apis.sh        # Enable required GCP APIs
│   └── validate-secrets.sh       # Secret validation
│
├── .env.example                  # Configuration template
├── .env.local.example            # Safe dev defaults
├── docker-compose.yml            # Service definitions
├── Makefile                      # Development commands
└── README.md                     # This file
```

### Data Flow Example: User Login

```
1. User enters credentials in frontend (React form)
   ↓
2. Frontend sends POST to http://localhost:8000/api/login
   ↓
3. API validates request (Express middleware)
   ↓
4. API queries PostgreSQL for user (pg library)
   ↓
5. PostgreSQL returns user data
   ↓
6. API checks Redis for cached session (redis library)
   ↓
7. API generates JWT token
   ↓
8. API stores session in Redis (fast cache)
   ↓
9. API returns token to frontend
   ↓
10. Frontend stores token in localStorage
    ↓
11. Frontend redirects to dashboard
```

### Development vs Production

**Development (Docker Compose):**
- Hot reload enabled (volume mounts)
- Debug ports exposed (9229)
- Source maps enabled
- Verbose logging
- Development secrets
- Single machine

**Production (Kubernetes):**
- Compiled/bundled code
- No debug ports
- Optimized images
- Production logging (JSON)
- Secure secret management
- Multi-machine, auto-scaling

---

