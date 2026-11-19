/* ============================================================
   1. GRUNDLEGENDES SETUP: ROLLE, WAREHOUSE, DATENBANK & SCHEMATA
   ============================================================ */

USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS CRITICAL_LOOT_WH
    WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
USE WAREHOUSE CRITICAL_LOOT_WH;

CREATE DATABASE IF NOT EXISTS CRITICAL_LOOT;
USE DATABASE CRITICAL_LOOT;

CREATE SCHEMA IF NOT EXISTS INGEST;
CREATE SCHEMA IF NOT EXISTS RAW_ERP;
CREATE SCHEMA IF NOT EXISTS RAW_CRM;
CREATE SCHEMA IF NOT EXISTS RAW_SUPPORT;
USE SCHEMA INGEST;

/* ============================================================
   2. EXTERNE DATENQUELLE (STAGE) DEFINIEREN
   ============================================================ */

CREATE STAGE IF NOT EXISTS INGEST.RAW_STAGE URL = 's3://snowflake-dsi/';

/* ============================================================
   3. DATEIFORMATE FÜR CSV- UND JSON-DATEN ANLEGEN
   ============================================================ */

CREATE OR REPLACE FILE FORMAT INGEST.FF_CSV
    TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE ENCODING = 'UTF8'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE;

CREATE OR REPLACE FILE FORMAT INGEST.FF_SUPPORT_JSON TYPE = JSON;

/* ============================================================
   4. RAW-TABELLEN FÜR CRM-, ERP- UND SUPPORT-DATEN ANLEGEN
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_CRM.CUSTOMER_SEGMENTS (
    segment_id NUMBER, segment_name VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_CRM.CUSTOMERS (
    customer_id NUMBER, segment_id NUMBER, first_name VARCHAR, last_name VARCHAR,
    email VARCHAR, country_code VARCHAR(2), registered_at TIMESTAMP_NTZ, updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS RAW_ERP.FRANCHISES (
    franchise_id NUMBER, franchise_name VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ERP.PLATFORMS (
    platform_id NUMBER, platform_name VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ERP.PRODUCT_CATEGORIES (
    category_id NUMBER, category_name VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ERP.PRODUCTS (
    product_id NUMBER, sku VARCHAR, franchise_id NUMBER, category_id NUMBER,
    platform_id NUMBER, product_name VARCHAR, edition VARCHAR, fulfillment_type VARCHAR,
    release_date DATE, list_price_net NUMBER(12,2), current_unit_cost_net NUMBER(12,2),
    is_active BOOLEAN, updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS RAW_ERP.ORDERS (
    order_id NUMBER, order_number VARCHAR, customer_id NUMBER, ordered_at TIMESTAMP_NTZ,
    order_status VARCHAR, currency_code VARCHAR(3), updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS RAW_ERP.ORDER_ITEMS (
    order_item_id NUMBER, order_id NUMBER, line_number NUMBER, product_id NUMBER,
    quantity NUMBER, unit_price_net NUMBER(12,2), discount_net NUMBER(12,2),
    tax_rate NUMBER(5,4), unit_cost_net_at_order NUMBER(12,2), updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS RAW_SUPPORT.TICKET_EXPORTS (payload VARIANT);

/* ============================================================
   5. GENERISCHE LADEPROZEDUR FÜR CSV-DATEN
   ============================================================ */

CREATE OR REPLACE PROCEDURE INGEST.LOAD_TABLE(
    quellsystem VARCHAR, tabellenname VARCHAR, lieferdatum DATE
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
BEGIN
    LET quellpfad VARCHAR := '@CRITICAL_LOOT.INGEST.RAW_STAGE/'
        || quellsystem || '/' || tabellenname || '/'
        || TO_CHAR(lieferdatum, 'YYYY-MM-DD') || '/' || tabellenname || '.csv';

    LET zieltabelle VARCHAR := 'CRITICAL_LOOT.RAW_' || quellsystem || '.' || tabellenname;

    TRUNCATE TABLE IDENTIFIER(:zieltabelle);

    COPY INTO IDENTIFIER(:zieltabelle)
        FROM :quellpfad
        FILE_FORMAT = (FORMAT_NAME = 'CRITICAL_LOOT.INGEST.FF_CSV')
        ON_ERROR = 'ABORT_STATEMENT';

    RETURN 'Geladen: ' || zieltabelle;
END;
;

/* ============================================================
   6. SPEZIELLE LADEPROZEDUR FÜR SUPPORT-JSON-DATEN
   ============================================================ */

CREATE OR REPLACE PROCEDURE INGEST.LOAD_SUPPORT(lieferdatum DATE)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
BEGIN
    LET quellpfad VARCHAR := '@CRITICAL_LOOT.INGEST.RAW_STAGE/support/'
        || TO_CHAR(lieferdatum, 'YYYY-MM-DD') || '/';

    TRUNCATE TABLE RAW_SUPPORT.TICKET_EXPORTS;

    COPY INTO CRITICAL_LOOT.RAW_SUPPORT.TICKET_EXPORTS
        FROM :quellpfad
        FILE_FORMAT = (FORMAT_NAME = 'CRITICAL_LOOT.INGEST.FF_SUPPORT_JSON')
        ON_ERROR = 'ABORT_STATEMENT';

    RETURN 'Support-Exporte geladen';
END;
;

/* ============================================================
   7. TASKS FÜR DEN TÄGLICHEN IMPORT DER QUELLDATEN
   ============================================================ */

CREATE OR REPLACE TASK INGEST.LOAD_CUSTOMER_SEGMENTS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('crm', 'customer_segments', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_CUSTOMERS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('crm', 'customers', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_FRANCHISES_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'franchises', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_PLATFORMS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'platforms', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_PRODUCT_CATEGORIES_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'product_categories', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_PRODUCTS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'products', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_ORDERS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'orders', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_ORDER_ITEMS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'order_items', '2026-01-03'::DATE);

CREATE OR REPLACE TASK INGEST.LOAD_SUPPORT_TASK
    WAREHOUSE = CRITICAL_LOOT_WH SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS CALL CRITICAL_LOOT.INGEST.LOAD_SUPPORT('2026-01-01'::DATE);

/* ============================================================
   8. ERSTMALIGES MANUELLES LADEN DER DATEN
   ============================================================ */

CALL INGEST.LOAD_TABLE('crm', 'customer_segments', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('crm', 'customers', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('erp', 'franchises', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('erp', 'platforms', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('erp', 'product_categories', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('erp', 'products', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('erp', 'orders', '2026-01-03'::DATE);
CALL INGEST.LOAD_TABLE('erp', 'order_items', '2026-01-03'::DATE);
CALL INGEST.LOAD_SUPPORT('2026-01-01'::DATE);

/* ============================================================
   9. TASKS AKTIVIEREN
   ============================================================ */

ALTER TASK INGEST.LOAD_CUSTOMER_SEGMENTS_TASK RESUME;
ALTER TASK INGEST.LOAD_CUSTOMERS_TASK RESUME;
ALTER TASK INGEST.LOAD_FRANCHISES_TASK RESUME;
ALTER TASK INGEST.LOAD_PLATFORMS_TASK RESUME;
ALTER TASK INGEST.LOAD_PRODUCT_CATEGORIES_TASK RESUME;
ALTER TASK INGEST.LOAD_PRODUCTS_TASK RESUME;
ALTER TASK INGEST.LOAD_ORDERS_TASK RESUME;
ALTER TASK INGEST.LOAD_ORDER_ITEMS_TASK RESUME;
ALTER TASK INGEST.LOAD_SUPPORT_TASK RESUME;

/* ============================================================
   10. ZUSÄTZLICHE ERP-DATEN: RECHNUNGEN
   ============================================================ */

CREATE OR REPLACE TASK INGEST.LOAD_INVOICES_TASK
    WAREHOUSE = CRITICAL_LOOT_WH
    SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS
BEGIN
    CREATE TABLE IF NOT EXISTS RAW_ERP.INVOICES (
        invoice_id NUMBER,
        invoice_number VARCHAR,
        order_id NUMBER,
        invoice_date DATE,
        due_date DATE,
        invoice_status VARCHAR,
        updated_at TIMESTAMP_NTZ
    );

    TRUNCATE TABLE RAW_ERP.INVOICES;

    COPY INTO RAW_ERP.INVOICES
    FROM @CRITICAL_LOOT.INGEST.RAW_STAGE/erp/invoices/2026-01-01/
    FILES = ('invoices.csv')
    FILE_FORMAT = (FORMAT_NAME = 'CRITICAL_LOOT.INGEST.FF_CSV');
END;

/* ============================================================
   11. ZUSÄTZLICHE ERP-DATEN: RECHNUNGSPOSITIONEN
   ============================================================ */

CREATE OR REPLACE TASK INGEST.LOAD_INVOICE_ITEMS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH
    SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS
BEGIN
    CREATE TABLE IF NOT EXISTS RAW_ERP.INVOICE_ITEMS (
        invoice_item_id NUMBER,
        invoice_id NUMBER,
        line_number NUMBER,
        order_item_id NUMBER,
        quantity NUMBER,
        unit_price_net NUMBER(12,2),
        discount_net NUMBER(12,2),
        tax_rate NUMBER(5,4)
    );

    TRUNCATE TABLE RAW_ERP.INVOICE_ITEMS;

    COPY INTO RAW_ERP.INVOICE_ITEMS
    FROM @CRITICAL_LOOT.INGEST.RAW_STAGE/erp/invoice_items/2026-01-01/
    FILES = ('invoice_items.csv')
    FILE_FORMAT = (FORMAT_NAME = 'CRITICAL_LOOT.INGEST.FF_CSV');
END;

/* ============================================================
   12. ZUSÄTZLICHE ERP-DATEN: ZAHLUNGEN
   ============================================================ */

CREATE OR REPLACE TASK INGEST.LOAD_PAYMENTS_TASK
    WAREHOUSE = CRITICAL_LOOT_WH
    SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS
BEGIN
    CREATE TABLE IF NOT EXISTS RAW_ERP.PAYMENTS (
        payment_id NUMBER,
        invoice_id NUMBER,
        payment_reference VARCHAR,
        amount_gross NUMBER(12,2),
        payment_method VARCHAR,
        payment_status VARCHAR,
        initiated_at TIMESTAMP_TZ,
        paid_at TIMESTAMP_TZ,
        updated_at TIMESTAMP_TZ
    );

    TRUNCATE TABLE RAW_ERP.PAYMENTS;

    COPY INTO RAW_ERP.PAYMENTS
    FROM @CRITICAL_LOOT.INGEST.RAW_STAGE/erp/payments/2026-01-01/
    FILES = ('payments.csv')

    -- SPEZIELLES TIMESTAMP-FORMAT FÜR DATUMSANGABEN MIT ZEITZONE
    -- Beispiel: 2024-01-02T14:29:51+00:00
    -- T trennt Datum und Uhrzeit, TZH:TZM enthält den UTC-Offset.

    FILE_FORMAT = (
        TYPE = CSV
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        EMPTY_FIELD_AS_NULL = TRUE
        ENCODING = 'UTF8'
        TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'
        ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    );
END;

/* ============================================================
   13. MANUELLER TESTLAUF DER NEUEN ERP-TASKS
   ============================================================ */

-- Neu angelegte Tasks sind pausiert. Diese Befehle starten je einen Ladelauf.
EXECUTE TASK INGEST.LOAD_INVOICES_TASK;
EXECUTE TASK INGEST.LOAD_INVOICE_ITEMS_TASK;
EXECUTE TASK INGEST.LOAD_PAYMENTS_TASK;