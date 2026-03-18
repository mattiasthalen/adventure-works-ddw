.PHONY: help up down clean restart seed
.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

seed: db/seed/data/.downloaded ## Download Adventure Works CSVs

db/seed/data/.downloaded:
	@mkdir -p db/seed/data
	@echo "Downloading Adventure Works CSVs..."
	@cd db/seed/data && \
	for file in $$(gh api repos/NorfolkDataSci/adventure-works-postgres/contents/data --jq '.[].name'); do \
		echo "  $$file"; \
		curl -sL "https://raw.githubusercontent.com/NorfolkDataSci/adventure-works-postgres/master/data/$$file" -o "$$file"; \
	done
	@touch db/seed/data/.downloaded
	@echo "Done."

up: seed ## Start containers (seeds on first run)
	docker compose up -d

down: ## Stop containers
	docker compose down

clean: ## Stop containers and delete volumes
	docker compose down -v

restart: clean up ## Reset and re-seed
