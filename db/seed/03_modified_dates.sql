-- Adventure Works for PostgreSQL — Modified Date Updates
-- Sets business-meaningful modified_date values for CDC/incremental processing

-- =============================================
-- TRANSACTIONAL: Use own business dates
-- =============================================

UPDATE das.aw__sales__sales_order_header
SET modified_date = order_date;

UPDATE das.aw__sales__sales_order_detail d
SET modified_date = h.order_date
FROM das.aw__sales__sales_order_header h
WHERE d.sales_order_id = h.sales_order_id;

UPDATE das.aw__sales__sales_order_header_sales_reason r
SET modified_date = h.order_date
FROM das.aw__sales__sales_order_header h
WHERE r.sales_order_id = h.sales_order_id;

UPDATE das.aw__purchasing__purchase_order_header
SET modified_date = order_date;

UPDATE das.aw__purchasing__purchase_order_detail d
SET modified_date = h.order_date
FROM das.aw__purchasing__purchase_order_header h
WHERE d.purchase_order_id = h.purchase_order_id;

UPDATE das.aw__production__transaction_history
SET modified_date = transaction_date;

UPDATE das.aw__production__transaction_history_archive
SET modified_date = transaction_date;

UPDATE das.aw__sales__currency_rate
SET modified_date = currency_rate_date;

UPDATE das.aw__sales__shopping_cart_item
SET modified_date = date_created;

UPDATE das.aw__production__work_order
SET modified_date = start_date;

UPDATE das.aw__production__work_order_routing
SET modified_date = scheduled_start_date;

UPDATE das.aw__production__bill_of_materials
SET modified_date = start_date;

-- =============================================
-- HISTORY TABLES: Use own temporal columns
-- =============================================

UPDATE das.aw__human_resources__employee_department_history
SET modified_date = start_date;

UPDATE das.aw__human_resources__employee_pay_history
SET modified_date = rate_change_date;

UPDATE das.aw__production__product_cost_history
SET modified_date = start_date;

UPDATE das.aw__production__product_list_price_history
SET modified_date = start_date;

UPDATE das.aw__sales__sales_territory_history
SET modified_date = start_date;

UPDATE das.aw__sales__sales_person_quota_history
SET modified_date = quota_date;

-- =============================================
-- PRODUCT/CATALOG: Lead time before sell start
-- =============================================

UPDATE das.aw__production__product
SET modified_date = sell_start_date - INTERVAL '30 days';

UPDATE das.aw__production__product_review
SET modified_date = review_date;

UPDATE das.aw__production__product_model pm
SET modified_date = sub.earliest - INTERVAL '7 days'
FROM (
  SELECT product_model_id, MIN(modified_date) AS earliest
  FROM das.aw__production__product
  WHERE product_model_id IS NOT NULL
  GROUP BY product_model_id
) sub
WHERE pm.product_model_id = sub.product_model_id;

UPDATE das.aw__production__product_subcategory ps
SET modified_date = sub.earliest - INTERVAL '7 days'
FROM (
  SELECT product_subcategory_id, MIN(modified_date) AS earliest
  FROM das.aw__production__product
  WHERE product_subcategory_id IS NOT NULL
  GROUP BY product_subcategory_id
) sub
WHERE ps.product_subcategory_id = sub.product_subcategory_id;

UPDATE das.aw__production__product_category pc
SET modified_date = sub.earliest - INTERVAL '7 days'
FROM (
  SELECT product_category_id, MIN(modified_date) AS earliest
  FROM das.aw__production__product_subcategory
  GROUP BY product_category_id
) sub
WHERE pc.product_category_id = sub.product_category_id;

UPDATE das.aw__production__product_description pd
SET modified_date = sub.earliest
FROM (
  SELECT pmpdc.product_description_id, MIN(pm.modified_date) AS earliest
  FROM das.aw__production__product_model_product_description_culture pmpdc
  JOIN das.aw__production__product_model pm ON pm.product_model_id = pmpdc.product_model_id
  GROUP BY pmpdc.product_description_id
) sub
WHERE pd.product_description_id = sub.product_description_id;

UPDATE das.aw__production__product_inventory pi
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE pi.product_id = p.product_id;

UPDATE das.aw__production__product_document pd
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE pd.product_id = p.product_id;

UPDATE das.aw__production__product_product_photo ppp
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE ppp.product_id = p.product_id;

UPDATE das.aw__production__product_photo pp
SET modified_date = sub.earliest
FROM (
  SELECT product_photo_id, MIN(p.modified_date) AS earliest
  FROM das.aw__production__product_product_photo ppp
  JOIN das.aw__production__product p ON p.product_id = ppp.product_id
  GROUP BY product_photo_id
) sub
WHERE pp.product_photo_id = sub.product_photo_id;

UPDATE das.aw__production__product_model_illustration pmi
SET modified_date = pm.modified_date
FROM das.aw__production__product_model pm
WHERE pmi.product_model_id = pm.product_model_id;

UPDATE das.aw__production__product_model_product_description_culture pmpdc
SET modified_date = pm.modified_date
FROM das.aw__production__product_model pm
WHERE pmpdc.product_model_id = pm.product_model_id;

UPDATE das.aw__production__illustration i
SET modified_date = sub.earliest
FROM (
  SELECT illustration_id, MIN(pm.modified_date) AS earliest
  FROM das.aw__production__product_model_illustration pmi
  JOIN das.aw__production__product_model pm ON pm.product_model_id = pmi.product_model_id
  GROUP BY illustration_id
) sub
WHERE i.illustration_id = sub.illustration_id;

UPDATE das.aw__production__document d
SET modified_date = sub.earliest
FROM (
  SELECT document_node, MIN(p.modified_date) AS earliest
  FROM das.aw__production__product_document pd
  JOIN das.aw__production__product p ON p.product_id = pd.product_id
  GROUP BY document_node
) sub
WHERE d.document_node = sub.document_node;

UPDATE das.aw__sales__special_offer
SET modified_date = start_date;

UPDATE das.aw__sales__special_offer_product sop
SET modified_date = so.modified_date
FROM das.aw__sales__special_offer so
WHERE sop.special_offer_id = so.special_offer_id;

UPDATE das.aw__purchasing__product_vendor pv
SET modified_date = p.modified_date
FROM das.aw__production__product p
WHERE pv.product_id = p.product_id;

-- =============================================
-- ENTITY TABLES: Derive from related data
-- =============================================

UPDATE das.aw__human_resources__employee
SET modified_date = hire_date;

UPDATE das.aw__sales__customer c
SET modified_date = sub.first_order
FROM (
  SELECT customer_id, MIN(order_date) AS first_order
  FROM das.aw__sales__sales_order_header
  GROUP BY customer_id
) sub
WHERE c.customer_id = sub.customer_id;

UPDATE das.aw__sales__store s
SET modified_date = sub.earliest
FROM (
  SELECT store_id, MIN(modified_date) AS earliest
  FROM das.aw__sales__customer
  WHERE store_id IS NOT NULL
  GROUP BY store_id
) sub
WHERE s.business_entity_id = sub.store_id;

UPDATE das.aw__sales__sales_person sp
SET modified_date = e.hire_date
FROM das.aw__human_resources__employee e
WHERE sp.business_entity_id = e.business_entity_id;

UPDATE das.aw__purchasing__vendor v
SET modified_date = sub.earliest
FROM (
  SELECT vendor_id, MIN(order_date) AS earliest
  FROM das.aw__purchasing__purchase_order_header
  GROUP BY vendor_id
) sub
WHERE v.business_entity_id = sub.vendor_id;

-- Person: set employees first, then customers
UPDATE das.aw__person__person p
SET modified_date = e.hire_date
FROM das.aw__human_resources__employee e
WHERE p.business_entity_id = e.business_entity_id;

UPDATE das.aw__person__person p
SET modified_date = c.modified_date
FROM das.aw__sales__customer c
WHERE c.person_id = p.business_entity_id
  AND p.modified_date > c.modified_date;

UPDATE das.aw__person__business_entity be
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE be.business_entity_id = p.business_entity_id;

UPDATE das.aw__person__address a
SET modified_date = sub.earliest
FROM (
  SELECT address_id, MIN(be.modified_date) AS earliest
  FROM das.aw__person__business_entity_address bea
  JOIN das.aw__person__business_entity be ON be.business_entity_id = bea.business_entity_id
  GROUP BY address_id
) sub
WHERE a.address_id = sub.address_id;

UPDATE das.aw__person__business_entity_address bea
SET modified_date = be.modified_date
FROM das.aw__person__business_entity be
WHERE bea.business_entity_id = be.business_entity_id;

UPDATE das.aw__person__business_entity_contact bec
SET modified_date = be.modified_date
FROM das.aw__person__business_entity be
WHERE bec.business_entity_id = be.business_entity_id;

UPDATE das.aw__person__email_address ea
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE ea.business_entity_id = p.business_entity_id;

UPDATE das.aw__person__password pw
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE pw.business_entity_id = p.business_entity_id;

UPDATE das.aw__person__person_phone pp
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE pp.business_entity_id = p.business_entity_id;

UPDATE das.aw__sales__person_credit_card pcc
SET modified_date = p.modified_date
FROM das.aw__person__person p
WHERE pcc.business_entity_id = p.business_entity_id;

UPDATE das.aw__sales__credit_card cc
SET modified_date = sub.earliest
FROM (
  SELECT credit_card_id, MIN(modified_date) AS earliest
  FROM das.aw__sales__person_credit_card
  GROUP BY credit_card_id
) sub
WHERE cc.credit_card_id = sub.credit_card_id;

UPDATE das.aw__human_resources__job_candidate jc
SET modified_date = e.hire_date - INTERVAL '60 days'
FROM das.aw__human_resources__employee e
WHERE jc.business_entity_id = e.business_entity_id;

-- =============================================
-- REFERENCE/LOOKUP: System epoch
-- =============================================

DO $$
DECLARE
  epoch TIMESTAMP;
BEGIN
  SELECT MIN(order_date) INTO epoch
  FROM das.aw__sales__sales_order_header;

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
