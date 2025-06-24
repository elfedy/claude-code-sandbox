.PHONY: build run stop clean logs

build:
	docker-compose build

# Usage: make run REPO_PATH=/path/to/your/repo [ANTHROPIC_BASE_URL=https://api.anthropic.com] [EXTRA_ALLOWED_DOMAINS=example.com,api.test.com]
run:
ifdef REPO_PATH
	@bash start-with-repo.sh $(REPO_PATH) $(if $(ANTHROPIC_BASE_URL),$(ANTHROPIC_BASE_URL)) $(if $(EXTRA_ALLOWED_DOMAINS),$(EXTRA_ALLOWED_DOMAINS))
else
	$(error REPO_PATH is required. Usage: make run REPO_PATH=/path/to/your/repo [ANTHROPIC_BASE_URL=https://api.anthropic.com] [EXTRA_ALLOWED_DOMAINS=example.com,api.test.com])
endif

stop:
	docker-compose down

clean:
	docker-compose down -v
	docker rmi claude-sandbox:latest || true

logs:
	docker-compose logs -f
