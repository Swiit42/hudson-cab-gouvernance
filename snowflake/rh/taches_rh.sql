-- =====================================================================
-- taches_rh.sql — la chaîne quotidienne : purger, contrôler, puis reconstruire (guide, jour 3, étape 6)
--   MARTS.T_PURGE   (racine, chaque jour à 6 h, heure de Paris) : règle R1, comme purge_rh.sql
--   MARTS.T_QUALITE (après T_PURGE) : mesure les 8 règles sur RAW, les enregistre dans QUALITE_RESULTATS,
--                    puis lève une erreur si une règle BLOQUANTE dépasse son seuil
--   MARTS.T_TABLES  (après T_QUALITE) : reconstruit MARTS (INSERT OVERWRITE), seulement si la qualité est passée
-- Les tâches appartiennent au rôle des outils et s'exécutent avec ses droits. Seuils et gravités : GOUVERNANCE.QUALITE_REGLES.
-- Exécuter les parties 1 et 2 en entier ; la partie 3 pour prouver le blocage ; la partie 4 à la fin du brief.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- ===================================================================== 1. Créer les tâches
-- Rejouable : on ne modifie pas un graphe dont la racine est active. On la suspend d'abord (sans erreur si elle n'existe pas).
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_PURGE SUSPEND;

CREATE OR REPLACE TASK NYC_TAXI.MARTS.T_PURGE
  WAREHOUSE = NYC_TAXI_WH
  SCHEDULE = 'USING CRON 0 6 * * * Europe/Paris'
  COMMENT = 'R1 : supprime partout les chauffeurs partis depuis plus de 5 ans'
AS
EXECUTE IMMEDIATE $$
BEGIN
  DELETE FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
  WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()));
  DELETE FROM NYC_TAXI.MARTS.DIM_DRIVER
  WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()));
  DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS
  WHERE driver_id IN (SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS WHERE end_date < DATEADD(year, -5, CURRENT_DATE()));
  DELETE FROM NYC_TAXI.RAW.DRIVERS
  WHERE end_date < DATEADD(year, -5, CURRENT_DATE());
  RETURN 'Purge R1 terminée : ' || SQLROWCOUNT || ' chauffeur(s) supprimé(s) de RAW.DRIVERS';
END;
$$;

CREATE OR REPLACE TASK NYC_TAXI.MARTS.T_QUALITE
  WAREHOUSE = NYC_TAXI_WH
  COMMENT = 'Mesure les règles de qualité sur RAW, enregistre, et arrête la chaîne si une règle bloquante dépasse son seuil'
  AFTER NYC_TAXI.MARTS.T_PURGE
AS
EXECUTE IMMEDIATE $$
DECLARE
  mesure_le   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
  nb_bloquees INTEGER;
  bloquee     EXCEPTION (-20001, 'Règle de qualité bloquante en dépassement : MARTS n''est pas reconstruit (voir QUALITE_RESULTATS)');
BEGIN
  -- Une ligne par règle et par exécution, enregistrée AVANT de décider : la mesure reste, même si la chaîne s'arrête
  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT m.regle, :mesure_le, m.nb, s.seuil_lignes, IFF(m.nb <= s.seuil_lignes, 'OK', 'ALERTE')
  FROM (
            SELECT 'licence_unique' AS regle,
                   (SELECT COUNT(*) - COUNT(DISTINCT tlc_license_number) FROM NYC_TAXI.RAW.DRIVERS) AS nb
  UNION ALL SELECT 'telephone_renseigne',
                   (SELECT COUNT_IF(end_date IS NULL AND NULLIF(TRIM(phone), '') IS NULL) FROM NYC_TAXI.RAW.DRIVERS)
  UNION ALL SELECT 'email_valide',
                   (SELECT COUNT_IF(email IS NULL OR email NOT LIKE '%@%') FROM NYC_TAXI.RAW.DRIVERS)
  UNION ALL SELECT 'dates_coherentes',
                   (SELECT COUNT_IF(hire_date > CURRENT_DATE() OR end_date < hire_date) FROM NYC_TAXI.RAW.DRIVERS)
  UNION ALL SELECT 'depot_connu',
                   (SELECT COUNT_IF(depot IS NULL OR depot NOT IN ('Bronx', 'Brooklyn', 'Queens')) FROM NYC_TAXI.RAW.DRIVERS)
                 + (SELECT COUNT_IF(depot IS NULL OR depot NOT IN ('Bronx', 'Brooklyn', 'Queens')) FROM NYC_TAXI.RAW.DRIVER_SHIFTS)
  UNION ALL SELECT 'service_rattache',
                   (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
                    WHERE NOT EXISTS (SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id = s.driver_id))
  UNION ALL SELECT 'service_unique',
                   (SELECT COUNT(*) - COUNT(DISTINCT shift_id) FROM NYC_TAXI.RAW.DRIVER_SHIFTS)
  UNION ALL SELECT 'duree_plausible',
                   (SELECT COUNT_IF(hours_worked > 16) FROM NYC_TAXI.RAW.DRIVER_SHIFTS)
  ) m
  JOIN (
    -- Un seuil en pourcentage se convertit en nombre de lignes au moment de la mesure
    SELECT regle,
           COALESCE(seuil, ROUND(seuil_pct / 100 * (SELECT COUNT_IF(end_date IS NULL) FROM NYC_TAXI.RAW.DRIVERS), 2)) AS seuil_lignes
    FROM NYC_TAXI.GOUVERNANCE.QUALITE_REGLES
  ) s ON s.regle = m.regle;

  -- Une règle bloquante en ALERTE arrête la chaîne : la tâche échoue, T_TABLES ne part pas
  SELECT COUNT(*) INTO :nb_bloquees
  FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS r
  JOIN NYC_TAXI.GOUVERNANCE.QUALITE_REGLES g ON g.regle = r.regle
  WHERE r.mesure_le = :mesure_le AND g.gravite = 'bloquant' AND r.statut = 'ALERTE';
  IF (nb_bloquees > 0) THEN
    RAISE bloquee;
  END IF;
  RETURN 'Qualité mesurée, aucune règle bloquante en dépassement';
END;
$$;

CREATE OR REPLACE TASK NYC_TAXI.MARTS.T_TABLES
  WAREHOUSE = NYC_TAXI_WH
  COMMENT = 'Reconstruit les tables de MARTS (INSERT OVERWRITE : tags et politiques restent en place)'
  AFTER NYC_TAXI.MARTS.T_QUALITE
AS
EXECUTE IMMEDIATE $$
BEGIN
  -- marts/dim_depot.sql
  INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DEPOT (depot, quartier, ouvert_en, nb_places) VALUES
      ('Bronx',    'Hunts Point',       2009, 140),
      ('Brooklyn', 'East New York',     2011, 120),
      ('Queens',   'Long Island City',  2008, 180);
  -- marts/dim_driver.sql
  INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DRIVER
  SELECT driver_id, first_name, last_name, email, phone, birth_date, tlc_license_number, depot, hire_date, end_date,
         end_date IS NULL AS is_active,
         ROUND(DATEDIFF(day, hire_date, COALESCE(end_date, CURRENT_DATE())) / 365.25, 1) AS tenure_years
  FROM NYC_TAXI.STAGING.STG_RH__DRIVERS;
  -- marts/mart_driver_monthly.sql
  INSERT OVERWRITE INTO NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
  SELECT DATE_TRUNC('month', s.shift_date)::date, s.driver_id, d.first_name || ' ' || d.last_name, s.depot,
         COUNT(*), ROUND(SUM(s.hours_worked), 1), SUM(s.trips_count), ROUND(SUM(s.revenue_usd), 2)
  FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS s
  LEFT JOIN NYC_TAXI.MARTS.DIM_DRIVER d ON d.driver_id = s.driver_id
  GROUP BY 1, 2, 3, 4;
  RETURN 'MARTS reconstruit';
END;
$$;

-- ===================================================================== 2. Activer, lancer, regarder
-- Activer la racine ET les tâches qui en dépendent, puis lancer tout de suite sans attendre 6 h
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('NYC_TAXI.MARTS.T_PURGE');
EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;

-- Une minute plus tard : les trois tâches en SUCCEEDED, 8 lignes de plus dans QUALITE_RESULTATS
--   SELECT name, state, return_value, error_message, scheduled_time, completed_time
--   FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY())
--   WHERE name IN ('T_PURGE', 'T_QUALITE', 'T_TABLES') AND state <> 'SCHEDULED'
--   ORDER BY scheduled_time DESC, completed_time DESC LIMIT 12;
--   SELECT * FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS ORDER BY mesure_le DESC, regle;

-- ===================================================================== 3. Prouver le blocage (bloc par bloc)
-- Abaisser le seuil de la règle bloquante sous le nombre de services orphelins (25), sans toucher aux tâches :
--   USE ROLE GOUVERNANCE;
--   UPDATE NYC_TAXI.GOUVERNANCE.QUALITE_REGLES SET seuil = 10 WHERE regle = 'service_rattache';
--   USE ROLE TRANSFORMER;
--   EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;
-- → T_QUALITE en FAILED avec le message, une ligne service_rattache en ALERTE, T_TABLES ne part pas.
-- Puis remettre le seuil du contrat :
--   USE ROLE GOUVERNANCE;
--   UPDATE NYC_TAXI.GOUVERNANCE.QUALITE_REGLES SET seuil = 50 WHERE regle = 'service_rattache';

-- ===================================================================== 4. À la fin du brief
-- Une tâche activée tourne chaque jour et consomme des crédits :
--   ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
