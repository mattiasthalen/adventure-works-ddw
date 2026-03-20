# Entity Mappings Design

Map all 14 model entities to source tables in the `das` schema using DMDL mapping files.

## Approach

**Direct column mapping** — map each entity to a single source table using direct column references. Skip attributes and relationships that require joins through lookup or bridge tables; comment those out in the model for now.

## Model Changes

### Attributes to comment out (5)

These require joins to lookup tables not directly available on the entity's source table:

| Attribute | Entity | Reason |
|-----------|--------|--------|
| `ADDRESS_STATE_PROVINCE_NAME` | ADDRESS | Requires join to `state_province` |
| `ADDRESS_COUNTRY_REGION_NAME` | ADDRESS | Requires join to `country_region` |
| `PRODUCT_SUBCATEGORY_NAME` | PRODUCT | Requires join to `product_subcategory` |
| `PRODUCT_CATEGORY_NAME` | PRODUCT | Requires join to `product_category` |
| `PRODUCT_MODEL_NAME` | PRODUCT | Requires join to `product_model` |

### Relationships to comment out (2)

These go through bridge/history tables with no direct FK on the source table:

| Relationship | Reason |
|-------------|--------|
| `PERSON_RESIDES_AT_ADDRESS` | Goes through `business_entity_address` bridge table |
| `EMPLOYEE_BELONGS_TO_DEPARTMENT` | Goes through `employee_department_history` bridge table |

DEPARTMENT becomes a disconnected entity (acceptable for now).

## Mapping Defaults

All 14 mappings share these settings:

- **Connection**: `dev`
- **Ingestion strategy**: `FULL`
- **Entity effective timestamp**: `modified_date`
- **allow_multiple_identifiers**: `false`

## Entity-to-Source Table Mapping

| Entity | Source Table | Primary Key |
|--------|-------------|-------------|
| PERSON | `das.aw__person__person` | `business_entity_id` |
| ADDRESS | `das.aw__person__address` | `address_id` |
| EMPLOYEE | `das.aw__human_resources__employee` | `business_entity_id` |
| DEPARTMENT | `das.aw__human_resources__department` | `department_id` |
| PRODUCT | `das.aw__production__product` | `product_id` |
| WORK_ORDER | `das.aw__production__work_order` | `work_order_id` |
| VENDOR | `das.aw__purchasing__vendor` | `business_entity_id` |
| PURCHASE_ORDER | `das.aw__purchasing__purchase_order_header` | `purchase_order_id` |
| CUSTOMER | `das.aw__sales__customer` | `customer_id` |
| STORE | `das.aw__sales__store` | `business_entity_id` |
| SALES_PERSON | `das.aw__sales__sales_person` | `business_entity_id` |
| SALES_TERRITORY | `das.aw__sales__sales_territory` | `territory_id` |
| SALES_ORDER | `das.aw__sales__sales_order_header` | `sales_order_id` |
| SALES_ORDER_DETAIL | `das.aw__sales__sales_order_detail` | `sales_order_detail_id` |
| SPECIAL_OFFER | `das.aw__sales__special_offer` | `special_offer_id` |

## Relationship Mapping

Relationship IDs use `SOURCE_NAME_TARGET` format (e.g., `EMPLOYEE_EMPLOYEE_IS_A_PERSON_PERSON`).

| Source Entity | Relationship | FK Column |
|--------------|-------------|-----------|
| EMPLOYEE | EMPLOYEE_IS_A_PERSON → PERSON | `business_entity_id` |
| WORK_ORDER | WORK_ORDER_IS_FOR_PRODUCT → PRODUCT | `product_id` |
| VENDOR | VENDOR_IS_A_BUSINESS_ENTITY → PERSON | `business_entity_id` |
| PURCHASE_ORDER | PURCHASE_ORDER_IS_PLACED_WITH_VENDOR → VENDOR | `vendor_id` |
| PURCHASE_ORDER | PURCHASE_ORDER_IS_ORDERED_BY_EMPLOYEE → EMPLOYEE | `employee_id` |
| CUSTOMER | CUSTOMER_REFERS_TO_PERSON → PERSON | `person_id` |
| CUSTOMER | CUSTOMER_REFERS_TO_STORE → STORE | `store_id` |
| CUSTOMER | CUSTOMER_BELONGS_TO_SALES_TERRITORY → SALES_TERRITORY | `territory_id` |
| STORE | STORE_IS_MANAGED_BY_SALES_PERSON → SALES_PERSON | `sales_person_id` |
| SALES_PERSON | SALES_PERSON_IS_AN_EMPLOYEE → EMPLOYEE | `business_entity_id` |
| SALES_PERSON | SALES_PERSON_BELONGS_TO_SALES_TERRITORY → SALES_TERRITORY | `territory_id` |
| SALES_ORDER | SALES_ORDER_IS_PLACED_BY_CUSTOMER → CUSTOMER | `customer_id` |
| SALES_ORDER | SALES_ORDER_IS_SOLD_BY_SALES_PERSON → SALES_PERSON | `sales_person_id` |
| SALES_ORDER | SALES_ORDER_BELONGS_TO_SALES_TERRITORY → SALES_TERRITORY | `territory_id` |
| SALES_ORDER | SALES_ORDER_IS_BILLED_TO_ADDRESS → ADDRESS | `bill_to_address_id` |
| SALES_ORDER | SALES_ORDER_IS_SHIPPED_TO_ADDRESS → ADDRESS | `ship_to_address_id` |
| SALES_ORDER_DETAIL | SALES_ORDER_DETAIL_BELONGS_TO_SALES_ORDER → SALES_ORDER | `sales_order_id` |
| SALES_ORDER_DETAIL | SALES_ORDER_DETAIL_REFERS_TO_PRODUCT → PRODUCT | `product_id` |
| SALES_ORDER_DETAIL | SALES_ORDER_DETAIL_HAS_APPLIED_SPECIAL_OFFER → SPECIAL_OFFER | `special_offer_id` |

## Notable Transformation Expressions

- **CUSTOMER_ACCOUNT_NUMBER**: `'AW' || LPAD(CAST(customer_id AS VARCHAR), 8, '0')` — no source column, derived from customer_id
- **SALES_TERRITORY_GROUP**: `"group"` — reserved word, needs quoting

## Workflow Changes

Update `workflow.yaml` to reference all 14 mapping file paths in `mappings:` array.

## Validation

Run `daana-cli check workflow --no-tui` — expect all 14 entities mapped with zero errors.
