# Deployment Guide

### Deployment Options Comparison

| Option | Complexity | Cost | Best For | Time to Deploy |
|--------|-----------|------|----------|----------------|
| **Local K8s (Minikube)** | Medium | Free | Learning K8s locally | 20 min |
| **Google GKE** | Medium | ~$75/month* | Production K8s, real cloud | 30 min |
| **Docker Compose** | Low | VPS cost | Simple production, small apps | 10 min |

*GKE offers $300 free credits for 90 days for new users

### Option 1: Local Kubernetes with Minikube (Recommended for Learning)

**What you get:**
- Full Kubernetes experience on your local machine
- Multi-service orchestration
- Practice with K8s concepts (pods, services, deployments)
- Health checks & rolling updates
- Production-like patterns without cloud costs

**Prerequisites:**
```bash
# Install Minikube
brew install minikube

# Install kubectl (if not already installed)
brew install kubectl
```

**Deploy:**
```bash
# 1. Start Minikube cluster
make k8s-setup

# 2. Deploy the application
make k8s-deploy

# 3. Access the services
kubectl get svc -n wander

# 4. Port forward to access locally
kubectl port-forward -n wander svc/wander-frontend 3000:3000
kubectl port-forward -n wander svc/wander-api 8000:8000
```

**Teardown:**
```bash
# Remove deployment
make k8s-teardown

# Stop Minikube
minikube stop

# Delete cluster (optional)
minikube delete
```

**Features demonstrated:**
- Kubernetes orchestration
- Service-to-service networking
- ConfigMaps and Secrets
- Health checks and readiness probes
- Rolling deployments
- Resource limits

**Cost:** Free (runs locally)

### Option 2: Google Kubernetes Engine (GKE) - Production Cloud

**What you get:**
- Fully managed Kubernetes in Google Cloud
- Production-grade infrastructure
- Auto-scaling, auto-repair, auto-upgrade
- Load balancing and SSL certificates
- Integrated monitoring and logging
- Real cloud experience

**Prerequisites:**
```bash
# Install Google Cloud SDK
brew install --cask google-cloud-sdk

# If Homebrew installation fails (Python issues), use manual installer:
./scripts/install-gcloud-manual.sh

# Install kubectl (if not already installed)
brew install kubectl

# Login to Google Cloud
gcloud auth login

# Set project (or create new one at console.cloud.google.com)
gcloud config set project YOUR_PROJECT_ID
```

**Important: Billing Setup Required**

GKE requires an active billing account. The setup script will check and guide you through enabling billing.

**New users get $300 free credits for 90 days!**

To set up billing:
1. Visit https://console.cloud.google.com/billing
2. Create a billing account (requires credit card - won't charge until credits expire)
3. Link billing account to your project
4. Continue with `make gke-setup`

**Note:** If you encounter Python version issues with Homebrew, the `gke-setup` script will automatically fall back to the official installer.

**Deploy:**
```bash
# 1. Check prerequisites (installs gcloud if needed)
make gke-prereqs

# 2. If gcloud was just installed, restart terminal or reload config:
# For Fish shell:
source ~/.config/fish/config.fish
# For Zsh:
source ~/.zshrc
# For Bash:
source ~/.bashrc

# 3. Login to Google Cloud (first time only)
gcloud auth login

# 4. Setup GKE cluster (creates cluster, ~10 min)
make gke-setup

# 5. Deploy application
make gke-deploy

# 6. Get external IP (may take 2-3 minutes to assign)
kubectl get svc -n wander

# 7. Access your app
# Frontend: http://<EXTERNAL-IP>:3000
# API: http://<EXTERNAL-IP>:8000
```

**Features demonstrated:**
- Real cloud Kubernetes
- Cloud Load Balancer
- Cloud SQL (PostgreSQL) or in-cluster database
- Persistent volumes
- External IP addresses
- Cloud monitoring

**Cost:**
- ~$75/month for small cluster (1 node e2-standard-2)
- **Free tier:** $300 credit for 90 days for new Google Cloud users
- Remember to delete cluster when done: `make gke-teardown`

**Teardown:**
```bash
# Delete everything to stop charges
make gke-teardown

# Or manually:
gcloud container clusters delete wander-cluster --zone us-central1-a
```

### Option 3: Docker Compose (Simplest Production)

**What you get:**
- Simple production deployment
- All services in one place
- Easy to understand
- Minimal setup

**Deploy to any VPS:**
```bash
# On your server (Ubuntu/Debian)
git clone <repo>
cd wander-dev-env

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in

# Configure environment
cp .env.example .env
# Edit .env with production secrets

# Start services
docker compose up -d

# Check health
docker ps
curl http://localhost:8000/health
```

**Cost:** VPS cost (~$5-20/month depending on provider)

**Providers:**
- DigitalOcean ($6/month droplet)
- Linode ($5/month instance)
- Vultr ($6/month instance)
- AWS Lightsail ($5/month instance)

### Option 4: Fly Machines (Simplest Cloud)

**What you get:**
- Auto-scaling
- Global deployment
- Automatic SSL
- Dead simple

**Deploy:**
```bash
# Install Fly CLI
brew install flyctl  # or: curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Deploy API
cd api
fly launch --name wander-api
fly deploy

# Deploy Frontend
cd ../frontend
fly launch --name wander-frontend
fly deploy

# Add Postgres
fly postgres create --name wander-db
fly postgres attach wander-db -a wander-api

# Add Redis
fly redis create --name wander-cache
fly redis attach wander-cache -a wander-api
```

**Cost:** ~$5/month with auto-scaling

**Advantages:**
- No container orchestration needed
- Automatic SSL certificates
- Global CDN
- Pay-per-use scaling

### Production Deployment Checklist

Before deploying to production, complete this checklist:

**Security:**
- [ ] Change all passwords in `.env` (use `openssl rand -base64 32`)
- [ ] Set `NODE_ENV=production`
- [ ] Enable HTTPS/SSL (Let's Encrypt, Cloudflare, or cloud provider)
- [ ] Configure CORS properly (don't use `*` in production)
- [ ] Set up rate limiting on API endpoints
- [ ] Remove debug ports from public access
- [ ] Review security headers (helmet.js)

**Data:**
- [ ] Set up automated database backups (daily minimum)
- [ ] Test backup restoration process
- [ ] Configure database replication (for high availability)
- [ ] Set up log rotation

**Monitoring:**
- [ ] Configure health check endpoints
- [ ] Set up uptime monitoring (UptimeRobot, Pingdom, etc.)
- [ ] Configure log aggregation (CloudWatch, Papertrail, etc.)
- [ ] Set up error tracking (Sentry, Rollbar, etc.)
- [ ] Configure alerts for downtime

**Performance:**
- [ ] Enable Redis caching
- [ ] Configure database connection pooling
- [ ] Set up CDN for static assets
- [ ] Enable gzip compression
- [ ] Optimize Docker images (multi-stage builds)

**Operational:**
- [ ] Document rollback procedure
- [ ] Test disaster recovery plan
- [ ] Set up CI/CD pipeline
- [ ] Configure staging environment
- [ ] Document deployment process

---

