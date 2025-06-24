# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Claude Code Docker Sandbox - a security-focused Docker environment for running Claude Code in an isolated container with network restrictions. The project provides a safe execution environment while allowing developers to work with their code repositories.

## Key Commands

### Building and Running
```bash
# Build the Docker image
make build

# Run with a repository mounted
make run REPO_PATH=/path/to/your/project

# Run with custom API endpoint
make run REPO_PATH=/path/to/your/project ANTHROPIC_BASE_URL=https://custom-api.example.com

# Run with extra allowed domains
make run REPO_PATH=/path/to/your/project EXTRA_ALLOWED_DOMAINS=example.com,api.myservice.com

# Stop the container
make stop

# View logs
make logs

# Clean up container and image
make clean
```

### Development Commands
```bash
# Manually build without Make
docker-compose build

# Manually run without Make
REPO_PATH=/path/to/repo docker-compose up -d

# Enter the running container
docker exec -it claude-sandbox bash
```

## Architecture

### Security Model
- **Network Isolation**: Firewall (init-firewall.sh) restricts outbound connections to only:
  - GitHub APIs and repositories
  - npm registry
  - Anthropic API endpoints
  - Sentry.io and Statsig for telemetry
  - DNS queries and SSH
- **Container Security**: Runs as non-root user with minimal Linux capabilities
- **Credential Protection**: Claude credentials mounted read-only

### Key Components
- **Dockerfile**: Builds Node.js 20 container with Claude Code and development tools
- **docker-compose.yml**: Orchestrates container with security settings and volume mounts
- **init-firewall.sh**: Implements iptables/ipset firewall rules
- **start-with-repo.sh**: Helper script for starting sandbox with repository
- **Makefile**: Provides convenient commands for common operations

### Important Environment Variables
- `REPO_PATH`: Host path to mount into container at /workspace
- `REPO_NAME`: Repository name (auto-detected from path)
- `ANTHROPIC_BASE_URL`: Optional custom API endpoint
- `DISABLE_NON_ESSENTIAL_MODEL_CALLS=1`: Set by default to reduce API calls
- `EXTRA_ALLOWED_DOMAINS`: Comma-separated list of additional domains to whitelist in the firewall

## Development Notes

- Changes made in /workspace persist on the host filesystem
- Command history is preserved between container sessions
- The firewall script verifies its rules on startup (GitHub should work, example.com should fail)
- Claude is aliased to include `--dangerously-skip-permissions` flag by default