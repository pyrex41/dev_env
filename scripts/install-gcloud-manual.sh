#!/bin/bash
# Manual Google Cloud SDK Installation
# Use this if Homebrew installation fails

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}Google Cloud SDK - Manual Installation${NC}"
echo ""

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    FILE="google-cloud-cli-darwin-arm.tar.gz"
    URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$FILE"
elif [ "$ARCH" = "x86_64" ]; then
    FILE="google-cloud-cli-darwin-x86_64.tar.gz"
    URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$FILE"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
fi

echo -e "${CYAN}Architecture: $ARCH${NC}"
echo ""

# Download
echo -e "${YELLOW}Downloading Google Cloud SDK...${NC}"
cd /tmp
curl -O "$URL"

# Extract
echo -e "${YELLOW}Extracting...${NC}"
tar -xf "$FILE"

# Install
echo -e "${YELLOW}Installing to $HOME/google-cloud-sdk...${NC}"
if [ -d "$HOME/google-cloud-sdk" ]; then
    echo -e "${YELLOW}Existing installation found, backing up...${NC}"
    mv "$HOME/google-cloud-sdk" "$HOME/google-cloud-sdk.backup.$(date +%s)"
fi

mv google-cloud-sdk "$HOME/"

# Run install script
echo -e "${YELLOW}Running installer...${NC}"
"$HOME/google-cloud-sdk/install.sh" --usage-reporting=false --path-update=true --quiet

# Cleanup
rm -f "/tmp/$FILE"

echo ""
echo -e "${GREEN}✓ Google Cloud SDK installed${NC}"
echo ""

# Detect and configure shell
CURRENT_SHELL=$(basename "$SHELL")
echo -e "${YELLOW}Detected shell: $CURRENT_SHELL${NC}"
echo ""

# Add to Fish config if using Fish
if [ "$CURRENT_SHELL" = "fish" ]; then
    FISH_CONFIG="$HOME/.config/fish/config.fish"
    mkdir -p "$HOME/.config/fish"

    if ! grep -q "google-cloud-sdk" "$FISH_CONFIG" 2>/dev/null; then
        echo "" >> "$FISH_CONFIG"
        echo "# Google Cloud SDK" >> "$FISH_CONFIG"
        echo "set -gx PATH \$HOME/google-cloud-sdk/bin \$PATH" >> "$FISH_CONFIG"
        echo -e "${GREEN}✓ Added to Fish config${NC}"
    fi
fi

echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Restart your terminal or reload config:"
if [ "$CURRENT_SHELL" = "fish" ]; then
    echo -e "   ${CYAN}source ~/.config/fish/config.fish${NC}"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    echo -e "   ${CYAN}source ~/.zshrc${NC}"
else
    echo -e "   ${CYAN}source ~/.bashrc${NC}"
fi
echo ""
echo -e "2. Verify gcloud is in PATH:"
echo -e "   ${CYAN}which gcloud${NC}"
echo ""
echo -e "3. Initialize gcloud:"
echo -e "   ${CYAN}gcloud auth login${NC}"
echo ""
echo -e "4. Continue with GKE setup:"
echo -e "   ${CYAN}make gke-setup${NC}"
echo ""
