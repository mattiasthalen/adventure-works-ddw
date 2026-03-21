# Weekly Four-Blocker Report

> Generated 2026-03-21 from Adventure Works data warehouse via `/daana:query`

---

## Revenue

### Total Revenue
**$109,846,381.40**

<details>
<summary>Prompt & SQL</summary>

> What is the total revenue across all sales orders?

```sql
SELECT ROUND(SUM(sub_total)::numeric, 2) AS total_revenue
FROM (
  SELECT sales_order_key, val_num AS sub_total,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
  FROM daana_dw.sales_order_desc
  WHERE type_key = 110
) t
WHERE nbr = 1;
```
</details>

### Discount Depth
**0.32%** avg discount across all order lines

<details>
<summary>Prompt & SQL</summary>

> What is the average special offer discount percentage applied to order lines?

```sql
WITH latest_rel AS (
  SELECT sales_order_detail_key, special_offer_key,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr,
    row_st
  FROM daana_dw.sales_order_detail_special_offer_x
  WHERE type_key = 3
),
latest_disc AS (
  SELECT special_offer_key, val_num AS discount_pct,
    RANK() OVER (PARTITION BY special_offer_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr,
    row_st
  FROM daana_dw.special_offer_desc
  WHERE type_key = 44
)
SELECT ROUND(AVG(d.discount_pct)::numeric, 4) AS avg_discount_pct
FROM latest_rel r
JOIN latest_disc d ON r.special_offer_key = d.special_offer_key AND d.nbr = 1 AND d.row_st = 'Y'
WHERE r.nbr = 1 AND r.row_st = 'Y';
```
</details>

### Sales Quota Coverage
**525% - 1,701%** attainment range across quota'd sales persons (3 have no quota)

| sales_person_key | sales_quota | sales_ytd | attainment_pct |
|---|---|---|---|
| 276 | 250,000 | 4,251,368.55 | 1,700.5% |
| 289 | 250,000 | 4,116,871.23 | 1,646.7% |
| 277 | 250,000 | 3,189,418.37 | 1,275.8% |
| 275 | 300,000 | 3,763,178.18 | 1,254.4% |
| 290 | 250,000 | 3,121,616.32 | 1,248.6% |
| 282 | 250,000 | 2,604,540.72 | 1,041.8% |
| 281 | 250,000 | 2,458,535.62 | 983.4% |
| 279 | 300,000 | 2,315,185.61 | 771.7% |
| 288 | 250,000 | 1,827,066.71 | 730.8% |
| 283 | 250,000 | 1,573,012.94 | 629.2% |
| 278 | 250,000 | 1,453,719.47 | 581.5% |
| 286 | 250,000 | 1,421,810.92 | 568.7% |
| 280 | 250,000 | 1,352,577.13 | 541.0% |
| 284 | 300,000 | 1,576,562.20 | 525.5% |

<details>
<summary>Prompt & SQL</summary>

> What is the sales quota vs YTD attainment for each sales person?

```sql
WITH latest AS (
  SELECT sales_person_key, type_key, val_num,
    RANK() OVER (PARTITION BY sales_person_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr,
    row_st
  FROM daana_dw.sales_person_desc
  WHERE type_key IN (5, 88)
)
SELECT sales_person_key,
  MAX(CASE WHEN type_key = 5 THEN val_num END) AS sales_quota,
  MAX(CASE WHEN type_key = 88 THEN val_num END) AS sales_ytd,
  ROUND((MAX(CASE WHEN type_key = 88 THEN val_num END)
    / NULLIF(MAX(CASE WHEN type_key = 5 THEN val_num END), 0) * 100)::numeric, 2) AS attainment_pct
FROM latest
WHERE nbr = 1 AND row_st = 'Y'
GROUP BY sales_person_key
ORDER BY attainment_pct DESC NULLS LAST;
```
</details>

### List Price Positioning
**$621.88** quantity-weighted average list price of products sold

<details>
<summary>Prompt & SQL</summary>

> What is the quantity-weighted average list price of products sold?

```sql
WITH latest_qty AS (
  SELECT sales_order_detail_key, val_num AS order_qty,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr,
    row_st
  FROM daana_dw.sales_order_detail_desc
  WHERE type_key = 60
),
latest_rel AS (
  SELECT sales_order_detail_key, product_key,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr,
    row_st
  FROM daana_dw.sales_order_detail_product_x
  WHERE type_key = 20
),
latest_price AS (
  SELECT product_key, val_num AS list_price,
    RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr,
    row_st
  FROM daana_dw.product_desc
  WHERE type_key = 50
)
SELECT ROUND((SUM(q.order_qty * p.list_price) / SUM(q.order_qty))::numeric, 4) AS qty_weighted_avg_list_price
FROM latest_qty q
JOIN latest_rel r ON q.sales_order_detail_key = r.sales_order_detail_key AND r.nbr = 1 AND r.row_st = 'Y'
JOIN latest_price p ON r.product_key = p.product_key AND p.nbr = 1 AND p.row_st = 'Y'
WHERE q.nbr = 1 AND q.row_st = 'Y';
```
</details>

---

## Gross Margin

### Gross Margin %
**8.97%** ($110.4M revenue vs $100.5M cost at line level)

<details>
<summary>Prompt & SQL</summary>

> What is the gross margin percentage based on line-level revenue and standard cost?

```sql
WITH sod AS (
  SELECT sales_order_detail_key AS entity_key, type_key, val_num,
    RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
  FROM daana_dw.sales_order_detail_desc
  WHERE type_key IN (60, 129) AND row_st = 'Y'
),
sod_pivot AS (
  SELECT entity_key,
    MAX(CASE WHEN type_key = 60 THEN val_num END) AS order_qty,
    MAX(CASE WHEN type_key = 129 THEN val_num END) AS unit_price
  FROM sod WHERE nbr = 1
  GROUP BY entity_key
),
rel AS (
  SELECT sales_order_detail_key, product_key,
    RANK() OVER (PARTITION BY sales_order_detail_key, product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
  FROM daana_dw.sales_order_detail_product_x
  WHERE row_st = 'Y'
),
prod AS (
  SELECT product_key AS entity_key, val_num AS standard_cost,
    RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
  FROM daana_dw.product_desc
  WHERE type_key = 41 AND row_st = 'Y'
)
SELECT
  ROUND(SUM(s.order_qty * s.unit_price)::numeric, 2) AS total_revenue,
  ROUND(SUM(s.order_qty * p.standard_cost)::numeric, 2) AS total_cost,
  ROUND((1 - SUM(s.order_qty * p.standard_cost) / NULLIF(SUM(s.order_qty * s.unit_price), 0)) * 100, 2) AS gross_margin_pct
FROM sod_pivot s
JOIN rel r ON r.sales_order_detail_key = s.entity_key AND r.nbr = 1
JOIN prod p ON p.entity_key = r.product_key AND p.nbr = 1;
```
</details>

### Standard Cost per Unit
**$365.48** quantity-weighted average standard cost

<details>
<summary>Prompt & SQL</summary>

> What is the quantity-weighted average standard cost of products sold?

```sql
WITH sod_qty AS (
  SELECT sales_order_detail_key AS entity_key, MAX(val_num) AS order_qty
  FROM (
    SELECT sales_order_detail_key, val_num,
      RANK() OVER (PARTITION BY sales_order_detail_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_desc
    WHERE type_key = 60 AND row_st = 'Y'
  ) t WHERE nbr = 1
  GROUP BY sales_order_detail_key
),
rel AS (
  SELECT sales_order_detail_key, product_key
  FROM (
    SELECT sales_order_detail_key, product_key,
      RANK() OVER (PARTITION BY sales_order_detail_key, product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_detail_product_x WHERE row_st = 'Y'
  ) t WHERE nbr = 1
),
prod_cost AS (
  SELECT product_key AS entity_key, MAX(val_num) AS standard_cost
  FROM (
    SELECT product_key, val_num,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc WHERE type_key = 41 AND row_st = 'Y'
  ) t WHERE nbr = 1
  GROUP BY product_key
)
SELECT ROUND(SUM(s.order_qty * p.standard_cost) / NULLIF(SUM(s.order_qty), 0), 4) AS weighted_avg_standard_cost
FROM sod_qty s
JOIN rel r ON r.sales_order_detail_key = s.entity_key
JOIN prod_cost p ON p.entity_key = r.product_key;
```
</details>

### Make vs Buy Mix
**47.4%** manufactured in-house / **52.6%** purchased (504 products)

<details>
<summary>Prompt & SQL</summary>

> What percentage of products are manufactured in-house vs purchased?

```sql
WITH prod_flag AS (
  SELECT product_key, MAX(val_str) AS make_flag
  FROM (
    SELECT product_key, val_str,
      RANK() OVER (PARTITION BY product_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.product_desc
    WHERE type_key = 120 AND row_st = 'Y'
  ) t WHERE nbr = 1
  GROUP BY product_key
)
SELECT
  ROUND(COUNT(*) FILTER (WHERE make_flag = 'true') * 100.0 / NULLIF(COUNT(*), 0), 2) AS make_pct,
  ROUND(COUNT(*) FILTER (WHERE make_flag != 'true') * 100.0 / NULLIF(COUNT(*), 0), 2) AS buy_pct,
  COUNT(*) AS total_products
FROM prod_flag;
```
</details>

### Vendor Credit Quality
**1.33** avg credit rating across 100 active vendors (1 = best)

<details>
<summary>Prompt & SQL</summary>

> What is the average credit rating of active vendors?

```sql
WITH vendor_pivot AS (
  SELECT vendor_key,
    MAX(CASE WHEN type_key = 70 THEN val_num END) AS credit_rating,
    MAX(CASE WHEN type_key = 86 THEN val_str END) AS active_flag
  FROM (
    SELECT vendor_key, type_key, val_num, val_str,
      RANK() OVER (PARTITION BY vendor_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.vendor_desc
    WHERE type_key IN (70, 86) AND row_st = 'Y'
  ) t WHERE nbr = 1
  GROUP BY vendor_key
)
SELECT ROUND(AVG(credit_rating), 2) AS avg_credit_rating,
  COUNT(*) AS active_vendor_count
FROM vendor_pivot WHERE active_flag = 'true';
```
</details>

---

## Fulfillment Cycle Time

### Avg Fulfillment Days
**7.0 days** average (range: 7.0 - 8.0)

<details>
<summary>Prompt & SQL</summary>

> What is the average number of days between order date and ship date?

```sql
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
WHERE ship_date IS NOT NULL AND order_date IS NOT NULL;
```
</details>

### Manufacturing Lead Time
**1.90 days** average for products on sold order lines (max: 4 days)

<details>
<summary>Prompt & SQL</summary>

> What is the average days to manufacture for products on sold order lines?

```sql
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
JOIN latest_product lp ON ldp.product_key = lp.product_key;
```
</details>

### Scrap Rate
**0.24%** (10,651 scrapped out of 4,507,721 ordered)

<details>
<summary>Prompt & SQL</summary>

> What is the scrap rate on work orders (scrapped qty / order qty)?

```sql
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
FROM latest_wo;
```
</details>

### Safety Stock Adequacy
**535 units** average safety stock level (range: 4 - 1,000)

<details>
<summary>Prompt & SQL</summary>

> What is the average safety stock level across all products?

```sql
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
FROM latest_product;
```
</details>

---

## Customer Breadth

### Unique Customers
**19,119** customers with at least one order

<details>
<summary>Prompt & SQL</summary>

> How many unique customers have placed at least one sales order?

```sql
SELECT COUNT(DISTINCT customer_key) AS unique_customers
FROM (
  SELECT sales_order_key, customer_key, row_st,
    RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
  FROM daana_dw.sales_order_customer_x
  WHERE type_key = 7
) sub
WHERE nbr = 1 AND row_st = 'Y';
```
</details>

### Territory Coverage

| Territory | Customers |
|---|---|
| Southwest | 4,565 |
| Australia | 3,625 |
| Northwest | 3,428 |
| United Kingdom | 1,951 |
| France | 1,844 |
| Germany | 1,812 |
| Canada | 1,677 |
| Southeast | 91 |
| Central | 69 |
| Northeast | 57 |

<details>
<summary>Prompt & SQL</summary>

> How many customers are in each sales territory?

```sql
WITH latest_cust_terr AS (
  SELECT customer_key, sales_territory_key
  FROM (
    SELECT customer_key, sales_territory_key, row_st,
      RANK() OVER (PARTITION BY customer_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.customer_sales_territory_x
    WHERE type_key = 33
  ) sub WHERE nbr = 1 AND row_st = 'Y'
),
latest_terr_name AS (
  SELECT sales_territory_key, val_str AS territory_name
  FROM (
    SELECT sales_territory_key, val_str, row_st,
      RANK() OVER (PARTITION BY sales_territory_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_territory_desc
    WHERE type_key = 108
  ) sub WHERE nbr = 1 AND row_st = 'Y'
)
SELECT tn.territory_name, COUNT(DISTINCT ct.customer_key) AS customers
FROM latest_cust_terr ct
JOIN latest_terr_name tn ON ct.sales_territory_key = tn.sales_territory_key
GROUP BY tn.territory_name
ORDER BY customers DESC;
```
</details>

### Online Order Ratio
**87.9%** online (27,659 of 31,465 orders)

<details>
<summary>Prompt & SQL</summary>

> What percentage of sales orders are placed online?

```sql
WITH latest_online_flag AS (
  SELECT sales_order_key, val_str AS online_order_flag
  FROM (
    SELECT sales_order_key, val_str, row_st,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_desc
    WHERE type_key = 87
  ) sub WHERE nbr = 1 AND row_st = 'Y'
)
SELECT
  COUNT(*) AS total_orders,
  SUM(CASE WHEN online_order_flag = 'true' THEN 1 ELSE 0 END) AS online_orders,
  ROUND(100.0 * SUM(CASE WHEN online_order_flag = 'true' THEN 1 ELSE 0 END) / COUNT(*), 2) AS online_pct
FROM latest_online_flag;
```
</details>

### Sales Person Reach
**51** avg unique customers per sales person (17 sales persons, 635 customers via SP channel)

<details>
<summary>Prompt & SQL</summary>

> What is the average number of unique customers per sales person?

```sql
WITH latest_order_cust AS (
  SELECT sales_order_key, customer_key
  FROM (
    SELECT sales_order_key, customer_key, row_st,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_customer_x
    WHERE type_key = 7
  ) sub WHERE nbr = 1 AND row_st = 'Y'
),
latest_order_sp AS (
  SELECT sales_order_key, sales_person_key
  FROM (
    SELECT sales_order_key, sales_person_key, row_st,
      RANK() OVER (PARTITION BY sales_order_key, type_key ORDER BY eff_tmstp DESC, ver_tmstp DESC) AS nbr
    FROM daana_dw.sales_order_sales_person_x
    WHERE type_key = 117
  ) sub WHERE nbr = 1 AND row_st = 'Y'
),
sp_customers AS (
  SELECT sp.sales_person_key, COUNT(DISTINCT oc.customer_key) AS unique_customers
  FROM latest_order_sp sp
  JOIN latest_order_cust oc ON sp.sales_order_key = oc.sales_order_key
  GROUP BY sp.sales_person_key
)
SELECT ROUND(AVG(unique_customers), 2) AS avg_customers_per_sales_person
FROM sp_customers;
```
</details>
