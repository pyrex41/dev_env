#!/bin/bash

# Fly.io Deployment Script for dev_env
# This script builds and deploys the Docker image to Fly.io's private registry

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}        Fly.io Deployment - Dev Environment                 ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Configuration
APP_NAME="${FLY_APP_NAME:-dev-env-minimal}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY_IMAGE="registry.fly.io/${APP_NAME}:${IMAGE_TAG}"

# Check if flyctl is installed
if ! command -v fly &> /dev/null; then
    echo -e "${RED}✗ flyctl is not installed${NC}"
    echo ""
    echo -e "${YELLOW}Install flyctl:${NC}"
    echo "  macOS/Linux: curl -L https://fly.io/install.sh | sh"
    echo "  Or visit: https://fly.io/docs/getting-started/installing-flyctl/"
    exit 1
fi

echo -e "${GREEN}✓ flyctl is installed${NC}"
echo ""

# Check if logged in
if ! fly auth whoami &> /dev/null; then
    echo -e "${YELLOW}⚠ Not logged in to Fly.io${NC}"
    echo -e "${YELLOW}Running: fly auth login${NC}"
    fly auth login
fi

echo -e "${GREEN}✓ Authenticated with Fly.io${NC}"
echo ""

# Check if app exists, create if not
if ! fly apps list | grep -q "^${APP_NAME}"; then
    echo -e "${YELLOW}⚠ App '${APP_NAME}' does not exist${NC}"
    echo -e "${BLUE}→ Creating app...${NC}"
    fly apps create "${APP_NAME}"
    echo -e "${GREEN}✓ App created${NC}"
else
    echo -e "${GREEN}✓ App '${APP_NAME}' exists${NC}"
fi

echo ""

# Authenticate Docker with Fly.io registry
echo -e "${BLUE}→ Authenticating Docker with Fly.io registry...${NC}"
fly auth docker
echo -e "${GREEN}✓ Docker authenticated${NC}"
echo ""

# Deploy using Fly's remote builder (builds for correct architecture)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Building and deploying with Fly's remote builder...${NC}"
echo -e "${BLUE}(This will build for AMD64 architecture automatically)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
fly deploy --app "${APP_NAME}"
echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""

# Show connection info
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "App Name:    ${GREEN}${APP_NAME}${NC}"
echo -e "Image:       ${GREEN}${REGISTRY_IMAGE}${NC}"
echo -e "SSH Command: ${YELLOW}fly ssh console -a ${APP_NAME}${NC}"
echo -e "App Info:    ${YELLOW}fly status -a ${APP_NAME}${NC}"
echo ""
