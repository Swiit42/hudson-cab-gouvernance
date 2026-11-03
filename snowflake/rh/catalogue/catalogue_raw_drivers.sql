-- =====================================================================
-- catalogue_raw_drivers.sql — fiche de catalogue COMPLÈTE de NYC_TAXI.RAW.DRIVERS (guide, jour 1, étape 11)
-- Avec le rôle des outils, propriétaire de la table, après 01_gouvernance.sql. Rejouable :
-- COMMENT et SET TAG remplacent la valeur précédente.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. La table : ce qu'elle contient, d'où elle vient, à quel rythme elle change
COMMENT ON TABLE NYC_TAXI.RAW.DRIVERS IS
  'Fichier du personnel des chauffeurs de Hudson Cab Partners, copie fidèle de drivers.csv transmis par le service RH : 1 ligne = 1 chauffeur, en poste ou parti. Chargée par COPY INTO (chargement_rh_2_copier.sql) à chaque nouveau fichier RH ; purgée chaque jour des chauffeurs partis depuis plus de 5 ans (tâche T_PURGE). Lue seulement par le rôle des outils. Responsable des données : service RH ; responsable technique : équipe data.';

-- 2. Les colonnes
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.driver_id          IS 'Identifiant interne du chauffeur attribué par le RH (format D0000), clé de jointure avec les services. Pseudonyme : n''identifie la personne qu''avec cette table.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.first_name         IS 'Prénom du chauffeur, tel que saisi par le RH.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.last_name          IS 'Nom de famille du chauffeur, tel que saisi par le RH.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.email              IS 'Adresse e-mail du chauffeur, utilisée par la paie pour envoyer les bulletins. Non nettoyée : peut être mal formée (règle email_valide).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.phone              IS 'Numéro de téléphone du chauffeur, format américain +1 (xxx) xxx-xxxx, pour le joindre pendant un service. Peut être vide (règle telephone_renseigne).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.birth_date         IS 'Date de naissance complète du chauffeur, utile à la paie (déclarations sociales). Combinée au dépôt et à l''embauche, elle identifie presque toujours une personne.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.tlc_license_number IS 'Numéro de la licence de conduite délivrée par la Taxi and Limousine Commission de New York (7 chiffres). Publié par la TLC avec le nom du titulaire : identifie directement le chauffeur. Doit être unique (règle licence_unique).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.depot              IS 'Dépôt (garage) de rattachement du chauffeur, tel que saisi par le RH : casse et espaces non normalisés (règle depot_connu). Valeurs attendues : Bronx, Brooklyn, Queens.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.hire_date          IS 'Date d''embauche du chauffeur (début du contrat).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.end_date           IS 'Date de fin du contrat ; vide = chauffeur en poste. Point de départ du délai de conservation de 5 ans (règle R1).';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._source_file       IS 'Colonne technique : nom du fichier d''où vient la ligne (METADATA$FILENAME), pour tracer un chargement.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._loaded_at         IS 'Colonne technique : date et heure du chargement de la ligne (METADATA$START_SCAN_TIME).';

-- 3. Les tags de la table (hérités par ses colonnes)
ALTER TABLE NYC_TAXI.RAW.DRIVERS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE        = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur (R1) ; Time Travel 1 jour (R2)';

-- 4. Les colonnes personnelles (inventaire : docs/REGISTRE.md, partie 1)
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN driver_id          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN first_name         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN last_name          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN email              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN phone              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN birth_date         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN tlc_license_number SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

-- 5. Vérifier : 12 colonnes décrites, 7 colonnes taguées DONNEE_PERSONNELLE
SELECT column_name, comment FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'RAW' AND table_name = 'DRIVERS' ORDER BY ordinal_position;

SELECT level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVERS', 'table'))
ORDER BY column_name, tag_name;
