# Makefile Daana Integration Design

## Goal

Consolidate Docker and daana-cli tasks into composite Makefile targets grouped by activity.

## Public Targets

| Target  | Purpose                                          |
|---------|--------------------------------------------------|
| `help`  | (default) Show available targets                 |
| `setup` | From zero to fully loaded data warehouse         |
| `run`   | Re-run pipeline after model/mapping changes      |
| `reset` | Nuke everything, then setup from scratch         |

## Target Chains

```
setup = seed -> docker-up -> install -> run
run   = check -> deploy -> execute
reset = clean -> setup
```

## Internal Steps

### seed
- Download Adventure Works CSVs (skipped if `.downloaded` marker exists)

### docker-up
- `docker compose up -d`
- Wait for both containers to be healthy

### install
- `daana-cli install --no-tui`

### check
- `daana-cli check --no-tui`

### deploy
- `daana-cli deploy --no-tui` (idempotent, safe to re-run)

### execute
- `daana-cli execute --no-tui`

### clean
- `docker compose down -v`
- Remove seed marker (`db/seed/data/.downloaded`) to force re-download

## Design Decisions

- **Composite-only public targets** -- individual steps are internal helpers, not listed in help
- **`--no-tui` on all daana-cli commands** -- clean log output in Make
- **`reset` chains into `setup`** -- DRY, single definition of the setup sequence
- **`setup` chains into `run`** -- DRY, setup ends with a full pipeline run
- **Seed is idempotent** -- marker file prevents re-download
