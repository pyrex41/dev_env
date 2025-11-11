#!/bin/bash
set -e

echo "Creating Pre-configured Image with Pre-pulled Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

APP_NAME="wander-test-minimal"

# Temporarily switch to Dockerfile build
echo "1. Setting up fly.toml to build from Dockerfile..."
cp fly.toml fly.toml.backup
sed -i.tmp 's/image = /# image = /' fly.toml
sed -i.tmp 's/# \[build\]/[build]/' fly.toml
sed -i.tmp 's/#   dockerfile/  dockerfile/' fly.toml
rm -f fly.toml.tmp

# Deploy
echo ""
echo "2. Deploying to Fly.io (builds remotely)..."
fly deploy --remote-only

# Wait
echo ""
echo "3. Waiting for machine to start..."
sleep 15

# Pull images
echo ""
echo "4. Pre-pulling Docker images (this takes 3-5 minutes)..."
fly ssh console -C "docker pull postgres:16 && docker pull redis:7 && docker pull node:20-alpine"

# Get image reference
echo ""
echo "5. Getting deployment image..."
IMAGE_REF=$(fly releases --json | jq -r '.[0].image_ref')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! Images pre-pulled on deployed machine."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Current image: $IMAGE_REF"
echo ""
echo "To use this exact state for future deploys:"
echo ""
echo "  [build]"
echo "    image = \"$IMAGE_REF\""
echo ""
echo "Update fly.toml with the above, then 'fly deploy' will be instant!"
echo ""

# Restore
mv fly.toml.backup fly.toml
