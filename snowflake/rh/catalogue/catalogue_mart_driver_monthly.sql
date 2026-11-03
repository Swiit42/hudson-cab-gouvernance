-- =====================================================================
-- catalogue_mart_driver_monthly.sql — fiche de catalogue de NYC_TAXI.MARTS.MART_DRIVER_MONTHLY (guide, jour 1, étape 11)
-- Avec le rôle des outils, propriétaire de la table, après 01_gouvernance.sql. Rejouable.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. La table
COMMENT ON TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY IS
  'Activité mensuelle de chaque chauffeur : 1 ligne = 1 chauffeur x 1 mois x 1 dépôt (services, heures, courses, recette). Source : RAW.DRIVER_SHIFTS (dédoublonnée en STAGING) jointe à DIM_DRIVER pour le nom. Reconstruite chaque jour par INSERT OVERWRITE (marts/mart_driver_monthly.sql, tâche T_TABLES). Lue par RH_PAIE, les responsables de dépôt (leur dépôt) et ANALYSTE (sans le nom). Responsable des données : service RH.';

-- 2. Les colonnes
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.activity_month IS 'Premier jour du mois d''activité.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.driver_id      IS 'Identifiant interne du chauffeur ; visible de tous les rôles métier.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.driver_name    IS 'Colonne calculée : prénom et nom du chauffeur (first_name || '' '' || last_name). Donnée personnelle comme le nom dont elle est copiée ; vide si le chauffeur est inconnu de DIM_DRIVER.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.depot          IS 'Dépôt d''où sont partis les services ; sert au filtre des lignes.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.nb_shifts      IS 'Nombre de services du chauffeur dans le mois.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.hours_worked   IS 'Total des heures travaillées dans le mois (1 décimale).';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.trips_count    IS 'Total des courses effectuées dans le mois.';
COMMENT ON COLUMN NYC_TAXI.MARTS.MART_DRIVER_MONTHLY.revenue_usd    IS 'Recette totale du mois en dollars américains (2 décimales).';

-- 3. Les tags de la table
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE        = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur concerné (R1), reconstruite depuis RAW purgée ; Time Travel 1 jour (R2)';

-- 4. Les colonnes personnelles, y compris la colonne calculée driver_name
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_id   SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';

-- 5. Vérifier
SELECT level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'))
ORDER BY column_name, tag_name;
