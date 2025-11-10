# pnpm Setup Guide

This project uses **pnpm** instead of npm for better performance and disk space efficiency.

## First Time Setup

When you first run `make dev`, Docker will automatically:
1. Enable pnpm via Node.js corepack
2. Install dependencies using pnpm
3. Generate `pnpm-lock.yaml` files

**You don't need to install pnpm locally** - it runs inside Docker containers.

## Why pnpm?

- ⚡ **Faster** - Uses content-addressable storage
- 💾 **Smaller** - Shares packages across projects
- 🔒 **Stricter** - Better dependency management
- 📦 **Compatible** - Works with existing npm/yarn projects

## Generated Files

After first `make dev`, you'll see:
```
api/pnpm-lock.yaml        # API dependencies lockfile
frontend/pnpm-lock.yaml   # Frontend dependencies lockfile
```

**Commit these files** - they ensure consistent installs across environments.

## Common Commands

All pnpm commands run inside Docker containers:

```bash
# Install dependencies
make dev  # Installs automatically on startup

# Run scripts
make seed   # Runs: pnpm run seed
make test   # Runs: pnpm test

# Access container shell
make shell-api
# Then inside container:
pnpm install        # Install deps
pnpm add express    # Add new package
pnpm remove lodash  # Remove package
```

## Manual Package Management

If you need to add/remove packages:

```bash
# Method 1: Edit package.json, then rebuild
# Edit api/package.json or frontend/package.json
make down
make dev

# Method 2: Use container shell
make shell-api
pnpm add express
# Exit container, then rebuild to persist changes
```

## Lockfile Management

**Important:** Always commit `pnpm-lock.yaml` files!

```bash
git add api/pnpm-lock.yaml frontend/pnpm-lock.yaml
git commit -m "update dependencies"
```

## Troubleshooting

**Missing pnpm-lock.yaml on first build?**
- Normal! Docker will generate them automatically
- They'll appear after first successful build

**Dependency conflicts?**
```bash
# Remove containers and rebuild
make reset
make dev
```

**Need to use npm instead?**
- See git history for npm versions of Dockerfiles
- Or update Dockerfiles to use npm instead of pnpm

## Performance Comparison

Typical install times:
- npm: ~60 seconds
- pnpm: ~20 seconds (first time)
- pnpm: ~5 seconds (cached)

Disk usage:
- npm: ~300MB per project
- pnpm: ~100MB (shared across projects)

---

**TL;DR:** Just run `make dev` - pnpm is handled automatically! 🚀
