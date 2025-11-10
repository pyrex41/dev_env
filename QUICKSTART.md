# 🚀 Zero to Running in 1 Step

## Fastest Start (First Time)

```bash
./setup.sh
```

**That's it!** The interactive script handles everything:
- ✓ Checks prerequisites
- ✓ Installs missing tools
- ✓ Starts Docker
- ✓ Configures environment
- ✓ Starts all services

## Manual Start (Already Setup)

```bash
# Step 1: Check you're ready
make prereqs

# Step 2: Start everything
make dev

# Step 3: Open browser
# Frontend: http://localhost:3000
# API:      http://localhost:8000
```

**That's it!** You should see "✅ Environment ready!" in 2-5 minutes.

## What Just Happened?

The `make dev` command:
1. ✅ Created `.env` from `.env.example` (if needed)
2. ✅ Started PostgreSQL and Redis
3. ✅ Waited for databases to be healthy
4. ✅ Started API server (with hot reload)
5. ✅ Waited for API to be healthy
6. ✅ Started frontend (with hot reload)
7. ✅ Displayed all service URLs

## Common Commands

```bash
make logs    # View logs from all services
make down    # Stop everything (removes volumes)
make reset   # Full teardown + cleanup
```

## Hot Reload

Edit any file and see changes instantly:
- **API:** Edit `api/src/index.ts`
- **Frontend:** Edit `frontend/src/App.tsx`

## Troubleshooting

**Problem:** Port already in use
```bash
lsof -ti:3000  # Find what's using the port
```

**Problem:** Services won't start
```bash
make logs    # Check what's failing
make reset   # Nuclear option: reset everything
make dev     # Try again
```

**Problem:** Docker not running
- Start Docker Desktop
- Wait for it to fully initialize
- Run `make dev` again

## Next Steps

Read the full [README.md](./README.md) for:
- Detailed documentation
- Configuration options
- Development workflow
- Architecture overview

---

**Need help?** Check `log_docs/` for detailed implementation notes.
