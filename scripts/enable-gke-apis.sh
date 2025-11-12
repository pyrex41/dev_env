#!/bin/bash
# Enable Required Google Cloud APIs for GKE

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}Enabling Google Cloud APIs for GKE...${NC}"
echo ""

# Get current project
PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT" ]; then
    echo -e "${YELLOW}No project set. Please set a project first:${NC}"
    echo "  gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${CYAN}Project: ${PROJECT}${NC}"
echo ""

# List of required APIs
APIS=(
    "cloudresourcemanager.googleapis.com"
    "compute.googleapis.com"
    "container.googleapis.com"
)

echo -e "${YELLOW}Enabling APIs (this may take a few minutes)...${NC}"
echo ""

for API in "${APIS[@]}"; do
    echo -e "${CYAN}Enabling ${API}...${NC}"
    if gcloud services enable "$API" --project="$PROJECT"; then
        echo -e "${GREEN}✓ ${API} enabled${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to enable ${API} (may already be enabled)${NC}"
    fi
    echo ""
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ APIs Enabled!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Next step:${NC}"
echo -e "  ${CYAN}make gke-setup${NC}"
echo ""
