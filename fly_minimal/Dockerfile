# Pre-configured Debian image for zero-to-running dev environment testing
# Based on Debian Bookworm slim with Docker pre-installed
# NO PERSISTENT STORAGE - Fresh start every deployment

FROM debian:bookworm-slim

# Install base utilities and dependencies
RUN apt-get update && apt-get install -y \
    openssh-server \
    bash \
    fish \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    make \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker (official Docker repository)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Configure SSH with Fly.io certificate authority
RUN mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && echo 'TrustedUserCAKeys /etc/ssh/ca.pub' >> /etc/ssh/sshd_config

# Add Fly.io SSH CA public key
RUN echo 'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBwdCfg6yLlGxJOJwc+bNCBoWNuPX8Y+HkdkYdKQaH0NjlLqpV2LhbOxQYPZs47KPFtoDHkf8w3oV1j5A0dS3vM= root@fly.io' > /etc/ssh/ca.pub

# Create test user with sudo access (default to Fish shell)
RUN adduser --disabled-password --gecos "" --shell /usr/bin/fish testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser \
    && usermod -aG docker testuser

# Set up SSH directory for test user
RUN mkdir -p /home/testuser/.ssh \
    && chown -R testuser:testuser /home/testuser/.ssh \
    && chmod 700 /home/testuser/.ssh

# Add authorized SSH key for testuser
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1mrjS7oLScUIJjifcMRi/Zm/BAcZbUiAqvPI/7SzOp mbp new" > /home/testuser/.ssh/authorized_keys \
    && chown testuser:testuser /home/testuser/.ssh/authorized_keys \
    && chmod 600 /home/testuser/.ssh/authorized_keys

# Clone the dev_env repository and set up .env
RUN cd /home/testuser && \
    git clone https://github.com/pyrex41/dev_env.git && \
    cd dev_env && \
    cp .env.local.example .env && \
    chown -R testuser:testuser /home/testuser/dev_env

# Create startup script to pre-pull images on first boot
RUN echo '#!/bin/bash' > /usr/local/bin/startup.sh && \
    echo '# Start Docker daemon' >> /usr/local/bin/startup.sh && \
    echo 'service docker start' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Wait for Docker to be ready' >> /usr/local/bin/startup.sh && \
    echo 'timeout=30' >> /usr/local/bin/startup.sh && \
    echo 'elapsed=0' >> /usr/local/bin/startup.sh && \
    echo 'while [ $elapsed -lt $timeout ]; do' >> /usr/local/bin/startup.sh && \
    echo '    if docker info >/dev/null 2>&1; then' >> /usr/local/bin/startup.sh && \
    echo '        echo "Docker daemon is ready"' >> /usr/local/bin/startup.sh && \
    echo '        break' >> /usr/local/bin/startup.sh && \
    echo '    fi' >> /usr/local/bin/startup.sh && \
    echo '    sleep 1' >> /usr/local/bin/startup.sh && \
    echo '    elapsed=$((elapsed + 1))' >> /usr/local/bin/startup.sh && \
    echo 'done' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Pre-pull Docker images in background to avoid blocking SSH' >> /usr/local/bin/startup.sh && \
    echo '(' >> /usr/local/bin/startup.sh && \
    echo '    echo "Pre-pulling Docker images..."' >> /usr/local/bin/startup.sh && \
    echo '    docker pull postgres:16 &' >> /usr/local/bin/startup.sh && \
    echo '    docker pull redis:7 &' >> /usr/local/bin/startup.sh && \
    echo '    docker pull node:20-alpine &' >> /usr/local/bin/startup.sh && \
    echo '    wait' >> /usr/local/bin/startup.sh && \
    echo '    echo "Docker images pre-pulled successfully"' >> /usr/local/bin/startup.sh && \
    echo ') > /tmp/docker-pull.log 2>&1 &' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Keep container running' >> /usr/local/bin/startup.sh && \
    echo 'tail -f /dev/null' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Expose SSH port (Fly's proxy handles SSH)
EXPOSE 22

# Start Docker daemon and keep container running
CMD ["/usr/local/bin/startup.sh"]
