#!/bin/bash
# Quick helper to add gcloud to PATH for current session
# Works with bash, zsh, and fish

echo "Setting up Google Cloud SDK in PATH..."

# Detect shell
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "fish" ]; then
    echo "Detected Fish shell"
    echo "Run this command in your Fish terminal:"
    echo ""
    echo "  set -gx PATH \$HOME/google-cloud-sdk/bin \$PATH"
    echo ""
    echo "Or reload your config:"
    echo "  source ~/.config/fish/config.fish"
else
    # For bash/zsh, just export
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
    echo "PATH updated for bash/zsh"
    echo "In this terminal, gcloud should now work"
    echo ""
    echo "To make permanent, add to your shell config:"
    if [ "$CURRENT_SHELL" = "zsh" ]; then
        echo "  echo 'export PATH=\"\$HOME/google-cloud-sdk/bin:\$PATH\"' >> ~/.zshrc"
    else
        echo "  echo 'export PATH=\"\$HOME/google-cloud-sdk/bin:\$PATH\"' >> ~/.bashrc"
    fi
fi

echo ""
echo "Test with: which gcloud"
