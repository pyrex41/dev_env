# Development Workflow

Complete guide for daily development tasks, debugging, and best practices.

## Daily Development Workflow

```bash
# Morning: Start services
make dev

# Check everything is healthy
make health

# View logs while developing
make logs-api  # or logs-frontend

# Make code changes (hot reload works automatically)
# Edit files in api/src/ or frontend/src/

# Run tests before committing
make test

# Evening: Stop services
make down
```

## Adding a New Feature

```bash
# 1. Start fresh (optional, recommended for clean state)
make reset

# 2. Create database migration (if needed)
cd api
pnpm run migrate:create add_users_table

# 3. Edit migration file
# Location: api/src/migrations/<timestamp>_add_users_table.ts

# 4. Run migration
make migrate

# 5. Add seed data (optional, for testing)
# Edit: api/src/seeds/01-users.ts
make seed

# 6. Develop feature
# Edit files in api/src/ or frontend/src/
# Hot reload works automatically!

# 7. Run tests
make test

# 8. Check health
make health

# 9. View in browser
open http://localhost:3000
open http://localhost:8000/health
```

## Optional: VS Code Integration

**Setup VS Code workspace for optimal development experience:**

```bash
# Install VS Code configs (opt-in)
make setup-vscode

# This creates:
# - .vscode/extensions.json  - Recommended extensions
# - .vscode/launch.json      - API debugger config (port 9229)
# - .vscode/settings.json    - Format on save settings
```

**What you get:**
- **Recommended Extensions** - ESLint, Prettier, Docker, TypeScript
- **One-Click Debugging** - Press F5 to attach to API container
- **Auto-formatting** - Format on save with Prettier

**Using the debugger:**

1. Run `make setup-vscode` (one-time setup)
2. Start services with `make dev`
3. Press F5 in VS Code (or Run > Start Debugging)
4. Select "Attach to API (Docker)"
5. Set breakpoints in `api/src/`
6. Make API requests - debugger will pause at breakpoints

**Note:** This is completely optional. The `.vscode/` folder is gitignored so each developer can choose their own setup.

## Database Operations

### Inspect Database

```bash
# Open psql shell
make shell-db

# Run queries
SELECT * FROM users;
\dt          # List tables
\d users     # Describe table
\q           # Quit
```

### Manage Migrations

```bash
# Create new migration
cd api
pnpm run migrate:create my_migration_name

# Run pending migrations
make migrate

# Rollback last migration
make migrate-rollback

# Reset database (danger: data loss!)
make reset
```

### Load Test Data

```bash
# Load seed data
make seed

# Custom seeds
# Edit: api/src/seeds/01-users.ts, api/src/seeds/02-posts.ts
# Then: make seed
```

## Container Shell Access

```bash
# API container
make shell-api

# Inside container, you can:
pnpm run test          # Run tests
pnpm run lint          # Run linter
env                    # See environment variables
ls -la /app            # Explore filesystem
```

## Optional: Pre-commit Hooks

**Automatically run linting and tests before each commit:**

```bash
# Install hooks (opt-in)
make setup-hooks

# This will:
# - Install husky and lint-staged
# - Run 'make lint' before each commit
# - Run 'make test' before each commit
# - Block commits if either fails

# To disable later:
rm -rf .husky
```

**Why use pre-commit hooks?**
- Catch issues before they reach CI
- Maintain code quality standards
- Prevent broken commits
- Save time in code review

**Note:** This is completely optional. Only install if you want automatic checks.
