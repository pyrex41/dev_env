# Lean Alpine Linux image for testing setup scripts
# Based on Alpine 3.19 (~5MB base image)
# NO PERSISTENT STORAGE - Fresh start every deployment

FROM alpine:3.19

# Install OpenSSH and basic utilities
RUN apk add --no-cache \
    openssh \
    bash \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Configure SSH
RUN mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Create test user with sudo access
RUN adduser -D -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser

# Set up SSH directory for test user
RUN mkdir -p /home/testuser/.ssh \
    && chown -R testuser:testuser /home/testuser/.ssh \
    && chmod 700 /home/testuser/.ssh

# Create working directory
RUN mkdir -p /home/testuser/workspace \
    && chown testuser:testuser /home/testuser/workspace

# Expose SSH port
EXPOSE 22

# Start SSH daemon
CMD ["/usr/sbin/sshd", "-D", "-e"]
