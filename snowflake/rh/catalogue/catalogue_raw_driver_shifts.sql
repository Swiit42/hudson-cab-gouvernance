-- =====================================================================
-- catalogue_raw_driver_shifts.sql — fiche de catalogue de NYC_TAXI.RAW.DRIVER_SHIFTS (guide, jour 1, étape 11)
-- Avec le rôle des outils, propriétaire de la table, après 01_gouvernance.sql. Rejouable.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. La table
COMMENT ON TABLE NYC_TAXI.RAW.DRIVER_SHIFTS IS
  'Relevé des services des chauffeurs (prises de poste), copie fidèle de driver_shifts.csv transmis par le service RH : 1 ligne = 1 service, janvier à mars 2025. Peut contenir des doublons et des services de chauffeurs inconnus (règles service_unique, service_rattache). Chargée par COPY INTO à chaque nouveau fichier ; purgée chaque jour des services des chauffeurs partis depuis plus de 5 ans (T_PURGE). Lue seulement par le rôle des outils. Responsable des données : service RH.';

-- 2. Les colonnes
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.shift_id     IS 'Identifiant du service (format S000000). Devrait être unique : les doublons sont retirés en STAGING.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.driver_id    IS 'Identifiant interne du chauffeur qui a assuré le service ; doit exister dans RAW.DRIVERS (règle bloquante service_rattache).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.shift_date   IS 'Jour du service.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.depot        IS 'Dépôt d''où est parti le taxi pour ce service.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.start_hour   IS 'Heure de prise de poste (0 à 23).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.hours_worked IS 'Durée du service en heures (décimales). Plus de 16 h est jugé non plausible (règle duree_plausible).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.trips_count  IS 'Nombre de courses effectuées pendant le service.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS.revenue_usd  IS 'Recette du service en dollars américains.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS._source_file IS 'Colonne technique : nom du fichier d''où vient la ligne.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVER_SHIFTS._loaded_at   IS 'Colonne technique : date et heure du chargement ; départage les doublons (la première chargée est gardée).';

-- 3. Les tags de la table
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE        = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur concerné (R1) ; Time Travel 1 jour (R2)';

-- 4. Les colonnes personnelles : seul driver_id relève d'une valeur du tag
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';

-- 5. Vérifier
SELECT level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVER_SHIFTS', 'table'))
ORDER BY column_name, tag_name;
