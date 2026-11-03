-- =====================================================================
-- conservation_rh.sql — règle R2 : une donnée personnelle supprimée ne peut plus être restaurée par
-- Time Travel au-delà de 1 jour (guide, jour 3, étape 2).
-- Avec le rôle des outils : seul le propriétaire d'une table peut changer sa durée de rétention
-- (GOUVERNANCE serait refusé). Rejouable.
--
-- Après Time Travel, Snowflake garde encore 7 jours de Fail-safe sur une table permanente : illisible
-- pour nous, accessible au seul support Snowflake, et non réductible. Délai réel de disparition : 1 + 7 = 8 jours.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. Les quatre tables qui contiennent des données de chauffeurs
ALTER TABLE NYC_TAXI.RAW.DRIVERS               SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS         SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER          SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- 2. Vérifier : retention_time = 1 sur les quatre tables (colonne retention_time)
SHOW TABLES IN SCHEMA NYC_TAXI.RAW;
SHOW TABLES IN SCHEMA NYC_TAXI.MARTS;
SELECT table_schema, table_name, retention_time
FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE table_schema IN ('RAW', 'MARTS') AND table_type = 'BASE TABLE'
ORDER BY 1, 2;

-- 3. R3 : le stage est vide (le fichier RH n'y reste pas)
LIST @NYC_TAXI.RAW.RH_STAGE;
