USE ROLE SYSADMIN;
USE WAREHOUSE CRITICAL_LOOT_WH;
USE DATABASE CRITICAL_LOOT;

SELECT order_id, order_status, updated_at, dbt_valid_from, dbt_valid_to
FROM DBT_SNAPSHOTS.ORDERS_SNAPSHOT
WHERE order_id IN (106001, 106002)
ORDER BY order_id, dbt_valid_from;

SELECT COUNT(*) AS versionen FROM DBT_SNAPSHOTS.ORDERS_SNAPSHOT;
SELECT COUNT(DISTINCT order_id) AS beobachtete_bestellungen
FROM DBT_SNAPSHOTS.ORDERS_SNAPSHOT;
SELECT COUNT(*) AS offene_versionen
FROM DBT_SNAPSHOTS.ORDERS_SNAPSHOT
WHERE dbt_valid_to IS NULL;
-- Nach allen drei Lieferständen: 6007 / 6005 / 6004.

SELECT order_id, order_status, dbt_valid_from, dbt_valid_to
FROM DBT_SNAPSHOTS.ORDERS_SNAPSHOT
WHERE order_id = 106003;
-- Nach Stand 03.01.: Historie bleibt, gültig bis zum tatsächlichen Snapshot-Lauf.
-- Der technische Endzeitpunkt ist weder ein Januar-Löschdatum noch eine Stornierung.

SELECT COUNT(*) AS kundenversionen
FROM DBT_SNAPSHOTS.CUSTOMERS_SNAPSHOT;
-- 1000 in allen drei Ständen.
