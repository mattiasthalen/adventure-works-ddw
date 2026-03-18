# Adventure Works DDW

A data warehouse for [Adventure Works](https://github.com/NorfolkDataSci/adventure-works-postgres), built with [Daana CLI](https://github.com/daana-code/daana-cli).

## Prerequisites

- Docker
- [GitHub CLI](https://cli.github.com/) (`gh`)
- [Daana CLI](https://github.com/daana-code/daana-cli)

## Quick Start

```bash
make up
```

This downloads the Adventure Works CSVs, starts two PostgreSQL containers, and seeds the customer database with all 68 tables.

Run `make` to see all available commands.

## Architecture

Two PostgreSQL databases, both running locally via Docker:

| Database | Container | Port | Purpose |
|----------|-----------|------|---------|
| customerdb | aw-customerdb | 5442 | Source data (Adventure Works) + transformed entities (`dab` schema) |
| internaldb | aw-internaldb | 5444 | Daana metadata and orchestration |

### Source Data

The Adventure Works OLTP dataset is loaded into the `das` schema with the naming convention:

```
das.aw__<schema>__<table_name>
```

For example:
- `das.aw__sales__sales_order_header`
- `das.aw__person__person`
- `das.aw__production__product`

All identifiers use `snake_case`. The `modified_date` column on each table is set to a business-meaningful date for CDC/incremental processing.

## Project Structure

```
adventure-works-ddw/
├── db/seed/
│   ├── 01_schema.sql          # 68 tables in das schema
│   ├── 02_load.sql            # CSV loading + post-processing
│   ├── 03_modified_dates.sql  # Business-meaningful modified_date updates
│   └── data/                  # CSVs (downloaded, not committed)
├── model.yaml                 # Daana data model
├── workflow.yaml              # Daana workflow orchestration
├── connections.yaml           # Database connection profiles
├── config.yaml                # Daana CLI configuration
├── docker-compose.yml         # Container definitions
├── Makefile                   # Development commands
└── mappings/                  # Entity mapping files
```
