# Installation Guide

## Prerequisites

You need:
- **Docker Desktop** - Provides Docker daemon and Docker Compose
- **8GB RAM minimum**

## Quick Install

### Option 1: Interactive Setup (Recommended)

```bash
./setup.sh
```

The script will:
- Check prerequisites
- Install Docker Desktop if needed
- Start Docker daemon
- Configure environment
- Start dev environment

### Option 2: Manual Install

**Step 1: Install Docker Desktop**

Download from: https://www.docker.com/products/docker-desktop

Or via Homebrew:
```bash
brew install --cask docker
```

**Step 2: Start Docker Desktop**

```bash
open -a Docker
```

Wait for the whale icon 🐳 in your menu bar to be stable.

**Step 3: Verify Installation**

```bash
docker info
docker compose version
```

**Step 4: Start Dev Environment**

```bash
make dev
```

## Troubleshooting

### Docker daemon not running
```bash
# Start Docker Desktop
open -a Docker

# Wait 30-60 seconds for startup
# Look for whale icon in menu bar
```

### Port conflicts
```bash
# Find what's using a port
lsof -ti:3000  # or :8000, :5432, :6379

# Change ports in .env file
```

### Permission denied
```bash
# Ensure Docker Desktop is running
docker info
```

## After Installation

Once Docker is running:

```bash
# Verify everything works
make prereqs

# Start development environment
make dev

# Visit http://localhost:3000
```

## Need Help?

- Run `./setup.sh` for interactive guidance
- Check [README.md](./README.md) for full documentation
- See [QUICKSTART.md](./QUICKSTART.md) for quick start guide
