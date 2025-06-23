# Claude Code Docker Sandbox

A Docker-based sandbox environment for running Claude Code with controlled permissions.

## Quick Start

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
```

4. Remove container 
```bash
docker-compose down
```
