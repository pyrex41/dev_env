#!/bin/bash

# Teardown Script for Wander Dev Environment
# Provides clean shutdown and cleanup options

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
WARNING="${YELLOW}⚠${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║        Wander Dev Environment - Teardown Script            ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if containers are running
check_containers() {
    if command_exists docker && docker info >/dev/null 2>&1; then
        local count=$(docker ps -q | wc -l | tr -d ' ')
        echo "$count"
    else
        echo "0"
    fi
}

# Display current status
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Current Environment Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check Docker
if command_exists docker; then
    echo -e "${CHECKMARK} Docker CLI installed"

    if docker info >/dev/null 2>&1; then
        echo -e "${CHECKMARK} Docker daemon running"

        RUNNING_CONTAINERS=$(check_containers)
        if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
            echo -e "${CHECKMARK} Running containers: ${YELLOW}$RUNNING_CONTAINERS${NC}"
        else
            echo -e "${CROSSMARK} No running containers"
        fi

        # Check for dev_env containers specifically
        DEV_CONTAINERS=$(docker ps --filter "name=wander_" -q | wc -l | tr -d ' ')
        if [ "$DEV_CONTAINERS" -gt 0 ]; then
            echo -e "${ARROW} Wander containers: ${YELLOW}$DEV_CONTAINERS${NC}"
        fi
    else
        echo -e "${CROSSMARK} Docker daemon not running"
    fi
else
    echo -e "${CROSSMARK} Docker not installed"
fi

# Check Colima
if command_exists colima; then
    echo -e "${CHECKMARK} Colima installed"
    if colima status >/dev/null 2>&1; then
        echo -e "${CHECKMARK} Colima running"
    else
        echo -e "${CROSSMARK} Colima stopped"
    fi
else
    echo -e "${CROSSMARK} Colima not installed"
fi

echo ""

# If nothing is running, exit early
if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Nothing to tear down!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Docker daemon is not running. No cleanup needed."
    echo ""
    exit 0
fi

# Teardown options
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Teardown Options${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Choose cleanup level:${NC}"
echo ""
echo -e "  ${GREEN}1)${NC} Basic      - Stop containers only"
echo -e "  ${GREEN}2)${NC} Full       - Stop containers + remove volumes ${YELLOW}(data loss)${NC}"
echo -e "  ${GREEN}3)${NC} Deep       - Full + Docker system prune ${YELLOW}(removes unused images)${NC}"
echo -e "  ${GREEN}4)${NC} Nuclear    - Deep + stop Colima ${YELLOW}(complete shutdown)${NC}"
echo -e "  ${GREEN}5)${NC} Cancel     - Exit without changes"
echo ""
echo -ne "${CYAN}Select option [1-5]:${NC} "
read -r TEARDOWN_LEVEL

case $TEARDOWN_LEVEL in
    1)
        LEVEL_NAME="Basic"
        DO_VOLUMES=false
        DO_PRUNE=false
        DO_COLIMA=false
        ;;
    2)
        LEVEL_NAME="Full"
        DO_VOLUMES=true
        DO_PRUNE=false
        DO_COLIMA=false
        ;;
    3)
        LEVEL_NAME="Deep"
        DO_VOLUMES=true
        DO_PRUNE=true
        DO_COLIMA=false
        ;;
    4)
        LEVEL_NAME="Nuclear"
        DO_VOLUMES=true
        DO_PRUNE=true
        DO_COLIMA=true
        ;;
    5)
        echo ""
        echo -e "${GREEN}Cancelled. No changes made.${NC}"
        echo ""
        exit 0
        ;;
    *)
        echo ""
        echo -e "${RED}Invalid option. Exiting.${NC}"
        echo ""
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠  $LEVEL_NAME Teardown Selected${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show what will happen
echo -e "${CYAN}This will:${NC}"
echo -e "  ${ARROW} Stop all containers"

if [ "$DO_VOLUMES" = true ]; then
    echo -e "  ${ARROW} Remove volumes ${RED}(DATABASE DATA WILL BE LOST)${NC}"
fi

if [ "$DO_PRUNE" = true ]; then
    echo -e "  ${ARROW} Remove unused Docker images and build cache"
fi

if [ "$DO_COLIMA" = true ]; then
    echo -e "  ${ARROW} Stop Colima VM"
fi

echo ""
echo -ne "${YELLOW}Are you sure you want to continue? (y/N):${NC} "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}Cancelled. No changes made.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Starting Teardown${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Stop containers
echo -e "${ARROW} Stopping containers..."
if [ "$DO_VOLUMES" = true ]; then
    make down >/dev/null 2>&1 || docker-compose down --volumes >/dev/null 2>&1
    echo -e "${CHECKMARK} Containers stopped and volumes removed"
else
    docker-compose stop >/dev/null 2>&1 || true
    echo -e "${CHECKMARK} Containers stopped"
fi

# Step 2: Docker system prune
if [ "$DO_PRUNE" = true ]; then
    echo ""
    echo -e "${ARROW} Cleaning up Docker system..."
    docker system prune -f >/dev/null 2>&1
    echo -e "${CHECKMARK} Docker system pruned"
fi

# Step 3: Stop Colima
if [ "$DO_COLIMA" = true ]; then
    echo ""
    echo -e "${ARROW} Stopping Colima..."
    if command_exists colima; then
        colima stop >/dev/null 2>&1 || true
        echo -e "${CHECKMARK} Colima stopped"
    else
        echo -e "${YELLOW}  Colima not installed, skipping${NC}"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Teardown Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}What was cleaned up:${NC}"
echo -e "  ${CHECKMARK} Containers stopped"

if [ "$DO_VOLUMES" = true ]; then
    echo -e "  ${CHECKMARK} Volumes removed (database data deleted)"
fi

if [ "$DO_PRUNE" = true ]; then
    echo -e "  ${CHECKMARK} Docker system pruned"
fi

if [ "$DO_COLIMA" = true ]; then
    echo -e "  ${CHECKMARK} Colima stopped"
fi

echo ""

# Next steps
if [ "$DO_COLIMA" = true ]; then
    echo -e "${BLUE}To start again:${NC}"
    echo -e "  ${CYAN}1)${NC} colima start"
    echo -e "  ${CYAN}2)${NC} make dev"
elif [ "$DO_VOLUMES" = true ]; then
    echo -e "${BLUE}To start again:${NC}"
    echo -e "  ${CYAN}make dev${NC}  (fresh database, will run migrations)"
else
    echo -e "${BLUE}To start again:${NC}"
    echo -e "  ${CYAN}make dev${NC}  (data preserved)"
fi

echo ""
