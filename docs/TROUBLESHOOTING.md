# Troubleshooting Guide

Common issues and their solutions for the development environment.

## First Step: Run Diagnostics

**Before anything else, run:**
```bash
make doctor
```

This will check:
- Docker installation and status
- Port availability (3000, 5432, 6379, 8000, 9229)
- `.env` file configuration
- Disk space
- Docker resources

Each issue includes a specific fix command.

## Services Won't Start

**Problem:** `make dev` fails with errors

**Solutions:**
```bash
# 1. Run diagnostics
make doctor

# 2. Check Docker is running
docker info

# If Docker not running:
# macOS: colima start or open -a Docker
# Linux: sudo service docker start

# 3. Check prerequisites
make prereqs

# 4. View detailed logs to see what's failing
make logs

# 5. Check individual service health
make health

# 6. Try fresh start (removes all data)
make reset
```

**Common causes:**
- Docker daemon not running
- Insufficient disk space
- Port conflicts
- Missing `.env` file

## Port Conflicts

**Problem:** Port already in use (3000, 8000, 5432, or 6379)

**Error message:** `Bind for 0.0.0.0:3000 failed: port is already allocated`

**Solutions:**

### Option 1: Kill the conflicting process
```bash
# Find what's using the port
lsof -ti:3000  # Replace with your port

# Kill the process
kill $(lsof -ti:3000)

# Then restart
make dev
```

### Option 2: Change the port
```bash
# Edit .env file
FRONTEND_PORT=3001  # Use a different port

# Restart services
make restart

# Access at new port
open http://localhost:3001
```

## Database Connection Failed

**Problem:** API can't connect to PostgreSQL

**Error message:** `Error: connect ECONNREFUSED` or `database "wander" does not exist`

**Solutions:**
```bash
# 1. Check PostgreSQL is healthy
make health

# Should show:
# ✓ PostgreSQL: healthy

# 2. Check database logs
make logs-db

# Look for errors in output

# 3. Verify password in .env matches
cat .env | grep POSTGRES_PASSWORD
# Password should NOT be "CHANGE_ME"

# 4. Validate secrets
make validate-secrets

# 5. Reset database (nuclear option)
make reset
```

**Common causes:**
- PostgreSQL container not started
- Wrong password in `.env`
- Database not initialized
- Network issues

## Services Show "Unhealthy"

**Problem:** `make health` shows services are unhealthy

**Solutions:**
```bash
# 1. Wait longer (first start can take ~20s)
sleep 15 && make health

# 2. Check specific service logs
make logs-api      # API issues
make logs-frontend # Frontend issues
make logs-db       # Database issues

# 3. View container details
docker ps
# Look at STATUS column

# 4. Check if migrations ran
make logs-api | grep migration

# 5. Try restart
make restart
```

**Common causes:**
- Services still starting up
- Migrations failed
- Missing dependencies
- Syntax errors in code

## "CHANGE_ME" Errors

**Problem:** Validation fails with CHANGE_ME values in `.env`

**Error message:** `Error: Found CHANGE_ME values in .env file`

**Solutions:**

### Option 1: Use safe defaults (recommended)
```bash
# Replace .env with safe defaults
rm .env
cp .env.local.example .env
make dev
```

### Option 2: Set custom values
```bash
# Check which values need changing
make validate-secrets

# Edit .env file and replace CHANGE_ME values
# Then verify
make validate-secrets

# Should show: ✓ All secrets validated
make dev
```

## Docker Out of Space

**Problem:** No space left on device

**Error message:** `Error: No space left on device`

**Solutions:**

### Option 1: Clean up Docker
```bash
# Remove unused images, containers, volumes
docker system prune -a --volumes

# Check space
docker system df
```

### Option 2: Nuclear cleanup
```bash
# Remove everything (data loss!)
make nuke

# Then restart
make dev
```

### Option 3: Increase Docker disk size
```bash
# For Colima users
colima stop
colima start --cpu 4 --memory 8 --disk 100  # Increase from 60 to 100 GB
```

## Hot Reload Not Working

**Problem:** Code changes not reflected in browser

### Frontend (React)
```bash
# 1. Check frontend logs
make logs-frontend

# Should see: "VITE server listening on http://localhost:3000"

# 2. Hard refresh browser
# Mac: Cmd+Shift+R
# Linux/Windows: Ctrl+Shift+R

# 3. Restart frontend
docker restart wander_frontend
```

### API (Node.js)
```bash
# 1. Check API logs
make logs-api

# Should see: "Server started on port 8000"

# 2. Restart API
docker restart wander_api

# 3. Check if nodemon is running
make shell-api
ps aux | grep nodemon
```

## Still Stuck?

1. **Check logs:** `make logs`
2. **Try fresh start:** `make reset`
3. **Verify Docker:** `docker info`
4. **Check disk space:** `df -h`
5. **Review documentation:** [README.md](../README.md)
6. **Create GitHub issue** with logs and error messages

### Useful debugging commands

```bash
# Full system status
make prereqs
make health
docker ps
docker images
docker volume ls

# View all logs
make logs

# Check resource usage
docker stats
```
