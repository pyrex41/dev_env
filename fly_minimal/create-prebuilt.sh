#!/bin/bash
set -e

echo "Creating Pre-configured Image with Pre-pulled Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

APP_NAME="wander-test-minimal"

# Deploy
echo "1. Deploying to Fly.io (builds remotely)..."
fly deploy --remote-only

# Wait
echo ""
echo "2. Waiting for machine to start..."
sleep 15

# Pull images
echo ""
echo "3. Pre-pulling Docker images (this takes 3-5 minutes)..."
fly ssh console -C "docker pull postgres:16 && docker pull redis:7 && docker pull node:20-alpine"

# Get image reference
echo ""
echo "4. Getting deployment image..."
IMAGE_REF=$(fly releases --json | jq -r '.[0].image_ref')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! Images pre-pulled on deployed machine."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current deployment image: $IMAGE_REF"
echo ""
echo "To use this exact state for future instant deploys:"
echo "1. Edit fly.toml and replace the [build] section with:"
echo ""
echo "  [build]"
echo "    image = \"$IMAGE_REF\""
echo ""
echo "2. Then run: fly deploy (instant!)"
echo ""
