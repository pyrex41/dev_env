#!/bin/bash
# Resume GKE Setup - Use this if cluster already exists
# This script finishes the setup without recreating the cluster

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║        Resume GKE Setup (Cluster Exists)                   ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Add gcloud to PATH
export PATH="$HOME/google-cloud-sdk/bin:/opt/homebrew/bin:$PATH"

# Get project
PROJECT=$(gcloud config get-value project 2>/dev/null)
CLUSTER_NAME="wander-cluster"
ZONE="us-central1-a"

echo -e "${CYAN}Project: ${PROJECT}${NC}"
echo -e "${CYAN}Cluster: ${CLUSTER_NAME}${NC}"
echo -e "${CYAN}Zone: ${ZONE}${NC}"
echo ""

# Get cluster credentials
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
echo -e "  Project: ${PROJECT}"
echo -e "  Cluster: ${CLUSTER_NAME}"
echo -e "  Zone: ${ZONE}"
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
