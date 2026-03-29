# Weekly Four-Blocker Report (13-Week Timeline) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate a weekly report with 16 metrics as 13-week ASCII bar chart time series, with collapsed NL prompts and SQL.

**Architecture:** Hand 16 NL questions to `/daana:query` subagents (4 parallel blocks of 4 questions). Each query returns 13 weekly rows. The assembler renders ASCII bar charts and writes `weekly-report.md`.

**Tech Stack:** `/daana:query` skill, PostgreSQL, Markdown with `<details>` tags, ASCII bar charts.

**Worktree:** `.worktrees/weekly-report` on branch `feat/weekly-report`

**Spec:** `docs/superpower/specs/2026-03-21-weekly-four-blocker-design.md`

---

## Pre-Requisites

The `/daana:query` session must already be bootstrapped:
- Connection profile: `dev` (PostgreSQL, localhost:5442, customerdb)
- Execution consent: Yes, don't ask again

**Important:** All queries bucket by `DATE_TRUNC('week', <timestamp>)` and filter to last 13 weeks. The subagent needs to determine the actual date range from the data (the latest week in the dataset may not be the current calendar week).

### Connection Command

```bash
PGSSLMODE=disable PGPASSWORD=devpass psql -h localhost -p 5442 -U dev -d customerdb -P pager=off --csv -c "SET statement_timeout = '30s'; <SQL>"
```

### Bootstrap Reference (TYPE_KEYs)

**Descriptor tables:**

| Table | Atomic Context | TYPE_KEY | Column |
|-------|---------------|----------|--------|
| SALES_ORDER_DESC | sub_total | 110 | VAL_NUM |
| SALES_ORDER_DESC | order_date | 55 | STA_TMSTP |
| SALES_ORDER_DESC | ship_date | 10 | END_TMSTP |
| SALES_ORDER_DESC | online_order_flag | 87 | VAL_STR |
| SALES_ORDER_DETAIL_DESC | order_qty | 60 | VAL_NUM |
| SALES_ORDER_DETAIL_DESC | unit_price | 129 | VAL_NUM |
| SPECIAL_OFFER_DESC | discount_pct | 44 | VAL_NUM |
| PRODUCT_DESC | standard_cost | 41 | VAL_NUM |
| PRODUCT_DESC | make_flag | 120 | VAL_STR |
| PURCHASE_ORDER_DESC | order_date | 98 | STA_TMSTP |
| WORK_ORDER_DESC | order_qty | 4 | VAL_NUM |
| WORK_ORDER_DESC | scrapped_qty | 73 | VAL_NUM |
| WORK_ORDER_DESC | start_date | 128 | STA_TMSTP |
| WORK_ORDER_DESC | end_date | 29 | END_TMSTP |

**Relationship tables:**

| Table | Atomic Context | TYPE_KEY | FOCAL01 col | FOCAL02 col |
|-------|---------------|----------|-------------|-------------|
| SALES_ORDER_CUSTOMER_X | placed_by | 7 | sales_order_key | customer_key |
| SALES_ORDER_DETAIL_PRODUCT_X | refers_to | 20 | sales_order_detail_key | product_key |
| SALES_ORDER_DETAIL_SPECIAL_OFFER_X | has_applied | 3 | sales_order_detail_key | special_offer_key |
| SALES_ORDER_DETAIL_SALES_ORDER_X | belongs_to | 48 | sales_order_detail_key | sales_order_key |
| SALES_ORDER_SALES_PERSON_X | sold_by | 117 | sales_order_key | sales_person_key |
| PURCHASE_ORDER_EMPLOYEE_X | ordered_by | 30 | purchase_order_key | employee_key |

### Query Pattern

All queries use Focal Pattern 1 (latest per entity+type_key via RANK), then GROUP BY `DATE_TRUNC('week', <timestamp>)` for weekly bucketing. Filter to last 13 weeks using a subquery to find the max date in the data.

### ASCII Bar Rendering Spec

For each metric's 13 weekly rows, the assembler:
1. Finds the max value across all 13 weeks
2. Scales each week's value to 20 characters: `bar_len = ROUND(value / max_value * 20)`
3. Renders: `W{nn} {'█' * bar_len}{'░' * (20 - bar_len)} {formatted_value}`
4. Appends WoW change for W02-W13: `↑`/`↓` + percentage (omit for W01)
5. Header line: `↑`/`↓` WoW % · latest value

---

## Task 1: Block 1 — Revenue (4 questions, parallel)

Hand these 4 questions to `/daana:query` as a parallel batch. Each subagent gets the full bootstrap + connection + query pattern context above.

### 1A: Total Revenue per week

> What is the total revenue (SUM of sales order sub_total) per week for the last 13 weeks? Group by DATE_TRUNC('week', order_date). Return week and total_revenue, ordered by week.

### 1B: Discount Depth per week

> What is the average special offer discount percentage applied to order lines, per week for the last 13 weeks? Join order details to special offers, bucket by the sales order's order_date week. Return week and avg_discount_pct, ordered by week.

### 1C: Revenue per Sales Person per week

> What is the total revenue (sub_total) per sales person per week for the last 13 weeks? Join sales orders to sales persons. Return week, sales_person_key, and revenue, ordered by week and sales_person_key.

### 1D: Average Order Value per week

> What is the average order value (SUM sub_total / COUNT orders) per week for the last 13 weeks? Group by order_date week. Return week, total_revenue, order_count, and avg_order_value, ordered by week.

**Step: Capture all 4 results + SQL, commit progress.**

---

## Task 2: Block 2 — Gross Margin (4 questions, parallel)

### 2A: Gross Margin % per week

> What is the gross margin percentage per week for the last 13 weeks? Calculate (line revenue - COGS) / line revenue where line revenue = order_qty * unit_price and COGS = order_qty * standard_cost. Join order details to products. Bucket by the sales order's order_date week. Return week, line_revenue, cogs, and gross_margin_pct, ordered by week.

### 2B: COGS per week

> What is the total cost of goods sold (SUM of order_qty * standard_cost) per week for the last 13 weeks? Join order details to products. Bucket by the sales order's order_date week. Return week and total_cogs, ordered by week.

### 2C: Revenue Split — Make vs Buy per week

> What is the total revenue (order_qty * unit_price) split by product make_flag per week for the last 13 weeks? Join order details to products. Bucket by the sales order's order_date week. Return week, make_flag, and revenue, ordered by week.

### 2D: Purchase Order Volume per week

> How many purchase orders were placed per week for the last 13 weeks? Bucket by PO order_date week. Return week and po_count, ordered by week.

**Step: Capture all 4 results + SQL, commit progress.**

---

## Task 3: Block 3 — Fulfillment Cycle Time (4 questions, parallel)

### 3A: Avg Fulfillment Days per week

> What is the average number of days between order date and ship date, per week for the last 13 weeks? Bucket by order_date week. Return week and avg_fulfillment_days, ordered by week.

### 3B: Work Order Volume per week

> How many work orders were started per week for the last 13 weeks? Bucket by work order start_date week. Return week and wo_count, ordered by week.

### 3C: Scrap Rate per week

> What is the scrap rate (SUM scrapped_qty / SUM order_qty) per week for the last 13 weeks? Bucket by work order start_date week. Return week, total_ordered, total_scrapped, and scrap_rate_pct, ordered by week.

### 3D: Work Order Completion Rate per week

> What percentage of work orders started each week have been completed (end_date is not null)? For the last 13 weeks by start_date week. Return week, total_started, total_completed, and completion_rate_pct, ordered by week.

**Step: Capture all 4 results + SQL, commit progress.**

---

## Task 4: Block 4 — Customer Breadth (4 questions, parallel)

### 4A: Unique Customers per week

> How many unique customers placed at least one order per week, for the last 13 weeks? Bucket by order_date week. Return week and unique_customers, ordered by week.

### 4B: New Customers per week

> How many customers placed their first-ever order each week, for the last 13 weeks? A new customer is one whose earliest order_date falls in that week. Return week and new_customers, ordered by week.

### 4C: Online Order Ratio per week

> What percentage of orders were placed online per week, for the last 13 weeks? Bucket by order_date week. Return week, total_orders, online_orders, and online_pct, ordered by week.

### 4D: Orders per Sales Person per week

> What is the average number of orders per sales person per week, for the last 13 weeks? Join orders to sales persons, count orders per SP per week, then average across SPs. Return week and avg_orders_per_sp, ordered by week.

**Step: Capture all 4 results + SQL, commit progress.**

---

## Task 5: Assemble Report

**Step 1:** For each of the 16 metrics, render the ASCII bar chart from the 13 weekly rows:
- Find max value, scale bars to 20 chars
- Format: `W{nn} {'█' * bar_len}{'░' * (20 - bar_len)} {value}  ↑/↓ WoW%`
- Header: `↑/↓ WoW% · latest_value`

**Step 2:** For metrics that return per-entity data (1C Revenue per SP, 2C Make vs Buy split), aggregate to a single weekly series for the chart (e.g., avg across SPs, or show make/buy as two sub-charts).

**Step 3:** Create `weekly-report.md` at project root. Structure:
- H1: Weekly Four-Blocker Report
- Date + source line
- H2 per block (Revenue, Gross Margin, Fulfillment, Customer Breadth)
- H3 per metric with ASCII chart + collapsed prompt/SQL

**Step 4:** Commit the report.

**Step 5:** Push branch and update PR.

---

## Parallelization

Tasks 1-4 are independent — all 4 blocks can run as parallel subagent batches.

Task 5 depends on tasks 1-4.
