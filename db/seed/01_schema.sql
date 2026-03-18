-- Adventure Works for PostgreSQL — Schema
-- Source: https://github.com/NorfolkDataSci/adventure-works-postgres
-- Adapted: snake_case, flat das schema, aw__ prefixed tables

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS tablefunc;

CREATE SCHEMA das;

-- =============================================
-- Person schema (13 tables)
-- =============================================

CREATE TABLE das.aw__person__business_entity(
  business_entity_id SERIAL,
  rowguid uuid NOT NULL CONSTRAINT df_business_entity_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_business_entity_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__person(
  business_entity_id INT NOT NULL,
  person_type char(2) NOT NULL,
  name_style boolean NOT NULL CONSTRAINT df_person_name_style DEFAULT (false),
  title varchar(8) NULL,
  first_name varchar(50) NULL,
  middle_name varchar(50) NULL,
  last_name varchar(50) NULL,
  suffix varchar(10) NULL,
  email_promotion INT NOT NULL CONSTRAINT df_person_email_promotion DEFAULT (0),
  additional_contact_info XML NULL,
  demographics XML NULL,
  rowguid uuid NOT NULL CONSTRAINT df_person_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_person_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_person_email_promotion CHECK (email_promotion BETWEEN 0 AND 2),
  CONSTRAINT ck_person_person_type CHECK (person_type IS NULL OR UPPER(person_type) IN ('SC', 'VC', 'IN', 'EM', 'SP', 'GC'))
);

CREATE TABLE das.aw__person__state_province(
  state_province_id SERIAL,
  state_province_code char(3) NOT NULL,
  country_region_code varchar(3) NOT NULL,
  is_only_state_province_flag boolean NOT NULL CONSTRAINT df_state_province_is_only_state_province_flag DEFAULT (true),
  name varchar(50) NULL,
  territory_id INT NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_state_province_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_state_province_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__address(
  address_id SERIAL,
  address_line_1 varchar(60) NOT NULL,
  address_line_2 varchar(60) NULL,
  city varchar(30) NOT NULL,
  state_province_id INT NOT NULL,
  postal_code varchar(15) NOT NULL,
  spatial_location varchar(44) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_address_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_address_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__address_type(
  address_type_id SERIAL,
  name varchar(50) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_address_type_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_address_type_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__business_entity_address(
  business_entity_id INT NOT NULL,
  address_id INT NOT NULL,
  address_type_id INT NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_business_entity_address_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_business_entity_address_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__contact_type(
  contact_type_id SERIAL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_contact_type_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__business_entity_contact(
  business_entity_id INT NOT NULL,
  person_id INT NOT NULL,
  contact_type_id INT NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_business_entity_contact_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_business_entity_contact_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__email_address(
  business_entity_id INT NOT NULL,
  email_address_id SERIAL,
  email_address varchar(50) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_email_address_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_email_address_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__password(
  business_entity_id INT NOT NULL,
  password_hash VARCHAR(128) NOT NULL,
  password_salt VARCHAR(10) NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_password_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_password_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__phone_number_type(
  phone_number_type_id SERIAL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_phone_number_type_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__person_phone(
  business_entity_id INT NOT NULL,
  phone_number varchar(25) NULL,
  phone_number_type_id INT NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_person_phone_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__person__country_region(
  country_region_code varchar(3) NOT NULL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_country_region_modified_date DEFAULT (NOW())
);

-- =============================================
-- HumanResources schema (6 tables)
-- =============================================

CREATE TABLE das.aw__human_resources__department(
  department_id SERIAL NOT NULL,
  name varchar(50) NULL,
  group_name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_department_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__human_resources__employee(
  business_entity_id INT NOT NULL,
  national_id_number varchar(15) NOT NULL,
  login_id varchar(256) NOT NULL,
  org varchar NULL,
  organization_level INT NULL,
  job_title varchar(50) NOT NULL,
  birth_date DATE NOT NULL,
  marital_status char(1) NOT NULL,
  gender char(1) NOT NULL,
  hire_date DATE NOT NULL,
  salaried_flag boolean NOT NULL CONSTRAINT df_employee_salaried_flag DEFAULT (true),
  vacation_hours smallint NOT NULL CONSTRAINT df_employee_vacation_hours DEFAULT (0),
  sick_leave_hours smallint NOT NULL CONSTRAINT df_employee_sick_leave_hours DEFAULT (0),
  current_flag boolean NOT NULL CONSTRAINT df_employee_current_flag DEFAULT (true),
  rowguid uuid NOT NULL CONSTRAINT df_employee_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_employee_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_employee_birth_date CHECK (birth_date BETWEEN '1930-01-01' AND NOW() - INTERVAL '18 years'),
  CONSTRAINT ck_employee_marital_status CHECK (UPPER(marital_status) IN ('M', 'S')),
  CONSTRAINT ck_employee_hire_date CHECK (hire_date BETWEEN '1996-07-01' AND NOW() + INTERVAL '1 day'),
  CONSTRAINT ck_employee_gender CHECK (UPPER(gender) IN ('M', 'F')),
  CONSTRAINT ck_employee_vacation_hours CHECK (vacation_hours BETWEEN -40 AND 240),
  CONSTRAINT ck_employee_sick_leave_hours CHECK (sick_leave_hours BETWEEN 0 AND 120)
);

CREATE TABLE das.aw__human_resources__employee_department_history(
  business_entity_id INT NOT NULL,
  department_id smallint NOT NULL,
  shift_id smallint NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_employee_department_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_employee_department_history_end_date CHECK ((end_date >= start_date) OR (end_date IS NULL))
);

CREATE TABLE das.aw__human_resources__employee_pay_history(
  business_entity_id INT NOT NULL,
  rate_change_date TIMESTAMP NOT NULL,
  rate numeric NOT NULL,
  pay_frequency smallint NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_employee_pay_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_employee_pay_history_pay_frequency CHECK (pay_frequency IN (1, 2)),
  CONSTRAINT ck_employee_pay_history_rate CHECK (rate BETWEEN 6.50 AND 200.00)
);

CREATE TABLE das.aw__human_resources__job_candidate(
  job_candidate_id SERIAL NOT NULL,
  business_entity_id INT NULL,
  resume XML NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_job_candidate_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__human_resources__shift(
  shift_id SERIAL NOT NULL,
  name varchar(50) NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_shift_modified_date DEFAULT (NOW())
);

-- =============================================
-- Production schema (25 tables)
-- =============================================

CREATE TABLE das.aw__production__bill_of_materials(
  bill_of_materials_id SERIAL NOT NULL,
  product_assembly_id INT NULL,
  component_id INT NOT NULL,
  start_date TIMESTAMP NOT NULL CONSTRAINT df_bill_of_materials_start_date DEFAULT (NOW()),
  end_date TIMESTAMP NULL,
  unit_measure_code char(3) NOT NULL,
  bom_level smallint NOT NULL,
  per_assembly_qty decimal(8, 2) NOT NULL CONSTRAINT df_bill_of_materials_per_assembly_qty DEFAULT (1.00),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_bill_of_materials_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_bill_of_materials_end_date CHECK ((end_date > start_date) OR (end_date IS NULL)),
  CONSTRAINT ck_bill_of_materials_product_assembly_id CHECK (product_assembly_id <> component_id),
  CONSTRAINT ck_bill_of_materials_bom_level CHECK (((product_assembly_id IS NULL)
      AND (bom_level = 0) AND (per_assembly_qty = 1.00))
      OR ((product_assembly_id IS NOT NULL) AND (bom_level >= 1))),
  CONSTRAINT ck_bill_of_materials_per_assembly_qty CHECK (per_assembly_qty >= 1.00)
);

CREATE TABLE das.aw__production__culture(
  culture_id char(6) NOT NULL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_culture_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__document(
  doc varchar NULL,
  document_level INTEGER,
  title varchar(50) NOT NULL,
  owner INT NOT NULL,
  folder_flag boolean NOT NULL CONSTRAINT df_document_folder_flag DEFAULT (false),
  file_name varchar(400) NOT NULL,
  file_extension varchar(8) NULL,
  revision char(5) NOT NULL,
  change_number INT NOT NULL CONSTRAINT df_document_change_number DEFAULT (0),
  status smallint NOT NULL,
  document_summary text NULL,
  document bytea NULL,
  rowguid uuid NOT NULL UNIQUE CONSTRAINT df_document_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_document_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_document_status CHECK (status BETWEEN 1 AND 3)
);

CREATE TABLE das.aw__production__product_category(
  product_category_id SERIAL NOT NULL,
  name varchar(50) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_product_category_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_category_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_subcategory(
  product_subcategory_id SERIAL NOT NULL,
  product_category_id INT NOT NULL,
  name varchar(50) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_product_subcategory_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_subcategory_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_model(
  product_model_id SERIAL NOT NULL,
  name varchar(50) NULL,
  catalog_description XML NULL,
  instructions XML NULL,
  rowguid uuid NOT NULL CONSTRAINT df_product_model_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_model_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product(
  product_id SERIAL NOT NULL,
  name varchar(50) NULL,
  product_number varchar(25) NOT NULL,
  make_flag boolean NOT NULL CONSTRAINT df_product_make_flag DEFAULT (true),
  finished_goods_flag boolean NOT NULL CONSTRAINT df_product_finished_goods_flag DEFAULT (true),
  color varchar(15) NULL,
  safety_stock_level smallint NOT NULL,
  reorder_point smallint NOT NULL,
  standard_cost numeric NOT NULL,
  list_price numeric NOT NULL,
  size varchar(5) NULL,
  size_unit_measure_code char(3) NULL,
  weight_unit_measure_code char(3) NULL,
  weight decimal(8, 2) NULL,
  days_to_manufacture INT NOT NULL,
  product_line char(2) NULL,
  class char(2) NULL,
  style char(2) NULL,
  product_subcategory_id INT NULL,
  product_model_id INT NULL,
  sell_start_date TIMESTAMP NOT NULL,
  sell_end_date TIMESTAMP NULL,
  discontinued_date TIMESTAMP NULL,
  rowguid uuid NOT NULL CONSTRAINT df_product_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_product_safety_stock_level CHECK (safety_stock_level > 0),
  CONSTRAINT ck_product_reorder_point CHECK (reorder_point > 0),
  CONSTRAINT ck_product_standard_cost CHECK (standard_cost >= 0.00),
  CONSTRAINT ck_product_list_price CHECK (list_price >= 0.00),
  CONSTRAINT ck_product_weight CHECK (weight > 0.00),
  CONSTRAINT ck_product_days_to_manufacture CHECK (days_to_manufacture >= 0),
  CONSTRAINT ck_product_product_line CHECK (UPPER(product_line) IN ('S', 'T', 'M', 'R') OR product_line IS NULL),
  CONSTRAINT ck_product_class CHECK (UPPER(class) IN ('L', 'M', 'H') OR class IS NULL),
  CONSTRAINT ck_product_style CHECK (UPPER(style) IN ('W', 'M', 'U') OR style IS NULL),
  CONSTRAINT ck_product_sell_end_date CHECK ((sell_end_date >= sell_start_date) OR (sell_end_date IS NULL))
);

CREATE TABLE das.aw__production__product_cost_history(
  product_id INT NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NULL,
  standard_cost numeric NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_cost_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_product_cost_history_end_date CHECK ((end_date >= start_date) OR (end_date IS NULL)),
  CONSTRAINT ck_product_cost_history_standard_cost CHECK (standard_cost >= 0.00)
);

CREATE TABLE das.aw__production__product_description(
  product_description_id SERIAL NOT NULL,
  description varchar(400) NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_product_description_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_description_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_document(
  product_id INT NOT NULL,
  doc varchar NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_document_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__location(
  location_id SERIAL NOT NULL,
  name varchar(50) NULL,
  cost_rate numeric NOT NULL CONSTRAINT df_location_cost_rate DEFAULT (0.00),
  availability decimal(8, 2) NOT NULL CONSTRAINT df_location_availability DEFAULT (0.00),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_location_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_location_cost_rate CHECK (cost_rate >= 0.00),
  CONSTRAINT ck_location_availability CHECK (availability >= 0.00)
);

CREATE TABLE das.aw__production__product_inventory(
  product_id INT NOT NULL,
  location_id smallint NOT NULL,
  shelf varchar(10) NOT NULL,
  bin smallint NOT NULL,
  quantity smallint NOT NULL CONSTRAINT df_product_inventory_quantity DEFAULT (0),
  rowguid uuid NOT NULL CONSTRAINT df_product_inventory_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_inventory_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_product_inventory_bin CHECK (bin BETWEEN 0 AND 100)
);

CREATE TABLE das.aw__production__product_list_price_history(
  product_id INT NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NULL,
  list_price numeric NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_list_price_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_product_list_price_history_end_date CHECK ((end_date >= start_date) OR (end_date IS NULL)),
  CONSTRAINT ck_product_list_price_history_list_price CHECK (list_price > 0.00)
);

CREATE TABLE das.aw__production__illustration(
  illustration_id SERIAL NOT NULL,
  diagram XML NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_illustration_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_model_illustration(
  product_model_id INT NOT NULL,
  illustration_id INT NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_model_illustration_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_model_product_description_culture(
  product_model_id INT NOT NULL,
  product_description_id INT NOT NULL,
  culture_id char(6) NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_model_product_description_culture_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_photo(
  product_photo_id SERIAL NOT NULL,
  thumb_nail_photo bytea NULL,
  thumbnail_photo_file_name varchar(50) NULL,
  large_photo bytea NULL,
  large_photo_file_name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_photo_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_product_photo(
  product_id INT NOT NULL,
  product_photo_id INT NOT NULL,
  "primary" boolean NOT NULL CONSTRAINT df_product_product_photo_primary DEFAULT (false),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_product_photo_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__product_review(
  product_review_id SERIAL NOT NULL,
  product_id INT NOT NULL,
  reviewer_name varchar(50) NULL,
  review_date TIMESTAMP NOT NULL CONSTRAINT df_product_review_review_date DEFAULT (NOW()),
  email_address varchar(50) NOT NULL,
  rating INT NOT NULL,
  comments varchar(3850),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_review_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_product_review_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE das.aw__production__scrap_reason(
  scrap_reason_id SERIAL NOT NULL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_scrap_reason_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__transaction_history(
  transaction_id SERIAL NOT NULL,
  product_id INT NOT NULL,
  reference_order_id INT NOT NULL,
  reference_order_line_id INT NOT NULL CONSTRAINT df_transaction_history_reference_order_line_id DEFAULT (0),
  transaction_date TIMESTAMP NOT NULL CONSTRAINT df_transaction_history_transaction_date DEFAULT (NOW()),
  transaction_type char(1) NOT NULL,
  quantity INT NOT NULL,
  actual_cost numeric NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_transaction_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_transaction_history_transaction_type CHECK (UPPER(transaction_type) IN ('W', 'S', 'P'))
);

CREATE TABLE das.aw__production__transaction_history_archive(
  transaction_id INT NOT NULL,
  product_id INT NOT NULL,
  reference_order_id INT NOT NULL,
  reference_order_line_id INT NOT NULL CONSTRAINT df_transaction_history_archive_reference_order_line_id DEFAULT (0),
  transaction_date TIMESTAMP NOT NULL CONSTRAINT df_transaction_history_archive_transaction_date DEFAULT (NOW()),
  transaction_type char(1) NOT NULL,
  quantity INT NOT NULL,
  actual_cost numeric NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_transaction_history_archive_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_transaction_history_archive_transaction_type CHECK (UPPER(transaction_type) IN ('W', 'S', 'P'))
);

CREATE TABLE das.aw__production__unit_measure(
  unit_measure_code char(3) NOT NULL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_unit_measure_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__production__work_order(
  work_order_id SERIAL NOT NULL,
  product_id INT NOT NULL,
  order_qty INT NOT NULL,
  stocked_qty INT,
  scrapped_qty smallint NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NULL,
  due_date TIMESTAMP NOT NULL,
  scrap_reason_id smallint NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_work_order_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_work_order_order_qty CHECK (order_qty > 0),
  CONSTRAINT ck_work_order_scrapped_qty CHECK (scrapped_qty >= 0),
  CONSTRAINT ck_work_order_end_date CHECK ((end_date >= start_date) OR (end_date IS NULL))
);

CREATE TABLE das.aw__production__work_order_routing(
  work_order_id INT NOT NULL,
  product_id INT NOT NULL,
  operation_sequence smallint NOT NULL,
  location_id smallint NOT NULL,
  scheduled_start_date TIMESTAMP NOT NULL,
  scheduled_end_date TIMESTAMP NOT NULL,
  actual_start_date TIMESTAMP NULL,
  actual_end_date TIMESTAMP NULL,
  actual_resource_hrs decimal(9, 4) NULL,
  planned_cost numeric NOT NULL,
  actual_cost numeric NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_work_order_routing_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_work_order_routing_scheduled_end_date CHECK (scheduled_end_date >= scheduled_start_date),
  CONSTRAINT ck_work_order_routing_actual_end_date CHECK ((actual_end_date >= actual_start_date)
      OR (actual_end_date IS NULL) OR (actual_start_date IS NULL)),
  CONSTRAINT ck_work_order_routing_actual_resource_hrs CHECK (actual_resource_hrs >= 0.0000),
  CONSTRAINT ck_work_order_routing_planned_cost CHECK (planned_cost > 0.00),
  CONSTRAINT ck_work_order_routing_actual_cost CHECK (actual_cost > 0.00)
);

-- =============================================
-- Purchasing schema (5 tables)
-- =============================================

CREATE TABLE das.aw__purchasing__product_vendor(
  product_id INT NOT NULL,
  business_entity_id INT NOT NULL,
  average_lead_time INT NOT NULL,
  standard_price numeric NOT NULL,
  last_receipt_cost numeric NULL,
  last_receipt_date TIMESTAMP NULL,
  min_order_qty INT NOT NULL,
  max_order_qty INT NOT NULL,
  on_order_qty INT NULL,
  unit_measure_code char(3) NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_product_vendor_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_product_vendor_average_lead_time CHECK (average_lead_time >= 1),
  CONSTRAINT ck_product_vendor_standard_price CHECK (standard_price > 0.00),
  CONSTRAINT ck_product_vendor_last_receipt_cost CHECK (last_receipt_cost > 0.00),
  CONSTRAINT ck_product_vendor_min_order_qty CHECK (min_order_qty >= 1),
  CONSTRAINT ck_product_vendor_max_order_qty CHECK (max_order_qty >= 1),
  CONSTRAINT ck_product_vendor_on_order_qty CHECK (on_order_qty >= 0)
);

CREATE TABLE das.aw__purchasing__purchase_order_detail(
  purchase_order_id INT NOT NULL,
  purchase_order_detail_id SERIAL NOT NULL,
  due_date TIMESTAMP NOT NULL,
  order_qty smallint NOT NULL,
  product_id INT NOT NULL,
  unit_price numeric NOT NULL,
  line_total numeric,
  received_qty decimal(8, 2) NOT NULL,
  rejected_qty decimal(8, 2) NOT NULL,
  stocked_qty numeric,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_purchase_order_detail_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_purchase_order_detail_order_qty CHECK (order_qty > 0),
  CONSTRAINT ck_purchase_order_detail_unit_price CHECK (unit_price >= 0.00),
  CONSTRAINT ck_purchase_order_detail_received_qty CHECK (received_qty >= 0.00),
  CONSTRAINT ck_purchase_order_detail_rejected_qty CHECK (rejected_qty >= 0.00)
);

CREATE TABLE das.aw__purchasing__purchase_order_header(
  purchase_order_id SERIAL NOT NULL,
  revision_number smallint NOT NULL CONSTRAINT df_purchase_order_header_revision_number DEFAULT (0),
  status smallint NOT NULL CONSTRAINT df_purchase_order_header_status DEFAULT (1),
  employee_id INT NOT NULL,
  vendor_id INT NOT NULL,
  ship_method_id INT NOT NULL,
  order_date TIMESTAMP NOT NULL CONSTRAINT df_purchase_order_header_order_date DEFAULT (NOW()),
  ship_date TIMESTAMP NULL,
  sub_total numeric NOT NULL CONSTRAINT df_purchase_order_header_sub_total DEFAULT (0.00),
  tax_amt numeric NOT NULL CONSTRAINT df_purchase_order_header_tax_amt DEFAULT (0.00),
  freight numeric NOT NULL CONSTRAINT df_purchase_order_header_freight DEFAULT (0.00),
  total_due numeric,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_purchase_order_header_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_purchase_order_header_status CHECK (status BETWEEN 1 AND 4),
  CONSTRAINT ck_purchase_order_header_ship_date CHECK ((ship_date >= order_date) OR (ship_date IS NULL)),
  CONSTRAINT ck_purchase_order_header_sub_total CHECK (sub_total >= 0.00),
  CONSTRAINT ck_purchase_order_header_tax_amt CHECK (tax_amt >= 0.00),
  CONSTRAINT ck_purchase_order_header_freight CHECK (freight >= 0.00)
);

CREATE TABLE das.aw__purchasing__ship_method(
  ship_method_id SERIAL NOT NULL,
  name varchar(50) NULL,
  ship_base numeric NOT NULL CONSTRAINT df_ship_method_ship_base DEFAULT (0.00),
  ship_rate numeric NOT NULL CONSTRAINT df_ship_method_ship_rate DEFAULT (0.00),
  rowguid uuid NOT NULL CONSTRAINT df_ship_method_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_ship_method_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_ship_method_ship_base CHECK (ship_base > 0.00),
  CONSTRAINT ck_ship_method_ship_rate CHECK (ship_rate > 0.00)
);

CREATE TABLE das.aw__purchasing__vendor(
  business_entity_id INT NOT NULL,
  account_number varchar(15) NULL,
  name varchar(50) NULL,
  credit_rating smallint NOT NULL,
  preferred_vendor_status boolean NOT NULL CONSTRAINT df_vendor_preferred_vendor_status DEFAULT (true),
  active_flag boolean NOT NULL CONSTRAINT df_vendor_active_flag DEFAULT (true),
  purchasing_web_service_url varchar(1024) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_vendor_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_vendor_credit_rating CHECK (credit_rating BETWEEN 1 AND 5)
);

-- =============================================
-- Sales schema (19 tables)
-- =============================================

CREATE TABLE das.aw__sales__country_region_currency(
  country_region_code varchar(3) NOT NULL,
  currency_code char(3) NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_country_region_currency_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__credit_card(
  credit_card_id SERIAL NOT NULL,
  card_type varchar(50) NOT NULL,
  card_number varchar(25) NOT NULL,
  exp_month smallint NOT NULL,
  exp_year smallint NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_credit_card_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__currency(
  currency_code char(3) NOT NULL,
  name varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_currency_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__currency_rate(
  currency_rate_id SERIAL NOT NULL,
  currency_rate_date TIMESTAMP NOT NULL,
  from_currency_code char(3) NOT NULL,
  to_currency_code char(3) NOT NULL,
  average_rate numeric NOT NULL,
  end_of_day_rate numeric NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_currency_rate_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__customer(
  customer_id SERIAL NOT NULL,
  person_id INT NULL,
  store_id INT NULL,
  territory_id INT NULL,
  account_number VARCHAR,
  rowguid uuid NOT NULL CONSTRAINT df_customer_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_customer_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__person_credit_card(
  business_entity_id INT NOT NULL,
  credit_card_id INT NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_person_credit_card_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__sales_order_detail(
  sales_order_id INT NOT NULL,
  sales_order_detail_id SERIAL NOT NULL,
  carrier_tracking_number varchar(25) NULL,
  order_qty smallint NOT NULL,
  product_id INT NOT NULL,
  special_offer_id INT NOT NULL,
  unit_price numeric NOT NULL,
  unit_price_discount numeric NOT NULL CONSTRAINT df_sales_order_detail_unit_price_discount DEFAULT (0.0),
  line_total numeric,
  rowguid uuid NOT NULL CONSTRAINT df_sales_order_detail_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_order_detail_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_order_detail_order_qty CHECK (order_qty > 0),
  CONSTRAINT ck_sales_order_detail_unit_price CHECK (unit_price >= 0.00),
  CONSTRAINT ck_sales_order_detail_unit_price_discount CHECK (unit_price_discount >= 0.00)
);

CREATE TABLE das.aw__sales__sales_order_header(
  sales_order_id SERIAL NOT NULL,
  revision_number smallint NOT NULL CONSTRAINT df_sales_order_header_revision_number DEFAULT (0),
  order_date TIMESTAMP NOT NULL CONSTRAINT df_sales_order_header_order_date DEFAULT (NOW()),
  due_date TIMESTAMP NOT NULL,
  ship_date TIMESTAMP NULL,
  status smallint NOT NULL CONSTRAINT df_sales_order_header_status DEFAULT (1),
  online_order_flag boolean NOT NULL CONSTRAINT df_sales_order_header_online_order_flag DEFAULT (true),
  sales_order_number VARCHAR(23),
  purchase_order_number varchar(25) NULL,
  account_number varchar(15) NULL,
  customer_id INT NOT NULL,
  sales_person_id INT NULL,
  territory_id INT NULL,
  bill_to_address_id INT NOT NULL,
  ship_to_address_id INT NOT NULL,
  ship_method_id INT NOT NULL,
  credit_card_id INT NULL,
  credit_card_approval_code varchar(15) NULL,
  currency_rate_id INT NULL,
  sub_total numeric NOT NULL CONSTRAINT df_sales_order_header_sub_total DEFAULT (0.00),
  tax_amt numeric NOT NULL CONSTRAINT df_sales_order_header_tax_amt DEFAULT (0.00),
  freight numeric NOT NULL CONSTRAINT df_sales_order_header_freight DEFAULT (0.00),
  total_due numeric,
  comment varchar(128) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_sales_order_header_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_order_header_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_order_header_status CHECK (status BETWEEN 0 AND 8),
  CONSTRAINT ck_sales_order_header_due_date CHECK (due_date >= order_date),
  CONSTRAINT ck_sales_order_header_ship_date CHECK ((ship_date >= order_date) OR (ship_date IS NULL)),
  CONSTRAINT ck_sales_order_header_sub_total CHECK (sub_total >= 0.00),
  CONSTRAINT ck_sales_order_header_tax_amt CHECK (tax_amt >= 0.00),
  CONSTRAINT ck_sales_order_header_freight CHECK (freight >= 0.00)
);

CREATE TABLE das.aw__sales__sales_order_header_sales_reason(
  sales_order_id INT NOT NULL,
  sales_reason_id INT NOT NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_order_header_sales_reason_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__sales_person(
  business_entity_id INT NOT NULL,
  territory_id INT NULL,
  sales_quota numeric NULL,
  bonus numeric NOT NULL CONSTRAINT df_sales_person_bonus DEFAULT (0.00),
  commission_pct numeric NOT NULL CONSTRAINT df_sales_person_commission_pct DEFAULT (0.00),
  sales_ytd numeric NOT NULL CONSTRAINT df_sales_person_sales_ytd DEFAULT (0.00),
  sales_last_year numeric NOT NULL CONSTRAINT df_sales_person_sales_last_year DEFAULT (0.00),
  rowguid uuid NOT NULL CONSTRAINT df_sales_person_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_person_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_person_sales_quota CHECK (sales_quota > 0.00),
  CONSTRAINT ck_sales_person_bonus CHECK (bonus >= 0.00),
  CONSTRAINT ck_sales_person_commission_pct CHECK (commission_pct >= 0.00),
  CONSTRAINT ck_sales_person_sales_ytd CHECK (sales_ytd >= 0.00),
  CONSTRAINT ck_sales_person_sales_last_year CHECK (sales_last_year >= 0.00)
);

CREATE TABLE das.aw__sales__sales_person_quota_history(
  business_entity_id INT NOT NULL,
  quota_date TIMESTAMP NOT NULL,
  sales_quota numeric NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_sales_person_quota_history_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_person_quota_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_person_quota_history_sales_quota CHECK (sales_quota > 0.00)
);

CREATE TABLE das.aw__sales__sales_reason(
  sales_reason_id SERIAL NOT NULL,
  name varchar(50) NULL,
  reason_type varchar(50) NULL,
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_reason_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__sales_tax_rate(
  sales_tax_rate_id SERIAL NOT NULL,
  state_province_id INT NOT NULL,
  tax_type smallint NOT NULL,
  tax_rate numeric NOT NULL CONSTRAINT df_sales_tax_rate_tax_rate DEFAULT (0.00),
  name varchar(50) NULL,
  rowguid uuid NOT NULL CONSTRAINT df_sales_tax_rate_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_tax_rate_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_tax_rate_tax_type CHECK (tax_type BETWEEN 1 AND 3)
);

CREATE TABLE das.aw__sales__sales_territory(
  territory_id SERIAL NOT NULL,
  name varchar(50) NULL,
  country_region_code varchar(3) NOT NULL,
  "group" varchar(50) NOT NULL,
  sales_ytd numeric NOT NULL CONSTRAINT df_sales_territory_sales_ytd DEFAULT (0.00),
  sales_last_year numeric NOT NULL CONSTRAINT df_sales_territory_sales_last_year DEFAULT (0.00),
  cost_ytd numeric NOT NULL CONSTRAINT df_sales_territory_cost_ytd DEFAULT (0.00),
  cost_last_year numeric NOT NULL CONSTRAINT df_sales_territory_cost_last_year DEFAULT (0.00),
  rowguid uuid NOT NULL CONSTRAINT df_sales_territory_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_territory_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_territory_sales_ytd CHECK (sales_ytd >= 0.00),
  CONSTRAINT ck_sales_territory_sales_last_year CHECK (sales_last_year >= 0.00),
  CONSTRAINT ck_sales_territory_cost_ytd CHECK (cost_ytd >= 0.00),
  CONSTRAINT ck_sales_territory_cost_last_year CHECK (cost_last_year >= 0.00)
);

CREATE TABLE das.aw__sales__sales_territory_history(
  business_entity_id INT NOT NULL,
  territory_id INT NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NULL,
  rowguid uuid NOT NULL CONSTRAINT df_sales_territory_history_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_sales_territory_history_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_sales_territory_history_end_date CHECK ((end_date >= start_date) OR (end_date IS NULL))
);

CREATE TABLE das.aw__sales__shopping_cart_item(
  shopping_cart_item_id SERIAL NOT NULL,
  shopping_cart_id varchar(50) NOT NULL,
  quantity INT NOT NULL CONSTRAINT df_shopping_cart_item_quantity DEFAULT (1),
  product_id INT NOT NULL,
  date_created TIMESTAMP NOT NULL CONSTRAINT df_shopping_cart_item_date_created DEFAULT (NOW()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_shopping_cart_item_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_shopping_cart_item_quantity CHECK (quantity >= 1)
);

CREATE TABLE das.aw__sales__special_offer(
  special_offer_id SERIAL NOT NULL,
  description varchar(255) NOT NULL,
  discount_pct numeric NOT NULL CONSTRAINT df_special_offer_discount_pct DEFAULT (0.00),
  type varchar(50) NOT NULL,
  category varchar(50) NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  min_qty INT NOT NULL CONSTRAINT df_special_offer_min_qty DEFAULT (0),
  max_qty INT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_special_offer_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_special_offer_modified_date DEFAULT (NOW()),
  CONSTRAINT ck_special_offer_end_date CHECK (end_date >= start_date),
  CONSTRAINT ck_special_offer_discount_pct CHECK (discount_pct >= 0.00),
  CONSTRAINT ck_special_offer_min_qty CHECK (min_qty >= 0),
  CONSTRAINT ck_special_offer_max_qty CHECK (max_qty >= 0)
);

CREATE TABLE das.aw__sales__special_offer_product(
  special_offer_id INT NOT NULL,
  product_id INT NOT NULL,
  rowguid uuid NOT NULL CONSTRAINT df_special_offer_product_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_special_offer_product_modified_date DEFAULT (NOW())
);

CREATE TABLE das.aw__sales__store(
  business_entity_id INT NOT NULL,
  name varchar(50) NULL,
  sales_person_id INT NULL,
  demographics XML NULL,
  rowguid uuid NOT NULL CONSTRAINT df_store_rowguid DEFAULT (uuid_generate_v1()),
  modified_date TIMESTAMP NOT NULL CONSTRAINT df_store_modified_date DEFAULT (NOW())
);
