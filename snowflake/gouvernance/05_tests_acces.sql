-- =====================================================================
-- 05_tests_acces.sql — le cahier de tests des accès, exécutable (docs/ACCES.md, partie 2)
-- Écrit AVANT les politiques (règle d'or du brief), à partir de la matrice du contrat (section 4).
--
-- Format : chaque test commence par une ligne
--     -- @test <n°> | <rôle> | <résultat attendu>
-- suivie de sa requête. Avant chaque test : USE SECONDARY ROLES NONE; USE ROLE <rôle>; USE WAREHOUSE NYC_TAXI_WH;
-- (à faire à la main dans Snowsight, test par test).
-- Résultat attendu : les valeurs de la ligne séparées par « , », les lignes par « ; »,
-- « 0 ligne » si aucune ligne, « refusé » si Snowflake répond « does not exist or not authorized ».
--
-- Valeur masquée : '*****' pour un texte, NULL pour une date ; l'analyste lit le 1er janvier de l'année de naissance.
-- Les tests de valeurs renvoient une catégorie (clair / masqué / NULL / année), jamais la valeur :
-- aucune donnée du fichier RH n'est recopiée dans le dépôt.
-- =====================================================================

-- ===================================================================== Lignes visibles : DIM_DRIVER
-- @test 1 | RH_PAIE | 400
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 2 | RESP_DEPOT_QUEENS | 161
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 3 | RESP_DEPOT_QUEENS | Queens
SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 3b | RESP_DEPOT_BRONX | Bronx, 122
SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot;
-- @test 4 | RESP_DEPOT_BRONX | 290
SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
-- @test 4b | RESP_DEPOT_QUEENS | 365
SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
-- @test 5 | ANALYSTE | 400
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 5b | ANALYSTE | 914
SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
-- @test 6 | GOUVERNANCE | refusé
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 7 | ACCOUNTADMIN | 0
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 7b | SYSADMIN | 0
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- @test 7c | TRANSFORMER | 400
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;

-- ===================================================================== Lignes visibles : RAW et référentiel
-- @test 8 | RH_PAIE | refusé
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
-- @test 9 | ANALYSTE | refusé
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;
-- @test 9b | ACCOUNTADMIN | 400, 400
SELECT COUNT(*), COUNT_IF(first_name = '*****' AND email = '*****') FROM NYC_TAXI.RAW.DRIVERS;
-- @test 9c | ACCOUNTADMIN | 400, 400
SELECT COUNT(*), COUNT_IF(last_name = '*****' AND birth_date IS NULL) FROM NYC_TAXI.STAGING.STG_RH__DRIVERS;
-- @test 9d | GOUVERNANCE | refusé
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;
-- @test 9e | RESP_DEPOT_BRONX | 3
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT;
-- @test 9f | ANALYSTE | 3
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT;

-- ===================================================================== Valeurs visibles : le chauffeur D0003 (dépôt de Queens)
-- Colonnes : driver_id, nom, prénom, e-mail, téléphone, licence, date de naissance
-- @test V1 | RH_PAIE | D0003, clair, clair, clair, clair, clair, complète
SELECT driver_id,
  CASE WHEN last_name  = '*****' THEN 'masqué' WHEN last_name  IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN first_name = '*****' THEN 'masqué' WHEN first_name IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN email      = '*****' THEN 'masqué' WHEN email      IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN phone      = '*****' THEN 'masqué' WHEN phone      IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN tlc_license_number = '*****' THEN 'masqué' WHEN tlc_license_number IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN birth_date IS NULL THEN 'NULL' WHEN birth_date = DATE_TRUNC('year', birth_date) THEN 'année' ELSE 'complète' END
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- @test V2 | RESP_DEPOT_QUEENS | D0003, clair, clair, masqué, clair, masqué, NULL
SELECT driver_id,
  CASE WHEN last_name  = '*****' THEN 'masqué' WHEN last_name  IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN first_name = '*****' THEN 'masqué' WHEN first_name IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN email      = '*****' THEN 'masqué' WHEN email      IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN phone      = '*****' THEN 'masqué' WHEN phone      IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN tlc_license_number = '*****' THEN 'masqué' WHEN tlc_license_number IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN birth_date IS NULL THEN 'NULL' WHEN birth_date = DATE_TRUNC('year', birth_date) THEN 'année' ELSE 'complète' END
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- @test V3 | RESP_DEPOT_BRONX | 0 ligne
SELECT driver_id FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- @test V4 | ANALYSTE | D0003, masqué, masqué, masqué, masqué, masqué, année
SELECT driver_id,
  CASE WHEN last_name  = '*****' THEN 'masqué' WHEN last_name  IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN first_name = '*****' THEN 'masqué' WHEN first_name IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN email      = '*****' THEN 'masqué' WHEN email      IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN phone      = '*****' THEN 'masqué' WHEN phone      IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN tlc_license_number = '*****' THEN 'masqué' WHEN tlc_license_number IS NULL THEN 'NULL' ELSE 'clair' END,
  CASE WHEN birth_date IS NULL THEN 'NULL' WHEN birth_date = DATE_TRUNC('year', birth_date) THEN 'année' ELSE 'complète' END
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- driver_name dans MART_DRIVER_MONTHLY (colonne calculée) : D0003 a 3 mois d'activité
-- @test V5 | RH_PAIE | 3, 3
SELECT COUNT(*), COUNT_IF(driver_name <> '*****') FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id = 'D0003';
-- @test V6 | RESP_DEPOT_QUEENS | 3, 3
SELECT COUNT(*), COUNT_IF(driver_name <> '*****') FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id = 'D0003';
-- @test V7 | ANALYSTE | 3, 0
SELECT COUNT(*), COUNT_IF(driver_name <> '*****') FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_id = 'D0003';

-- ===================================================================== Cas limites
-- Le masque s'applique AVANT le filtre : l'analyste ne peut pas chercher un e-mail
-- @test L1 | ANALYSTE | 0
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE email LIKE '%@%';
-- Ni deviner un nom par filtre
-- @test L2 | ANALYSTE | 0
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE last_name <> '*****';
-- Les rôles secondaires n'élargissent pas ce que voit la politique (elle ne regarde que le rôle principal)
-- @test L3 | RESP_DEPOT_QUEENS + SECONDARY ALL | 161, 0
USE SECONDARY ROLES ALL;
SELECT COUNT(*), COUNT_IF(email <> '*****') FROM NYC_TAXI.MARTS.DIM_DRIVER;
-- Le responsable du Bronx ne lit pas les services de Queens, même en filtrant dessus
-- @test L4 | RESP_DEPOT_BRONX | 0
SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE depot = 'Queens';
-- Un rôle métier ne lit pas la table de correspondance
-- @test L5 | RESP_DEPOT_BRONX | refusé
SELECT COUNT(*) FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT;
-- Le dépôt de Brooklyn n'a pas de responsable : seuls la paie et l'analyste le voient
-- @test L6 | RH_PAIE | 117
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE depot = 'Brooklyn';
-- Un téléphone vide reste vide pour le responsable (pas de faux masque)
-- @test L7 | RH_PAIE | 12
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE phone IS NULL;

-- ===================================================================== Le pipeline fonctionne toujours (après relance des SQL de marts/)
-- @test 10 | TRANSFORMER | 400, 914
SELECT (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER), (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY);
-- @test 11 | RH_PAIE | clair
SELECT CASE WHEN email LIKE '%@%' THEN 'clair' ELSE 'masqué' END FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
-- @test 11b | TRANSFORMER | 25
SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY WHERE driver_name IS NULL;
-- @test 12 | ACCOUNTADMIN | MASK_DATE, MASKING_POLICY; MASK_TEXTE, MASKING_POLICY; RAP_DEPOT, ROW_ACCESS_POLICY
SELECT DISTINCT policy_name, policy_kind
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'))
ORDER BY policy_name;
