-- =====================================================================
-- purge_rh.sql — règle R1 : les données d'un chauffeur sont supprimées 5 ans après la fin de son contrat
-- (guide, jour 3, étape 1). Avec le rôle des outils, propriétaire des tables. Rejouable : relancée, elle ne
-- trouve plus rien à supprimer. La même purge tourne chaque jour dans la tâche MARTS.T_PURGE (taches_rh.sql).
--
-- R1 s'applique « partout où la donnée du chauffeur a été copiée » :
--   RAW.DRIVERS          la source ;
--   RAW.DRIVER_SHIFTS    les services portent le driver_id : ce sont aussi ses données (heures, recettes) ;
--   MARTS.DIM_DRIVER, MARTS.MART_DRIVER_MONTHLY : reconstruites depuis RAW par T_TABLES, MAIS T_TABLES ne
--                        part pas si la règle bloquante échoue : on les purge donc aussi directement, pour
--                        qu'un incident de qualité ne prolonge pas la conservation ;
--   STAGING              des vues : rien de stocké ;
--   Time Travel          1 jour (R2, conservation_rh.sql), puis 7 jours de Fail-safe (non lisible).
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. Avant : combien de chauffeurs, de services et de lignes d'activité seront supprimés ?
SELECT
    DATEADD(year, -5, CURRENT_DATE())                                                      AS fin_de_contrat_avant_le,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE())) AS chauffeurs,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS WHERE driver_id IN
        (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()))) AS services,
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id IN
        (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()))) AS lignes_activite,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS)                                            AS chauffeurs_avant;

-- 2. Purger : d'abord tout ce qui dépend du chauffeur, puis le chauffeur lui-même (la liste vient de RAW.DRIVERS)
DELETE FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()));

DELETE FROM NYC_TAXI.MARTS.DIM_DRIVER
WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()));

DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS
WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()));

DELETE FROM NYC_TAXI.RAW.DRIVERS
WHERE end_date < DATEADD(year, -5, CURRENT_DATE());
SET purge_drivers = LAST_QUERY_ID();

-- 3. Après : plus aucun chauffeur parti depuis plus de 5 ans, nulle part
SELECT
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS)                                                   AS chauffeurs_apres,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS  WHERE end_date < DATEADD(year, -5, CURRENT_DATE())) AS reste_raw,
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE end_date < DATEADD(year, -5, CURRENT_DATE())) AS reste_dim;

-- 4. Time Travel : la ligne supprimée est ENCORE lisible, juste avant la suppression (d'où la règle R2)
SELECT COUNT(*) AS chauffeurs_lisibles_avant_purge
FROM NYC_TAXI.RAW.DRIVERS BEFORE (STATEMENT => $purge_drivers);
