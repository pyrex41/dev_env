# Troubleshooting - Fly.io Dev Environment

## Docker-in-Docker Issues

### "operation not permitted" or overlayfs errors when running make dev

**Problem:** You see errors like:
```
failed to extract layer (application/vnd.oci.image.layer.v1.tar+gzip sha256:...) to overlayfs:
failed to convert whiteout file "etc/alternatives/.wh.pager.1.gz": operation not permitted
```

**Cause:** This is a Docker-in-Docker issue on Fly.io. The default `overlay2` storage driver doesn't work in nested container environments due to permission restrictions with whiteout files.

**Solution:** The image uses smart storage driver detection:
- **Tries overlay2 first** (best performance)
- **Falls back to vfs automatically** if overlay2 fails (Docker-in-Docker)
- This happens automatically at container startup

#### Verify Which Storage Driver Is Being Used

1. **Check current storage driver:**
   ```bash
   fly ssh console -a dev-env-minimal
   docker info | grep "Storage Driver"
   ```

   Will show either:
   - `Storage Driver: overlay2` (best performance, if it works)
   - `Storage Driver: vfs` (fallback for Docker-in-Docker)

2. **Check startup logs to see the detection process:**
   ```bash
   fly logs -a dev-env-minimal | grep "Docker Startup"
   ```

   You'll see messages like:
   ```
   [Docker Startup] Docker-in-Docker environment detected
   [Docker Startup] Attempting overlay2 storage driver...
   [Docker Startup] ⚠ overlay2 failed (expected in nested containers)
   [Docker Startup] Falling back to vfs storage driver...
   [Docker Startup] ✓ Successfully started with vfs driver
   ```

3. **If you see overlayfs errors, the automatic fallback didn't work. Manually trigger it:**
   ```bash
   fly ssh console -a dev-env-minimal
   sudo /usr/local/bin/start-docker.sh
   ```

4. **If issues persist, redeploy with the latest image:**
   ```bash
   cd fly_minimal
   ./deploy.sh
   ```

#### Storage Driver Comparison

| Driver | Performance | Disk Space | Works in DinD? | Auto-Selected When |
|--------|-------------|------------|----------------|-------------------|
| **overlay2** | ✅ Fast | ✅ Efficient | ⚠️ Sometimes | Not in container OR overlay2 works |
| **vfs** | ⚠️ Slower | ⚠️ Uses more | ✅ Always | In container AND overlay2 fails |

**Why this approach:**
- **Best case**: Gets `overlay2` performance when possible
- **Worst case**: Falls back to `vfs` that always works
- **No manual intervention needed**: Detects and configures automatically

---

## Docker Daemon Issues

### Docker daemon not starting

**Problem:** `docker info` fails or shows daemon not running

**Solutions:**

```bash
# Check if daemon is running
fly ssh console -a dev-env-minimal
sudo service docker status

# Start if stopped
sudo service docker start

# Check logs
sudo journalctl -u docker -n 50

# Verify Docker works
docker run hello-world
```

### Permission denied on Docker socket

**Problem:** `permission denied while trying to connect to the Docker daemon socket`

**Solution:**

```bash
# Check user is in docker group
groups testuser

# Should show: testuser : testuser docker

# If not in docker group, add and restart session
sudo usermod -aG docker testuser
exit
# SSH back in
```

---

## SSH Connection Issues

### Can't SSH into machine

**Problem:** `fly ssh console` hangs or fails

**Solutions:**

1. **Check machine status:**
   ```bash
   fly status -a dev-env-minimal
   ```

2. **Machine may be stopped (auto-stop enabled):**
   ```bash
   fly machine start -a dev-env-minimal
   ```

3. **Check machine logs:**
   ```bash
   fly logs -a dev-env-minimal
   ```

4. **Force restart:**
   ```bash
   fly machine restart -a dev-env-minimal --force
   ```

---

## Resource Issues

### Out of disk space

**Problem:** "no space left on device"

**Cause:** Docker images accumulate over time, especially with vfs driver

**Solutions:**

```bash
# SSH into machine
fly ssh console -a dev-env-minimal

# Check disk usage
df -h

# Clean up Docker
docker system prune -a --volumes -f

# Check again
df -h
```

**Prevention:** Regularly clean up unused images:
```bash
docker image prune -a -f
docker volume prune -f
```

### Machine running slow

**Problem:** Machine feels sluggish or unresponsive

**Solutions:**

1. **Check current machine size:**
   ```bash
   fly status -a dev-env-minimal
   ```

2. **Scale up if needed:**
   ```bash
   # More memory
   fly scale vm shared-cpu-2x --memory 4096 -a dev-env-minimal

   # Dedicated CPU
   fly scale vm dedicated-cpu-2x --memory 4096 -a dev-env-minimal
   ```

3. **Check Docker resource usage:**
   ```bash
   fly ssh console -a dev-env-minimal
   docker stats --no-stream
   ```

---

## Build/Deploy Issues

### Deployment fails

**Problem:** `./deploy.sh` fails or `fly deploy` errors

**Solutions:**

1. **Check you're logged in:**
   ```bash
   fly auth whoami
   # If not logged in:
   fly auth login
   ```

2. **Check app exists:**
   ```bash
   fly apps list | grep dev-env-minimal
   # If not exists:
   fly apps create dev-env-minimal
   ```

3. **Try manual deploy:**
   ```bash
   fly deploy --app dev-env-minimal
   ```

4. **Check build logs:**
   ```bash
   fly logs -a dev-env-minimal
   ```

### Remote builder fails

**Problem:** "Error: failed to fetch an image or build from source"

**Solutions:**

1. **Check Dockerfile syntax:**
   ```bash
   docker build -t test .
   ```

2. **Verify fly.toml is valid:**
   ```bash
   cat fly.toml
   ```

3. **Try with --verbose:**
   ```bash
   fly deploy --app dev-env-minimal --verbose
   ```

---

## Make Dev Issues

### make dev fails immediately

**Problem:** `make dev` in dev_env directory fails

**Solutions:**

1. **Ensure you're in the right directory:**
   ```bash
   fly ssh console -a dev-env-minimal
   cd /home/testuser/dev_env
   ls -la  # Should see Makefile, docker-compose.yml, etc.
   ```

2. **Check .env file exists:**
   ```bash
   ls -la .env
   # If missing:
   cp .env.local.example .env
   ```

3. **Check Docker daemon is running:**
   ```bash
   docker info
   # If not running:
   sudo service docker start
   ```

4. **Try with verbose output:**
   ```bash
   make dev V=1
   ```

### Services won't start

**Problem:** `make dev` runs but services show as unhealthy

**Solutions:**

1. **Check logs:**
   ```bash
   make logs
   ```

2. **Check individual service logs:**
   ```bash
   make logs-api
   make logs-frontend
   make logs-db
   ```

3. **Verify Docker storage driver:**
   ```bash
   docker info | grep "Storage Driver"
   # Should show: vfs
   ```

4. **Try clean start:**
   ```bash
   make down
   make clean
   make dev
   ```

---

## Still Stuck?

1. **Verify Docker storage driver is vfs** (most common issue)
2. **Check machine has enough resources** (2GB RAM minimum)
3. **Review deployment logs:** `fly logs -a dev-env-minimal`
4. **Try fresh deployment:** `./deploy.sh`
5. **Check Fly.io status:** https://status.flyio.net/

---

## Quick Diagnostic Script

Run this inside the Fly.io machine to check everything:

```bash
#!/bin/bash
echo "=== System Info ==="
uname -a
df -h

echo -e "\n=== Docker Status ==="
docker info | grep -A 5 "Storage Driver"
docker version --format '{{.Server.Version}}'

echo -e "\n=== Docker Daemon Config ==="
cat /etc/docker/daemon.json

echo -e "\n=== User Groups ==="
groups

echo -e "\n=== Docker Socket ==="
ls -la /var/run/docker.sock

echo -e "\n=== Running Containers ==="
docker ps

echo -e "\n=== Disk Usage ==="
docker system df
```

Save as `diagnostic.sh`, run with `bash diagnostic.sh`, and share output when asking for help.
