# Adventure Works Data Model Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite `model.yaml` with 14 entities and 21 relationships covering the full Adventure Works enterprise.

**Architecture:** Single `model.yaml` file following DMDL schema. Entities are built domain by domain (Person, HR, Production, Purchasing, Sales), with all relationships added at the end. Each task validates with `daana-cli check model model.yaml`.

**Tech Stack:** DMDL YAML, daana-cli

**References:**
- Design doc: `docs/plans/2026-03-19-aw-data-model-design.md`
- DMDL schema rules: `/home/mattiasthalen/.claude/plugins/cache/daana-modeler/daana/1.1.0/references/model-schema.md`
- DMDL examples: `/home/mattiasthalen/.claude/plugins/cache/daana-modeler/daana/1.1.0/references/model-examples.md`

**DMDL rules to follow:**
- 2-space indentation
- All `id` and `name` fields set to the same UPPERCASE_WITH_UNDERSCORES value
- Quoted string values for `id`, `name`, `definition`, `description`, `type`, `source_entity_id`, `target_entity_id`
- Boolean values unquoted (`true`, `false`)
- When `effective_timestamp` is `false`, omit the field entirely
- Field ordering: `id`, `name`, `definition`, `description`, then type-specific fields
- Every attribute must have exactly one of `type` or `group`, never both

---

### Task 1: Model metadata + PERSON and ADDRESS entities

**Files:**
- Modify: `model.yaml` (full rewrite)

**Step 1: Write model.yaml with model metadata and Person/Core entities**

```yaml
model:
  id: "ADVENTURE_WORKS_DDW_MODEL"
  name: "ADVENTURE_WORKS_DDW_MODEL"
  definition: "Full enterprise data model for Adventure Works"
  description: "Transforms raw operational data from Person, HR, Production, Purchasing, and Sales domains into clean business entities"

  entities:
    - id: "PERSON"
      name: "PERSON"
      definition: "An individual tracked in the system"
      description: "Represents people across all roles: customers, employees, vendors, and contacts"
      attributes:
        - id: "PERSON_TYPE"
          name: "PERSON_TYPE"
          definition: "Classification of the person"
          description: "Type code: SC (Store Contact), VC (Vendor Contact), IN (Individual), EM (Employee), SP (Sales Person), GC (General Contact)"
          type: "STRING"
          effective_timestamp: true

        - id: "PERSON_TITLE"
          name: "PERSON_TITLE"
          definition: "Courtesy title"
          description: "Title such as Mr., Ms., Dr."
          type: "STRING"
          effective_timestamp: true

        - id: "PERSON_FIRST_NAME"
          name: "PERSON_FIRST_NAME"
          definition: "First name of the person"
          type: "STRING"
          effective_timestamp: true

        - id: "PERSON_MIDDLE_NAME"
          name: "PERSON_MIDDLE_NAME"
          definition: "Middle name of the person"
          type: "STRING"
          effective_timestamp: true

        - id: "PERSON_LAST_NAME"
          name: "PERSON_LAST_NAME"
          definition: "Last name of the person"
          type: "STRING"
          effective_timestamp: true

        - id: "PERSON_SUFFIX"
          name: "PERSON_SUFFIX"
          definition: "Name suffix"
          description: "Suffix such as Jr., Sr., III"
          type: "STRING"
          effective_timestamp: true

        - id: "PERSON_EMAIL_PROMOTION"
          name: "PERSON_EMAIL_PROMOTION"
          definition: "Email promotion preference level"
          description: "0 = no promotions, 1 = from Adventure Works, 2 = from Adventure Works and partners"
          type: "NUMBER"
          effective_timestamp: true

    - id: "ADDRESS"
      name: "ADDRESS"
      definition: "A physical address"
      description: "Represents mailing and shipping addresses with full geographic context"
      attributes:
        - id: "ADDRESS_LINE_1"
          name: "ADDRESS_LINE_1"
          definition: "Primary street address"
          type: "STRING"
          effective_timestamp: true

        - id: "ADDRESS_LINE_2"
          name: "ADDRESS_LINE_2"
          definition: "Secondary address line"
          description: "Apartment, suite, or unit number"
          type: "STRING"
          effective_timestamp: true

        - id: "ADDRESS_CITY"
          name: "ADDRESS_CITY"
          definition: "City name"
          type: "STRING"
          effective_timestamp: true

        - id: "ADDRESS_POSTAL_CODE"
          name: "ADDRESS_POSTAL_CODE"
          definition: "Postal or ZIP code"
          type: "STRING"
          effective_timestamp: true

        - id: "ADDRESS_STATE_PROVINCE_NAME"
          name: "ADDRESS_STATE_PROVINCE_NAME"
          definition: "State or province name"
          description: "Denormalized from state_province and country_region tables"
          type: "STRING"
          effective_timestamp: true

        - id: "ADDRESS_COUNTRY_REGION_NAME"
          name: "ADDRESS_COUNTRY_REGION_NAME"
          definition: "Country or region name"
          description: "Denormalized from country_region table"
          type: "STRING"
          effective_timestamp: true
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS (no errors)

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add PERSON and ADDRESS entities to data model"
```

---

### Task 2: EMPLOYEE and DEPARTMENT entities

**Files:**
- Modify: `model.yaml` (append to entities list)

**Step 1: Append EMPLOYEE and DEPARTMENT entities after ADDRESS**

```yaml
    - id: "EMPLOYEE"
      name: "EMPLOYEE"
      definition: "A person employed by Adventure Works"
      description: "Extends PERSON with employment details like job title, hire date, and leave balances"
      attributes:
        - id: "EMPLOYEE_NATIONAL_ID_NUMBER"
          name: "EMPLOYEE_NATIONAL_ID_NUMBER"
          definition: "Government-issued identification number"
          type: "STRING"

        - id: "EMPLOYEE_LOGIN_ID"
          name: "EMPLOYEE_LOGIN_ID"
          definition: "Network login identifier"
          type: "STRING"
          effective_timestamp: true

        - id: "EMPLOYEE_JOB_TITLE"
          name: "EMPLOYEE_JOB_TITLE"
          definition: "Current job title"
          type: "STRING"
          effective_timestamp: true

        - id: "EMPLOYEE_MARITAL_STATUS"
          name: "EMPLOYEE_MARITAL_STATUS"
          definition: "Marital status code"
          description: "M = Married, S = Single"
          type: "STRING"
          effective_timestamp: true

        - id: "EMPLOYEE_GENDER"
          name: "EMPLOYEE_GENDER"
          definition: "Gender code"
          description: "M = Male, F = Female"
          type: "STRING"
          effective_timestamp: true

        - id: "EMPLOYEE_SALARIED_FLAG"
          name: "EMPLOYEE_SALARIED_FLAG"
          definition: "Whether the employee is salaried"
          description: "true = salaried, false = hourly"
          type: "STRING"
          effective_timestamp: true

        - id: "EMPLOYEE_VACATION_HOURS"
          name: "EMPLOYEE_VACATION_HOURS"
          definition: "Accrued vacation hours"
          type: "NUMBER"
          effective_timestamp: true

        - id: "EMPLOYEE_SICK_LEAVE_HOURS"
          name: "EMPLOYEE_SICK_LEAVE_HOURS"
          definition: "Accrued sick leave hours"
          type: "NUMBER"
          effective_timestamp: true

        - id: "EMPLOYEE_CURRENT_FLAG"
          name: "EMPLOYEE_CURRENT_FLAG"
          definition: "Whether the employee is currently active"
          type: "STRING"
          effective_timestamp: true

        - id: "EMPLOYEE_BIRTH_DATE"
          name: "EMPLOYEE_BIRTH_DATE"
          definition: "Date of birth"
          type: "START_TIMESTAMP"

        - id: "EMPLOYEE_HIRE_DATE"
          name: "EMPLOYEE_HIRE_DATE"
          definition: "Date of hire"
          type: "START_TIMESTAMP"

    - id: "DEPARTMENT"
      name: "DEPARTMENT"
      definition: "An organizational department"
      description: "Represents departments within Adventure Works such as Engineering, Sales, Marketing"
      attributes:
        - id: "DEPARTMENT_NAME"
          name: "DEPARTMENT_NAME"
          definition: "Department name"
          type: "STRING"
          effective_timestamp: true

        - id: "DEPARTMENT_GROUP_NAME"
          name: "DEPARTMENT_GROUP_NAME"
          definition: "Department group classification"
          description: "High-level grouping such as Research and Development, Sales and Marketing"
          type: "STRING"
          effective_timestamp: true
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add EMPLOYEE and DEPARTMENT entities to data model"
```

---

### Task 3: PRODUCT and WORK_ORDER entities

**Files:**
- Modify: `model.yaml` (append to entities list)

**Step 1: Append PRODUCT and WORK_ORDER entities**

```yaml
    - id: "PRODUCT"
      name: "PRODUCT"
      definition: "An item in the product catalog"
      description: "Represents manufactured and purchased products with pricing, sizing, and categorization"
      attributes:
        - id: "PRODUCT_NAME"
          name: "PRODUCT_NAME"
          definition: "Product display name"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_NUMBER"
          name: "PRODUCT_NUMBER"
          definition: "Unique product identification number"
          type: "STRING"

        - id: "PRODUCT_MAKE_FLAG"
          name: "PRODUCT_MAKE_FLAG"
          definition: "Whether the product is manufactured in-house"
          description: "true = manufactured, false = purchased"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_FINISHED_GOODS_FLAG"
          name: "PRODUCT_FINISHED_GOODS_FLAG"
          definition: "Whether the product is sellable"
          description: "true = finished good, false = component or raw material"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_COLOR"
          name: "PRODUCT_COLOR"
          definition: "Product color"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_SAFETY_STOCK_LEVEL"
          name: "PRODUCT_SAFETY_STOCK_LEVEL"
          definition: "Minimum inventory quantity to avoid stockouts"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PRODUCT_REORDER_POINT"
          name: "PRODUCT_REORDER_POINT"
          definition: "Inventory level that triggers a new purchase order"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PRODUCT_STANDARD_COST"
          name: "PRODUCT_STANDARD_COST"
          definition: "Standard manufacturing or acquisition cost"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PRODUCT_LIST_PRICE"
          name: "PRODUCT_LIST_PRICE"
          definition: "Suggested retail price"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PRODUCT_SIZE"
          name: "PRODUCT_SIZE"
          definition: "Product size designation"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_WEIGHT"
          name: "PRODUCT_WEIGHT"
          definition: "Product weight"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PRODUCT_DAYS_TO_MANUFACTURE"
          name: "PRODUCT_DAYS_TO_MANUFACTURE"
          definition: "Number of days required to manufacture"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PRODUCT_LINE"
          name: "PRODUCT_LINE"
          definition: "Product line classification"
          description: "S = Standard, T = Touring, M = Mountain, R = Road"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_CLASS"
          name: "PRODUCT_CLASS"
          definition: "Product class"
          description: "L = Low, M = Medium, H = High"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_STYLE"
          name: "PRODUCT_STYLE"
          definition: "Product style"
          description: "W = Women, M = Men, U = Universal"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_SUBCATEGORY_NAME"
          name: "PRODUCT_SUBCATEGORY_NAME"
          definition: "Product subcategory name"
          description: "Denormalized from product_subcategory table"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_CATEGORY_NAME"
          name: "PRODUCT_CATEGORY_NAME"
          definition: "Product top-level category name"
          description: "Denormalized from product_category table"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_MODEL_NAME"
          name: "PRODUCT_MODEL_NAME"
          definition: "Product model or design template name"
          description: "Denormalized from product_model table"
          type: "STRING"
          effective_timestamp: true

        - id: "PRODUCT_SELL_START_DATE"
          name: "PRODUCT_SELL_START_DATE"
          definition: "Date the product became available for sale"
          type: "START_TIMESTAMP"

        - id: "PRODUCT_SELL_END_DATE"
          name: "PRODUCT_SELL_END_DATE"
          definition: "Date the product was no longer available for sale"
          type: "END_TIMESTAMP"

        - id: "PRODUCT_DISCONTINUED_DATE"
          name: "PRODUCT_DISCONTINUED_DATE"
          definition: "Date the product was discontinued"
          type: "END_TIMESTAMP"

    - id: "WORK_ORDER"
      name: "WORK_ORDER"
      definition: "A manufacturing work order"
      description: "Represents a production run for a specific product with quantity and schedule"
      attributes:
        - id: "WORK_ORDER_ORDER_QTY"
          name: "WORK_ORDER_ORDER_QTY"
          definition: "Quantity ordered for production"
          type: "NUMBER"
          effective_timestamp: true

        - id: "WORK_ORDER_SCRAPPED_QTY"
          name: "WORK_ORDER_SCRAPPED_QTY"
          definition: "Quantity scrapped during production"
          type: "NUMBER"
          effective_timestamp: true

        - id: "WORK_ORDER_START_DATE"
          name: "WORK_ORDER_START_DATE"
          definition: "Planned production start date"
          type: "START_TIMESTAMP"

        - id: "WORK_ORDER_END_DATE"
          name: "WORK_ORDER_END_DATE"
          definition: "Actual production end date"
          type: "END_TIMESTAMP"

        - id: "WORK_ORDER_DUE_DATE"
          name: "WORK_ORDER_DUE_DATE"
          definition: "Date the work order is due"
          type: "END_TIMESTAMP"
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add PRODUCT and WORK_ORDER entities to data model"
```

---

### Task 4: VENDOR and PURCHASE_ORDER entities

**Files:**
- Modify: `model.yaml` (append to entities list)

**Step 1: Append VENDOR and PURCHASE_ORDER entities**

```yaml
    - id: "VENDOR"
      name: "VENDOR"
      definition: "A supplier of products or services"
      description: "Represents vendors that Adventure Works purchases from"
      attributes:
        - id: "VENDOR_ACCOUNT_NUMBER"
          name: "VENDOR_ACCOUNT_NUMBER"
          definition: "Vendor account identifier"
          type: "STRING"

        - id: "VENDOR_NAME"
          name: "VENDOR_NAME"
          definition: "Vendor company name"
          type: "STRING"
          effective_timestamp: true

        - id: "VENDOR_CREDIT_RATING"
          name: "VENDOR_CREDIT_RATING"
          definition: "Vendor credit rating"
          description: "1 = Superior, 2 = Excellent, 3 = Above Average, 4 = Average, 5 = Below Average"
          type: "NUMBER"
          effective_timestamp: true

        - id: "VENDOR_PREFERRED_STATUS"
          name: "VENDOR_PREFERRED_STATUS"
          definition: "Whether the vendor is preferred"
          type: "STRING"
          effective_timestamp: true

        - id: "VENDOR_ACTIVE_FLAG"
          name: "VENDOR_ACTIVE_FLAG"
          definition: "Whether the vendor is currently active"
          type: "STRING"
          effective_timestamp: true

    - id: "PURCHASE_ORDER"
      name: "PURCHASE_ORDER"
      definition: "A purchase order placed with a vendor"
      description: "Represents orders for products or materials from external suppliers"
      attributes:
        - id: "PURCHASE_ORDER_STATUS"
          name: "PURCHASE_ORDER_STATUS"
          definition: "Current order status"
          description: "1 = Pending, 2 = Approved, 3 = Rejected, 4 = Complete"
          type: "STRING"
          effective_timestamp: true

        - id: "PURCHASE_ORDER_REVISION_NUMBER"
          name: "PURCHASE_ORDER_REVISION_NUMBER"
          definition: "Number of times the order has been revised"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PURCHASE_ORDER_SUB_TOTAL"
          name: "PURCHASE_ORDER_SUB_TOTAL"
          definition: "Subtotal before tax and freight"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PURCHASE_ORDER_TAX_AMT"
          name: "PURCHASE_ORDER_TAX_AMT"
          definition: "Tax amount"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PURCHASE_ORDER_FREIGHT"
          name: "PURCHASE_ORDER_FREIGHT"
          definition: "Shipping cost"
          type: "NUMBER"
          effective_timestamp: true

        - id: "PURCHASE_ORDER_ORDER_DATE"
          name: "PURCHASE_ORDER_ORDER_DATE"
          definition: "Date the purchase order was placed"
          type: "START_TIMESTAMP"

        - id: "PURCHASE_ORDER_SHIP_DATE"
          name: "PURCHASE_ORDER_SHIP_DATE"
          definition: "Date the order was shipped"
          type: "END_TIMESTAMP"
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add VENDOR and PURCHASE_ORDER entities to data model"
```

---

### Task 5: Sales entities (CUSTOMER, STORE, SALES_PERSON, SALES_TERRITORY)

**Files:**
- Modify: `model.yaml` (append to entities list)

**Step 1: Append sales master entities**

```yaml
    - id: "CUSTOMER"
      name: "CUSTOMER"
      definition: "A customer account"
      description: "Represents a customer linked to either a person or a store, assigned to a sales territory"
      attributes:
        - id: "CUSTOMER_ACCOUNT_NUMBER"
          name: "CUSTOMER_ACCOUNT_NUMBER"
          definition: "Unique customer account identifier"
          type: "STRING"

    - id: "STORE"
      name: "STORE"
      definition: "A retail store that purchases products"
      description: "Represents business-to-business customers that are retail stores"
      attributes:
        - id: "STORE_NAME"
          name: "STORE_NAME"
          definition: "Store business name"
          type: "STRING"
          effective_timestamp: true

    - id: "SALES_PERSON"
      name: "SALES_PERSON"
      definition: "A sales representative"
      description: "Extends EMPLOYEE with sales-specific metrics like quota, bonus, and commission"
      attributes:
        - id: "SALES_PERSON_SALES_QUOTA"
          name: "SALES_PERSON_SALES_QUOTA"
          definition: "Projected yearly sales target"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_PERSON_BONUS"
          name: "SALES_PERSON_BONUS"
          definition: "Bonus amount earned"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_PERSON_COMMISSION_PCT"
          name: "SALES_PERSON_COMMISSION_PCT"
          definition: "Commission percentage earned on sales"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_PERSON_SALES_YTD"
          name: "SALES_PERSON_SALES_YTD"
          definition: "Year-to-date sales amount"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_PERSON_SALES_LAST_YEAR"
          name: "SALES_PERSON_SALES_LAST_YEAR"
          definition: "Total sales from the previous year"
          type: "NUMBER"
          effective_timestamp: true

    - id: "SALES_TERRITORY"
      name: "SALES_TERRITORY"
      definition: "A geographic sales region"
      description: "Represents sales territories used for territory-based reporting and sales person assignment"
      attributes:
        - id: "SALES_TERRITORY_NAME"
          name: "SALES_TERRITORY_NAME"
          definition: "Territory name"
          type: "STRING"
          effective_timestamp: true

        - id: "SALES_TERRITORY_COUNTRY_REGION_CODE"
          name: "SALES_TERRITORY_COUNTRY_REGION_CODE"
          definition: "ISO country or region code"
          type: "STRING"
          effective_timestamp: true

        - id: "SALES_TERRITORY_GROUP"
          name: "SALES_TERRITORY_GROUP"
          definition: "Geographic grouping"
          description: "High-level region such as North America, Europe, Pacific"
          type: "STRING"
          effective_timestamp: true
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add CUSTOMER, STORE, SALES_PERSON, and SALES_TERRITORY entities"
```

---

### Task 6: Sales transaction entities (SALES_ORDER, SALES_ORDER_DETAIL, SPECIAL_OFFER)

**Files:**
- Modify: `model.yaml` (append to entities list)

**Step 1: Append sales transaction entities**

```yaml
    - id: "SALES_ORDER"
      name: "SALES_ORDER"
      definition: "A customer sales order"
      description: "Represents a sales transaction with shipping, billing, and payment details"
      attributes:
        - id: "SALES_ORDER_STATUS"
          name: "SALES_ORDER_STATUS"
          definition: "Current order status"
          description: "1 = In Process, 2 = Approved, 3 = Backordered, 4 = Rejected, 5 = Shipped, 6 = Cancelled"
          type: "STRING"
          effective_timestamp: true

        - id: "SALES_ORDER_ONLINE_ORDER_FLAG"
          name: "SALES_ORDER_ONLINE_ORDER_FLAG"
          definition: "Whether the order was placed online"
          description: "true = online, false = sales person"
          type: "STRING"
          effective_timestamp: true

        - id: "SALES_ORDER_PURCHASE_ORDER_NUMBER"
          name: "SALES_ORDER_PURCHASE_ORDER_NUMBER"
          definition: "Customer purchase order number reference"
          type: "STRING"

        - id: "SALES_ORDER_ACCOUNT_NUMBER"
          name: "SALES_ORDER_ACCOUNT_NUMBER"
          definition: "Customer account number at time of order"
          type: "STRING"

        - id: "SALES_ORDER_SUB_TOTAL"
          name: "SALES_ORDER_SUB_TOTAL"
          definition: "Subtotal before tax and freight"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_ORDER_TAX_AMT"
          name: "SALES_ORDER_TAX_AMT"
          definition: "Tax amount"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_ORDER_FREIGHT"
          name: "SALES_ORDER_FREIGHT"
          definition: "Shipping cost"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_ORDER_COMMENT"
          name: "SALES_ORDER_COMMENT"
          definition: "Sales representative comment"
          type: "STRING"
          effective_timestamp: true

        - id: "SALES_ORDER_ORDER_DATE"
          name: "SALES_ORDER_ORDER_DATE"
          definition: "Date the order was placed"
          type: "START_TIMESTAMP"

        - id: "SALES_ORDER_DUE_DATE"
          name: "SALES_ORDER_DUE_DATE"
          definition: "Date the order is due to the customer"
          type: "END_TIMESTAMP"

        - id: "SALES_ORDER_SHIP_DATE"
          name: "SALES_ORDER_SHIP_DATE"
          definition: "Date the order was shipped"
          type: "END_TIMESTAMP"

    - id: "SALES_ORDER_DETAIL"
      name: "SALES_ORDER_DETAIL"
      definition: "A line item within a sales order"
      description: "Represents a single product entry in a sales order with quantity and pricing"
      attributes:
        - id: "SALES_ORDER_DETAIL_CARRIER_TRACKING_NUMBER"
          name: "SALES_ORDER_DETAIL_CARRIER_TRACKING_NUMBER"
          definition: "Shipment tracking number"
          type: "STRING"

        - id: "SALES_ORDER_DETAIL_ORDER_QTY"
          name: "SALES_ORDER_DETAIL_ORDER_QTY"
          definition: "Quantity ordered"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_ORDER_DETAIL_UNIT_PRICE"
          name: "SALES_ORDER_DETAIL_UNIT_PRICE"
          definition: "Price per unit at time of sale"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SALES_ORDER_DETAIL_UNIT_PRICE_DISCOUNT"
          name: "SALES_ORDER_DETAIL_UNIT_PRICE_DISCOUNT"
          definition: "Discount percentage applied to the unit price"
          type: "NUMBER"
          effective_timestamp: true

    - id: "SPECIAL_OFFER"
      name: "SPECIAL_OFFER"
      definition: "A promotional discount offer"
      description: "Represents promotional offers with discount percentages, eligibility rules, and validity periods"
      attributes:
        - id: "SPECIAL_OFFER_DESCRIPTION"
          name: "SPECIAL_OFFER_DESCRIPTION"
          definition: "Description of the offer"
          type: "STRING"
          effective_timestamp: true

        - id: "SPECIAL_OFFER_DISCOUNT_PCT"
          name: "SPECIAL_OFFER_DISCOUNT_PCT"
          definition: "Discount percentage"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SPECIAL_OFFER_TYPE"
          name: "SPECIAL_OFFER_TYPE"
          definition: "Offer type classification"
          type: "STRING"
          effective_timestamp: true

        - id: "SPECIAL_OFFER_CATEGORY"
          name: "SPECIAL_OFFER_CATEGORY"
          definition: "Offer category"
          type: "STRING"
          effective_timestamp: true

        - id: "SPECIAL_OFFER_MIN_QTY"
          name: "SPECIAL_OFFER_MIN_QTY"
          definition: "Minimum order quantity to qualify"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SPECIAL_OFFER_MAX_QTY"
          name: "SPECIAL_OFFER_MAX_QTY"
          definition: "Maximum order quantity allowed"
          type: "NUMBER"
          effective_timestamp: true

        - id: "SPECIAL_OFFER_START_DATE"
          name: "SPECIAL_OFFER_START_DATE"
          definition: "Date the offer becomes active"
          type: "START_TIMESTAMP"

        - id: "SPECIAL_OFFER_END_DATE"
          name: "SPECIAL_OFFER_END_DATE"
          definition: "Date the offer expires"
          type: "END_TIMESTAMP"
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add SALES_ORDER, SALES_ORDER_DETAIL, and SPECIAL_OFFER entities"
```

---

### Task 7: Add all 21 relationships

**Files:**
- Modify: `model.yaml` (add `relationships:` section as sibling of `entities:` under `model:`)

**Step 1: Add relationships section after the entities list**

```yaml
  relationships:
    - id: "EMPLOYEE_IS_A_PERSON"
      name: "EMPLOYEE_IS_A_PERSON"
      definition: "Links an employee to their person record"
      description: "Each employee is a person identified by business_entity_id"
      source_entity_id: "EMPLOYEE"
      target_entity_id: "PERSON"

    - id: "SALES_PERSON_IS_AN_EMPLOYEE"
      name: "SALES_PERSON_IS_AN_EMPLOYEE"
      definition: "Links a sales person to their employee record"
      description: "Each sales person is an employee identified by business_entity_id"
      source_entity_id: "SALES_PERSON"
      target_entity_id: "EMPLOYEE"

    - id: "VENDOR_IS_A_BUSINESS_ENTITY"
      name: "VENDOR_IS_A_BUSINESS_ENTITY"
      definition: "Links a vendor to their business entity record"
      description: "Each vendor is a business entity identified by business_entity_id"
      source_entity_id: "VENDOR"
      target_entity_id: "PERSON"

    - id: "PERSON_RESIDES_AT_ADDRESS"
      name: "PERSON_RESIDES_AT_ADDRESS"
      definition: "Links a person to their address"
      description: "Each person has an address via business_entity_address"
      source_entity_id: "PERSON"
      target_entity_id: "ADDRESS"

    - id: "EMPLOYEE_BELONGS_TO_DEPARTMENT"
      name: "EMPLOYEE_BELONGS_TO_DEPARTMENT"
      definition: "Links an employee to their department"
      description: "Each employee belongs to a department via employee_department_history"
      source_entity_id: "EMPLOYEE"
      target_entity_id: "DEPARTMENT"

    - id: "WORK_ORDER_IS_FOR_PRODUCT"
      name: "WORK_ORDER_IS_FOR_PRODUCT"
      definition: "Links a work order to the product being manufactured"
      source_entity_id: "WORK_ORDER"
      target_entity_id: "PRODUCT"

    - id: "PURCHASE_ORDER_IS_PLACED_WITH_VENDOR"
      name: "PURCHASE_ORDER_IS_PLACED_WITH_VENDOR"
      definition: "Links a purchase order to the vendor supplying it"
      source_entity_id: "PURCHASE_ORDER"
      target_entity_id: "VENDOR"

    - id: "PURCHASE_ORDER_IS_ORDERED_BY_EMPLOYEE"
      name: "PURCHASE_ORDER_IS_ORDERED_BY_EMPLOYEE"
      definition: "Links a purchase order to the employee who placed it"
      source_entity_id: "PURCHASE_ORDER"
      target_entity_id: "EMPLOYEE"

    - id: "SALES_ORDER_IS_PLACED_BY_CUSTOMER"
      name: "SALES_ORDER_IS_PLACED_BY_CUSTOMER"
      definition: "Links a sales order to the purchasing customer"
      source_entity_id: "SALES_ORDER"
      target_entity_id: "CUSTOMER"

    - id: "SALES_ORDER_IS_SOLD_BY_SALES_PERSON"
      name: "SALES_ORDER_IS_SOLD_BY_SALES_PERSON"
      definition: "Links a sales order to the sales representative"
      source_entity_id: "SALES_ORDER"
      target_entity_id: "SALES_PERSON"

    - id: "SALES_ORDER_BELONGS_TO_SALES_TERRITORY"
      name: "SALES_ORDER_BELONGS_TO_SALES_TERRITORY"
      definition: "Links a sales order to its sales territory"
      source_entity_id: "SALES_ORDER"
      target_entity_id: "SALES_TERRITORY"

    - id: "SALES_ORDER_IS_BILLED_TO_ADDRESS"
      name: "SALES_ORDER_IS_BILLED_TO_ADDRESS"
      definition: "Links a sales order to the billing address"
      source_entity_id: "SALES_ORDER"
      target_entity_id: "ADDRESS"

    - id: "SALES_ORDER_IS_SHIPPED_TO_ADDRESS"
      name: "SALES_ORDER_IS_SHIPPED_TO_ADDRESS"
      definition: "Links a sales order to the shipping address"
      source_entity_id: "SALES_ORDER"
      target_entity_id: "ADDRESS"

    - id: "SALES_ORDER_DETAIL_BELONGS_TO_SALES_ORDER"
      name: "SALES_ORDER_DETAIL_BELONGS_TO_SALES_ORDER"
      definition: "Links a line item to its parent sales order"
      source_entity_id: "SALES_ORDER_DETAIL"
      target_entity_id: "SALES_ORDER"

    - id: "SALES_ORDER_DETAIL_REFERS_TO_PRODUCT"
      name: "SALES_ORDER_DETAIL_REFERS_TO_PRODUCT"
      definition: "Links a line item to the product ordered"
      source_entity_id: "SALES_ORDER_DETAIL"
      target_entity_id: "PRODUCT"

    - id: "SALES_ORDER_DETAIL_HAS_APPLIED_SPECIAL_OFFER"
      name: "SALES_ORDER_DETAIL_HAS_APPLIED_SPECIAL_OFFER"
      definition: "Links a line item to the special offer applied"
      source_entity_id: "SALES_ORDER_DETAIL"
      target_entity_id: "SPECIAL_OFFER"

    - id: "CUSTOMER_REFERS_TO_PERSON"
      name: "CUSTOMER_REFERS_TO_PERSON"
      definition: "Links a customer to the person behind the account"
      description: "Nullable — customer may be a store instead of an individual"
      source_entity_id: "CUSTOMER"
      target_entity_id: "PERSON"

    - id: "CUSTOMER_REFERS_TO_STORE"
      name: "CUSTOMER_REFERS_TO_STORE"
      definition: "Links a customer to the store behind the account"
      description: "Nullable — customer may be a person instead of a store"
      source_entity_id: "CUSTOMER"
      target_entity_id: "STORE"

    - id: "CUSTOMER_BELONGS_TO_SALES_TERRITORY"
      name: "CUSTOMER_BELONGS_TO_SALES_TERRITORY"
      definition: "Links a customer to their assigned sales territory"
      source_entity_id: "CUSTOMER"
      target_entity_id: "SALES_TERRITORY"

    - id: "STORE_IS_MANAGED_BY_SALES_PERSON"
      name: "STORE_IS_MANAGED_BY_SALES_PERSON"
      definition: "Links a store to its assigned sales representative"
      source_entity_id: "STORE"
      target_entity_id: "SALES_PERSON"

    - id: "SALES_PERSON_BELONGS_TO_SALES_TERRITORY"
      name: "SALES_PERSON_BELONGS_TO_SALES_TERRITORY"
      definition: "Links a sales person to their assigned territory"
      source_entity_id: "SALES_PERSON"
      target_entity_id: "SALES_TERRITORY"
```

**Step 2: Validate**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add model.yaml
git commit -m "feat: add all 21 relationships to data model"
```

---

### Task 8: Update workflow.yaml and README.md

**Files:**
- Modify: `workflow.yaml` (update mappings list to reflect new entities)
- Modify: `README.md` (if entity list is referenced)

**Step 1: Update workflow.yaml mappings list**

Replace the current mappings section with placeholders for all 14 entities:

```yaml
  mappings: []
    # Mappings will be generated with:
    #   daana-cli generate mapping --model model.yaml --all-entities --dir mappings/
```

**Step 2: Final validation**

Run: `daana-cli check model model.yaml`
Expected: PASS

**Step 3: Commit**

```bash
git add workflow.yaml
git commit -m "docs: update workflow mappings placeholder for new entity set"
```
