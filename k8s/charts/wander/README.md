# Wander Helm Chart

Helm chart for deploying the Wander application stack to Kubernetes.

## Overview

This Helm chart deploys a complete Wander application environment including:
- **Frontend**: React/Vite application (nginx-served static files)
- **API**: Node.js/Express backend with TypeScript
- **PostgreSQL**: Primary database (via Bitnami chart)
- **Redis**: Caching and session storage (via Bitnami chart)

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- PV provisioner support in the underlying infrastructure (for persistence)
- Ingress controller (if ingress is enabled)
- cert-manager (for TLS certificate management, optional)

## Installation

### Development/Local Installation

```bash
# Install with default values (development mode)
helm install wander ./k8s/charts/wander

# Or with custom values
helm install wander ./k8s/charts/wander \
  --set api.image.tag=latest \
  --set frontend.image.tag=latest
```

### Staging Installation

```bash
# Install staging environment
helm install wander-staging ./k8s/charts/wander \
  -f ./k8s/charts/wander/values-staging.yaml \
  --set secrets.postgresql.password=SECURE_PASSWORD_HERE \
  --set secrets.redis.password=SECURE_PASSWORD_HERE \
  --set secrets.api.JWT_SECRET=SECURE_JWT_SECRET_HERE \
  --set secrets.api.SESSION_SECRET=SECURE_SESSION_SECRET_HERE \
  --namespace wander-staging \
  --create-namespace
```

### Production Installation

```bash
# IMPORTANT: Use external secret management in production!
# This example uses --set for demonstration only

helm install wander-prod ./k8s/charts/wander \
  -f ./k8s/charts/wander/values-prod.yaml \
  --set secrets.postgresql.password=SECURE_PASSWORD_HERE \
  --set secrets.redis.password=SECURE_PASSWORD_HERE \
  --set secrets.api.JWT_SECRET=SECURE_JWT_SECRET_HERE \
  --set secrets.api.SESSION_SECRET=SECURE_SESSION_SECRET_HERE \
  --namespace wander-prod \
  --create-namespace
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.environment` | Environment name | `development` |
| `global.domain` | Application domain | `wander.local` |
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.replicaCount` | Number of frontend replicas | `2` |
| `frontend.image.repository` | Frontend image repository | `wander-frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `api.enabled` | Enable API deployment | `true` |
| `api.replicaCount` | Number of API replicas | `2` |
| `api.image.repository` | API image repository | `wander-api` |
| `api.image.tag` | API image tag | `latest` |
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `redis.enabled` | Enable Redis | `true` |

### Secret Management

**CRITICAL**: Never commit secrets to version control!

#### Option 1: External Secrets Operator (Recommended for Production)

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets

# Create SecretStore pointing to your secrets backend (AWS, GCP, Vault, etc.)
# See: https://external-secrets.io/latest/
```

#### Option 2: Sealed Secrets

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Encrypt secrets and commit to repo
kubeseal -f secrets.yaml -w sealed-secrets.yaml
```

#### Option 3: HashiCorp Vault

```bash
# Install Vault Secrets Operator
# See: https://developer.hashicorp.com/vault/docs/platform/k8s
```

#### Option 4: Helm --set (Development Only)

```bash
# NOT RECOMMENDED for production
helm install wander ./k8s/charts/wander \
  --set secrets.api.JWT_SECRET="dev-secret-123"
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade wander ./k8s/charts/wander \
  -f ./k8s/charts/wander/values-prod.yaml

# Rollback if needed
helm rollback wander
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall wander

# Note: PVCs are not automatically deleted
# Delete manually if needed:
kubectl delete pvc -l app.kubernetes.io/instance=wander
```

## Testing the Chart

```bash
# Dry-run to validate templates
helm install wander ./k8s/charts/wander --dry-run --debug

# Template rendering (without installation)
helm template wander ./k8s/charts/wander

# With specific values file
helm template wander ./k8s/charts/wander \
  -f ./k8s/charts/wander/values-staging.yaml

# Lint the chart
helm lint ./k8s/charts/wander
```

## Architecture

### Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Ingress                             │
│  (nginx-ingress with TLS from cert-manager)                 │
└─────────────────────────────────────────────────────────────┘
                           │
                           ├─────────────────┬─────────────────┐
                           │                 │                 │
                    ┌──────▼──────┐   ┌─────▼──────┐         │
                    │  Frontend   │   │    API     │         │
                    │  Service    │   │  Service   │         │
                    └──────┬──────┘   └─────┬──────┘         │
                           │                 │                 │
                    ┌──────▼──────┐   ┌─────▼──────┐         │
                    │  Frontend   │   │    API     │         │
                    │ Deployment  │   │ Deployment │         │
                    │ (2-3 pods)  │   │ (2-3 pods) │         │
                    └─────────────┘   └─────┬──────┘         │
                                            │                 │
                              ┌─────────────┴──────┬──────────┘
                              │                    │
                       ┌──────▼──────┐      ┌─────▼──────┐
                       │ PostgreSQL  │      │   Redis    │
                       │  Service    │      │  Service   │
                       └──────┬──────┘      └─────┬──────┘
                              │                    │
                       ┌──────▼──────┐      ┌─────▼──────┐
                       │ PostgreSQL  │      │   Redis    │
                       │ StatefulSet │      │ StatefulSet│
                       │   + PVC     │      │   + PVC    │
                       └─────────────┘      └────────────┘
```

### Network Policies

The chart creates ClusterIP services for internal communication:
- Frontend: Port 80 → Container 3000
- API: Port 8000 → Container 8000
- PostgreSQL: Port 5432 (via Bitnami chart)
- Redis: Port 6379 (via Bitnami chart)

### Health Checks

API pods include:
- **Liveness probe**: `/health` endpoint (ensures pod is alive)
- **Readiness probe**: `/health` endpoint (ensures pod is ready for traffic)

## Resource Requirements

### Development
- Frontend: 100m CPU, 128Mi RAM
- API: 200m CPU, 256Mi RAM
- PostgreSQL: 250m CPU, 256Mi RAM
- Redis: 100m CPU, 128Mi RAM

### Production
- Frontend: 250m CPU, 256Mi RAM (scales to 20 pods)
- API: 500m CPU, 512Mi RAM (scales to 20 pods)
- PostgreSQL: 1000m CPU, 2Gi RAM
- Redis: 500m CPU, 1Gi RAM (with 2 replicas)

## Autoscaling

Horizontal Pod Autoscaling (HPA) is available for API and frontend:

**Staging**: Disabled by default
**Production**: Enabled (3-20 pods, target 70% CPU)

```yaml
api:
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20
    targetCPUUtilizationPercentage: 70
```

## Monitoring

### Prometheus Metrics

The chart includes annotations for Prometheus scraping:

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=wander
kubectl logs -l app.kubernetes.io/component=api
kubectl describe pod <pod-name>
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
kubectl get pods -l app.kubernetes.io/name=postgresql

# Test database connection from API pod
kubectl exec -it <api-pod-name> -- psql $DATABASE_URL -c "SELECT 1"
```

### Redis Connection Issues

```bash
# Check Redis is running
kubectl get pods -l app.kubernetes.io/name=redis

# Test Redis connection from API pod
kubectl exec -it <api-pod-name> -- redis-cli -u $REDIS_URL ping
```

### View Secrets

```bash
# List secrets
kubectl get secrets -l app.kubernetes.io/name=wander

# Decode secret (development only!)
kubectl get secret wander-api-secrets -o jsonpath='{.data.JWT_SECRET}' | base64 -d
```

## Dependencies

This chart depends on:

- **postgresql** (Bitnami): v12.x.x
- **redis** (Bitnami): v17.x.x

Update dependencies:

```bash
helm dependency update ./k8s/charts/wander
```

## Security Considerations

1. **Never commit secrets** to version control
2. Use **external secret management** in production (External Secrets, Vault, etc.)
3. Enable **TLS/HTTPS** via ingress and cert-manager
4. Use **specific image tags** in production (not `latest`)
5. Enable **Pod Security Standards** in your cluster
6. Configure **network policies** to restrict pod-to-pod communication
7. Use **RBAC** to limit service account permissions
8. Enable **audit logging** in Kubernetes

## Contributing

When modifying this chart:

1. Update `Chart.yaml` version following semver
2. Test with `helm lint` and `helm template`
3. Update this README with any new configuration options
4. Test installation in a development cluster
5. Document any breaking changes

## Support

For issues and questions:
- GitHub Issues: [repository-url]/issues
- Documentation: [docs-url]

## License

[Your License Here]
