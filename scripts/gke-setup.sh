#!/bin/bash
# Google Kubernetes Engine (GKE) Setup Script
# Sets up a GKE cluster for the Wander application

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║        Google Kubernetes Engine (GKE) Setup                ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Add common gcloud installation paths to PATH
export PATH="$HOME/google-cloud-sdk/bin:/opt/homebrew/bin:/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin:/usr/local/bin:$PATH"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}✗ gcloud CLI not installed${NC}"
    read -p "Install Google Cloud SDK now? (y/N): " INSTALL_GCLOUD
    if [[ "$INSTALL_GCLOUD" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing Google Cloud SDK...${NC}"

        # Try installing with brew
        if brew install --cask google-cloud-sdk 2>&1 | tee /tmp/gcloud-install.log; then
            echo -e "${GREEN}✓ Google Cloud SDK installed via Homebrew${NC}"
        else
            # If brew fails (Python issues), use alternative method
            if grep -q "python" /tmp/gcloud-install.log; then
                echo -e "${YELLOW}Homebrew installation failed due to Python issues${NC}"
                echo -e "${BLUE}Installing via official installer instead...${NC}"

                # Download and install using official script
                cd /tmp
                curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
                tar -xf google-cloud-cli-darwin-arm.tar.gz
                ./google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=true

                # Add to PATH for current session
                export PATH="$HOME/google-cloud-sdk/bin:$PATH"

                echo -e "${GREEN}✓ Google Cloud SDK installed${NC}"
                echo -e "${YELLOW}Note: Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)${NC}"
            else
                echo -e "${RED}Installation failed. Please install manually from:${NC}"
                echo -e "${CYAN}https://cloud.google.com/sdk/docs/install${NC}"
                exit 1
            fi
        fi

        rm -f /tmp/gcloud-install.log

        # Don't auto-run gcloud init during setup - user can run it separately
        echo ""
        echo -e "${YELLOW}Note: Run 'gcloud init' or 'gcloud auth login' before continuing${NC}"
        read -p "Press Enter after you've logged in to continue..."

    else
        echo -e "${RED}gcloud is required. Install from: https://cloud.google.com/sdk/docs/install${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ gcloud CLI installed${NC}"
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}✗ kubectl not installed${NC}"
    read -p "Install kubectl now? (y/N): " INSTALL_KUBECTL
    if [[ "$INSTALL_KUBECTL" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing kubectl...${NC}"
        brew install kubectl
        echo -e "${GREEN}✓ kubectl installed${NC}"
    else
        echo -e "${RED}kubectl is required. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ kubectl installed${NC}"
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}✗ helm not installed${NC}"
    read -p "Install helm now? (y/N): " INSTALL_HELM
    if [[ "$INSTALL_HELM" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing helm...${NC}"
        brew install helm
        echo -e "${GREEN}✓ helm installed${NC}"
    else
        echo -e "${RED}helm is required. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ helm installed${NC}"
fi

echo ""

# Check authentication
echo -e "${YELLOW}Checking Google Cloud authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}✗ Not authenticated with Google Cloud${NC}"
    echo -e "${YELLOW}Running gcloud auth login...${NC}"
    gcloud auth login
fi

ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)
echo -e "${GREEN}✓ Authenticated as: ${ACCOUNT}${NC}"

# Get or set project
echo ""
echo -e "${YELLOW}Google Cloud Project Setup${NC}"
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)

if [ -n "$CURRENT_PROJECT" ]; then
    echo -e "${CYAN}Current project: ${CURRENT_PROJECT}${NC}"
    read -p "Use this project? (Y/n): " USE_CURRENT
    if [[ "$USE_CURRENT" =~ ^[Nn]$ ]]; then
        CURRENT_PROJECT=""
    fi
fi

if [ -z "$CURRENT_PROJECT" ]; then
    echo ""
    echo -e "${YELLOW}Available projects:${NC}"
    gcloud projects list
    echo ""
    read -p "Enter project ID (or press Enter to create new): " PROJECT_ID

    if [ -z "$PROJECT_ID" ]; then
        read -p "Enter new project ID: " PROJECT_ID
        read -p "Enter project name: " PROJECT_NAME
        echo -e "${BLUE}Creating project...${NC}"
        gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME"
    fi

    gcloud config set project "$PROJECT_ID"
    CURRENT_PROJECT="$PROJECT_ID"
fi

echo -e "${GREEN}✓ Using project: ${CURRENT_PROJECT}${NC}"

# Check billing using a more reliable method
echo ""
echo -e "${YELLOW}Checking billing status...${NC}"

# Try to enable a simple API as a test (this will fail quickly if billing isn't enabled)
# We'll use cloudresourcemanager.googleapis.com which is needed anyway
if gcloud services enable cloudresourcemanager.googleapis.com --project="$CURRENT_PROJECT" 2>&1 | grep -q "FAILED_PRECONDITION.*billing"; then
    echo -e "${RED}✗ Billing is not enabled for this project${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Billing Setup Required${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}To enable billing:${NC}"
    echo ""
    echo -e "1. Visit: ${CYAN}https://console.cloud.google.com/billing${NC}"
    echo -e "2. Create a billing account (requires credit card)"
    echo -e "3. Link it to project: ${CYAN}${CURRENT_PROJECT}${NC}"
    echo ""
    echo -e "${YELLOW}New users get \$300 free credits for 90 days!${NC}"
    echo ""
    echo -e "${CYAN}Or run this command to list billing accounts and link:${NC}"
    echo -e "  gcloud alpha billing accounts list"
    echo -e "  gcloud beta billing projects link $CURRENT_PROJECT --billing-account=BILLING_ACCOUNT_ID"
    echo ""
    read -p "Press Enter after enabling billing to continue (or Ctrl+C to exit)..."

    # Try again
    if gcloud services enable cloudresourcemanager.googleapis.com --project="$CURRENT_PROJECT" 2>&1 | grep -q "FAILED_PRECONDITION.*billing"; then
        echo -e "${RED}Billing still not enabled. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Billing enabled${NC}"

# Enable required APIs
echo ""
echo -e "${YELLOW}Enabling required Google Cloud APIs...${NC}"
echo -e "${CYAN}This may take a few minutes...${NC}"

gcloud services enable container.googleapis.com --project="$CURRENT_PROJECT"
gcloud services enable compute.googleapis.com --project="$CURRENT_PROJECT"

echo -e "${GREEN}✓ APIs enabled${NC}"

# Cluster configuration
echo ""
echo -e "${YELLOW}GKE Cluster Configuration${NC}"
echo ""

read -p "Enter cluster name (default: wander-cluster): " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-wander-cluster}

read -p "Enter zone (default: us-central1-a): " ZONE
ZONE=${ZONE:-us-central1-a}

read -p "Enter machine type (default: e2-standard-2): " MACHINE_TYPE
MACHINE_TYPE=${MACHINE_TYPE:-e2-standard-2}

read -p "Enter number of nodes (default: 1): " NUM_NODES
NUM_NODES=${NUM_NODES:-1}

echo ""
echo -e "${CYAN}Configuration Summary:${NC}"
echo -e "  Cluster name: ${CLUSTER_NAME}"
echo -e "  Zone: ${ZONE}"
echo -e "  Machine type: ${MACHINE_TYPE}"
echo -e "  Number of nodes: ${NUM_NODES}"
echo -e "  Estimated cost: ~\$75/month (1 node e2-standard-2)"
echo ""
echo -e "${YELLOW}Note: New Google Cloud users get \$300 free credits for 90 days${NC}"
echo ""

read -p "Create cluster with these settings? (y/N): " CONFIRM_CREATE
if [[ ! "$CONFIRM_CREATE" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

# Create GKE cluster
echo ""
echo -e "${BLUE}Creating GKE cluster...${NC}"
echo -e "${CYAN}This will take 5-10 minutes...${NC}"
echo ""

gcloud container clusters create "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --num-nodes="$NUM_NODES" \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3 \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=30 \
    --disk-type=pd-standard

echo -e "${GREEN}✓ GKE cluster created${NC}"

# Get cluster credentials
echo ""
echo -e "${YELLOW}Getting cluster credentials...${NC}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"
echo -e "${GREEN}✓ kubectl configured${NC}"

# Test connection
echo ""
echo -e "${YELLOW}Testing cluster connection...${NC}"
kubectl get nodes
echo -e "${GREEN}✓ Connected to cluster${NC}"

# Create namespace
echo ""
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace wander --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace 'wander' created${NC}"

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ GKE Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Cluster Information:${NC}"
echo -e "  Project: ${CURRENT_PROJECT}"
echo -e "  Cluster: ${CLUSTER_NAME}"
echo -e "  Zone: ${ZONE}"
echo -e "  Nodes: ${NUM_NODES} x ${MACHINE_TYPE}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo -e "1. Deploy application:"
echo -e "   ${CYAN}make gke-deploy${NC}"
echo ""
echo -e "2. Get service IPs:"
echo -e "   ${CYAN}kubectl get svc -n wander${NC}"
echo ""
echo -e "3. When done, delete cluster to stop charges:"
echo -e "   ${CYAN}make gke-teardown${NC}"
echo ""
echo -e "${YELLOW}⚠ Important: Remember to delete the cluster when you're done!${NC}"
echo -e "${YELLOW}   Estimated cost: ~\$75/month if left running${NC}"
echo ""
