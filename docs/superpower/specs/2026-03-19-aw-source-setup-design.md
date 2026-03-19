# Adventure Works Source Setup — Design

## Overview

Set up the Adventure Works OLTP database as a source layer for the Daana data warehouse. This includes branded Docker containers, a PostgreSQL seed script with snake_case conventions, and business-meaningful `modified_date` values for CDC/incremental processing.

## Directory Structure

```
adventure-works-ddw/
├── db/
│   └── seed/
│       ├── 01_schema.sql
│       ├── 02_load.sql
│       ├── 03_modified_dates.sql
│       └── data/
│           └── *.csv
├── docker-compose.yml
├── config.yaml
├── connections.yaml
├── Makefile
├── model.yaml
├── workflow.yaml
└── mappings/
```

## Docker Branding

All containers and volumes prefixed with `aw-` to avoid collisions with other Daana projects.

| Resource            | Value                    |
| ------------------- | ------------------------ |
| Customer container  | `aw-customerdb`          |
| Internal container  | `aw-internaldb`          |
| Customer volume     | `aw-customer-data`       |
| Internal volume     | `aw-internal-data`       |
| Customer host port  | `5442:5432`              |
| Internal host port  | `5444:5432`              |

## Seed Script Architecture

Three SQL scripts in `db/seed/`, auto-executed by PostgreSQL's `docker-entrypoint-initdb.d` on first container start.

### 01_schema.sql

- Creates the `das` schema
- Creates all 68 tables with naming convention: `aw__<schema>__<snake_case_table>`
  - e.g., `das.aw__sales__sales_order_header`
- All identifiers in snake_case (columns, constraints, etc.)
- Preserves data types and constraints from original schema
- Source: [NorfolkDataSci/adventure-works-postgres](https://github.com/NorfolkDataSci/adventure-works-postgres)

### 02_load.sql

- Loads all CSV files from `data/` directory using `\copy`
- Tab-delimited CSVs matching the original Adventure Works export

### 03_modified_dates.sql

Updates `modified_date` on every table with business-meaningful dates:

**Transactional tables (use own dates):**
- `sales_order_header` → `order_date`
- `sales_order_detail` → parent order's `order_date`
- `purchase_order_header` → `order_date`
- `purchase_order_detail` → parent order's `order_date`

**Entity tables (derive from related data):**
- `customer` → first sales order's `order_date`
- `person` → earliest related record (first order for customers, hire date for employees)
- `employee` → `hire_date`
- `sales_person` → `hire_date` from employee record

**History tables (use own temporal columns):**
- `employee_department_history` → `start_date`
- `employee_pay_history` → `rate_change_date`
- `product_cost_history` → `start_date`
- `product_list_price_history` → `start_date`
- `sales_territory_history` → `start_date`
- `sales_person_quota_history` → `quota_date`

**Product/catalog tables (lead time before sell start):**
- `product` → `sell_start_date - INTERVAL '30 days'`
- `product_model`, `product_category`, `product_subcategory` → earliest related product's `modified_date - INTERVAL '7 days'`

**Reference/lookup tables:**
- Set to the earliest `modified_date` across all transactional data (system epoch)

## Makefile

```makefile
up:       Start containers (seeds on first run)
down:     Stop containers
clean:    Stop + delete volumes (full reset)
restart:  Reset and re-seed
```

## Branch Strategy

| Branch                  | Parent                   | Purpose                                      |
| ----------------------- | ------------------------ | -------------------------------------------- |
| `epic/aw-source-setup`  | `main`                   | Epic: design doc + plan, integration point   |
| `feat/docker-branding`  | `epic/aw-source-setup`   | Container/port/Makefile changes              |
| `feat/seed-script`      | `epic/aw-source-setup`   | SQL scripts + CSVs + modified_date logic     |

Sub-branch PRs target the epic branch. Epic branch PRs into `main` when integrated.
