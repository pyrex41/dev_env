# Fly Minimal - Lean Linux Test Machine

A minimal Alpine Linux machine on Fly.io for testing setup scripts via SSH.

**NO PERSISTENT STORAGE** - Fresh, clean start every time you redeploy. Perfect for demos.

## Configuration

- **Image**: Alpine Linux 3.19 (~50MB with SSH/tools)
- **Region**: DFW (Dallas)
- **Size**: shared-cpu-1x, 256MB RAM
- **Auto-stop**: Enabled (stops when idle, starts on connection)
- **Min machines**: 0 (completely off until you start it)
- **Storage**: None - ephemeral only (fresh start each deployment)

## Setup

### 1. Deploy to Fly.io

```bash
cd fly_minimal

# Login to Fly.io (if not already)
fly auth login

# Create the app (first time only)
fly apps create wander-test-minimal

# Deploy
fly deploy

# The machine will auto-stop after deployment
```

### 2. Configure SSH Access

```bash
# Set up SSH certificate
fly ssh establish

# Or add your SSH key
fly ssh issue --agent
```

### 3. Start and Connect

```bash
# SSH into machine (auto-starts if stopped)
fly ssh console

# SSH as testuser (has sudo access)
fly ssh console -u testuser
```

## Usage

### Quick Demo Workflow

```bash
# 1. SSH into fresh machine
fly ssh console -u testuser

# 2. Clone your repo
cd ~/workspace
git clone https://github.com/your/repo.git
cd repo

# 3. Run setup scripts
./setup.sh

# 4. When done, exit and machine auto-stops
exit

# 5. Next demo: Redeploy for fresh start
fly deploy
```

### Test Setup Scripts

```bash
# SSH into machine
fly ssh console -u testuser

# Test your scripts
curl -O https://example.com/setup.sh
bash setup.sh

# Or clone and test
git clone <your-repo>
cd <your-repo>
./setup.sh
```

### Copy Files to Machine

```bash
# Using fly sftp
fly ssh sftp shell
put setup.sh /home/testuser/

# Or use scp through fly proxy
fly proxy 10022:22
scp -P 10022 setup.sh testuser@localhost:~/
```

## Features

- ✅ **Minimal**: Alpine Linux base (~50MB total)
- ✅ **SSH Ready**: OpenSSH server configured
- ✅ **Test User**: `testuser` with sudo access
- ✅ **Auto-stop**: No charges when idle
- ✅ **Stateless**: Fresh start every deployment (no volumes)
- ✅ **Basic Tools**: bash, curl, wget, git
- ✅ **Demo-Ready**: Clean environment every time

## Cost

- **Compute**: ~$0.001/hour when running (~$0.75/month if always on)
- **Storage**: Free (no volumes)
- **Auto-stop**: Only charged when machine is running

With auto-stop enabled and min_machines_running = 0, you only pay when actively using it.

## Customization

### Install Additional Tools (Temporary)

```bash
# SSH into machine
fly ssh console

# Install packages (Alpine uses apk)
# These will be lost on redeploy - that's the point!
apk add --no-cache docker nodejs npm python3 make gcc
```

### Add Tools Permanently

Edit `Dockerfile` and add to RUN command:

```dockerfile
RUN apk add --no-cache \
    openssh \
    bash \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    docker \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*
```

Then redeploy: `fly deploy`

### Change Region

Edit `fly.toml`:
```toml
primary_region = 'sjc'  # San Jose
# or 'ord' (Chicago), 'iad' (Virginia), 'lax' (LA), etc.
```

### Increase Resources

Edit `fly.toml`:
```toml
[[vm]]
  size = 'shared-cpu-2x'
  memory = '512mb'
```

## Commands Reference

```bash
# Deploy and manage
fly deploy                    # Deploy fresh machine
fly apps destroy wander-test-minimal  # Delete app

# Machine control
fly machine start             # Start machine
fly machine stop              # Stop machine
fly machine restart           # Restart machine
fly machine list              # List machines

# SSH access
fly ssh console               # SSH as root
fly ssh console -u testuser   # SSH as testuser (recommended)
fly ssh establish             # Set up SSH keys

# Logs and monitoring
fly logs                      # View logs
fly status                    # Check machine status
fly dashboard                 # Open web dashboard
```

## Troubleshooting

### Machine Won't Start

```bash
# Check status
fly status

# View logs
fly logs

# Force restart
fly machine restart --force
```

### Can't SSH

```bash
# Verify machine is running
fly status

# Re-establish SSH
fly ssh establish

# Try manual start
fly machine start
```

### Want Clean Start

```bash
# Just redeploy - no volumes means fresh machine
fly deploy
```

## Demo Workflow Example

Perfect for video demos showing clean environment setup:

```bash
# 1. Deploy fresh machine
fly deploy

# 2. SSH in (machine auto-starts)
fly ssh console -u testuser

# 3. Show clean environment
ls -la ~/
df -h

# 4. Demo your setup scripts
curl -fsSL https://your-site.com/install.sh | bash

# 5. Show results
docker --version
node --version
# etc...

# 6. Exit (machine auto-stops)
exit

# 7. Next demo: redeploy for fresh start
fly deploy
```

## Why Stateless?

- ✅ **Clean demos**: Every deployment is pristine
- ✅ **No cleanup needed**: Just redeploy
- ✅ **Faster**: No volume mounting overhead
- ✅ **Cheaper**: No storage costs
- ✅ **Simpler**: No volume management
- ✅ **Reproducible**: Same state every time

Perfect for:
- Video demos
- Testing installation scripts
- Setup script validation
- Clean environment testing
- Onboarding script demos
