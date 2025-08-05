#!/bin/bash
set -euo pipefail

# Script to start Claude sandbox with a mounted repository

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-repo> [anthropic-base-url] [extra-allowed-domains] [host-binaries-path]"
    echo "Example: $0 ~/projects/my-app"
    echo "Example: $0 ~/projects/my-app https://api.anthropic.com"
    echo "Example: $0 ~/projects/my-app https://api.anthropic.com example.com,api.test.com"
    echo "Example: $0 ~/projects/my-app https://api.anthropic.com example.com,api.test.com ~/my-tools/bin"
    exit 1
fi

REPO_PATH="$1"
REPO_ABS_PATH=$(realpath "$REPO_PATH")
REPO_NAME=$(basename "$REPO_ABS_PATH")

# Optional second argument for ANTHROPIC_BASE_URL
if [ $# -ge 2 ]; then
    export ANTHROPIC_BASE_URL="$2"
    echo "Setting ANTHROPIC_BASE_URL to: $ANTHROPIC_BASE_URL"
fi

# Optional third argument for EXTRA_ALLOWED_DOMAINS
if [ $# -ge 3 ]; then
    export EXTRA_ALLOWED_DOMAINS="$3"
    echo "Setting EXTRA_ALLOWED_DOMAINS to: $EXTRA_ALLOWED_DOMAINS"
fi

# Optional fourth argument for HOST_BINARIES_PATH
if [ $# -ge 4 ]; then
    export HOST_BINARIES_PATH="$4"
    if [ ! -d "$HOST_BINARIES_PATH" ]; then
        echo "Error: Host binaries directory '$HOST_BINARIES_PATH' does not exist"
        exit 1
    fi
    echo "Setting HOST_BINARIES_PATH to: $HOST_BINARIES_PATH"
fi

if [ ! -d "$REPO_ABS_PATH" ]; then
    echo "Error: Directory '$REPO_ABS_PATH' does not exist"
    exit 1
fi

echo "Starting Claude sandbox with repository: $REPO_ABS_PATH"
echo "Repository will be mounted at: /workspace/$REPO_NAME"

# Export the repo path for docker-compose
export REPO_PATH="$REPO_ABS_PATH"
export REPO_NAME="$REPO_NAME"

# Build if needed
docker-compose build

# Start the container with the mounted repo
docker-compose up -d

# Enter the container
docker-compose exec claude-sandbox bash -c "cd /workspace/$REPO_NAME && exec bash"