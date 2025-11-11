# Simple Debian image with Docker pre-installed
# Ready for development work

FROM debian:bookworm-slim

# Install all dependencies in one layer
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
    jq \
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

# Add smart Docker startup script
# Tries overlay2 first (best performance), falls back to vfs if needed
COPY start-docker.sh /usr/local/bin/start-docker.sh
RUN chmod +x /usr/local/bin/start-docker.sh

# Configure SSH with Fly.io certificate authority
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'TrustedUserCAKeys /etc/ssh/ca.pub' >> /etc/ssh/sshd_config

# Add Fly.io SSH CA public key
RUN echo 'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBwdCfg6yLlGxJOJwc+bNCBoWNuPX8Y+HkdkYdKQaH0NjlLqpV2LhbOxQYPZs47KPFtoDHkf8w3oV1j5A0dS3vM= root@fly.io' > /etc/ssh/ca.pub

# Create test user with sudo access
RUN adduser --disabled-password --gecos "" --shell /usr/bin/fish testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser && \
    chmod 0440 /etc/sudoers.d/testuser && \
    usermod -aG docker testuser

# Set up SSH directory for test user
RUN mkdir -p /home/testuser/.ssh && \
    chown -R testuser:testuser /home/testuser/.ssh && \
    chmod 700 /home/testuser/.ssh

# Add authorized SSH key for testuser
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1mrjS7oLScUIJjifcMRi/Zm/BAcZbUiAqvPI/7SzOp mbp new" > /home/testuser/.ssh/authorized_keys && \
    chown testuser:testuser /home/testuser/.ssh/authorized_keys && \
    chmod 600 /home/testuser/.ssh/authorized_keys

# Expose SSH port
EXPOSE 22

# Start Docker daemon with smart storage driver detection and keep container running
CMD /usr/local/bin/start-docker.sh && tail -f /dev/null
