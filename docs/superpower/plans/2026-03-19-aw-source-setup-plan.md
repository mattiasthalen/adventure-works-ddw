# Adventure Works Source Setup — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up Adventure Works OLTP as a fully seeded PostgreSQL source layer for the Daana data warehouse, with branded Docker containers and business-meaningful `modified_date` values.

**Architecture:** Two independent feature branches off `epic/aw-source-setup`. One handles Docker/infra branding (containers, ports, config, Makefile). The other creates the seed script pipeline (schema creation, CSV loading, modified_date updates). Both auto-seed the customerdb container on first start via `docker-entrypoint-initdb.d`.

**Tech Stack:** Docker Compose, PostgreSQL 15, SQL, Make, Daana CLI

---

## Task 1: Docker Branding & Infrastructure

**Branch:** `feat/docker-branding` (off `epic/aw-source-setup`)

**Files:**
- Modify: `docker-compose.yml`
- Modify: `config.yaml`
- Modify: `connections.yaml`
- Create: `Makefile`

### Step 1: Update `docker-compose.yml`

Rename services, containers, volumes, and ports. Add seed volume mount for customerdb.

```yaml
services:
  aw-customer:
    image: postgres:15
    container_name: aw-customerdb
    restart: unless-stopped
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: customerdb
    ports:
      - "5442:5432"
    volumes:
      - aw-customer-data:/var/lib/postgresql/data
      - ./db/seed:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev -d customerdb"]
      interval: 5s
      timeout: 5s
      retries: 5

  aw-internal:
    image: postgres:15
    container_name: aw-internaldb
    restart: unless-stopped
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: internaldb
    ports:
      - "5444:5432"
    volumes:
      - aw-internal-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev -d internaldb"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  aw-customer-data:
    driver: local
  aw-internal-data:
    driver: local
```

### Step 2: Update `config.yaml`

Change port from `5434` to `5444`:

```yaml
app:
  log_level: "info"
  db:
    host: "localhost"
    port: 5444
    user: "dev"
    password: "devpass"
    name: "internaldb"
    sslmode: "disable"
```

### Step 3: Update `connections.yaml`

Change port from `5432` to `5442`:

```yaml
connections:
  dev:
    type: "postgresql"
    host: "localhost"
    port: 5442
    user: "dev"
    password: "devpass"
    database: "customerdb"
    sslmode: "disable"
    target_schema: "daana_dw"
```

Remove all the commented-out boilerplate connection examples (BigQuery, MSSQL, Oracle, Snowflake) — keep it clean. Only keep the `dev` profile.

### Step 4: Create `Makefile`

```makefile
.PHONY: up down clean restart

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v

restart: clean up
```

### Step 5: Commit

```bash
git add docker-compose.yml config.yaml connections.yaml Makefile
git commit -m "feat: brand docker containers with aw prefix and add Makefile

Rename containers/volumes to aw-*, update ports to 5442/5444
to avoid collisions, add seed volume mount, and add Makefile
for docker lifecycle management."
```

### Step 6: Push and open PR

```bash
git push -u origin feat/docker-branding
gh pr create --base epic/aw-source-setup --title "feat: brand docker containers and add Makefile" --body "$(cat <<'EOF'
## Summary
- Rename containers/volumes from `daana-*` to `aw-*`
- Update ports to `5442` (customer) and `5444` (internal) to avoid collisions
- Add `./db/seed` volume mount to customerdb for auto-seeding
- Add Makefile with `up`, `down`, `clean`, `restart` targets
- Clean up connections.yaml boilerplate

## Test plan
- [ ] `make up` starts both containers
- [ ] `docker ps` shows `aw-customerdb` and `aw-internaldb`
- [ ] Ports 5442 and 5444 are accessible
- [ ] `make clean && make up` does a full reset

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Task 2: Seed Script — Schema & Tables

**Branch:** `feat/seed-script` (off `epic/aw-source-setup`)

**Files:**
- Create: `db/seed/01_schema.sql`
- Create: `db/seed/02_load.sql`
- Create: `db/seed/03_modified_dates.sql`
- Download: `db/seed/data/*.csv` (72 CSV files from NorfolkDataSci/adventure-works-postgres)

### Step 1: Download CSVs

```bash
mkdir -p db/seed/data
cd db/seed/data
# Download all CSVs from the NorfolkDataSci repo
for file in $(gh api repos/NorfolkDataSci/adventure-works-postgres/contents/data --jq '.[].name'); do
  curl -sL "https://raw.githubusercontent.com/NorfolkDataSci/adventure-works-postgres/master/data/$file" -o "$file"
done
```

### Step 2: Create `db/seed/01_schema.sql`

Creates the `das` schema and all 68 tables with snake_case naming convention `aw__<schema>__<table>`.

**Key rules:**
- Schema: `das`
- Table naming: `das.aw__<original_schema>__<snake_case_table>`
- All column names: snake_case (e.g., `BusinessEntityID` → `business_entity_id`)
- All constraint names: snake_case
- Remove custom domains (`"Name"`, `"Flag"`, `"NameStyle"`, `"Phone"`, `"OrderNumber"`, `"AccountNumber"`) — inline the actual types
- Keep `uuid-ossp` extension for UUID generation
- Keep `tablefunc` extension for crosstab
- Do NOT create the original 5 schemas (Person, HumanResources, Production, Purchasing, Sales)
- Do NOT create views or convenience schemas (pe, hr, pr, pu, sa)
- Do NOT create primary keys, foreign keys, or indexes (this is a source/staging layer)
- Do NOT add table/column comments (keep it clean)
- Keep the Employee `organizationnode` conversion logic (hex → hierarchy path)

**Complete table mapping (68 tables):**

Person schema (13 tables):
- `Person.BusinessEntity` → `das.aw__person__business_entity`
- `Person.Person` → `das.aw__person__person`
- `Person.StateProvince` → `das.aw__person__state_province`
- `Person.Address` → `das.aw__person__address`
- `Person.AddressType` → `das.aw__person__address_type`
- `Person.BusinessEntityAddress` → `das.aw__person__business_entity_address`
- `Person.ContactType` → `das.aw__person__contact_type`
- `Person.BusinessEntityContact` → `das.aw__person__business_entity_contact`
- `Person.EmailAddress` → `das.aw__person__email_address`
- `Person.Password` → `das.aw__person__password`
- `Person.PhoneNumberType` → `das.aw__person__phone_number_type`
- `Person.PersonPhone` → `das.aw__person__person_phone`
- `Person.CountryRegion` → `das.aw__person__country_region`

HumanResources schema (6 tables):
- `HumanResources.Department` → `das.aw__human_resources__department`
- `HumanResources.Employee` → `das.aw__human_resources__employee`
- `HumanResources.EmployeeDepartmentHistory` → `das.aw__human_resources__employee_department_history`
- `HumanResources.EmployeePayHistory` → `das.aw__human_resources__employee_pay_history`
- `HumanResources.JobCandidate` → `das.aw__human_resources__job_candidate`
- `HumanResources.Shift` → `das.aw__human_resources__shift`

Production schema (25 tables):
- `Production.BillOfMaterials` → `das.aw__production__bill_of_materials`
- `Production.Culture` → `das.aw__production__culture`
- `Production.Document` → `das.aw__production__document`
- `Production.ProductCategory` → `das.aw__production__product_category`
- `Production.ProductSubcategory` → `das.aw__production__product_subcategory`
- `Production.ProductModel` → `das.aw__production__product_model`
- `Production.Product` → `das.aw__production__product`
- `Production.ProductCostHistory` → `das.aw__production__product_cost_history`
- `Production.ProductDescription` → `das.aw__production__product_description`
- `Production.ProductDocument` → `das.aw__production__product_document`
- `Production.Location` → `das.aw__production__location`
- `Production.ProductInventory` → `das.aw__production__product_inventory`
- `Production.ProductListPriceHistory` → `das.aw__production__product_list_price_history`
- `Production.Illustration` → `das.aw__production__illustration`
- `Production.ProductModelIllustration` → `das.aw__production__product_model_illustration`
- `Production.ProductModelProductDescriptionCulture` → `das.aw__production__product_model_product_description_culture`
- `Production.ProductPhoto` → `das.aw__production__product_photo`
- `Production.ProductProductPhoto` → `das.aw__production__product_product_photo`
- `Production.ProductReview` → `das.aw__production__product_review`
- `Production.ScrapReason` → `das.aw__production__scrap_reason`
- `Production.TransactionHistory` → `das.aw__production__transaction_history`
- `Production.TransactionHistoryArchive` → `das.aw__production__transaction_history_archive`
- `Production.UnitMeasure` → `das.aw__production__unit_measure`
- `Production.WorkOrder` → `das.aw__production__work_order`
- `Production.WorkOrderRouting` → `das.aw__production__work_order_routing`

Purchasing schema (5 tables):
- `Purchasing.ProductVendor` → `das.aw__purchasing__product_vendor`
- `Purchasing.PurchaseOrderDetail` → `das.aw__purchasing__purchase_order_detail`
- `Purchasing.PurchaseOrderHeader` → `das.aw__purchasing__purchase_order_header`
- `Purchasing.ShipMethod` → `das.aw__purchasing__ship_method`
- `Purchasing.Vendor` → `das.aw__purchasing__vendor`

Sales schema (19 tables):
- `Sales.CountryRegionCurrency` → `das.aw__sales__country_region_currency`
- `Sales.CreditCard` → `das.aw__sales__credit_card`
- `Sales.Currency` → `das.aw__sales__currency`
- `Sales.CurrencyRate` → `das.aw__sales__currency_rate`
- `Sales.Customer` → `das.aw__sales__customer`
- `Sales.PersonCreditCard` → `das.aw__sales__person_credit_card`
- `Sales.SalesOrderDetail` → `das.aw__sales__sales_order_detail`
- `Sales.SalesOrderHeader` → `das.aw__sales__sales_order_header`
- `Sales.SalesOrderHeaderSalesReason` → `das.aw__sales__sales_order_header_sales_reason`
- `Sales.SalesPerson` → `das.aw__sales__sales_person`
- `Sales.SalesPersonQuotaHistory` → `das.aw__sales__sales_person_quota_history`
- `Sales.SalesReason` → `das.aw__sales__sales_reason`
- `Sales.SalesTaxRate` → `das.aw__sales__sales_tax_rate`
- `Sales.SalesTerritory` → `das.aw__sales__sales_territory`
- `Sales.SalesTerritoryHistory` → `das.aw__sales__sales_territory_history`
- `Sales.ShoppingCartItem` → `das.aw__sales__shopping_cart_item`
- `Sales.SpecialOffer` → `das.aw__sales__special_offer`
- `Sales.SpecialOfferProduct` → `das.aw__sales__special_offer_product`
- `Sales.Store` → `das.aw__sales__store`

**Domain type replacements:**
- `"Name"` → `varchar(50)`
- `"Flag"` → `boolean NOT NULL`
- `"NameStyle"` → `boolean NOT NULL`
- `"Phone"` → `varchar(25)`
- `"OrderNumber"` → `varchar(25)`
- `"AccountNumber"` → `varchar(15)`

**Post-load steps to include in 01_schema.sql:**
- Employee `organizationnode` conversion (the hex → hierarchy path function) — adapt table references to new names
- Drop the temporary `organization_level` column from employee after import
- Drop calculated columns after CSV import: `account_number` from customer, `line_total` from sales_order_detail, `sales_order_number` from sales_order_header

### Step 3: Create `db/seed/02_load.sql`

Load all CSVs using `\copy`. The CSV files keep their original names (PascalCase) as downloaded from the repo. The `\copy` paths reference `/docker-entrypoint-initdb.d/data/<FileName>.csv`.

**Important:** The `\copy` command in docker-entrypoint context uses absolute paths inside the container. The seed directory is mounted at `/docker-entrypoint-initdb.d/`.

Load order must match table creation order to avoid issues with the Employee post-processing. Group by original schema:

1. Person tables (13)
2. HumanResources tables (6) — includes Employee post-processing (org node conversion + drop column)
3. Production tables (25)
4. Purchasing tables (5)
5. Sales tables (19) — includes post-load column drops (AccountNumber, LineTotal, SalesOrderNumber)

### Step 4: Create `db/seed/03_modified_dates.sql`

Update `modified_date` on every table with business-meaningful dates.

**Strategy by table:**

```sql
-- =============================================
-- TRANSACTIONAL: Use own business dates
-- =============================================

-- Sales orders: use order_date
UPDATE das.aw__sales__sales_order_header
SET modified_date = order_date;

-- Sales order details: use parent order's order_date
UPDATE das.aw__sales__sales_order_detail d
SET modified_date = h.order_date
FROM das.aw__sales__sales_order_header h
WHERE d.sales_order_id = h.sales_order_id;

-- Sales order header sales reason: use parent order's order_date
UPDATE das.aw__sales__sales_order_header_sales_reason r
SET modified_date = h.order_date
FROM das.aw__sales__sales_order_header h
WHERE r.sales_order_id = h.sales_order_id;

-- Purchase orders: use order_date
UPDATE das.aw__purchasing__purchase_order_header
SET modified_date = order_date;

-- Purchase order details: use parent order's order_date
UPDATE das.aw__purchasing__purchase_order_detail d
SET modified_date = h.order_date
FROM das.aw__purchasing__purchase_order_header h
WHERE d.purchase_order_id = h.purchase_order_id;

-- Transaction history: use transaction_date
UPDATE das.aw__production__transaction_history
SET modified_date = transaction_date;

-- Transaction history archive: use transaction_date
UPDATE das.aw__production__transaction_history_archive
SET modified_date = transaction_date;

-- Currency rate: use currency_rate_date
UPDATE das.aw__sales__currency_rate
SET modified_date = currency_rate_date;

-- Shopping cart item: use date_created
UPDATE das.aw__sales__shopping_cart_item
SET modified_date = date_created;

-- Work order: use start_date
UPDATE das.aw__production__work_order
SET modified_date = start_date;

-- Work order routing: use scheduled_start_date
UPDATE das.aw__production__work_order_routing
SET modified_date = scheduled_start_date;

-- Bill of materials: use start_date
UPDATE das.aw__production__bill_of_materials
SET modified_date = start_date;

-- =============================================
-- HISTORY TABLES: Use own temporal columns
-- =============================================

-- Employee department history: use start_date
UPDATE das.aw__human_resources__employee_department_history
SET modified_date = start_date;

-- Employee pay history: use rate_change_date
UPDATE das.aw__human_resources__employee_pay_history
SET modified_date = rate_change_date;

-- Product cost history: use start_date
UPDATE das.aw__production__product_cost_history
SET modified_date = start_date;

-- Product list price history: use start_date
UPDATE das.aw__production__product_list_price_history
SET modified_date = start_date;

-- Sales territory history: use start_date
UPDATE das.aw__sales__sales_territory_history
SET modified_date = start_date;

-- Sales person quota history: use quota_date
UPDATE das.aw__sales__sales_person_quota_history
SET modified_date = quota_date;

-- =============================================
-- PRODUCT/CATALOG: Lead time before sell start
-- =============================================

-- Product: sell_start_date minus 30 days
UPDATE das.aw__production__product
SET modified_date = sell_start_date - INTERVAL '30 days';

-- Product review: use review_date
UPDATE das.aw__production__product_review
SET modified_date = review_date;

-- Product model: earliest related product's modified_date minus 7 days
UPDATE das.aw__production__product_model pm
SET modified_date = sub.earliest - INTERVAL '7 days'
FROM (
  SELECT product_model_id, MIN(modified_date) AS earliest
  FROM das.aw__production__product
  WHERE product_model_id IS NOT NULL
  GROUP BY product_model_id
) sub
WHERE pm.product_model_id = sub.product_model_id;

-- Product subcategory: earliest related product's modified_date minus 7 days
UPDATE das.aw__production__product_subcategory ps
SET modified_date = sub.earliest - INTERVAL '7 days'
FROM (
  SELECT product_subcategory_id, MIN(modified_date) AS earliest
  FROM das.aw__production__product
  WHERE product_subcategory_id IS NOT NULL
  GROUP BY product_subcategory_id
) sub
WHERE ps.product_subcategory_id = sub.product_subcategory_id;

-- Product category: earliest related subcategory's modified_date minus 7 days
UPDATE das.aw__production__product_category pc
SET modified_date = sub.earliest - INTERVAL '7 days'
FROM (
  SELECT product_category_id, MIN(modified_date) AS earliest
  FROM das.aw__production__product_subcategory
  GROUP BY product_category_id
) sub
WHERE pc.product_category_id = sub.product_category_id;

-- Product description: earliest related product model's modified_date
UPDATE das.aw__production__product_description pd
SET modified_date = sub.earliest
FROM (
  SELECT pmpdc.product_description_id, MIN(pm.modified_date) AS earliest
  FROM das.aw__production__product_model_product_description_culture pmpdc
  JOIN das.aw__production__product_model pm ON pm.product_model_id = pmpdc.product_model_id
  GROUP BY pmpdc.product_description_id
) sub
WHERE pd.product_description_id = sub.product_description_id;

-- Product inventory: related product's modified_date
UPDATE das.aw__production__product_inventory pi
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE pi.product_id = p.product_id;

-- Product document: related product's modified_date
UPDATE das.aw__production__product_document pd
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE pd.product_id = p.product_id;

-- Product product photo: related product's modified_date
UPDATE das.aw__production__product_product_photo ppp
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE ppp.product_id = p.product_id;

-- Product photo: earliest related product's modified_date
UPDATE das.aw__production__product_photo pp
SET modified_date = sub.earliest
FROM (
  SELECT product_photo_id, MIN(p.modified_date) AS earliest
  FROM das.aw__production__product_product_photo ppp
  JOIN das.aw__production__product p ON p.product_id = ppp.product_id
  GROUP BY product_photo_id
) sub
WHERE pp.product_photo_id = sub.product_photo_id;

-- Product model illustration: related product model's modified_date
UPDATE das.aw__production__product_model_illustration pmi
SET modified_date = pm.modified_date
FROM das.aw__production__product_model pm
WHERE pmi.product_model_id = pm.product_model_id;

-- Product model product description culture: related product model's modified_date
UPDATE das.aw__production__product_model_product_description_culture pmpdc
SET modified_date = pm.modified_date
FROM das.aw__production__product_model pm
WHERE pmpdc.product_model_id = pm.product_model_id;

-- Illustration: earliest related product model's modified_date
UPDATE das.aw__production__illustration i
SET modified_date = sub.earliest
FROM (
  SELECT illustration_id, MIN(pm.modified_date) AS earliest
  FROM das.aw__production__product_model_illustration pmi
  JOIN das.aw__production__product_model pm ON pm.product_model_id = pmi.product_model_id
  GROUP BY illustration_id
) sub
WHERE i.illustration_id = sub.illustration_id;

-- Document: earliest related product's modified_date
UPDATE das.aw__production__document d
SET modified_date = sub.earliest
FROM (
  SELECT document_node, MIN(p.modified_date) AS earliest
  FROM das.aw__production__product_document pd
  JOIN das.aw__production__product p ON p.product_id = pd.product_id
  GROUP BY document_node
) sub
WHERE d.document_node = sub.document_node;

-- Special offer: use start_date
UPDATE das.aw__sales__special_offer
SET modified_date = start_date;

-- Special offer product: related special offer's modified_date
UPDATE das.aw__sales__special_offer_product sop
SET modified_date = so.modified_date
FROM das.aw__sales__special_offer so
WHERE sop.special_offer_id = so.special_offer_id;

-- Product vendor: related product's modified_date
UPDATE das.aw__purchasing__product_vendor pv
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE pv.product_id = p.product_id;

-- =============================================
-- ENTITY TABLES: Derive from related data
-- =============================================

-- Employee: use hire_date
UPDATE das.aw__human_resources__employee
SET modified_date = hire_date;

-- Customer: first sales order's order_date
UPDATE das.aw__sales__customer c
SET modified_date = sub.first_order
FROM (
  SELECT customer_id, MIN(order_date) AS first_order
  FROM das.aw__sales__sales_order_header
  GROUP BY customer_id
) sub
WHERE c.customer_id = sub.customer_id;

-- Store: earliest related customer's modified_date
UPDATE das.aw__sales__store s
SET modified_date = sub.earliest
FROM (
  SELECT store_id, MIN(modified_date) AS earliest
  FROM das.aw__sales__customer
  WHERE store_id IS NOT NULL
  GROUP BY store_id
) sub
WHERE s.business_entity_id = sub.store_id;

-- Sales person: hire_date from employee
UPDATE das.aw__sales__sales_person sp
SET modified_date = e.hire_date
FROM das.aw__human_resources__employee e
WHERE sp.business_entity_id = e.business_entity_id;

-- Vendor: earliest related purchase order's order_date
UPDATE das.aw__purchasing__vendor v
SET modified_date = sub.earliest
FROM (
  SELECT vendor_id, MIN(order_date) AS earliest
  FROM das.aw__purchasing__purchase_order_header
  GROUP BY vendor_id
) sub
WHERE v.business_entity_id = sub.vendor_id;

-- Person: depends on person_type
--   Employees (EM): hire_date
--   Sales contacts (SP, SC): earliest related customer/store date
--   Individual customers (IN): their customer record's modified_date
--   General/vendor contacts (VC, GC): earliest related business entity date
UPDATE das.aw__person__person p
SET modified_date = e.hire_date
FROM das.aw__human_resources__employee e
WHERE p.business_entity_id = e.business_entity_id;

UPDATE das.aw__person__person p
SET modified_date = c.modified_date
FROM das.aw__sales__customer c
WHERE c.person_id = p.business_entity_id
  AND p.modified_date = (SELECT MAX(modified_date) FROM das.aw__person__person);
-- Only update those not already set by employee join

-- Business entity: copy from person's modified_date where available
UPDATE das.aw__person__business_entity be
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE be.business_entity_id = p.business_entity_id;

-- Address: earliest related business entity's modified_date
UPDATE das.aw__person__address a
SET modified_date = sub.earliest
FROM (
  SELECT address_id, MIN(be.modified_date) AS earliest
  FROM das.aw__person__business_entity_address bea
  JOIN das.aw__person__business_entity be ON be.business_entity_id = bea.business_entity_id
  GROUP BY address_id
) sub
WHERE a.address_id = sub.address_id;

-- Business entity address: related business entity's modified_date
UPDATE das.aw__person__business_entity_address bea
SET modified_date = be.modified_date
FROM das.aw__person__business_entity be
WHERE bea.business_entity_id = be.business_entity_id;

-- Business entity contact: related business entity's modified_date
UPDATE das.aw__person__business_entity_contact bec
SET modified_date = be.modified_date
FROM das.aw__person__business_entity be
WHERE bec.business_entity_id = be.business_entity_id;

-- Email address: related person's modified_date
UPDATE das.aw__person__email_address ea
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE ea.business_entity_id = p.business_entity_id;

-- Password: related person's modified_date
UPDATE das.aw__person__password pw
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE pw.business_entity_id = p.business_entity_id;

-- Person phone: related person's modified_date
UPDATE das.aw__person__person_phone pp
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE pp.business_entity_id = p.business_entity_id;

-- Person credit card: related person's modified_date
UPDATE das.aw__sales__person_credit_card pcc
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE pcc.business_entity_id = p.business_entity_id;

-- Credit card: earliest related person credit card's modified_date
UPDATE das.aw__sales__credit_card cc
SET modified_date = sub.earliest
FROM (
  SELECT credit_card_id, MIN(modified_date) AS earliest
  FROM das.aw__sales__person_credit_card
  GROUP BY credit_card_id
) sub
WHERE cc.credit_card_id = sub.credit_card_id;

-- Job candidate: related employee's hire_date, or system epoch if no employee link
UPDATE das.aw__human_resources__job_candidate jc
SET modified_date = e.hire_date - INTERVAL '60 days'
FROM das.aw__human_resources__employee e
WHERE jc.business_entity_id = e.business_entity_id;

-- =============================================
-- REFERENCE/LOOKUP: System epoch
-- =============================================
-- Set to the earliest order_date across all sales orders (system go-live)

-- First, compute the epoch
DO $$
DECLARE
  epoch TIMESTAMP;
BEGIN
  SELECT MIN(order_date) INTO epoch
  FROM das.aw__sales__sales_order_header;

  -- Tables with no business date relationship
  UPDATE das.aw__person__address_type SET modified_date = epoch;
  UPDATE das.aw__person__contact_type SET modified_date = epoch;
  UPDATE das.aw__person__country_region SET modified_date = epoch;
  UPDATE das.aw__person__phone_number_type SET modified_date = epoch;
  UPDATE das.aw__person__state_province SET modified_date = epoch;
  UPDATE das.aw__human_resources__department SET modified_date = epoch;
  UPDATE das.aw__human_resources__shift SET modified_date = epoch;
  UPDATE das.aw__production__culture SET modified_date = epoch;
  UPDATE das.aw__production__location SET modified_date = epoch;
  UPDATE das.aw__production__scrap_reason SET modified_date = epoch;
  UPDATE das.aw__production__unit_measure SET modified_date = epoch;
  UPDATE das.aw__purchasing__ship_method SET modified_date = epoch;
  UPDATE das.aw__sales__country_region_currency SET modified_date = epoch;
  UPDATE das.aw__sales__currency SET modified_date = epoch;
  UPDATE das.aw__sales__sales_reason SET modified_date = epoch;
  UPDATE das.aw__sales__sales_tax_rate SET modified_date = epoch;
  UPDATE das.aw__sales__sales_territory SET modified_date = epoch;
END $$;
```

### Step 5: Add `db/seed/data/` to `.gitignore`

The CSV files are large and downloaded from a public repo. Do not commit them. Add a download instruction to the Makefile instead.

Add to `.gitignore`:
```
db/seed/data/
```

Update Makefile to add a `seed` target:
```makefile
.PHONY: up down clean restart seed

seed:
	@mkdir -p db/seed/data
	@echo "Downloading Adventure Works CSVs..."
	@cd db/seed/data && \
	for file in $$(gh api repos/NorfolkDataSci/adventure-works-postgres/contents/data --jq '.[].name'); do \
		echo "  $$file"; \
		curl -sL "https://raw.githubusercontent.com/NorfolkDataSci/adventure-works-postgres/master/data/$$file" -o "$$file"; \
	done
	@echo "Done."

up: seed
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v

restart: clean up
```

### Step 6: Commit

```bash
git add db/seed/01_schema.sql db/seed/02_load.sql db/seed/03_modified_dates.sql .gitignore
git commit -m "feat: add adventure works seed scripts with snake_case and modified_date logic

Create three-stage SQL pipeline for auto-seeding customerdb:
- 01_schema.sql: das schema with aw__* prefixed tables in snake_case
- 02_load.sql: CSV loading from NorfolkDataSci adventure-works-postgres
- 03_modified_dates.sql: business-meaningful modified_date for all 68 tables"
```

### Step 7: Push and open PR

```bash
git push -u origin feat/seed-script
gh pr create --base epic/aw-source-setup --title "feat: add adventure works seed scripts" --body "$(cat <<'EOF'
## Summary
- Create `db/seed/01_schema.sql` with all 68 tables in `das` schema using `aw__<schema>__<table>` naming
- Create `db/seed/02_load.sql` to load CSVs from NorfolkDataSci/adventure-works-postgres
- Create `db/seed/03_modified_dates.sql` with business-meaningful dates for all tables
- Add `seed` target to Makefile for CSV download
- Add `db/seed/data/` to `.gitignore`

## Test plan
- [ ] `make up` downloads CSVs and starts containers
- [ ] All 68 tables created in `das` schema with correct naming
- [ ] All CSVs loaded successfully
- [ ] `modified_date` values reflect business dates, not import timestamps
- [ ] `make clean && make up` does a full reset and re-seed

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Execution Order

1. **Task 1** and **Task 2** can be executed in parallel (independent branches)
2. Both PRs target `epic/aw-source-setup`
3. After both PRs merge to epic, open a PR from `epic/aw-source-setup` → `main`

## Verification

After both branches are merged to the epic:
```bash
make up
# Wait for containers to be healthy
docker exec aw-customerdb psql -U dev -d customerdb -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'das' ORDER BY table_name;"
# Should show 68 tables
docker exec aw-customerdb psql -U dev -d customerdb -c "SELECT modified_date, order_date FROM das.aw__sales__sales_order_header LIMIT 5;"
# modified_date should equal order_date
```
