-- =====================================================================
-- demo_ajout_depot.sql — démonstration : ouvrir le dépôt de Brooklyn à un responsable
-- SANS modifier aucune politique (ni RAP_DEPOT, ni MASK_TEXTE, ni MASK_DATE).
-- Ce qui change : un rôle (ACCOUNTADMIN) et UNE ligne dans ACCES_DEPOT (GOUVERNANCE).
-- La partie C remet le compte dans l'état du contrat. À exécuter bloc par bloc.
-- =====================================================================

-- ===================================================================== A. Le nouveau rôle et ses droits de lecture
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
SET moi = '"' || CURRENT_USER() || '"';
CREATE ROLE IF NOT EXISTS RESP_DEPOT_BROOKLYN COMMENT = 'DÉMO : responsable du dépôt de Brooklyn';
GRANT ROLE RESP_DEPOT_BROOKLYN TO USER IDENTIFIER($moi);
GRANT USAGE ON WAREHOUSE NYC_TAXI_WH TO ROLE RESP_DEPOT_BROOKLYN;
GRANT USAGE ON DATABASE NYC_TAXI TO ROLE RESP_DEPOT_BROOKLYN;
GRANT USAGE ON SCHEMA NYC_TAXI.MARTS TO ROLE RESP_DEPOT_BROOKLYN;
GRANT SELECT ON TABLE NYC_TAXI.MARTS.DIM_DRIVER          TO ROLE RESP_DEPOT_BROOKLYN;
GRANT SELECT ON TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY TO ROLE RESP_DEPOT_BROOKLYN;

-- Avant la ligne de correspondance : le rôle lit la table, mais ne voit aucune ligne
USE ROLE RESP_DEPOT_BROOKLYN;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) AS avant FROM NYC_TAXI.MARTS.DIM_DRIVER;            -- 0

-- ===================================================================== B. Une ligne dans la table de correspondance
USE ROLE GOUVERNANCE;
INSERT INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT (role_name, depot) VALUES ('RESP_DEPOT_BROOKLYN', 'Brooklyn');

USE ROLE RESP_DEPOT_BROOKLYN;
SELECT depot, COUNT(*) AS apres FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot;   -- Brooklyn, 117
SELECT COUNT_IF(last_name <> '*****') AS noms_en_clair, COUNT_IF(email <> '*****') AS emails_en_clair
FROM NYC_TAXI.MARTS.DIM_DRIVER;                                                    -- 117, 0

-- ===================================================================== C. Remettre l'état du contrat
USE ROLE GOUVERNANCE;
DELETE FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT WHERE role_name = 'RESP_DEPOT_BROOKLYN';
USE ROLE ACCOUNTADMIN;
DROP ROLE IF EXISTS RESP_DEPOT_BROOKLYN;
