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

# With custom Anthropic API endpoint:
make run REPO_PATH=/path/to/your/repo ANTHROPIC_BASE_URL=https://api.anthropic.com

# With extra allowed domains (comma-separated):
make run REPO_PATH=/path/to/your/repo EXTRA_ALLOWED_DOMAINS=example.com,api.myservice.com

# With both custom API endpoint and extra domains:
make run REPO_PATH=/path/to/your/repo ANTHROPIC_BASE_URL=https://api.anthropic.com EXTRA_ALLOWED_DOMAINS=example.com,api.myservice.com
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
