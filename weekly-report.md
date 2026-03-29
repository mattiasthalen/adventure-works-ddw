# Weekly Four-Blocker Report

> Generated 2026-03-21 from Adventure Works data warehouse via `/daana:query`
> Data period: 2014-03-31 to 2014-06-30 (13 weeks)

---

## Revenue

### Total Revenue
**↓ 77.4% WoW · $2,644 latest**

```
W01 ████████████████████ $3,745,868
W02 ██░░░░░░░░░░░░░░░░░░ $404,065  ↓ 89.2%
W03 ██░░░░░░░░░░░░░░░░░░ $445,140  ↑ 10.2%
W04 ██░░░░░░░░░░░░░░░░░░ $413,635  ↓  7.1%
W05 ████████████████████ $3,789,035  ↑816.0%
W06 ███░░░░░░░░░░░░░░░░░ $502,054  ↓ 86.7%
W07 ██░░░░░░░░░░░░░░░░░░ $462,504  ↓  7.9%
W08 ███░░░░░░░░░░░░░░░░░ $480,806  ↑  4.0%
W09 ██░░░░░░░░░░░░░░░░░░ $319,205  ↓ 33.6%
W10 █░░░░░░░░░░░░░░░░░░░ $10,934  ↓ 96.6%
W11 █░░░░░░░░░░░░░░░░░░░ $10,574  ↓  3.3%
W12 █░░░░░░░░░░░░░░░░░░░ $11,657  ↑ 10.2%
W13 █░░░░░░░░░░░░░░░░░░░ $11,683  ↑  0.2%
W14 █░░░░░░░░░░░░░░░░░░░ $2,644  ↓ 77.4%
```

<details>
<summary>Prompt & SQL</summary>

> What is the total revenue (SUM of sales order sub_total) per week for the last 13 weeks?

```sql
SELECT DATE_TRUNC('week', order_date) AS week,
       ROUND(SUM(sub_total)::numeric, 2) AS total_revenue
FROM (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 110 THEN val_num END) AS sub_total,
    MAX(CASE WHEN type_key = 55 THEN sta_tmstp END) AS order_date
  FROM (
    SELECT sales_order_key, type_key, row_st, val_num, sta_tmstp,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc WHERE type_key IN (55, 110)
  ) a WHERE nbr = 1 AND row_st = 'Y'
  GROUP BY sales_order_key
) b
WHERE order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks'
                     FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', order_date) ORDER BY week
```
</details>

### Discount Depth
**0.00% latest**

```
W01 ████████████████████ 0.96%
W02 █░░░░░░░░░░░░░░░░░░░ 0.06%  ↓ 93.7%
W03 ██░░░░░░░░░░░░░░░░░░ 0.08%  ↑ 33.3%
W04 █░░░░░░░░░░░░░░░░░░░ 0.05%  ↓ 37.5%
W05 ██████████████████░░ 0.86%  ↑1620.0%
W06 █░░░░░░░░░░░░░░░░░░░ 0.07%  ↓ 91.9%
W07 █░░░░░░░░░░░░░░░░░░░ 0.06%  ↓ 14.3%
W08 █░░░░░░░░░░░░░░░░░░░ 0.05%  ↓ 16.7%
W09 █░░░░░░░░░░░░░░░░░░░ 0.06%  ↑ 20.0%
W10 ░░░░░░░░░░░░░░░░░░░░ 0.00%  ↓100.0%
W11 ░░░░░░░░░░░░░░░░░░░░ 0.00%
W12 ░░░░░░░░░░░░░░░░░░░░ 0.00%
W13 ░░░░░░░░░░░░░░░░░░░░ 0.00%
W14 ░░░░░░░░░░░░░░░░░░░░ 0.00%
```

<details>
<summary>Prompt & SQL</summary>

> What is the average special offer discount percentage applied to order lines, per week for the last 13 weeks?

```sql
WITH latest_rel AS (
  SELECT sales_order_detail_key, special_offer_key,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.sales_order_detail_special_offer_x WHERE type_key = 3
), latest_disc AS (
  SELECT special_offer_key, val_num AS discount_pct,
    RANK() OVER (PARTITION BY special_offer_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.special_offer_desc WHERE type_key = 44
), latest_so AS (
  SELECT sales_order_detail_key, sales_order_key,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.sales_order_detail_sales_order_x WHERE type_key = 48
), order_dates AS (
  SELECT sales_order_key, sta_tmstp AS order_date,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.sales_order_desc WHERE type_key = 55
)
SELECT DATE_TRUNC('week', od.order_date) AS week, ROUND(AVG(d.discount_pct)::numeric * 100, 2) AS avg_discount_pct
FROM latest_rel r
JOIN latest_disc d ON r.special_offer_key = d.special_offer_key AND d.nbr = 1 AND d.row_st = 'Y'
JOIN latest_so so ON r.sales_order_detail_key = so.sales_order_detail_key AND so.nbr = 1 AND so.row_st = 'Y'
JOIN order_dates od ON so.sales_order_key = od.sales_order_key AND od.nbr = 1 AND od.row_st = 'Y'
WHERE r.nbr = 1 AND r.row_st = 'Y'
  AND od.order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', od.order_date) ORDER BY week
```
</details>

### Revenue per Sales Person
**Only 2 of 14 weeks have SP-attributed orders (month-end batch weeks)**

```
W01 (2014-03-31) ██████████████████░░ $194,972/SP avg
W05 (2014-04-28) ████████████████████ $213,548/SP avg  ↑ 9.5%
```

<details>
<summary>Prompt & SQL</summary>

> What is the average revenue per sales person per week for the last 13 weeks?

```sql
WITH orders AS (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 110 THEN val_num END) AS sub_total,
    MAX(CASE WHEN type_key = 55 THEN sta_tmstp END) AS order_date
  FROM (SELECT sales_order_key, type_key, row_st, val_num, sta_tmstp,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc WHERE type_key IN (55, 110)) a
  WHERE nbr = 1 AND row_st = 'Y' GROUP BY sales_order_key
), sp AS (
  SELECT sales_order_key, sales_person_key,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.sales_order_sales_person_x WHERE type_key = 117
)
SELECT DATE_TRUNC('week', o.order_date) AS week,
  ROUND(AVG(o.sub_total)::numeric, 2) AS avg_revenue_per_sp
FROM orders o
JOIN sp ON sp.sales_order_key = o.sales_order_key AND sp.nbr = 1 AND sp.row_st = 'Y'
WHERE o.order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', o.order_date) ORDER BY week
```
</details>

### Average Order Value
**↑ 19.4% WoW · $66.09 latest**

```
W01 ██████████████████░░ $5,344
W02 ███░░░░░░░░░░░░░░░░░ $793.84  ↓ 85.1%
W03 ███░░░░░░░░░░░░░░░░░ $899.27  ↑ 13.3%
W04 ███░░░░░░░░░░░░░░░░░ $887.63  ↓  1.3%
W05 ████████████████████ $6,043  ↑580.8%
W06 ███░░░░░░░░░░░░░░░░░ $928.01  ↓ 84.6%
W07 ███░░░░░░░░░░░░░░░░░ $874.30  ↓  5.8%
W08 ███░░░░░░░░░░░░░░░░░ $903.77  ↑  3.4%
W09 ██░░░░░░░░░░░░░░░░░░ $740.62  ↓ 18.1%
W10 █░░░░░░░░░░░░░░░░░░░ $49.03  ↓ 93.4%
W11 █░░░░░░░░░░░░░░░░░░░ $50.59  ↑  3.2%
W12 █░░░░░░░░░░░░░░░░░░░ $52.51  ↑  3.8%
W13 █░░░░░░░░░░░░░░░░░░░ $55.37  ↑  5.4%
W14 █░░░░░░░░░░░░░░░░░░░ $66.09  ↑ 19.4%
```

<details>
<summary>Prompt & SQL</summary>

> What is the average order value (SUM sub_total / COUNT orders) per week for the last 13 weeks?

```sql
SELECT DATE_TRUNC('week', order_date) AS week,
  COUNT(*) AS order_count,
  ROUND((SUM(sub_total) / COUNT(*))::numeric, 2) AS avg_order_value
FROM (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 110 THEN val_num END) AS sub_total,
    MAX(CASE WHEN type_key = 55 THEN sta_tmstp END) AS order_date
  FROM (SELECT sales_order_key, type_key, row_st, val_num, sta_tmstp,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc WHERE type_key IN (55, 110)) a
  WHERE nbr = 1 AND row_st = 'Y' GROUP BY sales_order_key
) b
WHERE order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', order_date) ORDER BY week
```
</details>

---

## Gross Margin

### Gross Margin %
**↑ 1.4% WoW · 56.43% latest**

```
W01 ██░░░░░░░░░░░░░░░░░░ 4.42%
W02 ███████████████░░░░░ 42.11%  ↑852.7%
W03 ███████████████░░░░░ 41.65%  ↓  1.1%
W04 ██████████████░░░░░░ 40.98%  ↓  1.6%
W05 █░░░░░░░░░░░░░░░░░░░ 4.00%  ↓ 90.2%
W06 ███████████████░░░░░ 41.74%  ↑943.5%
W07 ██████████████░░░░░░ 41.23%  ↓  1.2%
W08 ██████████████░░░░░░ 41.17%  ↓  0.1%
W09 ██████████████░░░░░░ 41.50%  ↑  0.8%
W10 ███████████████████░ 55.85%  ↑ 34.6%
W11 ████████████████████ 57.37%  ↑  2.7%
W12 ███████████████████░ 54.65%  ↓  4.7%
W13 ███████████████████░ 55.67%  ↑  1.9%
W14 ████████████████████ 56.43%  ↑  1.4%
```

<details>
<summary>Prompt & SQL</summary>

> What is the gross margin percentage per week for the last 13 weeks, based on line-level revenue vs standard cost?

```sql
WITH detail AS (
  SELECT sales_order_detail_key,
    MAX(CASE WHEN type_key = 60 THEN val_num END) AS order_qty,
    MAX(CASE WHEN type_key = 129 THEN val_num END) AS unit_price
  FROM (SELECT sales_order_detail_key, type_key, row_st, val_num,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_desc WHERE type_key IN (60, 129)) a
  WHERE nbr = 1 AND row_st = 'Y' GROUP BY sales_order_detail_key
), rel_prod AS (
  SELECT sales_order_detail_key, product_key FROM (
    SELECT sales_order_detail_key, product_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_product_x WHERE type_key = 20) a WHERE nbr = 1 AND row_st = 'Y'
), prod AS (
  SELECT product_key, MAX(CASE WHEN type_key = 41 THEN val_num END) AS standard_cost FROM (
    SELECT product_key, type_key, row_st, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc WHERE type_key = 41) a WHERE nbr = 1 AND row_st = 'Y' GROUP BY product_key
), rel_so AS (
  SELECT sales_order_detail_key, sales_order_key FROM (
    SELECT sales_order_detail_key, sales_order_key, row_st,
      RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_sales_order_x WHERE type_key = 48) a WHERE nbr = 1 AND row_st = 'Y'
), od AS (
  SELECT sales_order_key, sta_tmstp AS order_date FROM (
    SELECT sales_order_key, sta_tmstp, row_st,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc WHERE type_key = 55) a WHERE nbr = 1 AND row_st = 'Y'
)
SELECT DATE_TRUNC('week', od.order_date) AS week,
  ROUND(SUM(d.order_qty * d.unit_price)::numeric, 2) AS line_revenue,
  ROUND(SUM(d.order_qty * p.standard_cost)::numeric, 2) AS cogs,
  ROUND(((SUM(d.order_qty * d.unit_price) - SUM(d.order_qty * p.standard_cost))
    / NULLIF(SUM(d.order_qty * d.unit_price), 0) * 100)::numeric, 2) AS gross_margin_pct
FROM detail d
JOIN rel_prod rp ON d.sales_order_detail_key = rp.sales_order_detail_key
JOIN prod p ON rp.product_key = p.product_key
JOIN rel_so rs ON d.sales_order_detail_key = rs.sales_order_detail_key
JOIN od ON rs.sales_order_key = od.sales_order_key
WHERE od.order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', od.order_date) ORDER BY week
```
</details>

### Cost of Goods Sold
**↓ 77.8% WoW · $1,152 latest**

```
W01 ████████████████████ $3,593,712
W02 █░░░░░░░░░░░░░░░░░░░ $233,927  ↓ 93.5%
W03 █░░░░░░░░░░░░░░░░░░░ $259,755  ↑ 11.0%
W04 █░░░░░░░░░░░░░░░░░░░ $244,136  ↓  6.0%
W05 ████████████████████ $3,649,725  ↑1395.0%
W06 ██░░░░░░░░░░░░░░░░░░ $292,474  ↓ 92.0%
W07 █░░░░░░░░░░░░░░░░░░░ $271,792  ↓  7.1%
W08 ██░░░░░░░░░░░░░░░░░░ $282,856  ↑  4.1%
W09 █░░░░░░░░░░░░░░░░░░░ $186,732  ↓ 34.0%
W10 █░░░░░░░░░░░░░░░░░░░ $4,828  ↓ 97.4%
W11 █░░░░░░░░░░░░░░░░░░░ $4,508  ↓  6.6%
W12 █░░░░░░░░░░░░░░░░░░░ $5,286  ↑ 17.3%
W13 █░░░░░░░░░░░░░░░░░░░ $5,179  ↓  2.0%
W14 █░░░░░░░░░░░░░░░░░░░ $1,152  ↓ 77.8%
```

<details>
<summary>Prompt & SQL</summary>

> What is the total cost of goods sold (SUM of order_qty * standard_cost) per week for the last 13 weeks?

```sql
-- Same as Gross Margin query above; extract the total_cogs column
```
</details>

### Make Product Revenue %
**0.00% latest**
*Percentage of weekly revenue from manufactured (make_flag=true) products*


```
W01 ████████████████████ 95.34%
W02 ████████████████████ 93.92%  ↓  1.5%
W03 ████████████████████ 94.73%  ↑  0.9%
W04 ████████████████████ 94.86%  ↑  0.1%
W05 ████████████████████ 95.52%  ↑  0.7%
W06 ████████████████████ 95.10%  ↓  0.4%
W07 ████████████████████ 94.83%  ↓  0.3%
W08 ████████████████████ 94.92%  ↑  0.1%
W09 ████████████████████ 93.84%  ↓  1.1%
W10 ░░░░░░░░░░░░░░░░░░░░ 0.00%  ↓100.0%
W11 ░░░░░░░░░░░░░░░░░░░░ 0.00%
W12 ░░░░░░░░░░░░░░░░░░░░ 0.00%
W13 ░░░░░░░░░░░░░░░░░░░░ 0.00%
W14 ░░░░░░░░░░░░░░░░░░░░ 0.00%
```

<details>
<summary>Prompt & SQL</summary>

> What percentage of weekly revenue comes from manufactured products (make_flag=true) vs purchased products, per week for the last 13 weeks?

```sql
-- Same as Gross Margin query with additional JOIN to product make_flag (type_key=120); GROUP BY week, make_flag
```
</details>

### Purchase Order Volume
**↓ 99.1% WoW · 1 latest**
*Note: PO dates are offset from sales order dates — different 13-week window*


```
W01 █████████████████░░░ 94
W02 ██████████████░░░░░░ 80  ↓ 14.9%
W03 █████████████████░░░ 96  ↑ 20.0%
W04 █████████████████░░░ 96  ↑  0.0%
W05 ████████████████████ 112  ↑ 16.7%
W06 ████████████████████ 112  ↑  0.0%
W07 █░░░░░░░░░░░░░░░░░░░ 1  ↓ 99.1%
```

<details>
<summary>Prompt & SQL</summary>

> How many purchase orders were placed per week for the last 13 weeks?

```sql
SELECT DATE_TRUNC('week', order_date) AS week, COUNT(DISTINCT purchase_order_key) AS po_count
FROM (
  SELECT purchase_order_key, sta_tmstp AS order_date,
    RANK() OVER (PARTITION BY purchase_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.purchase_order_desc WHERE type_key = 98
) a WHERE nbr = 1 AND row_st = 'Y'
  AND order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.purchase_order_desc WHERE type_key = 98)
GROUP BY DATE_TRUNC('week', order_date) ORDER BY week
```
</details>

---

## Fulfillment Cycle Time

### Avg Fulfillment Days
**7.0 days every week — fixed 1-week order-to-ship cycle**

```
W01 ████████████████████ 7.0dchr(10)W02 ████████████████████ 7.0dchr(10)W03 ████████████████████ 7.0dchr(10)W04 ████████████████████ 7.0dchr(10)W05 ████████████████████ 7.0dchr(10)W06 ████████████████████ 7.0dchr(10)W07 ████████████████████ 7.0dchr(10)W08 ████████████████████ 7.0dchr(10)W09 ████████████████████ 7.0dchr(10)W10 ████████████████████ 7.0dchr(10)W11 ████████████████████ 7.0dchr(10)W12 ████████████████████ 7.0dchr(10)W13 ████████████████████ 7.0dchr(10)W14 ████████████████████ 7.0d
```

<details>
<summary>Prompt & SQL</summary>

> What is the average number of days between order date and ship date, per week for the last 13 weeks?

```sql
SELECT DATE_TRUNC('week', order_date) AS week,
  ROUND(AVG(EXTRACT(EPOCH FROM (ship_date - order_date)) / 86400)::numeric, 2) AS avg_fulfillment_days
FROM (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 55 THEN sta_tmstp END) AS order_date,
    MAX(CASE WHEN type_key = 10 THEN end_tmstp END) AS ship_date
  FROM (SELECT sales_order_key, type_key, row_st, sta_tmstp, end_tmstp,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc WHERE type_key IN (55, 10)) a
  WHERE nbr = 1 AND row_st = 'Y' GROUP BY sales_order_key
) b WHERE ship_date IS NOT NULL
  AND order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', order_date) ORDER BY week
```
</details>

### Work Order Volume
**↓ 88.0% WoW · 89 latest**

```
W01 ████████████████████ 830
W02 ████████████████░░░░ 668  ↓ 19.5%
W03 █████████████████░░░ 712  ↑  6.6%
W04 █████████████████░░░ 731  ↑  2.7%
W05 ████████████████████ 844  ↑ 15.5%
W06 ██████████████████░░ 754  ↓ 10.7%
W07 █████████████████░░░ 732  ↓  2.9%
W08 ██████████████████░░ 741  ↑  1.2%
W09 ███████████████████░ 821  ↑ 10.8%
W10 ██████████████████░░ 758  ↓  7.7%
W11 ██████████████████░░ 746  ↓  1.6%
W12 ██████████████████░░ 755  ↑  1.2%
W13 ██████████████████░░ 740  ↓  2.0%
W14 ██░░░░░░░░░░░░░░░░░░ 89  ↓ 88.0%
```

<details>
<summary>Prompt & SQL</summary>

> How many work orders were started per week for the last 13 weeks?

```sql
SELECT DATE_TRUNC('week', start_date) AS week, COUNT(*) AS wo_count
FROM (
  SELECT work_order_key, sta_tmstp AS start_date,
    RANK() OVER (PARTITION BY work_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.work_order_desc WHERE type_key = 128
) a WHERE nbr = 1 AND row_st = 'Y'
  AND start_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.work_order_desc WHERE type_key = 128)
GROUP BY DATE_TRUNC('week', start_date) ORDER BY week
```
</details>

### Scrap Rate
**↓ 100.0% WoW · 0.00% latest**

```
W01 ███░░░░░░░░░░░░░░░░░ 0.08%
W02 ██░░░░░░░░░░░░░░░░░░ 0.05%  ↓ 37.5%
W03 ██░░░░░░░░░░░░░░░░░░ 0.04%  ↓ 20.0%
W04 ██████░░░░░░░░░░░░░░ 0.14%  ↑250.0%
W05 █████████████████░░░ 0.40%  ↑185.7%
W06 ██████████░░░░░░░░░░ 0.23%  ↓ 42.5%
W07 █████████░░░░░░░░░░░ 0.20%  ↓ 13.0%
W08 ███████░░░░░░░░░░░░░ 0.16%  ↓ 20.0%
W09 ██████░░░░░░░░░░░░░░ 0.14%  ↓ 12.5%
W10 ███░░░░░░░░░░░░░░░░░ 0.07%  ↓ 50.0%
W11 ██░░░░░░░░░░░░░░░░░░ 0.04%  ↓ 42.9%
W12 ███░░░░░░░░░░░░░░░░░ 0.07%  ↑ 75.0%
W13 ████████████████████ 0.46%  ↑557.1%
W14 ░░░░░░░░░░░░░░░░░░░░ 0.00%  ↓100.0%
```

<details>
<summary>Prompt & SQL</summary>

> What is the scrap rate (scrapped qty / order qty) per week for the last 13 weeks?

```sql
SELECT DATE_TRUNC('week', s.start_date) AS week,
  SUM(CASE WHEN q.type_key = 4 THEN q.val_num END) AS total_ordered,
  SUM(CASE WHEN q.type_key = 73 THEN q.val_num END) AS total_scrapped,
  ROUND((SUM(CASE WHEN q.type_key = 73 THEN q.val_num END)
    / NULLIF(SUM(CASE WHEN q.type_key = 4 THEN q.val_num END), 0) * 100)::numeric, 2) AS scrap_rate_pct
FROM (SELECT work_order_key, sta_tmstp AS start_date,
  RANK() OVER (PARTITION BY work_order_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.work_order_desc WHERE type_key = 128) s
JOIN (SELECT work_order_key, type_key, val_num,
  RANK() OVER (PARTITION BY work_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.work_order_desc WHERE type_key IN (4, 73)) q
  ON s.work_order_key = q.work_order_key AND q.nbr = 1 AND q.row_st = 'Y'
WHERE s.nbr = 1 AND s.row_st = 'Y'
  AND s.start_date >= (SELECT MAX(sta_tmstp) - INTERVAL '13 weeks' FROM daana_dw.work_order_desc WHERE type_key = 128)
GROUP BY DATE_TRUNC('week', s.start_date) ORDER BY week
```
</details>

### Work Order Completion Rate
**100.0% every week — all started work orders have been completed**

```
W01 ████████████████████ 100.0%chr(10)W02 ████████████████████ 100.0%chr(10)W03 ████████████████████ 100.0%chr(10)W04 ████████████████████ 100.0%chr(10)W05 ████████████████████ 100.0%chr(10)W06 ████████████████████ 100.0%chr(10)W07 ████████████████████ 100.0%chr(10)W08 ████████████████████ 100.0%chr(10)W09 ████████████████████ 100.0%chr(10)W10 ████████████████████ 100.0%chr(10)W11 ████████████████████ 100.0%chr(10)W12 ████████████████████ 100.0%chr(10)W13 ████████████████████ 100.0%chr(10)W14 ████████████████████ 100.0%
```

<details>
<summary>Prompt & SQL</summary>

> What percentage of work orders started each week have been completed (end_date not null), for the last 13 weeks?

```sql
-- Same as Work Order Volume query with LEFT JOIN to end_date (type_key=29);
-- COUNT(end_tmstp) / COUNT(*) * 100 AS completion_rate_pct
```
</details>

---

## Customer Breadth

### Unique Customers
**↓ 80.8% WoW · 40 latest**

```
W01 ████████████████████ 699
W02 ██████████████░░░░░░ 504  ↓ 27.9%
W03 ██████████████░░░░░░ 493  ↓  2.2%
W04 █████████████░░░░░░░ 464  ↓  5.9%
W05 ██████████████████░░ 622  ↑ 34.1%
W06 ███████████████░░░░░ 539  ↓ 13.3%
W07 ███████████████░░░░░ 522  ↓  3.2%
W08 ███████████████░░░░░ 530  ↑  1.5%
W09 ████████████░░░░░░░░ 427  ↓ 19.4%
W10 ██████░░░░░░░░░░░░░░ 222  ↓ 48.0%
W11 ██████░░░░░░░░░░░░░░ 206  ↓  7.2%
W12 ██████░░░░░░░░░░░░░░ 221  ↑  7.3%
W13 ██████░░░░░░░░░░░░░░ 208  ↓  5.9%
W14 █░░░░░░░░░░░░░░░░░░░ 40  ↓ 80.8%
```

<details>
<summary>Prompt & SQL</summary>

> How many unique customers placed at least one order per week, for the last 13 weeks?

```sql
WITH order_dates AS (
  SELECT sales_order_key, sta_tmstp AS order_date,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.sales_order_desc WHERE type_key = 55
), cust_rel AS (
  SELECT sales_order_key, customer_key,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr, row_st
  FROM daana_dw.sales_order_customer_x WHERE type_key = 7
)
SELECT DATE_TRUNC('week', od.order_date) AS week, COUNT(DISTINCT c.customer_key) AS unique_customers
FROM order_dates od
JOIN cust_rel c ON od.sales_order_key = c.sales_order_key AND c.nbr = 1 AND c.row_st = 'Y'
WHERE od.nbr = 1 AND od.row_st = 'Y'
  AND od.order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', od.order_date) ORDER BY week
```
</details>

### New Customers
**↓ 82.3% WoW · 23 latest**

```
W01 ████████████████████ 286
W02 ██████████████████░░ 263  ↓  8.0%
W03 ████████████████████ 284  ↑  8.0%
W04 █████████████████░░░ 241  ↓ 15.1%
W05 █████████████████░░░ 238  ↓  1.2%
W06 ███████████████████░ 278  ↑ 16.8%
W07 ████████████████████ 286  ↑  2.9%
W08 ███████████████████░ 276  ↓  3.5%
W09 ████████████████░░░░ 227  ↓ 17.8%
W10 █████████░░░░░░░░░░░ 133  ↓ 41.4%
W11 ███████░░░░░░░░░░░░░ 107  ↓ 19.5%
W12 █████████░░░░░░░░░░░ 131  ↑ 22.4%
W13 █████████░░░░░░░░░░░ 130  ↓  0.8%
W14 ██░░░░░░░░░░░░░░░░░░ 23  ↓ 82.3%
```

<details>
<summary>Prompt & SQL</summary>

> How many customers placed their first-ever order each week, for the last 13 weeks?

```sql
-- Same as Unique Customers query but with MIN(order_date) per customer across ALL orders;
-- filter to customers whose first order falls within the 13-week window
```
</details>

### Online Order Ratio
**↑ 0.0% WoW · 100.00% latest**

```
W01 ███████████████░░░░░ 74.61%
W02 ████████████████████ 100.00%  ↑ 34.0%
W03 ████████████████████ 100.00%  ↑  0.0%
W04 ████████████████████ 100.00%  ↑  0.0%
W05 ██████████████░░░░░░ 71.13%  ↓ 28.9%
W06 ████████████████████ 100.00%  ↑ 40.6%
W07 ████████████████████ 100.00%  ↑  0.0%
W08 ████████████████████ 100.00%  ↑  0.0%
W09 ████████████████████ 100.00%  ↑  0.0%
W10 ████████████████████ 100.00%  ↑  0.0%
W11 ████████████████████ 100.00%  ↑  0.0%
W12 ████████████████████ 100.00%  ↑  0.0%
W13 ████████████████████ 100.00%  ↑  0.0%
W14 ████████████████████ 100.00%  ↑  0.0%
```

<details>
<summary>Prompt & SQL</summary>

> What percentage of orders were placed online per week, for the last 13 weeks?

```sql
WITH order_flags AS (
  SELECT sales_order_key,
    MAX(CASE WHEN type_key = 55 THEN sta_tmstp END) AS order_date,
    MAX(CASE WHEN type_key = 87 THEN val_str END) AS online_flag
  FROM (SELECT sales_order_key, type_key, row_st, sta_tmstp, val_str,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc WHERE type_key IN (55, 87)) a
  WHERE nbr = 1 AND row_st = 'Y' GROUP BY sales_order_key
)
SELECT DATE_TRUNC('week', order_date) AS week,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN online_flag = 'true' THEN 1 ELSE 0 END) AS online_orders,
  ROUND(100.0 * SUM(CASE WHEN online_flag = 'true' THEN 1 ELSE 0 END) / COUNT(*), 2) AS online_pct
FROM order_flags
WHERE order_date >= (SELECT DATE_TRUNC('week', MAX(sta_tmstp)) - INTERVAL '13 weeks' FROM daana_dw.sales_order_desc WHERE type_key = 55)
GROUP BY DATE_TRUNC('week', order_date) ORDER BY week
```
</details>

### Orders per Sales Person
**Only 2 of 14 weeks have SP-attributed orders (month-end batch weeks)**

```
W01 (2014-03-31) ███████████████████░ 10.5 orders/SP
W05 (2014-04-28) ████████████████████ 11.3 orders/SP  ↑ 8.0%
```

<details>
<summary>Prompt & SQL</summary>

> What is the average number of orders per sales person per week, for the last 13 weeks?

```sql
-- Same as Revenue per SP query but COUNT(orders) instead of SUM(sub_total);
-- then AVG across sales persons per week
```
</details>
