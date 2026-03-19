# Makefile Daana Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace individual Docker/daana targets with composite activity-based targets: `setup`, `run`, `reset`.

**Architecture:** Single Makefile rewrite. Public targets (`setup`, `run`, `reset`, `help`) compose internal helper targets. `reset` chains `clean` + `setup`, `setup` chains seed + docker + install + `run`, keeping it DRY.

**Tech Stack:** GNU Make, Docker Compose, daana-cli

---

### Task 1: Rewrite Makefile with composite targets

**Files:**
- Modify: `Makefile` (full rewrite)

**Step 1: Replace Makefile contents**

```makefile
.PHONY: help setup run reset
.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: _seed _docker-up _install run ## From zero to fully loaded data warehouse

run: ## Re-run pipeline after model/mapping changes
	daana-cli check --no-tui
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
```

**Step 2: Verify `make help` only shows public targets**

Run: `make help`
Expected output shows only: `setup`, `run`, `reset`, `help`

**Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: replace individual targets with composite activity-based targets

Consolidate Docker and daana-cli tasks into three composite targets:
- setup: seed + docker + install + pipeline
- run: check + deploy + execute
- reset: nuke + setup"
```

### Task 2: Verify setup works end-to-end

**Step 1: Run `make reset` to test full chain**

Run: `make reset`
Expected: Containers nuked, re-seeded, re-created, daana installed, pipeline executed.

**Step 2: Run `make run` to test re-run**

Run: `make run`
Expected: check + deploy + execute succeed (idempotent).
