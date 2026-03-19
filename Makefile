.PHONY: help setup run reset _docker-up _install _clean
.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: _seed _docker-up _install run ## From zero to fully loaded data warehouse

run: ## Re-run pipeline after model/mapping changes
	daana-cli check workflow --no-tui
	daana-cli deploy --no-tui
	daana-cli execute --no-tui

reset: _clean setup ## Nuke everything, then setup from scratch

# --- Internal targets (not in help) ---

_seed: db/seed/data/.downloaded

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

_docker-up:
	docker compose up -d --wait

_install:
	daana-cli install --no-tui

_clean:
	docker compose down -v
	@rm -f db/seed/data/.downloaded
