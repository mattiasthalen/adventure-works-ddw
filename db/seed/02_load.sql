-- Adventure Works for PostgreSQL — Data Loading
-- Loads CSV data from NorfolkDataSci/adventure-works-postgres

-- =============================================
-- Person
-- =============================================

COPY das.aw__person__business_entity FROM '/docker-entrypoint-initdb.d/data/BusinessEntity.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__person FROM '/docker-entrypoint-initdb.d/data/Person.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__state_province FROM '/docker-entrypoint-initdb.d/data/StateProvince.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__address FROM '/docker-entrypoint-initdb.d/data/Address.csv' DELIMITER E'\t' CSV ENCODING 'latin1';
COPY das.aw__person__address_type FROM '/docker-entrypoint-initdb.d/data/AddressType.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__business_entity_address FROM '/docker-entrypoint-initdb.d/data/BusinessEntityAddress.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__contact_type FROM '/docker-entrypoint-initdb.d/data/ContactType.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__business_entity_contact FROM '/docker-entrypoint-initdb.d/data/BusinessEntityContact.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__email_address FROM '/docker-entrypoint-initdb.d/data/EmailAddress.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__password FROM '/docker-entrypoint-initdb.d/data/Password.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__phone_number_type FROM '/docker-entrypoint-initdb.d/data/PhoneNumberType.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__person_phone FROM '/docker-entrypoint-initdb.d/data/PersonPhone.csv' DELIMITER E'\t' CSV;
COPY das.aw__person__country_region FROM '/docker-entrypoint-initdb.d/data/CountryRegion.csv' DELIMITER E'\t' CSV;

-- =============================================
-- HumanResources
-- =============================================

COPY das.aw__human_resources__department FROM '/docker-entrypoint-initdb.d/data/Department.csv' DELIMITER E'\t' CSV;
COPY das.aw__human_resources__employee FROM '/docker-entrypoint-initdb.d/data/Employee.csv' DELIMITER E'\t' CSV;
COPY das.aw__human_resources__employee_department_history FROM '/docker-entrypoint-initdb.d/data/EmployeeDepartmentHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__human_resources__employee_pay_history FROM '/docker-entrypoint-initdb.d/data/EmployeePayHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__human_resources__job_candidate FROM '/docker-entrypoint-initdb.d/data/JobCandidate.csv' DELIMITER E'\t' CSV ENCODING 'latin1';
COPY das.aw__human_resources__shift FROM '/docker-entrypoint-initdb.d/data/Shift.csv' DELIMITER E'\t' CSV;

-- Employee hierarchy conversion
ALTER TABLE das.aw__human_resources__employee DROP COLUMN organization_level;
ALTER TABLE das.aw__human_resources__employee ADD organizationnode VARCHAR DEFAULT '/';

-- Convert from all the hex to a stream of hierarchyid bits
WITH RECURSIVE hier AS (
  SELECT business_entity_id, org, get_byte(decode(substring(org, 1, 2), 'hex'), 0)::bit(8)::varchar AS bits, 2 AS i
    FROM das.aw__human_resources__employee
  UNION ALL
  SELECT e.business_entity_id, e.org, hier.bits || get_byte(decode(substring(e.org, i + 1, 2), 'hex'), 0)::bit(8)::varchar, i + 2 AS i
    FROM das.aw__human_resources__employee AS e INNER JOIN
      hier ON e.business_entity_id = hier.business_entity_id AND i < LENGTH(e.org)
)
UPDATE das.aw__human_resources__employee AS emp
  SET org = COALESCE(trim(trailing '0' FROM hier.bits::TEXT), '')
  FROM hier
  WHERE emp.business_entity_id = hier.business_entity_id
    AND (hier.org IS NULL OR i = LENGTH(hier.org));

-- Convert bits to the real hierarchy paths
CREATE OR REPLACE FUNCTION f_convert_org_nodes()
  RETURNS void AS
$func$
DECLARE
  got_none BOOLEAN;
BEGIN
  LOOP
  got_none := true;
  -- 01 = 0-3
  UPDATE das.aw__human_resources__employee
   SET organizationnode = organizationnode || SUBSTRING(org, 3,2)::bit(2)::INTEGER::VARCHAR || CASE SUBSTRING(org, 5, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 6, 9999)
    WHERE org LIKE '01%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 100 = 4-7
  UPDATE das.aw__human_resources__employee
   SET organizationnode = organizationnode || (SUBSTRING(org, 4,2)::bit(2)::INTEGER + 4)::VARCHAR || CASE SUBSTRING(org, 6, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 7, 9999)
    WHERE org LIKE '100%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 101 = 8-15
  UPDATE das.aw__human_resources__employee
   SET organizationnode = organizationnode || (SUBSTRING(org, 4,3)::bit(3)::INTEGER + 8)::VARCHAR || CASE SUBSTRING(org, 7, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 8, 9999)
    WHERE org LIKE '101%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 110 = 16-79
  UPDATE das.aw__human_resources__employee
   SET organizationnode = organizationnode || ((SUBSTRING(org, 4,2)||SUBSTRING(org, 7,1)||SUBSTRING(org, 9,3))::bit(6)::INTEGER + 16)::VARCHAR || CASE SUBSTRING(org, 12, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 13, 9999)
    WHERE org LIKE '110%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 1110 = 80-1103
  UPDATE das.aw__human_resources__employee
   SET organizationnode = organizationnode || ((SUBSTRING(org, 5,3)||SUBSTRING(org, 9,3)||SUBSTRING(org, 13,1)||SUBSTRING(org, 15,3))::bit(10)::INTEGER + 80)::VARCHAR || CASE SUBSTRING(org, 18, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 19, 9999)
    WHERE org LIKE '1110%';
  IF FOUND THEN
    got_none := false;
  END IF;
  EXIT WHEN got_none;
  END LOOP;
END
$func$ LANGUAGE plpgsql;

SELECT f_convert_org_nodes();
ALTER TABLE das.aw__human_resources__employee DROP COLUMN org;
DROP FUNCTION f_convert_org_nodes();

-- =============================================
-- Production
-- =============================================

COPY das.aw__production__bill_of_materials FROM '/docker-entrypoint-initdb.d/data/BillOfMaterials.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__culture FROM '/docker-entrypoint-initdb.d/data/Culture.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__document FROM '/docker-entrypoint-initdb.d/data/Document.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_category FROM '/docker-entrypoint-initdb.d/data/ProductCategory.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_subcategory FROM '/docker-entrypoint-initdb.d/data/ProductSubcategory.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_model FROM '/docker-entrypoint-initdb.d/data/ProductModel.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product FROM '/docker-entrypoint-initdb.d/data/Product.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_cost_history FROM '/docker-entrypoint-initdb.d/data/ProductCostHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_description FROM '/docker-entrypoint-initdb.d/data/ProductDescription.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_document FROM '/docker-entrypoint-initdb.d/data/ProductDocument.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__location FROM '/docker-entrypoint-initdb.d/data/Location.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_inventory FROM '/docker-entrypoint-initdb.d/data/ProductInventory.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_list_price_history FROM '/docker-entrypoint-initdb.d/data/ProductListPriceHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__illustration FROM '/docker-entrypoint-initdb.d/data/Illustration.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_model_illustration FROM '/docker-entrypoint-initdb.d/data/ProductModelIllustration.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_model_product_description_culture FROM '/docker-entrypoint-initdb.d/data/ProductModelProductDescriptionCulture.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_photo FROM '/docker-entrypoint-initdb.d/data/ProductPhoto.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__product_product_photo FROM '/docker-entrypoint-initdb.d/data/ProductProductPhoto.csv' DELIMITER E'\t' CSV;

-- ProductReview is inserted directly (CSV doesn't work for this table)
INSERT INTO das.aw__production__product_review (product_review_id, product_id, reviewer_name, review_date, email_address, rating, comments, modified_date) VALUES
 (1, 709, 'John Smith', '2013-09-18 00:00:00', 'john@fourthcoffee.com', 5, 'I can''t believe I''m singing the praises of a pair of socks, but I just came back from a grueling
3-day ride and these socks really helped make the trip a blast. They''re lightweight yet really cushioned my feet all day.
The reinforced toe is nearly bullet-proof and I didn''t experience any problems with rubbing or blisters like I have with
other brands. I know it sounds silly, but it''s always the little stuff (like comfortable feet) that makes or breaks a long trip.
I won''t go on another trip without them!', '2013-09-18 00:00:00'),

 (2, 937, 'David', '2013-11-13 00:00:00', 'david@graphicdesigninstitute.com', 4, 'A little on the heavy side, but overall the entry/exit is easy in all conditions. I''ve used these pedals for
more than 3 years and I''ve never had a problem. Cleanup is easy. Mud and sand don''t get trapped. I would like
them even better if there was a weight reduction. Maybe in the next design. Still, I would recommend them to a friend.', '2013-11-13 00:00:00'),

 (3, 937, 'Jill', '2013-11-15 00:00:00', 'jill@margiestravel.com', 2, 'Maybe it''s just because I''m new to mountain biking, but I had a terrible time getting use
to these pedals. In my first outing, I wiped out trying to release my foot. Any suggestions on
ways I can adjust the pedals, or is it just a learning curve thing?', '2013-11-15 00:00:00'),

 (4, 798, 'Laura Norman', '2013-11-15 00:00:00', 'laura@treyresearch.net', 5, 'The Road-550-W from Adventure Works Cycles is everything it''s advertised to be. Finally, a quality bike that
is actually built for a woman and provides control and comfort in one neat package. The top tube is shorter, the suspension is weight-tuned and there''s a much shorter reach to the brake
levers. All this adds up to a great mountain bike that is sure to accommodate any woman''s anatomy. In addition to getting the size right, the saddle is incredibly comfortable.
Attention to detail is apparent in every aspect from the frame finish to the careful design of each component. Each component is a solid performer without any fluff.
The designers clearly did their homework and thought about size, weight, and funtionality throughout. And at less than 19 pounds, the bike is manageable for even the most petite cyclist.

We had 5 riders take the bike out for a spin and really put it to the test. The results were consistent and very positive. Our testers loved the manuverability
and control they had with the redesigned frame on the 550-W. A definite improvement over the 2012 design. Four out of five testers listed quick handling
and responsivness were the key elements they noticed. Technical climbing and on the flats, the bike just cruises through the rough. Tight corners and obstacles were handled effortlessly. The fifth tester was more impressed with the smooth ride. The heavy-duty shocks absorbed even the worst bumps and provided a soft ride on all but the
nastiest trails and biggest drops. The shifting was rated superb and typical of what we''ve come to expect from Adventure Works Cycles. On descents, the bike handled flawlessly and tracked very well. The bike is well balanced front-to-rear and frame flex was minimal. In particular, the testers
noted that the brake system had a unique combination of power and modulation.  While some brake setups can be overly touchy, these brakes had a good
amount of power, but also a good feel that allows you to apply as little or as much braking power as is needed. Second is their short break-in period. We found that they tend to break-in well before
the end of the first ride; while others take two to three rides (or more) to come to full power.

On the negative side, the pedals were not quite up to our tester''s standards.
Just for fun, we experimented with routine maintenance tasks. Overall we found most operations to be straight forward and easy to complete. The only exception was replacing the front wheel. The maintenance manual that comes
with the bike say to install the front wheel with the axle quick release or bolt, then compress the fork a few times before fastening and tightening the two quick-release mechanisms on the bottom of the dropouts. This is to seat the axle in the dropouts, and if you do not
do this, the axle will become seated after you tightened the two bottom quick releases, which will then become loose. It''s better to test the tightness carefully or you may notice that the two bottom quick releases have come loose enough to fall completely open. And that''s something you don''t want to experience
while out on the road!

The Road-550-W frame is available in a variety of sizes and colors and has the same durable, high-quality aluminum that AWC is known for. At a MSRP of just under $1125.00, it''s comparable in price to its closest competitors and
we think that after a test drive you''l find the quality and performance above and beyond . You''ll have a grin on your face and be itching to get out on the road for more. While designed for serious road racing, the Road-550-W would be an excellent choice for just about any terrain and
any level of experience. It''s a huge step in the right direction for female cyclists and well worth your consideration and hard-earned money.', '2013-11-15 00:00:00');

COPY das.aw__production__scrap_reason FROM '/docker-entrypoint-initdb.d/data/ScrapReason.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__transaction_history FROM '/docker-entrypoint-initdb.d/data/TransactionHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__transaction_history_archive FROM '/docker-entrypoint-initdb.d/data/TransactionHistoryArchive.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__unit_measure FROM '/docker-entrypoint-initdb.d/data/UnitMeasure.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__work_order FROM '/docker-entrypoint-initdb.d/data/WorkOrder.csv' DELIMITER E'\t' CSV;
COPY das.aw__production__work_order_routing FROM '/docker-entrypoint-initdb.d/data/WorkOrderRouting.csv' DELIMITER E'\t' CSV;

-- Drop calculated columns from Production
ALTER TABLE das.aw__production__work_order DROP COLUMN stocked_qty;
ALTER TABLE das.aw__production__document DROP COLUMN document_level;

-- Document hierarchy conversion
ALTER TABLE das.aw__production__document ADD document_node VARCHAR DEFAULT '/';
WITH RECURSIVE hier AS (
  SELECT rowguid, doc, get_byte(decode(substring(doc, 1, 2), 'hex'), 0)::bit(8)::varchar AS bits, 2 AS i
    FROM das.aw__production__document
  UNION ALL
  SELECT e.rowguid, e.doc, hier.bits || get_byte(decode(substring(e.doc, i + 1, 2), 'hex'), 0)::bit(8)::varchar, i + 2 AS i
    FROM das.aw__production__document AS e INNER JOIN
      hier ON e.rowguid = hier.rowguid AND i < LENGTH(e.doc)
)
UPDATE das.aw__production__document AS emp
  SET doc = COALESCE(trim(trailing '0' FROM hier.bits::TEXT), '')
  FROM hier
  WHERE emp.rowguid = hier.rowguid
    AND (hier.doc IS NULL OR i = LENGTH(hier.doc));

CREATE OR REPLACE FUNCTION f_convert_doc_nodes()
  RETURNS void AS
$func$
DECLARE
  got_none BOOLEAN;
BEGIN
  LOOP
  got_none := true;
  -- 01 = 0-3
  UPDATE das.aw__production__document
   SET document_node = document_node || SUBSTRING(doc, 3,2)::bit(2)::INTEGER::VARCHAR || CASE SUBSTRING(doc, 5, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 6, 9999)
    WHERE doc LIKE '01%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 100 = 4-7
  UPDATE das.aw__production__document
   SET document_node = document_node || (SUBSTRING(doc, 4,2)::bit(2)::INTEGER + 4)::VARCHAR || CASE SUBSTRING(doc, 6, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 7, 9999)
    WHERE doc LIKE '100%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 101 = 8-15
  UPDATE das.aw__production__document
   SET document_node = document_node || (SUBSTRING(doc, 4,3)::bit(3)::INTEGER + 8)::VARCHAR || CASE SUBSTRING(doc, 7, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 8, 9999)
    WHERE doc LIKE '101%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 110 = 16-79
  UPDATE das.aw__production__document
   SET document_node = document_node || ((SUBSTRING(doc, 4,2)||SUBSTRING(doc, 7,1)||SUBSTRING(doc, 9,3))::bit(6)::INTEGER + 16)::VARCHAR || CASE SUBSTRING(doc, 12, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 13, 9999)
    WHERE doc LIKE '110%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 1110 = 80-1103
  UPDATE das.aw__production__document
   SET document_node = document_node || ((SUBSTRING(doc, 5,3)||SUBSTRING(doc, 9,3)||SUBSTRING(doc, 13,1)||SUBSTRING(doc, 15,3))::bit(10)::INTEGER + 80)::VARCHAR || CASE SUBSTRING(doc, 18, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 19, 9999)
    WHERE doc LIKE '1110%';
  IF FOUND THEN
    got_none := false;
  END IF;
  EXIT WHEN got_none;
  END LOOP;
END
$func$ LANGUAGE plpgsql;

SELECT f_convert_doc_nodes();
ALTER TABLE das.aw__production__document DROP COLUMN doc;
DROP FUNCTION f_convert_doc_nodes();

-- ProductDocument hierarchy conversion
ALTER TABLE das.aw__production__product_document ADD document_node VARCHAR DEFAULT '/';
ALTER TABLE das.aw__production__product_document ADD rowguid uuid NOT NULL CONSTRAINT df_product_document_rowguid DEFAULT (uuid_generate_v1());
WITH RECURSIVE hier AS (
  SELECT rowguid, doc, get_byte(decode(substring(doc, 1, 2), 'hex'), 0)::bit(8)::varchar AS bits, 2 AS i
    FROM das.aw__production__product_document
  UNION ALL
  SELECT e.rowguid, e.doc, hier.bits || get_byte(decode(substring(e.doc, i + 1, 2), 'hex'), 0)::bit(8)::varchar, i + 2 AS i
    FROM das.aw__production__product_document AS e INNER JOIN
      hier ON e.rowguid = hier.rowguid AND i < LENGTH(e.doc)
)
UPDATE das.aw__production__product_document AS emp
  SET doc = COALESCE(trim(trailing '0' FROM hier.bits::TEXT), '')
  FROM hier
  WHERE emp.rowguid = hier.rowguid
    AND (hier.doc IS NULL OR i = LENGTH(hier.doc));

CREATE OR REPLACE FUNCTION f_convert_product_doc_nodes()
  RETURNS void AS
$func$
DECLARE
  got_none BOOLEAN;
BEGIN
  LOOP
  got_none := true;
  -- 01 = 0-3
  UPDATE das.aw__production__product_document
   SET document_node = document_node || SUBSTRING(doc, 3,2)::bit(2)::INTEGER::VARCHAR || CASE SUBSTRING(doc, 5, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 6, 9999)
    WHERE doc LIKE '01%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 100 = 4-7
  UPDATE das.aw__production__product_document
   SET document_node = document_node || (SUBSTRING(doc, 4,2)::bit(2)::INTEGER + 4)::VARCHAR || CASE SUBSTRING(doc, 6, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 7, 9999)
    WHERE doc LIKE '100%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 101 = 8-15
  UPDATE das.aw__production__product_document
   SET document_node = document_node || (SUBSTRING(doc, 4,3)::bit(3)::INTEGER + 8)::VARCHAR || CASE SUBSTRING(doc, 7, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 8, 9999)
    WHERE doc LIKE '101%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 110 = 16-79
  UPDATE das.aw__production__product_document
   SET document_node = document_node || ((SUBSTRING(doc, 4,2)||SUBSTRING(doc, 7,1)||SUBSTRING(doc, 9,3))::bit(6)::INTEGER + 16)::VARCHAR || CASE SUBSTRING(doc, 12, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 13, 9999)
    WHERE doc LIKE '110%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 1110 = 80-1103
  UPDATE das.aw__production__product_document
   SET document_node = document_node || ((SUBSTRING(doc, 5,3)||SUBSTRING(doc, 9,3)||SUBSTRING(doc, 13,1)||SUBSTRING(doc, 15,3))::bit(10)::INTEGER + 80)::VARCHAR || CASE SUBSTRING(doc, 18, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 19, 9999)
    WHERE doc LIKE '1110%';
  IF FOUND THEN
    got_none := false;
  END IF;
  EXIT WHEN got_none;
  END LOOP;
END
$func$ LANGUAGE plpgsql;

SELECT f_convert_product_doc_nodes();
ALTER TABLE das.aw__production__product_document DROP COLUMN doc;
DROP FUNCTION f_convert_product_doc_nodes();
ALTER TABLE das.aw__production__product_document DROP COLUMN rowguid;

-- =============================================
-- Purchasing
-- =============================================

COPY das.aw__purchasing__product_vendor FROM '/docker-entrypoint-initdb.d/data/ProductVendor.csv' DELIMITER E'\t' CSV;
COPY das.aw__purchasing__purchase_order_detail FROM '/docker-entrypoint-initdb.d/data/PurchaseOrderDetail.csv' DELIMITER E'\t' CSV;
COPY das.aw__purchasing__purchase_order_header FROM '/docker-entrypoint-initdb.d/data/PurchaseOrderHeader.csv' DELIMITER E'\t' CSV;
COPY das.aw__purchasing__ship_method FROM '/docker-entrypoint-initdb.d/data/ShipMethod.csv' DELIMITER E'\t' CSV;
COPY das.aw__purchasing__vendor FROM '/docker-entrypoint-initdb.d/data/Vendor.csv' DELIMITER E'\t' CSV;

-- Drop calculated columns from Purchasing
ALTER TABLE das.aw__purchasing__purchase_order_detail DROP COLUMN line_total;
ALTER TABLE das.aw__purchasing__purchase_order_detail DROP COLUMN stocked_qty;
ALTER TABLE das.aw__purchasing__purchase_order_header DROP COLUMN total_due;

-- =============================================
-- Sales
-- =============================================

COPY das.aw__sales__country_region_currency FROM '/docker-entrypoint-initdb.d/data/CountryRegionCurrency.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__credit_card FROM '/docker-entrypoint-initdb.d/data/CreditCard.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__currency FROM '/docker-entrypoint-initdb.d/data/Currency.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__currency_rate FROM '/docker-entrypoint-initdb.d/data/CurrencyRate.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__customer FROM '/docker-entrypoint-initdb.d/data/Customer.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__person_credit_card FROM '/docker-entrypoint-initdb.d/data/PersonCreditCard.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_order_detail FROM '/docker-entrypoint-initdb.d/data/SalesOrderDetail.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_order_header FROM '/docker-entrypoint-initdb.d/data/SalesOrderHeader.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_order_header_sales_reason FROM '/docker-entrypoint-initdb.d/data/SalesOrderHeaderSalesReason.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_person FROM '/docker-entrypoint-initdb.d/data/SalesPerson.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_person_quota_history FROM '/docker-entrypoint-initdb.d/data/SalesPersonQuotaHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_reason FROM '/docker-entrypoint-initdb.d/data/SalesReason.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_tax_rate FROM '/docker-entrypoint-initdb.d/data/SalesTaxRate.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_territory FROM '/docker-entrypoint-initdb.d/data/SalesTerritory.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__sales_territory_history FROM '/docker-entrypoint-initdb.d/data/SalesTerritoryHistory.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__shopping_cart_item FROM '/docker-entrypoint-initdb.d/data/ShoppingCartItem.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__special_offer FROM '/docker-entrypoint-initdb.d/data/SpecialOffer.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__special_offer_product FROM '/docker-entrypoint-initdb.d/data/SpecialOfferProduct.csv' DELIMITER E'\t' CSV;
COPY das.aw__sales__store FROM '/docker-entrypoint-initdb.d/data/Store.csv' DELIMITER E'\t' CSV;

-- Drop temporary columns from Sales
ALTER TABLE das.aw__sales__customer DROP COLUMN account_number;
ALTER TABLE das.aw__sales__sales_order_detail DROP COLUMN line_total;
ALTER TABLE das.aw__sales__sales_order_header DROP COLUMN sales_order_number;
ALTER TABLE das.aw__sales__sales_order_header DROP COLUMN total_due;
