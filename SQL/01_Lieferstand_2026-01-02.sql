USE ROLE SYSADMIN;
USE WAREHOUSE CRITICAL_LOOT_WH;
USE DATABASE CRITICAL_LOOT;

-- Tag 3: Erst nach Snapshot des vorherigen Lieferstands ausführen.
-- Beide COPY-Läufe abschließen, erst danach im Terminal den nächsten Snapshot starten.
-- Kunden und Produktstammdaten sind gegenüber 01.01.2026 unverändert.

-- Bestehenden Ladeweg mit dem gewählten Lieferdatum verwenden.
CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'orders', '2026-01-02'::DATE);

-- Bestehenden Ladeweg mit dem gewählten Lieferdatum verwenden.
CALL CRITICAL_LOOT.INGEST.LOAD_TABLE('erp', 'order_items', '2026-01-02'::DATE);

SELECT COUNT(*) AS orders FROM RAW_ERP.ORDERS;
SELECT COUNT(*) AS order_items FROM RAW_ERP.ORDER_ITEMS;

-- Beide Stände: 6004 Orders und 10004 Items, bei unterschiedlichen Inhalten.
SELECT order_id, order_status, updated_at
FROM RAW_ERP.ORDERS
WHERE order_id >= 106001
ORDER BY order_id;
