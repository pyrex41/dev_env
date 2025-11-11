# Fly.io Minimal Dev Environment

Lightweight Debian-based development environment with Docker pre-installed, deployable to Fly.io.

## Features

- **Base**: Debian Bookworm Slim
- **Includes**: Docker, Git, Fish shell, SSH server, sudo, make, curl, wget
- **User**: `testuser` with passwordless sudo and Docker access
- **Auto-stop**: Machine automatically stops when idle to save costs
- **Auto-start**: Machine automatically starts on SSH connection
- **Smart Docker**: Auto-detects overlay2 vs vfs storage driver for best performance

## Quick Deploy

```bash
./deploy.sh
```

This script:
1. Authenticates with Fly.io
2. Builds the image on Fly's remote builder (AMD64)
3. Deploys with auto-stop/auto-start enabled
4. Configures single machine with `min_machines_running = 0`

## Configuration

- **Machine size**: `shared-cpu-2x` with 2GB RAM
- **Region**: DFW (Dallas)
- **Auto-stop**: Enabled (stops when idle)
- **Auto-start**: Enabled (starts on SSH)
- **Min machines**: 0 (scales to zero)

## Usage

### Connect via SSH
```bash
fly ssh console -a dev-env-minimal
```

### Check status
```bash
fly status -a dev-env-minimal
```

### View logs
```bash
fly logs -a dev-env-minimal
```

### Scale machine
```bash
# Change to different VM size
fly scale vm shared-cpu-4x --memory 4096 -a dev-env-minimal

# Or dedicated CPU
fly scale vm dedicated-cpu-2x --memory 4096 -a dev-env-minimal
```

## Reusing the Image

After deploying, the image is stored in Fly's registry and can be reused for other apps:

```bash
# Get current image reference
fly releases -a dev-env-minimal --image

# Deploy to a new app
fly apps create my-new-dev-env
fly deploy -a my-new-dev-env \
  --image registry.fly.io/dev-env-minimal:deployment-01K9T9QMTQEV99W3XSHC0JMMXZ
```

See `REUSE_IMAGE.md` for detailed multi-app deployment patterns.

## Current Image

Latest deployment:
```
registry.fly.io/dev-env-minimal:deployment-01K9T9QMTQEV99W3XSHC0JMMXZ
```

Image size: ~218 MB

## Cost Optimization

- Machine automatically stops when not in use
- No charges while stopped (only when running)
- Starts automatically when you SSH in
- Perfect for on-demand dev environments

## Files

- `Dockerfile` - Debian image with Docker pre-installed
- `fly.toml` - Fly.io configuration with auto-stop enabled
- `deploy.sh` - Automated deployment script
- `REUSE_IMAGE.md` - Guide for multi-app deployments

## What's Included

### Installed Packages
- openssh-server, bash, fish
- curl, wget, git
- sudo, ca-certificates, make
- gnupg, lsb-release, jq
- Docker CE (latest)
- Docker Compose plugin
- Docker Buildx plugin

### User Setup
- Username: `testuser`
- Shell: Fish
- Sudo: Passwordless
- Groups: docker
- SSH: Authorized key configured

## Next Steps

After deploying:

1. **SSH in**: `fly ssh console -a dev-env-minimal`
2. **Clone your repo**: `git clone <your-repo>`
3. **Start developing**: All Docker commands work immediately
4. **Disconnect**: Machine will auto-stop after idle period

## Notes

- No pre-cloned repositories (clean slate)
- Docker daemon starts automatically
- SSH via Fly's proxy (no public IP needed)
- Uses Fly.io's SSH CA for authentication
