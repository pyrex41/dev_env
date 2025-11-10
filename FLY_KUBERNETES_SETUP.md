# Fly.io Kubernetes (FKS) Deployment Guide

Deploy your Wander Helm charts to Fly.io's managed Kubernetes service.

## ⚠️ Important Notes

- **FKS is in BETA** - Not recommended for critical production
- **Costs Money** - Check Fly.io pricing before deploying
- **WireGuard Required** - Must set up VPN to access cluster
- **Limitations**: No multi-container pods (yet), no HPA, limited features

## Prerequisites

```bash
# Install flyctl if not already installed
brew install flyctl

# Authenticate
fly auth login

# Verify you're logged in
fly auth whoami
```

## Step 1: Create FKS Cluster

```bash
# Create cluster (interactive prompts)
fly ext k8s create

# You'll be asked for:
# - Cluster name (e.g., "wander-fks")
# - Organization (your Fly.io org)
# - Region (e.g., "ord" for Chicago, "iad" for Virginia)
```

**Estimated time**: 5-10 minutes for cluster provisioning

## Step 2: Save Kubeconfig

After cluster creation, save the kubeconfig output:

```bash
# Save to file
fly ext k8s create > kubeconfig-fks.yaml

# Or if cluster already exists, get config:
fly ext k8s get <cluster-name> > kubeconfig-fks.yaml

# Set environment variable
export KUBECONFIG=$(pwd)/kubeconfig-fks.yaml

# Verify connection (will fail until WireGuard is set up)
kubectl get nodes
```

## Step 3: Set Up WireGuard VPN

FKS clusters are accessible only over your organization's private network.

### Option A: Permanent WireGuard Connection (Recommended)

```bash
# Create WireGuard configuration
fly wireguard create

# Follow prompts to create a peer
# Save the configuration file (e.g., fly-wg.conf)

# On macOS, use WireGuard app:
# 1. Download from https://www.wireguard.com/install/
# 2. Import the fly-wg.conf file
# 3. Activate the tunnel
```

### Option B: Fly Proxy (Alternative)

```bash
# Start proxy in background
fly proxy 6443:6443 -a <cluster-name>

# In kubeconfig, change server URL to:
# server: https://localhost:6443
```

## Step 4: Verify Connection

```bash
# Should work now (with WireGuard active)
kubectl get nodes

# Should see FKS nodes
kubectl get namespaces
```

## Step 5: Prepare Helm Chart for FKS

### Known FKS Limitations

Our Helm chart needs modifications for FKS compatibility:

1. ❌ **Multi-container pods** - Not supported yet
   - Our API pod has init containers for migrations
   - Need to remove or modify

2. ❌ **Horizontal Pod Autoscaling** - Not supported
   - Remove HPA from production values

3. ❌ **Network Policies** - Not supported
   - Remove if using them

4. ❌ **Some probe configurations** - Limited support
   - Simplify health checks

### Create FKS-Specific Values

Create `k8s/charts/wander/values-fks.yaml`:

```yaml
# Fly Kubernetes Configuration
# Beta limitations applied

## API Configuration
api:
  replicaCount: 2  # No autoscaling on FKS

  image:
    repository: registry.fly.io/<your-org>/wander-api
    tag: latest
    pullPolicy: Always

  service:
    type: LoadBalancer  # FKS supports LoadBalancer
    port: 8000

  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

  env:
    NODE_ENV: production
    API_PORT: "8000"

## Frontend Configuration
frontend:
  replicaCount: 2

  image:
    repository: registry.fly.io/<your-org>/wander-frontend
    tag: latest
    pullPolicy: Always

  service:
    type: LoadBalancer
    port: 3000

  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"

  env:
    NODE_ENV: production

## PostgreSQL - Use Fly Postgres instead
postgresql:
  enabled: false  # Use Fly Postgres instead

## Redis - Use Upstash or Fly Redis
redis:
  enabled: false  # Use external Redis

## Ingress
ingress:
  enabled: false  # Use LoadBalancer services

## Autoscaling
autoscaling:
  enabled: false  # Not supported on FKS

## Service Account
serviceAccount:
  create: true
  name: wander-fks
```

## Step 6: Set Up External Services

### PostgreSQL (Fly Postgres)

```bash
# Create Fly Postgres app
fly postgres create --name wander-postgres --region ord

# Get connection string
fly postgres connect -a wander-postgres

# Save credentials for Kubernetes secret
```

### Redis (Upstash recommended)

```bash
# Create Upstash Redis (free tier available)
# Visit: https://console.upstash.com/

# Or use Fly Redis (when available)
```

### Create Kubernetes Secrets

```bash
# Create namespace
kubectl create namespace wander-fks

# Create PostgreSQL secret
kubectl create secret generic postgres-credentials \
  --from-literal=connection-string='postgresql://...' \
  -n wander-fks

# Create Redis secret
kubectl create secret generic redis-credentials \
  --from-literal=url='redis://...' \
  -n wander-fks
```

## Step 7: Build and Push Images

### Set Up Fly Registry

```bash
# Authenticate with Fly registry
fly auth docker

# Build and push API
docker build -t registry.fly.io/<your-org>/wander-api:latest ./api
docker push registry.fly.io/<your-org>/wander-api:latest

# Build and push Frontend
docker build -t registry.fly.io/<your-org>/wander-frontend:latest ./frontend
docker push registry.fly.io/<your-org>/wander-frontend:latest
```

## Step 8: Deploy with Helm

```bash
# Deploy to FKS
helm upgrade --install wander ./k8s/charts/wander \
  --namespace wander-fks \
  --create-namespace \
  --values ./k8s/charts/wander/values-fks.yaml \
  --wait \
  --timeout 10m

# Watch deployment
kubectl get pods -n wander-fks -w
```

## Step 9: Access Your Application

### Get Service IPs

```bash
# Get LoadBalancer IPs
kubectl get svc -n wander-fks

# Example output:
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP
# wander-frontend   LoadBalancer   10.x.x.x        fly.dev-assigned-ip
# wander-api        LoadBalancer   10.x.x.x        fly.dev-assigned-ip
```

### Access Services

FKS LoadBalancers get Fly.io IPs that are publicly accessible:

```bash
# Frontend
curl http://<frontend-external-ip>:3000

# API
curl http://<api-external-ip>:8000/health
```

## Useful Commands

### View Resources

```bash
# All resources
kubectl get all -n wander-fks

# Pods with details
kubectl get pods -n wander-fks -o wide

# Services with IPs
kubectl get svc -n wander-fks

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n wander-fks
```

### View Logs

```bash
# API logs (all pods in namespace due to FKS limitation)
kubectl logs -l app=wander-api -n wander-fks

# Frontend logs
kubectl logs -l app=wander-frontend -n wander-fks

# Follow logs
kubectl logs -f -l app=wander-api -n wander-fks
```

### Update Deployment

```bash
# Rebuild and push new images
docker build -t registry.fly.io/<your-org>/wander-api:latest ./api
docker push registry.fly.io/<your-org>/wander-api:latest

# Update Helm deployment
helm upgrade wander ./k8s/charts/wander \
  --namespace wander-fks \
  --values ./k8s/charts/wander/values-fks.yaml \
  --reuse-values

# Or force pod restart
kubectl rollout restart deployment/wander-api -n wander-fks
```

### Cleanup

```bash
# Delete Helm release
helm uninstall wander -n wander-fks

# Delete namespace
kubectl delete namespace wander-fks

# Delete FKS cluster (when done testing)
fly ext k8s destroy <cluster-name>
```

## Troubleshooting

### Can't Connect to Cluster

```bash
# Verify WireGuard is active
# Check WireGuard app on macOS

# Or test with fly proxy
fly proxy 6443:6443 -a <cluster-name>

# Verify kubeconfig
echo $KUBECONFIG
kubectl config current-context
```

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n wander-fks

# Common issues:
# - Image pull errors (check registry auth)
# - Resource limits too low
# - Missing secrets
# - Init containers failing (not supported on FKS)
```

### Image Pull Errors

```bash
# Re-authenticate with Fly registry
fly auth docker

# Verify images exist
fly registry list

# Check image pull secrets
kubectl get secrets -n wander-fks
```

## FKS Limitations Workarounds

### 1. No Multi-Container Pods (Init Containers)

**Problem**: Our migrations run in init containers

**Solution**: Run migrations as a separate Job before deployment

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: wander-migrations
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: registry.fly.io/<your-org>/wander-api:latest
        command: ["pnpm", "run", "migrate"]
      restartPolicy: OnFailure
```

Run before main deployment:
```bash
kubectl apply -f migrations-job.yaml -n wander-fks
kubectl wait --for=condition=complete job/wander-migrations -n wander-fks
```

### 2. No Horizontal Pod Autoscaling

**Problem**: Can't auto-scale based on metrics

**Solution**: Use fixed replica counts, scale manually:

```bash
# Scale API
kubectl scale deployment wander-api --replicas=5 -n wander-fks

# Scale frontend
kubectl scale deployment wander-frontend --replicas=3 -n wander-fks
```

### 3. Limited Health Checks

**Problem**: Some probe configurations not supported

**Solution**: Simplify to basic HTTP checks:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
readinessProbe:
  httpGet:
    path: /health
    port: 8000
```

## Cost Estimation

FKS pricing (check Fly.io for current rates):
- Cluster base cost: ~$X/month
- Per-node cost: ~$Y/month
- Traffic: $Z per GB

**Recommended for demos**: Create cluster → test → destroy after demo

## Alternative: Fly.io Apps (Non-Kubernetes)

If FKS limitations are too restrictive, consider using Fly Apps instead:
- Full feature support
- Multi-container apps
- Better pricing for small apps
- Simpler deployment (fly.toml)

See: https://fly.io/docs/apps/

## Summary

**To deploy to FKS:**

1. `fly ext k8s create` - Create cluster
2. Set up WireGuard VPN
3. `export KUBECONFIG=./kubeconfig-fks.yaml`
4. Create external Postgres + Redis
5. Build and push images to Fly registry
6. `helm install` with values-fks.yaml
7. Access via LoadBalancer IPs

**Estimated time**: 30-45 minutes for first deployment

**Cost**: Check Fly.io pricing, destroy cluster after testing

**Best for**: Demonstrating Kubernetes deployment on Fly.io platform
