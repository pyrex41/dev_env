# Lean Alpine Linux image for testing setup scripts
# Based on Alpine 3.19 (~5MB base image)
# NO PERSISTENT STORAGE - Fresh start every deployment

FROM alpine:3.19

# Install OpenSSH, Fish shell, and basic utilities
RUN apk add --no-cache \
    openssh \
    bash \
    fish \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    && rm -rf /var/cache/apk/*

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
RUN adduser -D -s /usr/bin/fish testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser

# Set up SSH directory for test user
RUN mkdir -p /home/testuser/.ssh \
    && chown -R testuser:testuser /home/testuser/.ssh \
    && chmod 700 /home/testuser/.ssh

# Add authorized SSH key for testuser
RUN echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1mrjS7oLScUIJjifcMRi/Zm/BAcZbUiAqvPI/7SzOp mbp new" > /home/testuser/.ssh/authorized_keys \
    && chown testuser:testuser /home/testuser/.ssh/authorized_keys \
    && chmod 600 /home/testuser/.ssh/authorized_keys

# Create working directory
RUN mkdir -p /home/testuser/workspace \
    && chown testuser:testuser /home/testuser/workspace

# Expose SSH port (Fly's proxy handles SSH)
EXPOSE 22

# Keep container running (Fly's SSH proxy handles connections)
CMD ["/bin/sh", "-c", "while true; do sleep 3600; done"]
