#!/bin/bash
# Smart Docker daemon startup script
# Tries overlay2 first (best performance), falls back to vfs if Docker-in-Docker

set -e

DOCKER_CONFIG="/etc/docker/daemon.json"
LOG_PREFIX="[Docker Startup]"

echo "${LOG_PREFIX} Starting Docker daemon with smart storage driver detection..."

# Function to detect if we're in a container (Docker-in-Docker scenario)
is_container() {
    # Check multiple indicators
    [ -f /.dockerenv ] || \
    [ -f /run/.containerenv ] || \
    grep -q docker /proc/1/cgroup 2>/dev/null || \
    grep -q lxc /proc/1/cgroup 2>/dev/null
}

# Function to create Docker config with specified storage driver
create_docker_config() {
    local storage_driver=$1
    echo "${LOG_PREFIX} Configuring Docker with ${storage_driver} storage driver..."

    cat > "${DOCKER_CONFIG}" <<EOF
{
  "storage-driver": "${storage_driver}",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
}

# Function to test if Docker daemon starts successfully
test_docker_start() {
    local timeout=10
    local elapsed=0

    # Start Docker daemon in background
    service docker start >/dev/null 2>&1 || return 1

    # Wait for Docker to be ready
    while [ $elapsed -lt $timeout ]; do
        if docker info >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    return 1
}

# Main logic
if is_container; then
    echo "${LOG_PREFIX} Docker-in-Docker environment detected (running inside a container)"

    # Try overlay2 first (best performance)
    echo "${LOG_PREFIX} Attempting overlay2 storage driver..."
    create_docker_config "overlay2"

    if test_docker_start; then
        STORAGE_DRIVER=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}')
        echo "${LOG_PREFIX} ✓ Successfully started with ${STORAGE_DRIVER} driver"
    else
        # overlay2 failed, fall back to vfs
        echo "${LOG_PREFIX} ⚠ overlay2 failed (expected in nested containers)"
        echo "${LOG_PREFIX} Falling back to vfs storage driver..."

        # Stop failed daemon
        service docker stop >/dev/null 2>&1 || true

        # Clean up Docker data from failed attempt
        rm -rf /var/lib/docker/*

        # Configure for vfs
        create_docker_config "vfs"

        if test_docker_start; then
            STORAGE_DRIVER=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}')
            echo "${LOG_PREFIX} ✓ Successfully started with ${STORAGE_DRIVER} driver"
            echo "${LOG_PREFIX} Note: vfs is slower but works reliably in Docker-in-Docker"
        else
            echo "${LOG_PREFIX} ✗ Failed to start Docker daemon with both overlay2 and vfs"
            exit 1
        fi
    fi
else
    # Not in a container, use overlay2 (standard performance)
    echo "${LOG_PREFIX} Standard environment detected (not in a container)"
    echo "${LOG_PREFIX} Using overlay2 storage driver for best performance..."
    create_docker_config "overlay2"

    if test_docker_start; then
        STORAGE_DRIVER=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}')
        echo "${LOG_PREFIX} ✓ Successfully started with ${STORAGE_DRIVER} driver"
    else
        echo "${LOG_PREFIX} ✗ Failed to start Docker daemon"
        exit 1
    fi
fi

# Show final configuration
echo "${LOG_PREFIX} Docker daemon configuration:"
docker info | grep -A 5 "Storage Driver" || true
echo "${LOG_PREFIX} Docker is ready!"
