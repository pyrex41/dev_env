# Local Kubernetes Testing Guide

Test your Kubernetes/Helm deployment locally using Minikube - **completely free, no cloud costs!**

## Quick Start (2 Commands)

```bash
# 1. Set up Minikube and build images
make k8s-local-setup

# 2. Deploy to local cluster
make deploy-local
```

That's it! Your Helm chart is now running in a local Kubernetes cluster.

---

## What You Get

### Automated Setup (`make k8s-local-setup`)
1. ✅ Installs Minikube and kubectl (if needed)
2. ✅ Starts Minikube with 4 CPUs, 8GB RAM, 40GB disk
3. ✅ Builds Docker images for local use
4. ✅ Configures everything automatically

**Time**: ~5-10 minutes first time, ~2 minutes after that

### Automated Deployment (`make deploy-local`)
1. ✅ Validates Minikube is running
2. ✅ Deploys using `values-local.yaml` (optimized for local testing)
3. ✅ Installs PostgreSQL and Redis via Bitnami charts
4. ✅ Deploys API and Frontend with proper dependencies
5. ✅ Waits for all pods to be ready
6. ✅ Shows you how to access services

**Time**: ~3-5 minutes (downloading Bitnami charts first time)

---

## Accessing Your Services

After `make deploy-local` completes, get service URLs:

```bash
# Frontend
minikube service wander-local-frontend -n wander-local --url

# API
minikube service wander-local-api -n wander-local --url
```

Or open directly in browser:
```bash
# Frontend (opens in browser)
minikube service wander-local-frontend -n wander-local

# API (opens in browser)
minikube service wander-local-api -n wander-local
```

---

## Useful Commands

### View Deployment Status
```bash
# See all pods
kubectl get pods -n wander-local

# Watch pods starting up
kubectl get pods -n wander-local -w

# See all services
kubectl get svc -n wander-local

# See everything
kubectl get all -n wander-local
```

### View Logs
```bash
# API logs (follow)
kubectl logs -f -n wander-local -l app=wander-api

# Frontend logs (follow)
kubectl logs -f -n wander-local -l app=wander-frontend

# PostgreSQL logs
kubectl logs -f -n wander-local -l app.kubernetes.io/name=postgresql

# Redis logs
kubectl logs -f -n wander-local -l app.kubernetes.io/name=redis
```

### Debug Issues
```bash
# Describe a pod (shows events, issues)
kubectl describe pod <pod-name> -n wander-local

# Get pod details (shows image pulls, restarts)
kubectl get pod <pod-name> -n wander-local -o yaml

# Execute shell in API pod
kubectl exec -it -n wander-local deployment/wander-local-api -- sh

# Execute shell in Frontend pod
kubectl exec -it -n wander-local deployment/wander-local-frontend -- sh
```

### Test Database Connection
```bash
# Connect to PostgreSQL
kubectl exec -it -n wander-local deployment/wander-local-postgresql -- psql -U wander -d wander_dev

# Connect to Redis
kubectl exec -it -n wander-local deployment/wander-local-redis-master -- redis-cli
```

---

## Cleanup

### Remove Deployment (Keep Minikube Running)
```bash
helm uninstall wander-local -n wander-local
```

### Stop Minikube (Free Up Resources)
```bash
minikube stop
```

### Delete Minikube Cluster (Full Cleanup)
```bash
minikube delete
```

---

## Rebuilding After Code Changes

If you make changes to your code:

```bash
# 1. Stop current deployment
helm uninstall wander-local -n wander-local

# 2. Rebuild images
eval $(minikube docker-env)
docker build -t wander-api:local ./api
docker build -t wander-frontend:local ./frontend

# 3. Redeploy
make deploy-local
```

Or use the shortcut:
```bash
# All-in-one: rebuild and redeploy
make k8s-local-setup && make deploy-local
```

---

## Troubleshooting

### Minikube Won't Start
```bash
# Delete and recreate
minikube delete
minikube start --cpus=4 --memory=8192 --disk-size=40g
```

### Pods Stuck in "ImagePullBackOff"
```bash
# Rebuild images in Minikube's Docker daemon
eval $(minikube docker-env)
docker build -t wander-api:local ./api
docker build -t wander-frontend:local ./frontend

# Restart deployment
kubectl rollout restart deployment/wander-local-api -n wander-local
kubectl rollout restart deployment/wander-local-frontend -n wander-local
```

### Pods Stuck in "Pending"
```bash
# Check if Minikube has enough resources
minikube status
kubectl describe pod <pod-name> -n wander-local

# May need to increase Minikube resources:
minikube delete
minikube start --cpus=4 --memory=10240 --disk-size=50g
```

### Can't Access Services
```bash
# Check if services are running
kubectl get svc -n wander-local

# Check if pods are ready
kubectl get pods -n wander-local

# Get service URL directly
minikube service wander-local-frontend -n wander-local --url
```

### Database Connection Errors
```bash
# Check PostgreSQL is running
kubectl get pods -n wander-local -l app.kubernetes.io/name=postgresql

# Check Redis is running
kubectl get pods -n wander-local -l app.kubernetes.io/name=redis

# View logs
kubectl logs -n wander-local -l app.kubernetes.io/name=postgresql
kubectl logs -n wander-local -l app.kubernetes.io/name=redis
```

---

## What's Different from Docker Compose?

| Feature | Docker Compose | Minikube |
|---------|---------------|----------|
| **Setup** | `make dev` | `make k8s-local-setup` → `make deploy-local` |
| **Access** | localhost:3000 | `minikube service` command |
| **Logs** | `make logs` | `kubectl logs` |
| **Shell** | `make shell-api` | `kubectl exec` |
| **Database** | `make shell-db` | `kubectl exec` |
| **Stop** | `make down` | `helm uninstall` or `minikube stop` |
| **Production-like** | No | Yes (uses same Helm charts) |
| **Resource usage** | Lower | Higher (full K8s stack) |

---

## Why Test with Minikube?

### ✅ Pros
- **Free**: No cloud costs
- **Production-like**: Tests actual Helm charts you'll use in production
- **Complete**: Full Kubernetes features (pods, services, deployments, etc.)
- **Validates charts**: Catches Helm template errors before deploying to real cluster
- **Learning**: Understand how your app runs in Kubernetes
- **Dependency management**: Tests service dependencies and health checks

### ⚠️ Cons
- **Slower startup**: Takes 5-10 minutes vs 2 minutes for Docker Compose
- **More resources**: Uses ~4GB RAM (Minikube overhead)
- **More complex**: Need to learn kubectl commands
- **Not for daily dev**: Use Docker Compose (`make dev`) for normal development

---

## Recommended Workflow

1. **Daily Development**: Use `make dev` (Docker Compose)
   - Fast startup
   - Hot reload works
   - Easy to debug

2. **Before Deployment**: Use `make deploy-local` (Minikube)
   - Validate Helm charts
   - Test in Kubernetes environment
   - Catch configuration issues
   - Verify resource limits work

3. **Production**: Deploy to real cluster (Fly.io, AWS, GCP, etc.)
   - Use `values-staging.yaml` or `values-prod.yaml`
   - Same Helm charts, different values

---

## Next Steps After Local Testing

Once you've verified your Helm chart works locally:

### Option 1: Deploy to Fly.io
Fly.io doesn't use Kubernetes, but you could:
- Export your app as Docker images
- Deploy using Fly.io's `fly.toml` configuration
- Keep Helm charts for future cloud deployment

### Option 2: Deploy to Cloud Kubernetes
Your Helm chart is ready for:
- **GKE** (Google Kubernetes Engine) - ~$75/month for small cluster
- **EKS** (AWS Elastic Kubernetes Service) - ~$75/month
- **AKS** (Azure Kubernetes Service) - ~$75/month
- **DigitalOcean Kubernetes** - ~$40/month for small cluster

### Option 3: Stick with Docker Compose
If you don't need Kubernetes features:
- Keep using `make dev` for development
- Deploy Docker Compose to a VPS
- Much simpler and cheaper

---

## Files Created for Local Testing

- `k8s/charts/wander/values-local.yaml` - Local configuration
  - NodePort services (no LoadBalancer)
  - Smaller resource limits
  - No replicas
  - Local image tags

- `Makefile` additions:
  - `make k8s-local-setup` - One-command setup
  - `make deploy-local` - One-command deploy

---

## Summary

**To test your Kubernetes/Helm setup locally:**

```bash
# Setup (first time only, ~10 minutes)
make k8s-local-setup

# Deploy (~5 minutes)
make deploy-local

# Access services
minikube service wander-local-frontend -n wander-local
minikube service wander-local-api -n wander-local

# When done
minikube stop
```

**Cost**: $0 (completely free!)

**Result**: Confidence that your Helm charts work before deploying to production! 🚀
