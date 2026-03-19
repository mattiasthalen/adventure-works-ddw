# Entity Mappings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create DMDL mapping files for all 14 model entities, connecting them to source tables in the `das` schema.

**Architecture:** Each entity gets one mapping YAML file in `mappings/`. All use the `dev` connection, FULL ingestion, and `modified_date` as the effective timestamp. The model is updated to comment out 5 denormalized attributes and 2 bridge-table relationships that cannot be mapped with direct column references.

**Tech Stack:** DMDL mapping YAML, daana-cli for validation, PostgreSQL source (das schema)

**Design spec:** `docs/superpower/specs/2026-03-20-entity-mappings-design.md`

**Worktree:** `.worktrees/feat-entity-mappings` on branch `feat/entity-mappings`

---

## Task 1: Comment out unsupported model elements

**Files:**
- Modify: `model.yaml`

**Step 1: Comment out 5 denormalized attributes**

In `model.yaml`, comment out these attribute blocks (each is a `- id:` block with all its fields):

- ADDRESS entity: `ADDRESS_STATE_PROVINCE_NAME` (lines ~89-95) and `ADDRESS_COUNTRY_REGION_NAME` (lines ~97-101)
- PRODUCT entity: `PRODUCT_SUBCATEGORY_NAME` (lines ~292-297), `PRODUCT_CATEGORY_NAME` (lines ~299-304), `PRODUCT_MODEL_NAME` (lines ~306-311)

Use YAML comment syntax — prefix each line with `# `.

**Step 2: Comment out 2 bridge-table relationships**

In `model.yaml`, comment out these relationship blocks:

- `PERSON_RESIDES_AT_ADDRESS` (lines ~689-693)
- `EMPLOYEE_BELONGS_TO_DEPARTMENT` (lines ~695-699)

**Step 3: Validate model still parses**

Run: `daana-cli check workflow --no-tui`
Expected: `✓ Workflow valid` (with unmapped entity warnings — that's fine)

**Step 4: Commit**

```bash
git add model.yaml
git commit -m "chore: comment out denormalized attrs and bridge-table rels

Temporarily disable 5 attributes requiring lookup joins and 2
relationships requiring bridge tables until mapping approach decided."
```

---

## Task 2: Create mapping files — Person domain (PERSON, ADDRESS)

These are independent entities with no outbound relationships (after commenting out bridge rels).

**Files:**
- Create: `mappings/person-mapping.yaml`
- Create: `mappings/address-mapping.yaml`

**Step 1: Create mappings directory**

```bash
mkdir -p mappings
```

**Step 2: Write person-mapping.yaml**

```yaml
entity_id: "PERSON"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__person__person"

        primary_keys:
          - business_entity_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "PERSON_TYPE"
            transformation_expression: "person_type"

          - id: "PERSON_TITLE"
            transformation_expression: "title"

          - id: "PERSON_FIRST_NAME"
            transformation_expression: "first_name"

          - id: "PERSON_MIDDLE_NAME"
            transformation_expression: "middle_name"

          - id: "PERSON_LAST_NAME"
            transformation_expression: "last_name"

          - id: "PERSON_SUFFIX"
            transformation_expression: "suffix"

          - id: "PERSON_EMAIL_PROMOTION"
            transformation_expression: "email_promotion"
```

**Step 3: Write address-mapping.yaml**

```yaml
entity_id: "ADDRESS"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__person__address"

        primary_keys:
          - address_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "ADDRESS_LINE_1"
            transformation_expression: "address_line_1"

          - id: "ADDRESS_LINE_2"
            transformation_expression: "address_line_2"

          - id: "ADDRESS_CITY"
            transformation_expression: "city"

          - id: "ADDRESS_POSTAL_CODE"
            transformation_expression: "postal_code"
```

**Step 4: Commit**

```bash
git add mappings/person-mapping.yaml mappings/address-mapping.yaml
git commit -m "feat: add PERSON and ADDRESS mapping files"
```

---

## Task 3: Create mapping files — HR domain (EMPLOYEE, DEPARTMENT)

EMPLOYEE has a relationship to PERSON. DEPARTMENT is disconnected (no relationships).

**Files:**
- Create: `mappings/employee-mapping.yaml`
- Create: `mappings/department-mapping.yaml`

**Step 1: Write employee-mapping.yaml**

```yaml
entity_id: "EMPLOYEE"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__human_resources__employee"

        primary_keys:
          - business_entity_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "EMPLOYEE_NATIONAL_ID_NUMBER"
            transformation_expression: "national_id_number"

          - id: "EMPLOYEE_LOGIN_ID"
            transformation_expression: "login_id"

          - id: "EMPLOYEE_JOB_TITLE"
            transformation_expression: "job_title"

          - id: "EMPLOYEE_MARITAL_STATUS"
            transformation_expression: "marital_status"

          - id: "EMPLOYEE_GENDER"
            transformation_expression: "gender"

          - id: "EMPLOYEE_SALARIED_FLAG"
            transformation_expression: "salaried_flag"

          - id: "EMPLOYEE_VACATION_HOURS"
            transformation_expression: "vacation_hours"

          - id: "EMPLOYEE_SICK_LEAVE_HOURS"
            transformation_expression: "sick_leave_hours"

          - id: "EMPLOYEE_CURRENT_FLAG"
            transformation_expression: "current_flag"

          - id: "EMPLOYEE_BIRTH_DATE"
            transformation_expression: "birth_date"

          - id: "EMPLOYEE_HIRE_DATE"
            transformation_expression: "hire_date"

    relationships:
      - id: "EMPLOYEE_EMPLOYEE_IS_A_PERSON_PERSON"
        source_table: "das.aw__human_resources__employee"
        target_transformation_expression: "business_entity_id"
```

**Step 2: Write department-mapping.yaml**

```yaml
entity_id: "DEPARTMENT"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__human_resources__department"

        primary_keys:
          - department_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "DEPARTMENT_NAME"
            transformation_expression: "name"

          - id: "DEPARTMENT_GROUP_NAME"
            transformation_expression: "group_name"
```

**Step 3: Commit**

```bash
git add mappings/employee-mapping.yaml mappings/department-mapping.yaml
git commit -m "feat: add EMPLOYEE and DEPARTMENT mapping files"
```

---

## Task 4: Create mapping files — Production domain (PRODUCT, WORK_ORDER)

WORK_ORDER has a relationship to PRODUCT.

**Files:**
- Create: `mappings/product-mapping.yaml`
- Create: `mappings/work_order-mapping.yaml`

**Step 1: Write product-mapping.yaml**

```yaml
entity_id: "PRODUCT"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__production__product"

        primary_keys:
          - product_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "PRODUCT_NAME"
            transformation_expression: "name"

          - id: "PRODUCT_NUMBER"
            transformation_expression: "product_number"

          - id: "PRODUCT_MAKE_FLAG"
            transformation_expression: "make_flag"

          - id: "PRODUCT_FINISHED_GOODS_FLAG"
            transformation_expression: "finished_goods_flag"

          - id: "PRODUCT_COLOR"
            transformation_expression: "color"

          - id: "PRODUCT_SAFETY_STOCK_LEVEL"
            transformation_expression: "safety_stock_level"

          - id: "PRODUCT_REORDER_POINT"
            transformation_expression: "reorder_point"

          - id: "PRODUCT_STANDARD_COST"
            transformation_expression: "standard_cost"

          - id: "PRODUCT_LIST_PRICE"
            transformation_expression: "list_price"

          - id: "PRODUCT_SIZE"
            transformation_expression: "size"

          - id: "PRODUCT_WEIGHT"
            transformation_expression: "weight"

          - id: "PRODUCT_DAYS_TO_MANUFACTURE"
            transformation_expression: "days_to_manufacture"

          - id: "PRODUCT_LINE"
            transformation_expression: "product_line"

          - id: "PRODUCT_CLASS"
            transformation_expression: "class"

          - id: "PRODUCT_STYLE"
            transformation_expression: "style"

          - id: "PRODUCT_SELL_START_DATE"
            transformation_expression: "sell_start_date"

          - id: "PRODUCT_SELL_END_DATE"
            transformation_expression: "sell_end_date"

          - id: "PRODUCT_DISCONTINUED_DATE"
            transformation_expression: "discontinued_date"
```

**Step 2: Write work_order-mapping.yaml**

```yaml
entity_id: "WORK_ORDER"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__production__work_order"

        primary_keys:
          - work_order_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "WORK_ORDER_ORDER_QTY"
            transformation_expression: "order_qty"

          - id: "WORK_ORDER_SCRAPPED_QTY"
            transformation_expression: "scrapped_qty"

          - id: "WORK_ORDER_START_DATE"
            transformation_expression: "start_date"

          - id: "WORK_ORDER_END_DATE"
            transformation_expression: "end_date"

          - id: "WORK_ORDER_DUE_DATE"
            transformation_expression: "due_date"

    relationships:
      - id: "WORK_ORDER_WORK_ORDER_IS_FOR_PRODUCT_PRODUCT"
        source_table: "das.aw__production__work_order"
        target_transformation_expression: "product_id"
```

**Step 3: Commit**

```bash
git add mappings/product-mapping.yaml mappings/work_order-mapping.yaml
git commit -m "feat: add PRODUCT and WORK_ORDER mapping files"
```

---

## Task 5: Create mapping files — Purchasing domain (VENDOR, PURCHASE_ORDER)

VENDOR links to PERSON. PURCHASE_ORDER links to VENDOR and EMPLOYEE.

**Files:**
- Create: `mappings/vendor-mapping.yaml`
- Create: `mappings/purchase_order-mapping.yaml`

**Step 1: Write vendor-mapping.yaml**

```yaml
entity_id: "VENDOR"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__purchasing__vendor"

        primary_keys:
          - business_entity_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "VENDOR_ACCOUNT_NUMBER"
            transformation_expression: "account_number"

          - id: "VENDOR_NAME"
            transformation_expression: "name"

          - id: "VENDOR_CREDIT_RATING"
            transformation_expression: "credit_rating"

          - id: "VENDOR_PREFERRED_STATUS"
            transformation_expression: "preferred_vendor_status"

          - id: "VENDOR_ACTIVE_FLAG"
            transformation_expression: "active_flag"

    relationships:
      - id: "VENDOR_VENDOR_IS_A_BUSINESS_ENTITY_PERSON"
        source_table: "das.aw__purchasing__vendor"
        target_transformation_expression: "business_entity_id"
```

**Step 2: Write purchase_order-mapping.yaml**

```yaml
entity_id: "PURCHASE_ORDER"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__purchasing__purchase_order_header"

        primary_keys:
          - purchase_order_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "PURCHASE_ORDER_STATUS"
            transformation_expression: "status"

          - id: "PURCHASE_ORDER_REVISION_NUMBER"
            transformation_expression: "revision_number"

          - id: "PURCHASE_ORDER_SUB_TOTAL"
            transformation_expression: "sub_total"

          - id: "PURCHASE_ORDER_TAX_AMT"
            transformation_expression: "tax_amt"

          - id: "PURCHASE_ORDER_FREIGHT"
            transformation_expression: "freight"

          - id: "PURCHASE_ORDER_ORDER_DATE"
            transformation_expression: "order_date"

          - id: "PURCHASE_ORDER_SHIP_DATE"
            transformation_expression: "ship_date"

    relationships:
      - id: "PURCHASE_ORDER_PURCHASE_ORDER_IS_PLACED_WITH_VENDOR_VENDOR"
        source_table: "das.aw__purchasing__purchase_order_header"
        target_transformation_expression: "vendor_id"

      - id: "PURCHASE_ORDER_PURCHASE_ORDER_IS_ORDERED_BY_EMPLOYEE_EMPLOYEE"
        source_table: "das.aw__purchasing__purchase_order_header"
        target_transformation_expression: "employee_id"
```

**Step 3: Commit**

```bash
git add mappings/vendor-mapping.yaml mappings/purchase_order-mapping.yaml
git commit -m "feat: add VENDOR and PURCHASE_ORDER mapping files"
```

---

## Task 6: Create mapping files — Sales foundation (SALES_TERRITORY, SPECIAL_OFFER, STORE, SALES_PERSON)

These are entities that other sales entities reference. STORE and SALES_PERSON have relationships.

**Files:**
- Create: `mappings/sales_territory-mapping.yaml`
- Create: `mappings/special_offer-mapping.yaml`
- Create: `mappings/store-mapping.yaml`
- Create: `mappings/sales_person-mapping.yaml`

**Step 1: Write sales_territory-mapping.yaml**

Note: `group` is a reserved word in SQL; quote it in the transformation expression.

```yaml
entity_id: "SALES_TERRITORY"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__sales_territory"

        primary_keys:
          - territory_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "SALES_TERRITORY_NAME"
            transformation_expression: "name"

          - id: "SALES_TERRITORY_COUNTRY_REGION_CODE"
            transformation_expression: "country_region_code"

          - id: "SALES_TERRITORY_GROUP"
            transformation_expression: "\"group\""
```

**Step 2: Write special_offer-mapping.yaml**

```yaml
entity_id: "SPECIAL_OFFER"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__special_offer"

        primary_keys:
          - special_offer_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "SPECIAL_OFFER_DESCRIPTION"
            transformation_expression: "description"

          - id: "SPECIAL_OFFER_DISCOUNT_PCT"
            transformation_expression: "discount_pct"

          - id: "SPECIAL_OFFER_TYPE"
            transformation_expression: "type"

          - id: "SPECIAL_OFFER_CATEGORY"
            transformation_expression: "category"

          - id: "SPECIAL_OFFER_MIN_QTY"
            transformation_expression: "min_qty"

          - id: "SPECIAL_OFFER_MAX_QTY"
            transformation_expression: "max_qty"

          - id: "SPECIAL_OFFER_START_DATE"
            transformation_expression: "start_date"

          - id: "SPECIAL_OFFER_END_DATE"
            transformation_expression: "end_date"
```

**Step 3: Write store-mapping.yaml**

```yaml
entity_id: "STORE"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__store"

        primary_keys:
          - business_entity_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "STORE_NAME"
            transformation_expression: "name"

    relationships:
      - id: "STORE_STORE_IS_MANAGED_BY_SALES_PERSON_SALES_PERSON"
        source_table: "das.aw__sales__store"
        target_transformation_expression: "sales_person_id"
```

**Step 4: Write sales_person-mapping.yaml**

```yaml
entity_id: "SALES_PERSON"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__sales_person"

        primary_keys:
          - business_entity_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "SALES_PERSON_SALES_QUOTA"
            transformation_expression: "sales_quota"

          - id: "SALES_PERSON_BONUS"
            transformation_expression: "bonus"

          - id: "SALES_PERSON_COMMISSION_PCT"
            transformation_expression: "commission_pct"

          - id: "SALES_PERSON_SALES_YTD"
            transformation_expression: "sales_ytd"

          - id: "SALES_PERSON_SALES_LAST_YEAR"
            transformation_expression: "sales_last_year"

    relationships:
      - id: "SALES_PERSON_SALES_PERSON_IS_AN_EMPLOYEE_EMPLOYEE"
        source_table: "das.aw__sales__sales_person"
        target_transformation_expression: "business_entity_id"

      - id: "SALES_PERSON_SALES_PERSON_BELONGS_TO_SALES_TERRITORY_SALES_TERRITORY"
        source_table: "das.aw__sales__sales_person"
        target_transformation_expression: "territory_id"
```

**Step 5: Commit**

```bash
git add mappings/sales_territory-mapping.yaml mappings/special_offer-mapping.yaml mappings/store-mapping.yaml mappings/sales_person-mapping.yaml
git commit -m "feat: add SALES_TERRITORY, SPECIAL_OFFER, STORE, and SALES_PERSON mapping files"
```

---

## Task 7: Create mapping files — Sales transactions (CUSTOMER, SALES_ORDER, SALES_ORDER_DETAIL)

CUSTOMER has a derived attribute and 3 relationships. SALES_ORDER has 5 relationships. SALES_ORDER_DETAIL has 3 relationships.

**Files:**
- Create: `mappings/customer-mapping.yaml`
- Create: `mappings/sales_order-mapping.yaml`
- Create: `mappings/sales_order_detail-mapping.yaml`

**Step 1: Write customer-mapping.yaml**

Note: `CUSTOMER_ACCOUNT_NUMBER` is derived — no source column exists. Use: `'AW' || LPAD(CAST(customer_id AS VARCHAR), 8, '0')`

```yaml
entity_id: "CUSTOMER"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__customer"

        primary_keys:
          - customer_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "CUSTOMER_ACCOUNT_NUMBER"
            transformation_expression: "'AW' || LPAD(CAST(customer_id AS VARCHAR), 8, '0')"

    relationships:
      - id: "CUSTOMER_CUSTOMER_REFERS_TO_PERSON_PERSON"
        source_table: "das.aw__sales__customer"
        target_transformation_expression: "person_id"

      - id: "CUSTOMER_CUSTOMER_REFERS_TO_STORE_STORE"
        source_table: "das.aw__sales__customer"
        target_transformation_expression: "store_id"

      - id: "CUSTOMER_CUSTOMER_BELONGS_TO_SALES_TERRITORY_SALES_TERRITORY"
        source_table: "das.aw__sales__customer"
        target_transformation_expression: "territory_id"
```

**Step 2: Write sales_order-mapping.yaml**

```yaml
entity_id: "SALES_ORDER"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__sales_order_header"

        primary_keys:
          - sales_order_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "SALES_ORDER_STATUS"
            transformation_expression: "status"

          - id: "SALES_ORDER_ONLINE_ORDER_FLAG"
            transformation_expression: "online_order_flag"

          - id: "SALES_ORDER_PURCHASE_ORDER_NUMBER"
            transformation_expression: "purchase_order_number"

          - id: "SALES_ORDER_ACCOUNT_NUMBER"
            transformation_expression: "account_number"

          - id: "SALES_ORDER_SUB_TOTAL"
            transformation_expression: "sub_total"

          - id: "SALES_ORDER_TAX_AMT"
            transformation_expression: "tax_amt"

          - id: "SALES_ORDER_FREIGHT"
            transformation_expression: "freight"

          - id: "SALES_ORDER_COMMENT"
            transformation_expression: "comment"

          - id: "SALES_ORDER_ORDER_DATE"
            transformation_expression: "order_date"

          - id: "SALES_ORDER_DUE_DATE"
            transformation_expression: "due_date"

          - id: "SALES_ORDER_SHIP_DATE"
            transformation_expression: "ship_date"

    relationships:
      - id: "SALES_ORDER_SALES_ORDER_IS_PLACED_BY_CUSTOMER_CUSTOMER"
        source_table: "das.aw__sales__sales_order_header"
        target_transformation_expression: "customer_id"

      - id: "SALES_ORDER_SALES_ORDER_IS_SOLD_BY_SALES_PERSON_SALES_PERSON"
        source_table: "das.aw__sales__sales_order_header"
        target_transformation_expression: "sales_person_id"

      - id: "SALES_ORDER_SALES_ORDER_BELONGS_TO_SALES_TERRITORY_SALES_TERRITORY"
        source_table: "das.aw__sales__sales_order_header"
        target_transformation_expression: "territory_id"

      - id: "SALES_ORDER_SALES_ORDER_IS_BILLED_TO_ADDRESS_ADDRESS"
        source_table: "das.aw__sales__sales_order_header"
        target_transformation_expression: "bill_to_address_id"

      - id: "SALES_ORDER_SALES_ORDER_IS_SHIPPED_TO_ADDRESS_ADDRESS"
        source_table: "das.aw__sales__sales_order_header"
        target_transformation_expression: "ship_to_address_id"
```

**Step 3: Write sales_order_detail-mapping.yaml**

```yaml
entity_id: "SALES_ORDER_DETAIL"

mapping_groups:
  - name: "default_mapping_group"
    allow_multiple_identifiers: false

    tables:
      - connection: "dev"
        table: "das.aw__sales__sales_order_detail"

        primary_keys:
          - sales_order_detail_id

        ingestion_strategy: FULL

        entity_effective_timestamp_expression: "modified_date"

        attributes:
          - id: "SALES_ORDER_DETAIL_CARRIER_TRACKING_NUMBER"
            transformation_expression: "carrier_tracking_number"

          - id: "SALES_ORDER_DETAIL_ORDER_QTY"
            transformation_expression: "order_qty"

          - id: "SALES_ORDER_DETAIL_UNIT_PRICE"
            transformation_expression: "unit_price"

          - id: "SALES_ORDER_DETAIL_UNIT_PRICE_DISCOUNT"
            transformation_expression: "unit_price_discount"

    relationships:
      - id: "SALES_ORDER_DETAIL_SALES_ORDER_DETAIL_BELONGS_TO_SALES_ORDER_SALES_ORDER"
        source_table: "das.aw__sales__sales_order_detail"
        target_transformation_expression: "sales_order_id"

      - id: "SALES_ORDER_DETAIL_SALES_ORDER_DETAIL_REFERS_TO_PRODUCT_PRODUCT"
        source_table: "das.aw__sales__sales_order_detail"
        target_transformation_expression: "product_id"

      - id: "SALES_ORDER_DETAIL_SALES_ORDER_DETAIL_HAS_APPLIED_SPECIAL_OFFER_SPECIAL_OFFER"
        source_table: "das.aw__sales__sales_order_detail"
        target_transformation_expression: "special_offer_id"
```

**Step 4: Commit**

```bash
git add mappings/customer-mapping.yaml mappings/sales_order-mapping.yaml mappings/sales_order_detail-mapping.yaml
git commit -m "feat: add CUSTOMER, SALES_ORDER, and SALES_ORDER_DETAIL mapping files"
```

---

## Task 8: Update workflow and validate

Register all mapping files in `workflow.yaml` and run full validation.

**Files:**
- Modify: `workflow.yaml`

**Step 1: Update workflow.yaml mappings array**

Replace the empty `mappings: []` with a list of all 14 mapping file paths:

```yaml
  mappings:
    - "mappings/person-mapping.yaml"
    - "mappings/address-mapping.yaml"
    - "mappings/employee-mapping.yaml"
    - "mappings/department-mapping.yaml"
    - "mappings/product-mapping.yaml"
    - "mappings/work_order-mapping.yaml"
    - "mappings/vendor-mapping.yaml"
    - "mappings/purchase_order-mapping.yaml"
    - "mappings/customer-mapping.yaml"
    - "mappings/store-mapping.yaml"
    - "mappings/sales_person-mapping.yaml"
    - "mappings/sales_territory-mapping.yaml"
    - "mappings/sales_order-mapping.yaml"
    - "mappings/sales_order_detail-mapping.yaml"
    - "mappings/special_offer-mapping.yaml"
```

Also remove the now-stale comment block below `mappings:` that says "Mappings will be generated with...".

**Step 2: Run full validation**

Run: `daana-cli check workflow --no-tui`
Expected: All 14 entities show `mapped ✓`, zero errors. Only warnings should be connection profile warnings (hardcoded password, sslmode).

**Step 3: Commit**

```bash
git add workflow.yaml
git commit -m "feat: register all 14 mapping files in workflow"
```

---

## Task 9: Push branch

**Step 1: Push**

```bash
git push -u origin feat/entity-mappings
```

---

## Parallelization

Tasks 2-7 (mapping files by domain) are independent and can be executed in parallel by separate agents. Task 1 (model changes) must complete first. Task 8 (workflow update + validation) must run after all mapping files are created. Task 9 runs last.

```
Task 1 (model changes)
  ├── Task 2 (Person domain)
  ├── Task 3 (HR domain)
  ├── Task 4 (Production domain)
  ├── Task 5 (Purchasing domain)
  ├── Task 6 (Sales foundation)
  └── Task 7 (Sales transactions)
       └── Task 8 (workflow + validate)
            └── Task 9 (push)
```
