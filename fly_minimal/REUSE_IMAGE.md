# Reusing the Base Image Across Apps

After deploying `dev-env-minimal` once, the image is stored in Fly's registry and can be reused for other apps in your organization.

## Get Image Reference

### Option 1: From recent releases
```bash
# View image references
fly releases -a dev-env-minimal --image

# Get latest image ref as JSON
fly releases -a dev-env-minimal -j | jq -r '.[0].imageRef'
```

### Option 2: Use registry path with deployment version
```bash
# Latest deployment version
fly releases -a dev-env-minimal -j | jq -r '.[0].version'

# Image path
registry.fly.io/dev-env-minimal:deployment-<version>
```

## Deploy to New Apps

### Create and deploy new app with base image
```bash
# Get the image reference
IMAGE_REF=$(fly releases -a dev-env-minimal -j | jq -r '.[0].imageRef')

# Create new app
fly apps create my-new-dev-env

# Deploy using base image
fly deploy --app my-new-dev-env --image "$IMAGE_REF"
```

### Or use explicit tag
```bash
fly deploy --app my-new-dev-env \
  --image registry.fly.io/dev-env-minimal:deployment-1
```

## Multi-App SaaS Pattern

Build once, deploy many:

```bash
#!/bin/bash
# build-once-deploy-many.sh

# Build base image (only once)
./deploy.sh

# Get image reference
IMAGE_REF=$(fly releases -a dev-env-minimal -j | jq -r '.[0].imageRef')

echo "Base image: $IMAGE_REF"

# Deploy to multiple customer apps
for customer in customer1 customer2 customer3; do
  APP_NAME="dev-env-${customer}"
  
  # Create app if doesn't exist
  fly apps create "$APP_NAME" || true
  
  # Deploy base image
  echo "Deploying to $APP_NAME..."
  fly deploy --app "$APP_NAME" --image "$IMAGE_REF"
done
```

## Verify Image Exists

```bash
# Authenticate Docker first
fly auth docker

# Check if image exists
docker manifest inspect registry.fly.io/dev-env-minimal:deployment-1
```

## Key Points

- **Cross-app access**: Images can be used by any app in the same Fly.io organization
- **No tag listing**: You can only see images that have been deployed (use `fly releases`)
- **Image retention**: Images persist as long as they're referenced by a release
- **Registry path**: Always `registry.fly.io/<app-name>:<tag>`
- **Build once**: Remote builder creates AMD64 images, reusable everywhere

## Example: Update fly.toml to use base image

Instead of `fly deploy --image`, you can set it in `fly.toml`:

```toml
[build]
  image = "registry.fly.io/dev-env-minimal:deployment-1"
```

Then just run:
```bash
fly deploy -a my-new-app
```
