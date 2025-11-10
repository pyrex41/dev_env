#!/bin/bash
# Validate secrets in .env file
if [ ! -f .env ]; then
  echo "Error: .env file not found. Run 'cp .env.example .env' first."
  exit 1
fi

if grep -q "CHANGE_ME" .env; then
  echo "Warning: .env contains 'CHANGE_ME' placeholders. Update with real values before production."
  exit 1
fi

echo "✓ All secrets validated (no CHANGE_ME placeholders found)."
