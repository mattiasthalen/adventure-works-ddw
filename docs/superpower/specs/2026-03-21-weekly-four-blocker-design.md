# Weekly Four-Blocker Report

## Purpose

A markdown report presenting 4 output metrics (lagging indicators) alongside their actionable input metrics (leading indicators) as **13-week time series**. Each metric shows a horizontal ASCII bar chart with week-over-week changes, plus a collapsed NL prompt and SQL — making the report reproducible and self-documenting.

## Structure

Single markdown file: `weekly-report.md` at project root.

4 blocks, each as an H2 section. Each block contains 1 output metric + 3 input metrics.

### Metric Format

```markdown
### Total Revenue
↑ 3.2% WoW · $9.5M latest

W01 ████████████████░░░░ $7.2M
W02 ██████████████████░░ $8.1M  ↑12.5%
W03 ██████████████░░░░░░ $6.5M  ↓19.8%
...
W13 █████████████████████ $9.5M  ↑ 3.2%

<details>
<summary>Prompt & SQL</summary>

> Natural language prompt for /daana:query

```sql
SELECT ...
```
</details>
```

### ASCII Bar Rendering

- Bar width: 20 characters (`█` filled, `░` empty)
- Scale: per metric (each metric's max value = full 20-char bar)
- WoW: `↑`/`↓` + percentage change vs prior week (omitted for W01)
- Header line: latest week value + WoW change

## Data Source

All queries run against the Focal-based Daana data warehouse via `/daana:query`. Connection profile: `dev` (PostgreSQL, localhost:5442, database: customerdb).

### Time Dimension

- 13 weeks of history (one quarter)
- All event-based metrics bucketed by `DATE_TRUNC('week', <timestamp>)`
- Each query returns 13 rows (one per week)
- No point-in-time/snapshot metrics — all metrics are event-based

## Block 1: Revenue

| Metric | Type | Definition | Weekly bucket via |
|--------|------|-----------|-------------------|
| Total Revenue | Output | SUM(sub_total) | order_date |
| Discount Depth | Input | AVG(special offer discount_pct) per order line | order_date |
| Revenue per Sales Person | Input | SUM(sub_total) per SP | order_date |
| Average Order Value | Input | SUM(sub_total) / COUNT(orders) | order_date |

**Why these inputs?**

- Discount depth: Marketing controls promotion intensity — trending up erodes price.
- Revenue per SP: Sales leadership can identify declining/growing reps week-to-week.
- Average order value: Pricing and upsell effectiveness — trending down signals commoditization.

## Block 2: Gross Margin

| Metric | Type | Definition | Weekly bucket via |
|--------|------|-----------|-------------------|
| Gross Margin % | Output | (line revenue - COGS) / line revenue | order_date |
| COGS | Input | SUM(order_qty * standard_cost) | order_date |
| Revenue Split: Make vs Buy | Input | Revenue by product make_flag | order_date |
| Purchase Order Volume | Input | COUNT(purchase orders) | PO order_date |

**Why these inputs?**

- COGS: Procurement trend — rising COGS compresses margin.
- Make vs buy revenue split: Shift toward buy products may signal margin erosion.
- PO volume: Leading indicator for future cost pressure.

## Block 3: Fulfillment Cycle Time

| Metric | Type | Definition | Weekly bucket via |
|--------|------|-----------|-------------------|
| Avg Fulfillment Days | Output | AVG(ship_date - order_date) | order_date |
| Work Order Volume | Input | COUNT(work orders) | WO start_date |
| Scrap Rate | Input | SUM(scrapped_qty) / SUM(order_qty) | WO start_date |
| Work Order Completion Rate | Input | Completed (end_date not null) / total | WO start_date |

**Why these inputs?**

- WO volume: Spike in work orders can predict fulfillment delays.
- Scrap rate: Rising scrap = rework = delays.
- Completion rate: Dropping completion rate is an early warning for backlog buildup.

## Block 4: Customer Breadth

| Metric | Type | Definition | Weekly bucket via |
|--------|------|-----------|-------------------|
| Unique Customers | Output | COUNT(DISTINCT customer) with orders | order_date |
| New Customers | Input | Customers whose first-ever order is that week | order_date |
| Online Order Ratio | Input | Online orders / total orders | order_date |
| Orders per Sales Person | Input | COUNT(orders) per SP | order_date |

**Why these inputs?**

- New customers: Acquisition trend — is the funnel growing or shrinking?
- Online ratio: Channel shift trend — rising online reduces acquisition cost.
- Orders per SP: Capacity indicator — declining means reps are stretched.

## Query Approach

All queries use Pattern 1 (latest) with GROUP BY `DATE_TRUNC('week', <timestamp>)`, filtered to last 13 weeks. Each returns 13 rows ordered by week. Cross-entity queries join via relationship tables using the standard RANK pattern.

## Constraints

- Read-only queries — no DDL/DML.
- No hardcoded TYPE_KEYs — all resolved from bootstrap metadata.
- Statement timeout: 30s per query.
- No default LIMIT clause.
