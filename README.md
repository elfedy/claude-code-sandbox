# Claude Code Docker Sandbox

A Docker-based sandbox environment for running Claude Code with controlled permissions.

## Quick Start

### Using Make Commands (Recommended)

1. Build the Docker image:
```bash
make build
```

2. Run with a repository mounted:
```bash
make run REPO_PATH=/path/to/your/repo
# Or with custom Anthropic API endpoint:
make run REPO_PATH=/path/to/your/repo ANTHROPIC_BASE_URL=https://api.anthropic.com
```

3. View container logs:
```bash
make logs
```

4. Stop the container:
```bash
make stop
```

5. Clean up (remove container and image):
```bash
make clean
```

### Manual Docker Commands

1. Build and start the container:
```bash
docker-compose up -d
```

2. Enter the sandbox:
```bash
docker exec -it claude-sandbox bash
```

3. Run Claude Code inside the container:
```bash
# Inside the container
claude  # Alias for claude-code --yes-to-all
# Or use the full command:
claude-code
# Note: DISABLE_NON_ESSENTIAL_MODEL_CALLS=1 is automatically set
```

## Files

- `Dockerfile` - Defines the sandbox environment with Alpine Linux 3.19 and common dev tools
- `docker-compose.yml` - Safe configuration with limited capabilities
- `workspace/` - Shared directory between host and container

## Security Levels

### Current Setup (Safe)
- User has sudo inside container
- Limited capabilities (SYS_PTRACE, NET_ADMIN)
- Cannot escape to host system
- Good for most development tasks

### Privileged Mode (Not Recommended)
If you need full system access, create a `docker-compose-privileged.yml` with:
```yaml
privileged: true
security_opt:
  - seccomp:unconfined
```

⚠️ **Warning**: Privileged mode can potentially affect your host system.

## Stopping the Sandbox

```bash
docker-compose down
```

## Persistent Files

Any files created in `/workspace` inside the container will be saved in the `./workspace` directory on your host.
