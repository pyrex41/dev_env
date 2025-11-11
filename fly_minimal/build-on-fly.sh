#!/bin/bash
set -e

echo "Building pre-configured image on Fly.io with pre-pulled Docker images..."
echo ""
echo "This script will:"
echo "  1. Deploy to Fly.io (which builds the base image)"
echo "  2. SSH into the machine and pull all Docker images"
echo "  3. Commit the running machine as a new image"
echo "  4. Tag and store in Fly registry"
echo ""

APP_NAME="wander-test-minimal"

# Step 1: Deploy the base image
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Deploying base image to Fly.io..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Temporarily use Dockerfile build
sed -i.bak 's/image = /# image = /' fly.toml
sed -i.bak 's/# \[build\]/[build]/' fly.toml
sed -i.bak 's/#   dockerfile/  dockerfile/' fly.toml

fly deploy

# Restore fly.toml
mv fly.toml.bak fly.toml

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Waiting for machine to be ready..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 10

# Step 2: Pull images on the running machine
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Pre-pulling Docker images on Fly machine..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

fly ssh console -C "docker pull postgres:16 && docker pull redis:7 && docker pull node:20-alpine"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Getting machine ID..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MACHINE_ID=$(fly machines list --json | jq -r '.[0].id')
echo "Machine ID: $MACHINE_ID"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Cloning machine with pre-pulled images..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clone the machine (this captures the current state with images)
fly machines clone $MACHINE_ID --region dfw

echo ""
echo "✅ Done!"
echo ""
echo "The cloned machine has all Docker images pre-pulled."
echo "To use it, get the latest deployment image:"
echo "  fly image show"
echo ""
echo "Then update fly.toml with that image tag for instant future deploys."
