#!/bin/bash
# Fly Kubernetes (FKS) Setup Script
# Sets up everything needed for FKS deployment

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Fly Kubernetes Setup${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v flyctl &> /dev/null; then
    echo -e "${RED}✗ flyctl not installed${NC}"
    echo "Install: brew install flyctl"
    exit 1
fi
echo -e "${GREEN}✓ flyctl installed${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not installed${NC}"
    echo "Install: brew install kubectl"
    exit 1
fi
echo -e "${GREEN}✓ kubectl installed${NC}"

if ! command -v helm &> /dev/null; then
    echo -e "${RED}✗ helm not installed${NC}"
    echo "Install: brew install helm"
    exit 1
fi
echo -e "${GREEN}✓ helm installed${NC}"

# Check authentication
echo ""
echo -e "${YELLOW}Checking Fly.io authentication...${NC}"
if ! fly auth whoami &> /dev/null; then
    echo -e "${RED}✗ Not authenticated with Fly.io${NC}"
    echo "Run: fly auth login"
    exit 1
fi
FLY_ORG=$(fly auth whoami | grep "Organization" | awk '{print $2}')
echo -e "${GREEN}✓ Authenticated as: ${FLY_ORG}${NC}"

# Prompt for cluster name
echo ""
read -p "Enter FKS cluster name (or press Enter to skip creation): " CLUSTER_NAME

if [ -n "$CLUSTER_NAME" ]; then
    echo ""
    echo -e "${YELLOW}Creating FKS cluster: ${CLUSTER_NAME}${NC}"

    # Create cluster
    fly ext k8s create --name "$CLUSTER_NAME" --org "$FLY_ORG" --region ord

    # Save kubeconfig
    echo ""
    echo -e "${YELLOW}Saving kubeconfig...${NC}"
    fly ext k8s get "$CLUSTER_NAME" > kubeconfig-fks.yaml
    export KUBECONFIG="$(pwd)/kubeconfig-fks.yaml"
    echo -e "${GREEN}✓ Kubeconfig saved to kubeconfig-fks.yaml${NC}"
else
    echo -e "${BLUE}Skipping cluster creation${NC}"

    # Check if kubeconfig exists
    if [ ! -f "kubeconfig-fks.yaml" ]; then
        echo -e "${RED}✗ kubeconfig-fks.yaml not found${NC}"
        echo "Create cluster first or get existing kubeconfig"
        exit 1
    fi
    export KUBECONFIG="$(pwd)/kubeconfig-fks.yaml"
fi

# Set up WireGuard
echo ""
echo -e "${YELLOW}WireGuard Setup${NC}"
echo "FKS requires WireGuard connection to access cluster"
echo ""
echo "Options:"
echo "1. Use WireGuard app (recommended)"
echo "   - Download: https://www.wireguard.com/install/"
echo "   - Run: fly wireguard create"
echo "   - Import config to WireGuard app"
echo ""
echo "2. Use fly proxy"
echo "   - Run: fly proxy 6443:6443 -a <cluster-name>"
echo ""
read -p "Press Enter after WireGuard is connected..."

# Test connection
echo ""
echo -e "${YELLOW}Testing cluster connection...${NC}"
if kubectl get nodes &> /dev/null; then
    echo -e "${GREEN}✓ Connected to FKS cluster${NC}"
    kubectl get nodes
else
    echo -e "${RED}✗ Cannot connect to cluster${NC}"
    echo "Make sure WireGuard is active and try again"
    exit 1
fi

# Create namespace
echo ""
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace wander-fks --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"

# Set up external services
echo ""
echo -e "${YELLOW}External Services Setup${NC}"
echo ""
echo "You need to set up:"
echo "1. Fly Postgres: fly postgres create --name wander-postgres"
echo "2. Redis (Upstash): https://console.upstash.com/"
echo ""
read -p "Do you want to create Fly Postgres now? (y/N): " CREATE_POSTGRES

if [[ "$CREATE_POSTGRES" =~ ^[Yy]$ ]]; then
    fly postgres create --name wander-postgres --region ord
fi

# Prompt for connection strings
echo ""
echo -e "${YELLOW}Database Configuration${NC}"
read -p "Enter PostgreSQL connection string: " POSTGRES_URL
read -p "Enter Redis connection string: " REDIS_URL

# Create secrets
echo ""
echo -e "${YELLOW}Creating Kubernetes secrets...${NC}"
kubectl create secret generic postgres-credentials \
    --from-literal=connection-string="$POSTGRES_URL" \
    -n wander-fks \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic redis-credentials \
    --from-literal=url="$REDIS_URL" \
    -n wander-fks \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓ Secrets created${NC}"

# Authenticate with Fly registry
echo ""
echo -e "${YELLOW}Authenticating with Fly registry...${NC}"
fly auth docker
echo -e "${GREEN}✓ Docker authenticated${NC}"

# Update values file
echo ""
echo -e "${YELLOW}Updating values-fks.yaml...${NC}"
FLY_ORG_SLUG=$(echo "$FLY_ORG" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
sed -i.bak "s/CHANGE_ME/$FLY_ORG_SLUG/g" k8s/charts/wander/values-fks.yaml
rm k8s/charts/wander/values-fks.yaml.bak
sed -i.bak "s/CHANGE_ME/$FLY_ORG_SLUG/g" k8s/fks-migration-job.yaml
rm k8s/fks-migration-job.yaml.bak
echo -e "${GREEN}✓ Values updated${NC}"

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ FKS Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1. Build and push images:"
echo "   ${YELLOW}docker build -t registry.fly.io/$FLY_ORG_SLUG/wander-api:latest ./api${NC}"
echo "   ${YELLOW}docker push registry.fly.io/$FLY_ORG_SLUG/wander-api:latest${NC}"
echo "   ${YELLOW}docker build -t registry.fly.io/$FLY_ORG_SLUG/wander-frontend:latest ./frontend${NC}"
echo "   ${YELLOW}docker push registry.fly.io/$FLY_ORG_SLUG/wander-frontend:latest${NC}"
echo ""
echo "2. Deploy to FKS:"
echo "   ${YELLOW}make deploy-fks${NC}"
echo ""
echo "3. Get service URLs:"
echo "   ${YELLOW}kubectl get svc -n wander-fks${NC}"
echo ""
echo -e "${BLUE}Environment variables:${NC}"
echo "   export KUBECONFIG=$(pwd)/kubeconfig-fks.yaml"
echo ""
