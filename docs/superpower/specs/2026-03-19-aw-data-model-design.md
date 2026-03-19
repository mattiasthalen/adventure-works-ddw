# Adventure Works Data Model Design

## Summary

Full enterprise DMDL model for Adventure Works, covering all 5 domains: Person, HR, Production, Purchasing, and Sales. 14 entities with 21 relationships, built from the 68 source tables in the `das` schema.

## Entities

### Person/Core

**PERSON** — from `aw__person__person` + related tables
- PERSON_TYPE (STRING, track changes)
- PERSON_TITLE (STRING, track changes)
- PERSON_FIRST_NAME (STRING, track changes)
- PERSON_MIDDLE_NAME (STRING, track changes)
- PERSON_LAST_NAME (STRING, track changes)
- PERSON_SUFFIX (STRING, track changes)
- PERSON_EMAIL_PROMOTION (NUMBER, track changes)

**ADDRESS** — from `aw__person__address` + state_province + country_region
- ADDRESS_LINE_1 (STRING, track changes)
- ADDRESS_LINE_2 (STRING, track changes)
- ADDRESS_CITY (STRING, track changes)
- ADDRESS_POSTAL_CODE (STRING, track changes)
- ADDRESS_STATE_PROVINCE_NAME (STRING, track changes)
- ADDRESS_COUNTRY_REGION_NAME (STRING, track changes)

### Human Resources

**EMPLOYEE** — from `aw__human_resources__employee`
- EMPLOYEE_NATIONAL_ID_NUMBER (STRING, no tracking)
- EMPLOYEE_LOGIN_ID (STRING, track changes)
- EMPLOYEE_JOB_TITLE (STRING, track changes)
- EMPLOYEE_MARITAL_STATUS (STRING, track changes)
- EMPLOYEE_GENDER (STRING, track changes)
- EMPLOYEE_SALARIED_FLAG (STRING, track changes)
- EMPLOYEE_VACATION_HOURS (NUMBER, track changes)
- EMPLOYEE_SICK_LEAVE_HOURS (NUMBER, track changes)
- EMPLOYEE_CURRENT_FLAG (STRING, track changes)
- EMPLOYEE_BIRTH_DATE (START_TIMESTAMP)
- EMPLOYEE_HIRE_DATE (START_TIMESTAMP)

**DEPARTMENT** — from `aw__human_resources__department`
- DEPARTMENT_NAME (STRING, track changes)
- DEPARTMENT_GROUP_NAME (STRING, track changes)

### Production

**PRODUCT** — from `aw__production__product` + subcategory + category + model
- PRODUCT_NAME (STRING, track changes)
- PRODUCT_NUMBER (STRING, no tracking)
- PRODUCT_MAKE_FLAG (STRING, track changes)
- PRODUCT_FINISHED_GOODS_FLAG (STRING, track changes)
- PRODUCT_COLOR (STRING, track changes)
- PRODUCT_SAFETY_STOCK_LEVEL (NUMBER, track changes)
- PRODUCT_REORDER_POINT (NUMBER, track changes)
- PRODUCT_STANDARD_COST (NUMBER, track changes)
- PRODUCT_LIST_PRICE (NUMBER, track changes)
- PRODUCT_SIZE (STRING, track changes)
- PRODUCT_WEIGHT (NUMBER, track changes)
- PRODUCT_DAYS_TO_MANUFACTURE (NUMBER, track changes)
- PRODUCT_LINE (STRING, track changes)
- PRODUCT_CLASS (STRING, track changes)
- PRODUCT_STYLE (STRING, track changes)
- PRODUCT_SUBCATEGORY_NAME (STRING, track changes)
- PRODUCT_CATEGORY_NAME (STRING, track changes)
- PRODUCT_MODEL_NAME (STRING, track changes)
- PRODUCT_SELL_START_DATE (START_TIMESTAMP)
- PRODUCT_SELL_END_DATE (END_TIMESTAMP)
- PRODUCT_DISCONTINUED_DATE (END_TIMESTAMP)

**WORK_ORDER** — from `aw__production__work_order`
- WORK_ORDER_ORDER_QTY (NUMBER, track changes)
- WORK_ORDER_SCRAPPED_QTY (NUMBER, track changes)
- WORK_ORDER_START_DATE (START_TIMESTAMP)
- WORK_ORDER_END_DATE (END_TIMESTAMP)
- WORK_ORDER_DUE_DATE (END_TIMESTAMP)

### Purchasing

**VENDOR** — from `aw__purchasing__vendor`
- VENDOR_ACCOUNT_NUMBER (STRING, no tracking)
- VENDOR_NAME (STRING, track changes)
- VENDOR_CREDIT_RATING (NUMBER, track changes)
- VENDOR_PREFERRED_STATUS (STRING, track changes)
- VENDOR_ACTIVE_FLAG (STRING, track changes)

**PURCHASE_ORDER** — from `aw__purchasing__purchase_order_header`
- PURCHASE_ORDER_STATUS (STRING, track changes)
- PURCHASE_ORDER_REVISION_NUMBER (NUMBER, track changes)
- PURCHASE_ORDER_SUB_TOTAL (NUMBER, track changes)
- PURCHASE_ORDER_TAX_AMT (NUMBER, track changes)
- PURCHASE_ORDER_FREIGHT (NUMBER, track changes)
- PURCHASE_ORDER_ORDER_DATE (START_TIMESTAMP)
- PURCHASE_ORDER_SHIP_DATE (END_TIMESTAMP)

### Sales

**CUSTOMER** — from `aw__sales__customer`
- CUSTOMER_ACCOUNT_NUMBER (STRING, no tracking)

**STORE** — from `aw__sales__store`
- STORE_NAME (STRING, track changes)

**SALES_PERSON** — from `aw__sales__sales_person`
- SALES_PERSON_SALES_QUOTA (NUMBER, track changes)
- SALES_PERSON_BONUS (NUMBER, track changes)
- SALES_PERSON_COMMISSION_PCT (NUMBER, track changes)
- SALES_PERSON_SALES_YTD (NUMBER, track changes)
- SALES_PERSON_SALES_LAST_YEAR (NUMBER, track changes)

**SALES_TERRITORY** — from `aw__sales__sales_territory`
- SALES_TERRITORY_NAME (STRING, track changes)
- SALES_TERRITORY_COUNTRY_REGION_CODE (STRING, track changes)
- SALES_TERRITORY_GROUP (STRING, track changes)

**SALES_ORDER** — from `aw__sales__sales_order_header`
- SALES_ORDER_STATUS (STRING, track changes)
- SALES_ORDER_ONLINE_ORDER_FLAG (STRING, track changes)
- SALES_ORDER_PURCHASE_ORDER_NUMBER (STRING, no tracking)
- SALES_ORDER_ACCOUNT_NUMBER (STRING, no tracking)
- SALES_ORDER_SUB_TOTAL (NUMBER, track changes)
- SALES_ORDER_TAX_AMT (NUMBER, track changes)
- SALES_ORDER_FREIGHT (NUMBER, track changes)
- SALES_ORDER_COMMENT (STRING, track changes)
- SALES_ORDER_ORDER_DATE (START_TIMESTAMP)
- SALES_ORDER_DUE_DATE (END_TIMESTAMP)
- SALES_ORDER_SHIP_DATE (END_TIMESTAMP)

**SALES_ORDER_DETAIL** — from `aw__sales__sales_order_detail`
- SALES_ORDER_DETAIL_CARRIER_TRACKING_NUMBER (STRING, no tracking)
- SALES_ORDER_DETAIL_ORDER_QTY (NUMBER, track changes)
- SALES_ORDER_DETAIL_UNIT_PRICE (NUMBER, track changes)
- SALES_ORDER_DETAIL_UNIT_PRICE_DISCOUNT (NUMBER, track changes)

**SPECIAL_OFFER** — from `aw__sales__special_offer`
- SPECIAL_OFFER_DESCRIPTION (STRING, track changes)
- SPECIAL_OFFER_DISCOUNT_PCT (NUMBER, track changes)
- SPECIAL_OFFER_TYPE (STRING, track changes)
- SPECIAL_OFFER_CATEGORY (STRING, track changes)
- SPECIAL_OFFER_MIN_QTY (NUMBER, track changes)
- SPECIAL_OFFER_MAX_QTY (NUMBER, track changes)
- SPECIAL_OFFER_START_DATE (START_TIMESTAMP)
- SPECIAL_OFFER_END_DATE (END_TIMESTAMP)

## Relationships

All relationships are *:1 (source holds the FK, points to target). Naming convention: `SOURCE_VERB_TARGET`.

| Relationship ID | Source | Target |
|---|---|---|
| EMPLOYEE_IS_A_PERSON | EMPLOYEE | PERSON |
| SALES_PERSON_IS_AN_EMPLOYEE | SALES_PERSON | EMPLOYEE |
| VENDOR_IS_A_BUSINESS_ENTITY | VENDOR | PERSON |
| PERSON_RESIDES_AT_ADDRESS | PERSON | ADDRESS |
| EMPLOYEE_BELONGS_TO_DEPARTMENT | EMPLOYEE | DEPARTMENT |
| WORK_ORDER_IS_FOR_PRODUCT | WORK_ORDER | PRODUCT |
| PURCHASE_ORDER_IS_PLACED_WITH_VENDOR | PURCHASE_ORDER | VENDOR |
| PURCHASE_ORDER_IS_ORDERED_BY_EMPLOYEE | PURCHASE_ORDER | EMPLOYEE |
| SALES_ORDER_IS_PLACED_BY_CUSTOMER | SALES_ORDER | CUSTOMER |
| SALES_ORDER_IS_SOLD_BY_SALES_PERSON | SALES_ORDER | SALES_PERSON |
| SALES_ORDER_BELONGS_TO_SALES_TERRITORY | SALES_ORDER | SALES_TERRITORY |
| SALES_ORDER_IS_BILLED_TO_ADDRESS | SALES_ORDER | ADDRESS |
| SALES_ORDER_IS_SHIPPED_TO_ADDRESS | SALES_ORDER | ADDRESS |
| SALES_ORDER_DETAIL_BELONGS_TO_SALES_ORDER | SALES_ORDER_DETAIL | SALES_ORDER |
| SALES_ORDER_DETAIL_REFERS_TO_PRODUCT | SALES_ORDER_DETAIL | PRODUCT |
| SALES_ORDER_DETAIL_HAS_APPLIED_SPECIAL_OFFER | SALES_ORDER_DETAIL | SPECIAL_OFFER |
| CUSTOMER_REFERS_TO_PERSON | CUSTOMER | PERSON |
| CUSTOMER_REFERS_TO_STORE | CUSTOMER | STORE |
| CUSTOMER_BELONGS_TO_SALES_TERRITORY | CUSTOMER | SALES_TERRITORY |
| STORE_IS_MANAGED_BY_SALES_PERSON | STORE | SALES_PERSON |
| SALES_PERSON_BELONGS_TO_SALES_TERRITORY | SALES_PERSON | SALES_TERRITORY |

## Out of Scope

- Junction/association tables (business_entity_address, special_offer_product, etc.) — handled in mappings
- History tables (employee_department_history, pay_history, etc.) — tracked via effective_timestamp
- Reference/lookup tables (culture, unit_measure, shift, etc.) — denormalized into entity attributes where useful
- Binary/XML columns (photos, documents, demographics XML)
- Shopping cart items (session-based, not analytical)
- Transaction history / archive tables
