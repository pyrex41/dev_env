#!/bin/bash
set -e

echo "Building image with pre-pulled Docker images..."

# Build the base image
docker build -t wander-dev-base .

echo "Starting container to pre-pull images..."

# Run container in privileged mode to allow Docker-in-Docker
CONTAINER_ID=$(docker run -d --privileged wander-dev-base)

echo "Container started: $CONTAINER_ID"
echo "Waiting for Docker daemon to start inside container..."
sleep 10

# Pre-pull images inside the running container
echo "Pulling postgres:16..."
docker exec $CONTAINER_ID docker pull postgres:16

echo "Pulling redis:7..."
docker exec $CONTAINER_ID docker pull redis:7

echo "Pulling node:20-alpine..."
docker exec $CONTAINER_ID docker pull node:20-alpine

echo "Committing container with pre-pulled images..."
docker commit $CONTAINER_ID wander-dev-complete

echo "Stopping and removing temporary container..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

echo "Tagging for Fly registry..."
docker tag wander-dev-complete registry.fly.io/wander-test-minimal:prebuilt

echo "Authenticating with Fly registry..."
fly auth docker

echo "Pushing to Fly registry..."
docker push registry.fly.io/wander-test-minimal:prebuilt

echo ""
echo "✅ Done! Image pushed to: registry.fly.io/wander-test-minimal:prebuilt"
echo ""
echo "Next steps:"
echo "1. Update fly.toml to use the prebuilt image"
echo "2. Run: fly deploy"
