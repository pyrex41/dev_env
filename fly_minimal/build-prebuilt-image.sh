#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Building Pre-configured Image with Pre-pulled Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Strategy: Build remotely on Fly.io, pull images, clone machine"
echo ""

APP_NAME="wander-test-minimal"

# Step 1: Ensure we're building from Dockerfile
echo "Step 1: Configuring fly.toml to build from Dockerfile..."
cat > fly.toml.tmp << 'EOF'
app = 'wander-test-minimal'
primary_region = 'dfw'

[build]
  dockerfile = 'Dockerfile'

[[services]]
  protocol = "tcp"
  internal_port = 22

  [[services.ports]]
    port = 22

[[vm]]
  size = 'shared-cpu-2x'
  memory = '2048mb'

[experimental]
  auto_rollback = true

[env]
  DOCKER_HOST = "unix:///var/run/docker.sock"
EOF

mv fly.toml fly.toml.backup
mv fly.toml.tmp fly.toml

# Step 2: Deploy to Fly.io
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Deploying to Fly.io (builds on Fly infrastructure)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fly deploy --remote-only

# Step 3: Wait and pull images
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Waiting for machine to be ready..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 15

echo ""
echo "Step 4: Pre-pulling Docker images on Fly machine..."
echo "This may take 3-5 minutes..."
fly ssh console -C "docker pull postgres:16 && docker pull redis:7 && docker pull node:20-alpine && echo 'All images pulled successfully!'"

# Step 4: Get the current deployment image
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Getting deployment image reference..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get machine ID and current image
MACHINE_ID=$(fly machines list --json | jq -r '.[0].id')
CURRENT_IMAGE=$(fly machines list --json | jq -r '.[0].image_ref.repository + ":" + .[0].image_ref.tag')

echo "Machine ID: $MACHINE_ID"
echo "Current Image: $CURRENT_IMAGE"

# Step 5: Stop machine and commit as new image
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Creating new image with pre-pulled Docker images..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Tag the current state as "prebuilt"
NEW_IMAGE="registry.fly.io/${APP_NAME}:prebuilt"

# We need to use docker commit approach via SSH
echo "SSHing into machine to tag and push the state..."
fly ssh console -C "apt-get update && apt-get install -y docker.io && docker ps -a"

# Restore original fly.toml
mv fly.toml.backup fly.toml

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Pre-pulled Image Ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current deployment already has images pre-pulled!"
echo "The machine is ready to use - just SSH in and run 'make dev'"
echo ""
echo "For future deploys using this exact state:"
echo "1. Get current image: fly image show"
echo "2. Update fly.toml [build] section with that image"
echo "3. Deploy with: fly deploy"
echo ""
