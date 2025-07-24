#!/bin/bash

# Script to start Claude Code sandbox with the current repository mounted
# Usage: Run this script from any git repository to mount it in the sandbox

set -e

# Get the directory where this script is located (the sandbox project)
SANDBOX_DIR="~/projects/agent-sandbox"

# Get the current working directory (the repo to mount)
CURRENT_REPO="$(pwd)"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Current directory is not a git repository"
    echo "Please run this script from within a git repository"
    exit 1
fi

# Get the repository name
REPO_NAME="$(basename "$CURRENT_REPO")"

echo "Starting Claude Code sandbox..."
echo "Sandbox project: $SANDBOX_DIR"
echo "Mounting repository: $CURRENT_REPO ($REPO_NAME)"

# Change to the sandbox directory and run make
cd "$SANDBOX_DIR"
exec make run REPO_PATH="$CURRENT_REPO"
