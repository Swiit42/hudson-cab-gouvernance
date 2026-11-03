-- =====================================================================
-- catalogue_dim_driver.sql — fiche de catalogue COMPLÈTE de NYC_TAXI.MARTS.DIM_DRIVER (guide, jour 1, étape 11)
-- Avec le rôle des outils, propriétaire de la table, après 01_gouvernance.sql. Rejouable.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. La table
COMMENT ON TABLE NYC_TAXI.MARTS.DIM_DRIVER IS
  'Dimension chauffeur : 1 ligne = 1 chauffeur de Hudson Cab Partners, en poste ou parti depuis moins de 5 ans, avec son dépôt normalisé, son statut et son ancienneté. Source : RAW.DRIVERS (fichier RH) via la vue STAGING.STG_RH__DRIVERS. Reconstruite chaque jour par INSERT OVERWRITE (marts/dim_driver.sql, tâche T_TABLES). Lue par RH_PAIE, les responsables de dépôt (leur dépôt seulement) et ANALYSTE, colonnes personnelles masquées selon le rôle. Responsable des données : service RH.';

-- 2. Les colonnes
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.driver_id          IS 'Identifiant interne du chauffeur (format D0000), clé de la table. Visible de tous les rôles métier : il permet de compter et de joindre sans nommer.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.first_name         IS 'Prénom du chauffeur. En clair pour la paie et les responsables de dépôt, masqué pour les autres rôles.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.last_name          IS 'Nom de famille du chauffeur. En clair pour la paie et les responsables de dépôt, masqué pour les autres rôles.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.email              IS 'Adresse e-mail du chauffeur, mise en minuscules et sans espaces. Sert à la paie (envoi des bulletins) ; masquée pour tous les autres rôles.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.phone              IS 'Téléphone du chauffeur ; NULL si non renseigné par le RH. Sert à la paie et aux responsables de dépôt pour joindre le chauffeur.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.birth_date         IS 'Date de naissance du chauffeur. Complète pour la paie ; réduite à l''année de naissance pour l''analyste (contrat, section 4).';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tlc_license_number IS 'Numéro de licence TLC (Taxi and Limousine Commission de New York), qui autorise à conduire un taxi jaune. Identifie directement le chauffeur : en clair pour la paie seulement.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.depot              IS 'Dépôt de rattachement, normalisé (Bronx, Brooklyn, Queens) ; clé vers DIM_DEPOT. Sert au filtre des lignes : un responsable ne voit que son dépôt.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.hire_date          IS 'Date d''embauche du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.end_date           IS 'Date de fin de contrat ; NULL = chauffeur en poste. Le chauffeur disparaît de la table 5 ans après cette date (purge, règle R1).';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.is_active          IS 'Colonne calculée : TRUE si le chauffeur est en poste (end_date vide).';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tenure_years       IS 'Colonne calculée : ancienneté en années (1 décimale), de l''embauche à la fin du contrat ou, pour un chauffeur en poste, au jour de construction de la table.';

-- 3. Les tags de la table
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE        = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur (R1), reconstruite depuis RAW.DRIVERS purgée ; Time Travel 1 jour (R2)';

-- 4. Les colonnes personnelles
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN driver_id          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN first_name         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN last_name          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN email              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN phone              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_date         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tlc_license_number SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

-- 5. Vérifier : 12 colonnes décrites, 7 colonnes taguées DONNEE_PERSONNELLE
SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'MARTS' AND table_name = 'DIM_DRIVER' ORDER BY ordinal_position;

SELECT level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'table'))
ORDER BY column_name, tag_name;
