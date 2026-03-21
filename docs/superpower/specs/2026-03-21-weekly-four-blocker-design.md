# Weekly Four-Blocker Report

## Purpose

A markdown report presenting 4 output metrics (lagging indicators) alongside their actionable input metrics (leading indicators). Each metric includes the result, the natural language prompt for `/daana:query`, and the generated SQL — making the report reproducible and self-documenting.

## Structure

Single markdown file: `weekly-report.md` at project root.

4 blocks, each as an H2 section. Each block contains:

1. **Output metric** — the result the business measures
2. **3 input metrics** — actionable levers the business can pull

For every metric:

- Result value + brief business summary (visible by default)
- NL prompt + SQL in a collapsed `<details>` block

### Metric Format

```markdown
### Metric Name
**value** summary text

<details>
<summary>Prompt & SQL</summary>

> Natural language prompt for /daana:query

​```sql
SELECT ...
​```
</details>
```

## Data Source

All queries run against the Focal-based Daana data warehouse via `/daana:query`. Connection profile: `dev` (PostgreSQL, localhost:5442, database: customerdb). Latest snapshot, no cutoff date.

## Block 1: Revenue

| Metric | Type | Definition |
|--------|------|-----------|
| Total Revenue | Output | SUM of sales order sub_total |
| Discount Depth | Input | Avg special offer discount % applied to order lines |
| Sales Quota Coverage | Input | Quota vs YTD attainment per sales person |
| List Price Positioning | Input | Qty-weighted avg list price of products sold |

**Why these inputs?**

- Discount depth: Marketing controls promotion intensity — deeper discounts drive volume but erode price.
- Quota coverage: Sales leadership can adjust quotas, reassign territories, or coach underperformers.
- List price positioning: Pricing team can adjust list prices; tracks whether the mix skews premium or commodity.

## Block 2: Gross Margin %

| Metric | Type | Definition |
|--------|------|-----------|
| Gross Margin % | Output | (line revenue - standard cost) / line revenue |
| Standard Cost per Unit | Input | Qty-weighted avg standard cost of products sold |
| Make vs Buy Mix | Input | % of products with make_flag = true |
| Vendor Credit Quality | Input | Avg credit rating of active vendors |

**Why these inputs?**

- Standard cost: Procurement negotiates supplier pricing — directly compresses or expands margin.
- Make vs buy: Operations decides what to manufacture in-house vs outsource.
- Vendor credit quality: Poor-quality vendors drive hidden costs; procurement selects and manages vendors.

## Block 3: Fulfillment Cycle Time

| Metric | Type | Definition |
|--------|------|-----------|
| Avg Fulfillment Days | Output | Avg days between order_date and ship_date |
| Manufacturing Lead Time | Input | Avg days_to_manufacture for products on sold order lines |
| Scrap Rate | Input | scrapped_qty / order_qty on work orders |
| Safety Stock Adequacy | Input | Avg safety stock level across products |

**Why these inputs?**

- Manufacturing lead time: Operations can optimize production lines and scheduling.
- Scrap rate: Quality control investments reduce rework and delays.
- Safety stock: Supply chain planning can adjust buffer stock to prevent stockouts.

## Block 4: Customer Breadth

| Metric | Type | Definition |
|--------|------|-----------|
| Unique Customers | Output | Distinct customers with at least one order |
| Territory Coverage | Input | Customer count per sales territory |
| Online Order Ratio | Input | % of orders placed online |
| Sales Person Reach | Input | Avg unique customers per sales person |

**Why these inputs?**

- Territory coverage: Sales leadership can identify and expand into underserved territories.
- Online order ratio: Digital team can invest in e-commerce to lower acquisition cost.
- Sales person reach: Sales management can rebalance assignments and hire to grow coverage.

## Query Approach

All queries use Pattern 1 (latest snapshot) from the Focal query patterns:

- Descriptor tables: RANK by `eff_tmstp DESC, ver_tmstp DESC`, filter `nbr = 1 AND row_st = 'Y'`, pivot with `MAX(CASE WHEN type_key = ... THEN ... END)`.
- Relationship tables: Same RANK pattern, resolve latest active relationship before joining.
- Cross-entity: Resolve each entity/relationship in its own CTE, then join.

## Constraints

- Read-only queries — no DDL/DML.
- No hardcoded TYPE_KEYs — all resolved from bootstrap metadata.
- Statement timeout: 30s per query.
- No default LIMIT clause.
