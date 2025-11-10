#!/bin/bash

# Interactive Setup Script for Wander Dev Environment
# This script walks you through setting up all prerequisites

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Unicode symbols
CHECKMARK="${GREEN}✓${NC}"
CROSSMARK="${RED}✗${NC}"
ARROW="${CYAN}→${NC}"
WAITING="${YELLOW}⏳${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║        Wander Dev Environment - Interactive Setup          ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to wait for user
wait_for_enter() {
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for Docker daemon with timeout
wait_for_docker() {
    local timeout=60
    local elapsed=0

    echo -e "${YELLOW}Waiting for Docker daemon to start...${NC}"

    while [ $elapsed -lt $timeout ]; do
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker daemon is running!${NC}"
            return 0
        fi

        printf "${YELLOW}."
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo ""
    echo -e "${RED}✗ Docker daemon did not start within ${timeout} seconds${NC}"
    return 1
}

# Step 1: Check Docker
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1: Checking Docker Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,$//')
    echo -e "${CHECKMARK} Docker is installed (version ${DOCKER_VERSION})"
else
    echo -e "${CROSSMARK} Docker is not installed"
    echo ""
    echo -e "${YELLOW}Would you like to install Docker Desktop? (y/n)${NC}"
    read -r install_docker

    if [[ "$install_docker" =~ ^[Yy]$ ]]; then
        if command_exists brew; then
            echo -e "${ARROW} Installing Docker Desktop via Homebrew..."
            brew install --cask docker
            echo -e "${CHECKMARK} Docker Desktop installed!"
            echo ""
            echo -e "${YELLOW}Please open Docker Desktop from your Applications folder${NC}"
            echo -e "${YELLOW}Look for the whale icon in your menu bar${NC}"
            wait_for_enter
        else
            echo -e "${RED}Homebrew is not installed. Please install Docker Desktop manually from:${NC}"
            echo -e "${CYAN}https://www.docker.com/products/docker-desktop${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Docker is required to run the development environment${NC}"
        exit 1
    fi
fi

echo ""

# Step 2: Check Docker Daemon
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2: Starting Docker Daemon${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if docker info >/dev/null 2>&1; then
    echo -e "${CHECKMARK} Docker daemon is already running"
else
    echo -e "${CROSSMARK} Docker daemon is not running"
    echo ""

    # Check if Colima is installed
    if command_exists colima; then
        echo -e "${YELLOW}Would you like me to start Colima for you? (y/n)${NC}"
        read -r start_colima

        if [[ "$start_colima" =~ ^[Yy]$ ]]; then
            echo -e "${ARROW} Starting Colima..."
            colima start --cpu 4 --memory 8 --disk 60

            if wait_for_docker; then
                echo -e "${CHECKMARK} Colima started successfully!"
            else
                echo -e "${RED}Docker daemon did not start. Please start Colima manually:${NC}"
                echo -e "  colima start"
                exit 1
            fi
        else
            echo -e "${YELLOW}Please start Colima manually:${NC}"
            echo -e "  colima start"
            echo ""
            echo -e "${YELLOW}When Colima is running, press Enter to continue...${NC}"
            read -r

            if ! docker info >/dev/null 2>&1; then
                echo -e "${RED}Docker daemon is still not running. Exiting.${NC}"
                exit 1
            fi
        fi
    else
        # Colima not installed
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠  Colima Not Found${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${CYAN}You have Docker CLI but Colima is missing.${NC}"
        echo ""
        echo -e "Colima provides a lightweight Docker runtime for macOS."
        echo -e "It's faster and uses less resources than Docker Desktop."
        echo ""
        echo -e "${CYAN}Think of it like:${NC}"
        echo -e "  ${GREEN}Docker CLI${NC} = steering wheel (what you have)"
        echo -e "  ${GREEN}Colima${NC}     = the engine (what you need)"
        echo ""
        echo -e "${YELLOW}Would you like to install Colima now? (y/n)${NC}"
        read -r install_colima

        if [[ "$install_colima" =~ ^[Yy]$ ]]; then
            if command_exists brew; then
                echo -e "${ARROW} Installing Colima via Homebrew..."
                echo -e "${CYAN}This may take a few minutes...${NC}"
                echo ""
                brew install colima
                echo ""
                echo -e "${CHECKMARK} Colima installed!"
                echo ""
                echo -e "${ARROW} Starting Colima..."
                colima start --cpu 4 --memory 8 --disk 60

                if wait_for_docker; then
                    echo -e "${CHECKMARK} Colima started successfully!"
                else
                    echo -e "${RED}Colima did not start. Please run:${NC}"
                    echo -e "  colima start"
                    exit 1
                fi
            else
                echo -e "${RED}Homebrew is not installed. Please install Docker Desktop manually from:${NC}"
                echo -e "${CYAN}https://www.docker.com/products/docker-desktop${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Docker Desktop is required to run the Docker daemon.${NC}"
            echo -e "${YELLOW}Alternative: Install manually from ${CYAN}https://www.docker.com/products/docker-desktop${NC}"
            exit 1
        fi
    fi
fi

echo ""

# Step 3: Check Docker Compose
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3: Checking Docker Compose${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check for docker-compose (v1)
if command_exists docker-compose; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $4}' | sed 's/,$//')
    echo -e "${CHECKMARK} docker-compose is installed (v1, version ${COMPOSE_VERSION})"
    COMPOSE_CMD="docker-compose"
# Check for docker compose (v2)
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "${CHECKMARK} docker compose is installed (v2, version ${COMPOSE_VERSION})"
    COMPOSE_CMD="docker compose"
else
    echo -e "${CROSSMARK} Docker Compose is not installed"
    echo ""
    echo -e "${YELLOW}Docker Compose is required. Install options:${NC}"
    echo -e "  ${CYAN}1)${NC} Install via Homebrew (recommended)"
    echo -e "  ${CYAN}2)${NC} Use Docker Desktop's built-in compose"
    echo -e "  ${CYAN}3)${NC} Manual installation"
    echo ""
    echo -e "${YELLOW}Choose an option (1-3):${NC} "
    read -r compose_option

    case $compose_option in
        1)
            if command_exists brew; then
                echo -e "${ARROW} Installing docker-compose via Homebrew..."
                brew install docker-compose

                # Add config for Docker to find the plugin
                DOCKER_CONFIG="$HOME/.docker/config.json"
                mkdir -p "$HOME/.docker"

                if [ -f "$DOCKER_CONFIG" ]; then
                    # Check if cliPluginsExtraDirs already exists
                    if ! grep -q "cliPluginsExtraDirs" "$DOCKER_CONFIG"; then
                        echo -e "${ARROW} Configuring Docker to find the plugin..."
                        # Backup existing config
                        cp "$DOCKER_CONFIG" "$DOCKER_CONFIG.backup"
                        # Add cliPluginsExtraDirs
                        jq '. + {"cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]}' "$DOCKER_CONFIG" > "$DOCKER_CONFIG.tmp" && mv "$DOCKER_CONFIG.tmp" "$DOCKER_CONFIG"
                    fi
                else
                    echo '{"cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]}' > "$DOCKER_CONFIG"
                fi

                echo -e "${CHECKMARK} docker-compose installed!"
                COMPOSE_CMD="docker-compose"
            else
                echo -e "${RED}Homebrew is not installed. Please install Homebrew first:${NC}"
                echo -e "${CYAN}https://brew.sh${NC}"
                exit 1
            fi
            ;;
        2)
            echo -e "${YELLOW}Docker Desktop includes Docker Compose v2${NC}"
            echo -e "${YELLOW}Try running: docker compose version${NC}"
            echo ""
            if docker compose version >/dev/null 2>&1; then
                echo -e "${CHECKMARK} Docker Compose v2 is available!"
                COMPOSE_CMD="docker compose"
            else
                echo -e "${RED}Docker Compose is not available. Please reinstall Docker Desktop.${NC}"
                exit 1
            fi
            ;;
        3)
            echo -e "${YELLOW}Manual installation instructions:${NC}"
            echo -e "See: ${CYAN}INSTALL.md${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
fi

echo ""

# Step 4: Configure Environment
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 4: Environment Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f .env ]; then
    echo -e "${CHECKMARK} .env file already exists"
else
    echo -e "${ARROW} Creating .env from .env.example..."
    cp .env.example .env
    echo -e "${CHECKMARK} .env file created"
    echo ""
    echo -e "${YELLOW}⚠ Important: The .env file contains default passwords${NC}"
    echo -e "${YELLOW}  These are fine for local development but should be changed for production${NC}"
fi

echo ""

# Step 5: Summary and Next Steps
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 5: Setup Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}✓ All prerequisites are satisfied!${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo -e "  ${CHECKMARK} Docker is installed and running"
echo -e "  ${CHECKMARK} Docker Compose is available (${COMPOSE_CMD})"
echo -e "  ${CHECKMARK} Environment configuration ready"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ready to start the development environment!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run: ${CYAN}make dev${NC}       - Start all services"
echo -e "  2. Open: ${CYAN}http://localhost:3000${NC}"
echo -e "  3. Run: ${CYAN}make logs${NC}      - View service logs"
echo -e "  4. Run: ${CYAN}make down${NC}      - Stop everything"
echo ""
echo -e "${YELLOW}Would you like to start the development environment now? (y/n)${NC}"
read -r start_now

if [[ "$start_now" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${ARROW} Starting development environment..."
    echo ""
    make dev
else
    echo ""
    echo -e "${BLUE}When you're ready, run:${NC} ${CYAN}make dev${NC}"
    echo ""
fi
