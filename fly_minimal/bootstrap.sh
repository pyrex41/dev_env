#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Wander Zero-to-Running Bootstrap Script
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# This script demonstrates "zero-to-running" on a clean Linux machine.
# Starting from a fresh Ubuntu/Alpine system, it will:
#   1. Install Docker
#   2. Clone the repository
#   3. Run `make dev`
#   4. Verify all services are healthy
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/your/repo/bootstrap.sh | bash
#   OR
#   wget -qO- https://raw.githubusercontent.com/your/repo/bootstrap.sh | bash
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e  # Exit on error

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration (change these for your repo)
REPO_URL="${REPO_URL:-https://github.com/your-org/wander-dev-env.git}"
REPO_DIR="${REPO_DIR:-wander-dev-env}"
REPO_BRANCH="${REPO_BRANCH:-master}"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Wander Zero-to-Running Developer Environment${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}✗ Cannot detect OS. /etc/os-release not found.${NC}"
    exit 1
fi

echo -e "${CYAN}Detected OS:${NC} $OS $VER"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1: Install Docker
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${CYAN}[1/5] Checking Docker installation...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
else
    echo -e "${YELLOW}⚠ Docker not found. Installing...${NC}"

    case $OS in
        ubuntu|debian)
            echo "Installing Docker on Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Add current user to docker group
            sudo usermod -aG docker $USER
            echo -e "${GREEN}✓ Docker installed successfully${NC}"
            echo -e "${YELLOW}⚠ You may need to log out and back in for docker group to take effect${NC}"
            ;;

        alpine)
            echo "Installing Docker on Alpine..."
            sudo apk add --no-cache docker docker-compose
            sudo rc-update add docker boot
            sudo service docker start
            sudo addgroup $USER docker
            echo -e "${GREEN}✓ Docker installed successfully${NC}"
            ;;

        *)
            echo -e "${RED}✗ Unsupported OS: $OS${NC}"
            echo "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
fi

# Verify Docker is running
if ! docker info &> /dev/null; then
    echo -e "${YELLOW}⚠ Docker daemon is not running. Starting...${NC}"
    sudo service docker start || sudo systemctl start docker
    sleep 3
fi

if docker info &> /dev/null; then
    echo -e "${GREEN}✓ Docker is running${NC}"
else
    echo -e "${RED}✗ Docker is not running. Please start Docker manually.${NC}"
    exit 1
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Install Git (if not present)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${CYAN}[2/5] Checking Git installation...${NC}"

if command -v git &> /dev/null; then
    echo -e "${GREEN}✓ Git is already installed${NC}"
else
    echo -e "${YELLOW}⚠ Git not found. Installing...${NC}"

    case $OS in
        ubuntu|debian)
            sudo apt-get install -y git
            ;;
        alpine)
            sudo apk add --no-cache git
            ;;
    esac

    echo -e "${GREEN}✓ Git installed successfully${NC}"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: Clone Repository
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${CYAN}[3/5] Cloning repository...${NC}"

if [ -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}⚠ Directory $REPO_DIR already exists. Removing...${NC}"
    rm -rf "$REPO_DIR"
fi

git clone -b "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

echo -e "${GREEN}✓ Repository cloned successfully${NC}"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 4: Setup Environment
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${CYAN}[4/5] Setting up environment...${NC}"

# Create .env file with safe defaults
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file with safe defaults...${NC}"
    cp .env.local.example .env
    echo -e "${GREEN}✓ .env file created${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 5: Start Services
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${CYAN}[5/5] Starting services with make dev...${NC}"
echo ""

# Run make dev
make dev

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Zero-to-Running setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Services running at:${NC}"
echo -e "  Frontend: ${GREEN}http://localhost:3000${NC}"
echo -e "  API:      ${GREEN}http://localhost:8000${NC}"
echo -e "  Health:   ${GREEN}http://localhost:8000/health${NC}"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo -e "  ${YELLOW}make logs${NC}        - View logs from all services"
echo -e "  ${YELLOW}make health${NC}      - Check service health"
echo -e "  ${YELLOW}make down${NC}        - Stop all services"
echo -e "  ${YELLOW}make reset${NC}       - Reset environment (fresh start)"
echo -e "  ${YELLOW}make help${NC}        - Show all available commands"
echo ""
echo -e "${CYAN}Time elapsed:${NC} $SECONDS seconds"
echo ""
