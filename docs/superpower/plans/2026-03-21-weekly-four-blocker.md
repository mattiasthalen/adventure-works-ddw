# Weekly Four-Blocker Report Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate a weekly report markdown file with 4 output metrics and 12 input metrics, each with result, NL prompt, and SQL.

**Architecture:** Run 16 queries against the Focal DW via psql, capture results, assemble into a single markdown file with collapsed prompt/SQL sections.

**Tech Stack:** PostgreSQL (psql CLI), Focal query patterns (Pattern 1 — latest snapshot), Markdown with `<details>` tags.

**Worktree:** `.worktrees/weekly-report` on branch `feat/weekly-report`

**Spec:** `docs/superpower/specs/2026-03-21-weekly-four-blocker-design.md`

---

## Connection

All queries use:

```bash
PGSSLMODE=disable PGPASSWORD=devpass psql -h localhost -p 5442 -U dev -d customerdb -P pager=off --csv -c "SET statement_timeout = '30s'; <SQL>"
```

## Focal Bootstrap Reference (TYPE_KEYs)

Resolved from bootstrap — do NOT hardcode differently:

| Entity | Atomic Context | TYPE_KEY | Column |
|--------|---------------|----------|--------|
| SALES_ORDER_DESC | sub_total | 110 | VAL_NUM |
| SALES_ORDER_DESC | order_date | 55 | STA_TMSTP |
| SALES_ORDER_DESC | ship_date | 10 | END_TMSTP |
| SALES_ORDER_DESC | online_order_flag | 87 | VAL_STR |
| SALES_ORDER_DETAIL_DESC | order_qty | 60 | VAL_NUM |
| SALES_ORDER_DETAIL_DESC | unit_price | 129 | VAL_NUM |
| SALES_ORDER_DETAIL_DESC | unit_price_discount | 36 | VAL_NUM |
| PRODUCT_DESC | list_price | 50 | VAL_NUM |
| PRODUCT_DESC | standard_cost | 41 | VAL_NUM |
| PRODUCT_DESC | make_flag | 120 | VAL_STR |
| PRODUCT_DESC | days_to_manufacture | 116 | VAL_NUM |
| PRODUCT_DESC | safety_stock_level | 34 | VAL_NUM |
| SPECIAL_OFFER_DESC | discount_pct | 44 | VAL_NUM |
| SALES_PERSON_DESC | sales_quota | 5 | VAL_NUM |
| SALES_PERSON_DESC | sales_ytd | 88 | VAL_NUM |
| VENDOR_DESC | credit_rating | 70 | VAL_NUM |
| VENDOR_DESC | active_flag | 86 | VAL_STR |
| WORK_ORDER_DESC | order_qty | 4 | VAL_NUM |
| WORK_ORDER_DESC | scrapped_qty | 73 | VAL_NUM |
| SALES_TERRITORY_DESC | name | 108 | VAL_STR |

| Relationship Table | Atomic Context | TYPE_KEY | FOCAL01 col | FOCAL02 col |
|-------------------|---------------|----------|-------------|-------------|
| SALES_ORDER_CUSTOMER_X | placed_by | 7 | sales_order_key | customer_key |
| SALES_ORDER_DETAIL_PRODUCT_X | refers_to | 20 | sales_order_detail_key | product_key |
| SALES_ORDER_DETAIL_SPECIAL_OFFER_X | has_applied | 3 | sales_order_detail_key | special_offer_key |
| SALES_ORDER_DETAIL_SALES_ORDER_X | belongs_to | 48 | sales_order_detail_key | sales_order_key |
| CUSTOMER_SALES_TERRITORY_X | belongs_to | 33 | customer_key | sales_territory_key |
| SALES_ORDER_SALES_PERSON_X | sold_by | 117 | sales_order_key | sales_person_key |

## Query Pattern

All queries follow Focal Pattern 1 (latest). Standard CTE shape:

```sql
WITH latest_[entity] AS (
  SELECT [entity]_key,
    MAX(CASE WHEN type_key = [KEY] THEN [column] END) AS [alias]
  FROM (
    SELECT [entity]_key, type_key, row_st, [columns],
      RANK() OVER (PARTITION BY [entity]_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.[table]
    WHERE type_key IN ([keys])
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY [entity]_key
)
```

Relationship tables use the same RANK pattern with the physical column names from `attribute_name` (not FOCAL01_KEY/FOCAL02_KEY).

---

## Task 1: Block 1 — Revenue (4 queries, parallel)

Run these 4 queries in parallel via subagents. Each subagent returns: the result, the NL prompt, and the SQL.

### 1A: Total Revenue (output)

**Prompt:** "What is the total revenue across all sales orders?"

```sql
SET statement_timeout = '30s';
SELECT ROUND(SUM(sub_total)::numeric, 2) AS total_revenue
FROM (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 110 THEN val_num END) AS sub_total
  FROM (
    SELECT sales_order_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc
    WHERE type_key = 110
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_key
) b
```

### 1B: Discount Depth (input)

**Prompt:** "What is the average special offer discount percentage applied to order lines?"

```sql
SET statement_timeout = '30s';
WITH latest_discount AS (
  SELECT special_offer_key,
    MAX(CASE WHEN type_key = 44 THEN val_num END) AS discount_pct
  FROM (
    SELECT special_offer_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY special_offer_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.special_offer_desc
    WHERE type_key = 44
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY special_offer_key
),
latest_detail_offer AS (
  SELECT sales_order_detail_key, special_offer_key
  FROM (
    SELECT sales_order_detail_key, special_offer_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, special_offer_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_special_offer_x
    WHERE type_key = 3
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
)
SELECT
  ROUND(AVG(ld.discount_pct)::numeric * 100, 2) AS avg_discount_pct,
  COUNT(*) AS order_lines_with_offers
FROM latest_detail_offer ldo
JOIN latest_discount ld ON ldo.special_offer_key = ld.special_offer_key
```

### 1C: Sales Quota Coverage (input)

**Prompt:** "What is the sales quota vs YTD attainment for each sales person?"

```sql
SET statement_timeout = '30s';
SELECT
  sales_person_key,
  sales_quota,
  sales_ytd,
  CASE WHEN sales_quota > 0 THEN ROUND((sales_ytd / sales_quota * 100)::numeric, 1) ELSE NULL END AS quota_attainment_pct
FROM (
  SELECT sales_person_key,
    MAX(CASE WHEN type_key = 5 THEN val_num END) AS sales_quota,
    MAX(CASE WHEN type_key = 88 THEN val_num END) AS sales_ytd
  FROM (
    SELECT sales_person_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY sales_person_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_person_desc
    WHERE type_key IN (5, 88)
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_person_key
) b
ORDER BY quota_attainment_pct DESC NULLS LAST
```

### 1D: List Price Positioning (input)

**Prompt:** "What is the quantity-weighted average list price of products sold?"

```sql
SET statement_timeout = '30s';
WITH latest_detail_qty AS (
  SELECT sales_order_detail_key,
    MAX(CASE WHEN type_key = 60 THEN val_num END) AS order_qty
  FROM (
    SELECT sales_order_detail_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_desc
    WHERE type_key = 60
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_detail_key
),
latest_detail_product AS (
  SELECT sales_order_detail_key, product_key
  FROM (
    SELECT sales_order_detail_key, product_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, product_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_product_x
    WHERE type_key = 20
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
),
latest_product_price AS (
  SELECT product_key,
    MAX(CASE WHEN type_key = 50 THEN val_num END) AS list_price
  FROM (
    SELECT product_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 50
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY product_key
)
SELECT ROUND((SUM(lpp.list_price * ldq.order_qty) / SUM(ldq.order_qty))::numeric, 2) AS weighted_avg_list_price
FROM latest_detail_qty ldq
JOIN latest_detail_product ldp ON ldq.sales_order_detail_key = ldp.sales_order_detail_key
JOIN latest_product_price lpp ON ldp.product_key = lpp.product_key
```

**Step: Commit block 1 results to report**

---

## Task 2: Block 2 — Gross Margin (4 queries, parallel)

### 2A: Gross Margin % (output)

**Prompt:** "What is the gross margin percentage based on line-level revenue and standard cost?"

```sql
SET statement_timeout = '30s';
WITH latest_detail AS (
  SELECT sales_order_detail_key,
    MAX(CASE WHEN type_key = 60 THEN val_num END) AS order_qty,
    MAX(CASE WHEN type_key = 129 THEN val_num END) AS unit_price
  FROM (
    SELECT sales_order_detail_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_desc
    WHERE type_key IN (60, 129)
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_detail_key
),
latest_detail_product AS (
  SELECT sales_order_detail_key, product_key
  FROM (
    SELECT sales_order_detail_key, product_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, product_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_product_x
    WHERE type_key = 20
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
),
latest_product AS (
  SELECT product_key,
    MAX(CASE WHEN type_key = 41 THEN val_num END) AS standard_cost
  FROM (
    SELECT product_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 41
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY product_key
)
SELECT
  ROUND(SUM(ld.order_qty * ld.unit_price)::numeric, 2) AS total_line_revenue,
  ROUND(SUM(ld.order_qty * lp.standard_cost)::numeric, 2) AS total_cost,
  ROUND(((SUM(ld.order_qty * ld.unit_price) - SUM(ld.order_qty * lp.standard_cost)) / NULLIF(SUM(ld.order_qty * ld.unit_price), 0) * 100)::numeric, 2) AS gross_margin_pct
FROM latest_detail ld
JOIN latest_detail_product ldp ON ld.sales_order_detail_key = ldp.sales_order_detail_key
JOIN latest_product lp ON ldp.product_key = lp.product_key
```

### 2B: Standard Cost per Unit (input)

**Prompt:** "What is the quantity-weighted average standard cost of products sold?"

```sql
SET statement_timeout = '30s';
WITH latest_detail AS (
  SELECT sales_order_detail_key,
    MAX(CASE WHEN type_key = 60 THEN val_num END) AS order_qty
  FROM (
    SELECT sales_order_detail_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_desc
    WHERE type_key = 60
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_detail_key
),
latest_detail_product AS (
  SELECT sales_order_detail_key, product_key
  FROM (
    SELECT sales_order_detail_key, product_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, product_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_product_x
    WHERE type_key = 20
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
),
latest_product AS (
  SELECT product_key,
    MAX(CASE WHEN type_key = 41 THEN val_num END) AS standard_cost
  FROM (
    SELECT product_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 41
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY product_key
)
SELECT ROUND((SUM(lp.standard_cost * ld.order_qty) / SUM(ld.order_qty))::numeric, 2) AS weighted_avg_standard_cost
FROM latest_detail ld
JOIN latest_detail_product ldp ON ld.sales_order_detail_key = ldp.sales_order_detail_key
JOIN latest_product lp ON ldp.product_key = lp.product_key
```

### 2C: Make vs Buy Mix (input)

**Prompt:** "What percentage of products are manufactured in-house vs purchased?"

```sql
SET statement_timeout = '30s';
WITH latest_product AS (
  SELECT product_key,
    MAX(CASE WHEN type_key = 120 THEN val_str END) AS make_flag
  FROM (
    SELECT product_key, type_key, row_st, val_str,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 120
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY product_key
)
SELECT
  COUNT(*) AS total_products,
  SUM(CASE WHEN make_flag = 'true' THEN 1 ELSE 0 END) AS make_count,
  SUM(CASE WHEN make_flag = 'false' THEN 1 ELSE 0 END) AS buy_count,
  ROUND((SUM(CASE WHEN make_flag = 'true' THEN 1 ELSE 0 END)::numeric / COUNT(*)) * 100, 1) AS make_pct
FROM latest_product
```

### 2D: Vendor Credit Quality (input)

**Prompt:** "What is the average credit rating of active vendors?"

```sql
SET statement_timeout = '30s';
WITH latest_vendor AS (
  SELECT vendor_key,
    MAX(CASE WHEN type_key = 70 THEN val_num END) AS credit_rating,
    MAX(CASE WHEN type_key = 86 THEN val_str END) AS active_flag
  FROM (
    SELECT vendor_key, type_key, row_st, val_num, val_str,
      RANK() OVER (PARTITION BY vendor_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.vendor_desc
    WHERE type_key IN (70, 86)
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY vendor_key
)
SELECT
  COUNT(*) AS active_vendors,
  ROUND(AVG(credit_rating)::numeric, 2) AS avg_credit_rating,
  MIN(credit_rating) AS min_credit_rating,
  MAX(credit_rating) AS max_credit_rating
FROM latest_vendor
WHERE active_flag = 'true'
```

**Step: Commit block 2 results to report**

---

## Task 3: Block 3 — Fulfillment Cycle Time (4 queries, parallel)

### 3A: Avg Fulfillment Days (output)

**Prompt:** "What is the average number of days between order date and ship date?"

```sql
SET statement_timeout = '30s';
SELECT
  ROUND(AVG(EXTRACT(EPOCH FROM (ship_date - order_date)) / 86400)::numeric, 1) AS avg_fulfillment_days,
  ROUND(MIN(EXTRACT(EPOCH FROM (ship_date - order_date)) / 86400)::numeric, 1) AS min_days,
  ROUND(MAX(EXTRACT(EPOCH FROM (ship_date - order_date)) / 86400)::numeric, 1) AS max_days
FROM (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 55 THEN sta_tmstp END) AS order_date,
    MAX(CASE WHEN type_key = 10 THEN end_tmstp END) AS ship_date
  FROM (
    SELECT sales_order_key, type_key, row_st, sta_tmstp, end_tmstp,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc
    WHERE type_key IN (55, 10)
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_key
) b
WHERE ship_date IS NOT NULL AND order_date IS NOT NULL
```

### 3B: Manufacturing Lead Time (input)

**Prompt:** "What is the average days to manufacture for products on sold order lines?"

```sql
SET statement_timeout = '30s';
WITH latest_product AS (
  SELECT product_key,
    MAX(CASE WHEN type_key = 116 THEN val_num END) AS days_to_manufacture
  FROM (
    SELECT product_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 116
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY product_key
),
latest_detail_product AS (
  SELECT sales_order_detail_key, product_key
  FROM (
    SELECT sales_order_detail_key, product_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, product_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_product_x
    WHERE type_key = 20
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
)
SELECT
  ROUND(AVG(lp.days_to_manufacture)::numeric, 2) AS avg_days_to_manufacture,
  MAX(lp.days_to_manufacture) AS max_days_to_manufacture
FROM latest_detail_product ldp
JOIN latest_product lp ON ldp.product_key = lp.product_key
```

### 3C: Scrap Rate (input)

**Prompt:** "What is the scrap rate on work orders (scrapped qty / order qty)?"

```sql
SET statement_timeout = '30s';
WITH latest_wo AS (
  SELECT work_order_key,
    MAX(CASE WHEN type_key = 4 THEN val_num END) AS order_qty,
    MAX(CASE WHEN type_key = 73 THEN val_num END) AS scrapped_qty
  FROM (
    SELECT work_order_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY work_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.work_order_desc
    WHERE type_key IN (4, 73)
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY work_order_key
)
SELECT
  SUM(order_qty) AS total_ordered,
  SUM(scrapped_qty) AS total_scrapped,
  ROUND((SUM(scrapped_qty) / NULLIF(SUM(order_qty), 0) * 100)::numeric, 2) AS scrap_rate_pct
FROM latest_wo
```

### 3D: Safety Stock Adequacy (input)

**Prompt:** "What is the average safety stock level across all products?"

```sql
SET statement_timeout = '30s';
WITH latest_product AS (
  SELECT product_key,
    MAX(CASE WHEN type_key = 34 THEN val_num END) AS safety_stock_level
  FROM (
    SELECT product_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 34
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY product_key
)
SELECT
  ROUND(AVG(safety_stock_level)::numeric, 0) AS avg_safety_stock,
  MIN(safety_stock_level) AS min_safety_stock,
  MAX(safety_stock_level) AS max_safety_stock
FROM latest_product
```

**Step: Commit block 3 results to report**

---

## Task 4: Block 4 — Customer Breadth (4 queries, parallel)

### 4A: Unique Customers (output)

**Prompt:** "How many unique customers have placed at least one sales order?"

```sql
SET statement_timeout = '30s';
WITH latest_order_customer AS (
  SELECT sales_order_key, customer_key
  FROM (
    SELECT sales_order_key, customer_key, row_st,
      RANK() OVER (PARTITION BY sales_order_key, customer_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_customer_x
    WHERE type_key = 7
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
)
SELECT COUNT(DISTINCT customer_key) AS unique_customers_with_orders
FROM latest_order_customer
```

### 4B: Territory Coverage (input)

**Prompt:** "How many customers are in each sales territory?"

```sql
SET statement_timeout = '30s';
WITH latest_cust_territory AS (
  SELECT customer_key, sales_territory_key
  FROM (
    SELECT customer_key, sales_territory_key, row_st,
      RANK() OVER (PARTITION BY customer_key, sales_territory_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.customer_sales_territory_x
    WHERE type_key = 33
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
),
latest_territory_name AS (
  SELECT sales_territory_key,
    MAX(CASE WHEN type_key = 108 THEN val_str END) AS territory_name
  FROM (
    SELECT sales_territory_key, type_key, row_st, val_str,
      RANK() OVER (PARTITION BY sales_territory_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_territory_desc
    WHERE type_key = 108
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_territory_key
)
SELECT
  ltn.territory_name,
  COUNT(DISTINCT lct.customer_key) AS customers
FROM latest_cust_territory lct
JOIN latest_territory_name ltn ON lct.sales_territory_key = ltn.sales_territory_key
GROUP BY ltn.territory_name
ORDER BY customers DESC
```

### 4C: Online Order Ratio (input)

**Prompt:** "What percentage of sales orders are placed online?"

```sql
SET statement_timeout = '30s';
WITH latest_online_flag AS (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 87 THEN val_str END) AS online_order_flag
  FROM (
    SELECT sales_order_key, type_key, row_st, val_str,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc
    WHERE type_key = 87
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_key
)
SELECT
  COUNT(*) AS total_orders,
  SUM(CASE WHEN online_order_flag = 'true' THEN 1 ELSE 0 END) AS online_orders,
  SUM(CASE WHEN online_order_flag = 'false' THEN 1 ELSE 0 END) AS offline_orders,
  ROUND((SUM(CASE WHEN online_order_flag = 'true' THEN 1 ELSE 0 END)::numeric / COUNT(*)) * 100, 1) AS online_pct
FROM latest_online_flag
```

### 4D: Sales Person Reach (input)

**Prompt:** "What is the average number of unique customers per sales person?"

```sql
SET statement_timeout = '30s';
WITH latest_order_customer AS (
  SELECT sales_order_key, customer_key
  FROM (
    SELECT sales_order_key, customer_key, row_st,
      RANK() OVER (PARTITION BY sales_order_key, customer_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_customer_x
    WHERE type_key = 7
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
),
latest_order_sp AS (
  SELECT sales_order_key, sales_person_key
  FROM (
    SELECT sales_order_key, sales_person_key, row_st,
      RANK() OVER (PARTITION BY sales_order_key, sales_person_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_sales_person_x
    WHERE type_key = 117
  ) a
  WHERE nbr = 1 AND row_st = 'Y'
)
SELECT
  COUNT(DISTINCT losp.sales_person_key) AS total_sales_persons,
  COUNT(DISTINCT loc.customer_key) AS total_customers,
  ROUND((COUNT(DISTINCT loc.customer_key)::numeric / NULLIF(COUNT(DISTINCT losp.sales_person_key), 0)), 0) AS avg_customers_per_sp
FROM latest_order_customer loc
JOIN latest_order_sp losp ON loc.sales_order_key = losp.sales_order_key
```

**Step: Commit block 4 results to report**

---

## Task 5: Assemble Report

**Step 1:** Create `weekly-report.md` at project root in the worktree, assembling all 16 results with the markdown format from the spec (result visible, prompt + SQL in collapsed `<details>` blocks).

**Step 2:** Commit the report.

**Step 3:** Push branch and create PR.

---

## Parallelization

Tasks 1-4 are independent — all 4 blocks can run in parallel. Each block's 4 queries are also independent. Maximum parallelism: 16 concurrent queries.

Task 5 depends on tasks 1-4.
