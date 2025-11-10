# Deploy to Fly.io Kubernetes (FKS) - Production Demo

This guide demonstrates deploying the Wander application to Fly.io's Kubernetes service (FKS) as a production deployment example.

## Overview

**What This Demonstrates:**
- Production-ready Kubernetes deployment
- Multi-service orchestration (API, Frontend, PostgreSQL, Redis)
- Secret management with Kubernetes secrets
- Health checks and rolling updates
- External database services (Fly Postgres)
- Container registry (Fly Registry)

**Time Required:** ~30 minutes
**Cost:** ~$10-20/month (can be destroyed after demo)

---

## Prerequisites

1. **Fly.io Account**
   ```bash
   fly auth signup  # Create account
   fly auth login   # Login
   ```

2. **Install Required Tools**
   ```bash
   # macOS
   brew install flyctl kubectl helm

   # Linux
   curl -L https://fly.io/install.sh | sh
   # kubectl: https://kubernetes.io/docs/tasks/tools/
   # helm: https://helm.sh/docs/intro/install/
   ```

3. **WireGuard (Required for FKS)**
   - Download: https://www.wireguard.com/install/
   - FKS requires WireGuard VPN to access the cluster

---

## Quick Start (Automated)

### Option 1: One Command Deployment

```bash
make fly-deploy
```

This will:
1. Check prerequisites (flyctl, kubectl, helm)
2. Guide you through FKS cluster creation
3. Set up WireGuard connection
4. Create Fly Postgres database
5. Configure secrets
6. Build and push Docker images
7. Deploy with Helm
8. Verify deployment

### Option 2: Manual Step-by-Step

Follow the detailed steps below for more control.

---

## Detailed Deployment Steps

### Step 1: Create FKS Cluster

```bash
# Create a Kubernetes cluster on Fly.io
fly ext k8s create --name wander-prod-demo --region ord

# Save kubeconfig
fly ext k8s get wander-prod-demo > kubeconfig-fks.yaml
export KUBECONFIG=$(pwd)/kubeconfig-fks.yaml
```

**Regions available:**
- `ord` - Chicago
- `dfw` - Dallas
- `iad` - Virginia
- `sjc` - San Jose

### Step 2: Set Up WireGuard

FKS requires WireGuard for secure cluster access:

```bash
# Create WireGuard config
fly wireguard create personal wander wander-prod-demo

# This creates a config file - import it to WireGuard app
# Start WireGuard, then verify connection:
kubectl get nodes
```

Expected output:
```
NAME                  STATUS   ROLES    AGE   VERSION
fks-wander-prod-xyz   Ready    <none>   1m    v1.28.x
```

### Step 3: Create External Services

#### PostgreSQL Database

```bash
# Create Fly Postgres
fly postgres create \
  --name wander-postgres \
  --region ord \
  --initial-cluster-size 1 \
  --vm-size shared-cpu-1x \
  --volume-size 10

# Get connection string
fly postgres connect -a wander-postgres
# Note the connection string: postgres://username:password@host:5432/dbname
```

#### Redis Cache

**Option A: Upstash Redis (Recommended - Free tier)**
1. Go to https://console.upstash.com/
2. Create new Redis database
3. Select region closest to Fly.io region
4. Get connection string (format: `redis://...`)

**Option B: Fly Redis**
```bash
fly redis create --name wander-redis --region ord
fly redis status wander-redis  # Get connection info
```

### Step 4: Configure Kubernetes Secrets

```bash
# Create namespace
kubectl create namespace wander-prod

# PostgreSQL credentials
kubectl create secret generic postgres-credentials \
  --from-literal=connection-string="postgresql://user:pass@host:5432/db" \
  -n wander-prod

# Redis credentials
kubectl create secret generic redis-credentials \
  --from-literal=url="redis://default:pass@host:6379" \
  -n wander-prod

# API secrets
kubectl create secret generic api-secrets \
  --from-literal=api-secret="your-api-secret-key" \
  --from-literal=jwt-secret="your-jwt-secret-key" \
  -n wander-prod
```

### Step 5: Build and Push Docker Images

```bash
# Authenticate with Fly registry
fly auth docker

# Get your Fly org name
FLY_ORG=$(fly auth whoami | grep "Organization" | awk '{print $2}' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Build and push API
docker build -t registry.fly.io/$FLY_ORG/wander-api:latest \
  --target production \
  ./api
docker push registry.fly.io/$FLY_ORG/wander-api:latest

# Build and push Frontend
docker build -t registry.fly.io/$FLY_ORG/wander-frontend:latest \
  --target production \
  ./frontend
docker push registry.fly.io/$FLY_ORG/wander-frontend:latest
```

### Step 6: Deploy with Helm

```bash
# Update values file with your org name
cd k8s/charts/wander
cp values-fks.yaml values-fks-custom.yaml
# Edit values-fks-custom.yaml and replace CHANGE_ME with your org name

# Deploy
helm upgrade --install wander . \
  -f values-fks-custom.yaml \
  -n wander-prod \
  --create-namespace

# Watch deployment
kubectl get pods -n wander-prod -w
```

### Step 7: Run Database Migrations

```bash
# Apply migration job
kubectl apply -f k8s/fks-migration-job.yaml -n wander-prod

# Watch migration
kubectl logs -f job/wander-migration -n wander-prod
```

### Step 8: Verify Deployment

```bash
# Check all resources
kubectl get all -n wander-prod

# Check service endpoints
kubectl get svc -n wander-prod

# Check pod health
kubectl get pods -n wander-prod

# View logs
kubectl logs -l app=wander-api -n wander-prod
kubectl logs -l app=wander-frontend -n wander-prod
```

### Step 9: Access Application

FKS services are internal by default. To access:

**Option A: Port Forward (Quick Test)**
```bash
# Forward frontend
kubectl port-forward svc/wander-frontend 3000:3000 -n wander-prod

# Access at http://localhost:3000
```

**Option B: Fly Proxy (Recommended)**
```bash
# Create Fly app as proxy
fly apps create wander-proxy

# Deploy proxy
fly deploy --config fly-proxy.toml

# Access at https://wander-proxy.fly.dev
```

**Option C: LoadBalancer Service (Production)**
```yaml
# Edit values-fks-custom.yaml
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/fly-load-balancer: "true"
```

---

## Monitoring & Management

### View Logs

```bash
# All logs
kubectl logs -l app=wander-api -n wander-prod --tail=100 -f

# Specific pod
kubectl logs wander-api-xyz123 -n wander-prod
```

### Check Health

```bash
# Pod status
kubectl get pods -n wander-prod

# Service health
kubectl port-forward svc/wander-api 8000:8000 -n wander-prod
curl http://localhost:8000/health
```

### Scale Services

```bash
# Scale API replicas
kubectl scale deployment wander-api --replicas=3 -n wander-prod

# Scale frontend
kubectl scale deployment wander-frontend --replicas=2 -n wander-prod
```

### Update Deployment

```bash
# Build new image
docker build -t registry.fly.io/$FLY_ORG/wander-api:v2 ./api
docker push registry.fly.io/$FLY_ORG/wander-api:v2

# Update deployment
kubectl set image deployment/wander-api \
  api=registry.fly.io/$FLY_ORG/wander-api:v2 \
  -n wander-prod

# Watch rolling update
kubectl rollout status deployment/wander-api -n wander-prod
```

---

## Cleanup

### Destroy Everything

```bash
# Delete Kubernetes resources
helm uninstall wander -n wander-prod
kubectl delete namespace wander-prod

# Delete external services
fly postgres destroy wander-postgres
fly redis destroy wander-redis  # If using Fly Redis

# Delete FKS cluster
fly ext k8s delete wander-prod-demo

# Remove kubeconfig
rm kubeconfig-fks.yaml
```

**Cost:** Stopping all services = $0/month (only storage charges for volumes)

---

## Troubleshooting

### Can't Connect to Cluster

```bash
# Verify WireGuard is running
# Check connection
kubectl get nodes

# If fails, restart WireGuard and try again
```

### Pod CrashLoopBackOff

```bash
# Check logs
kubectl logs pod-name -n wander-prod

# Common issues:
# 1. Database connection string wrong → Check secrets
# 2. Migrations failed → Check migration job logs
# 3. Image pull error → Verify registry authentication
```

### Database Connection Failed

```bash
# Test connection from pod
kubectl run -it --rm debug --image=postgres:16 --restart=Never -n wander-prod -- \
  psql "postgresql://user:pass@host:5432/db"

# Check secret
kubectl get secret postgres-credentials -n wander-prod -o yaml
```

### Image Pull Errors

```bash
# Re-authenticate
fly auth docker

# Verify image exists
fly registry show
```

---

## Cost Breakdown

**FKS Cluster:**
- 1 node (shared-cpu-1x): ~$7/month
- Persistent volumes (10GB): ~$1/month

**External Services:**
- Fly Postgres (shared-cpu-1x): ~$7/month
- Upstash Redis (free tier): $0

**Total:** ~$15-20/month

**Demo Mode:** Destroy after demo = ~$0.50 for a few hours

---

## Production Considerations

This is a **demo deployment**. For actual production:

1. **High Availability**
   - Multiple replicas (3+)
   - Spread across regions
   - PostgreSQL HA cluster

2. **Security**
   - External Secrets Operator
   - Network policies
   - RBAC configuration
   - TLS/SSL certificates

3. **Monitoring**
   - Prometheus + Grafana
   - Log aggregation (ELK/Loki)
   - Alerting (PagerDuty, OpsGenie)

4. **Backups**
   - Automated database backups
   - Disaster recovery plan
   - Point-in-time recovery

5. **CI/CD**
   - GitHub Actions for builds
   - Automated testing
   - GitOps (ArgoCD, Flux)

---

## Alternative: Fly Machines (Simpler)

If Kubernetes is overkill, consider **Fly Machines** for simpler production:

```bash
# Deploy API
fly launch --name wander-api --region ord --config fly-api.toml

# Deploy Frontend
fly launch --name wander-frontend --region ord --config fly-frontend.toml

# Much simpler, ~$5/month, auto-scaling
```

See `fly.toml` examples in the repository.

---

## Summary

**What We Demonstrated:**
✅ Production Kubernetes deployment on Fly.io
✅ Multi-service orchestration
✅ External database services
✅ Secret management
✅ Container registry
✅ Health checks and rolling updates
✅ Scaling and monitoring

**Time:** 30 minutes
**Cost:** ~$15/month (or ~$0.50 for demo)
**Complexity:** Medium (Kubernetes knowledge required)

**Next Steps:**
- Try the simpler Fly Machines deployment
- Add monitoring (Prometheus/Grafana)
- Set up CI/CD pipeline
- Implement backup strategy
