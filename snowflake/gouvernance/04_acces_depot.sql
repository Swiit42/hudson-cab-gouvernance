-- =====================================================================
-- 04_acces_depot.sql — filtrer les lignes par dépôt (guide, jour 2, étape 6)
-- Qui voit quel dépôt est écrit dans une TABLE (GOUVERNANCE.ACCES_DEPOT), pas dans la politique :
-- ouvrir un dépôt à un rôle = ajouter une ligne, sans toucher à la politique.
-- À exécuter en entier avec GOUVERNANCE (APPLY ROW ACCESS POLICY reçu au jour 1). Rejouable.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. La table de correspondance (contrat, section 1). '*' = tous les dépôts.
CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.ACCES_DEPOT (
    role_name VARCHAR NOT NULL COMMENT 'Rôle Snowflake (rôle principal de la session)',
    depot     VARCHAR NOT NULL COMMENT 'Dépôt visible par ce rôle (Bronx, Brooklyn, Queens), ou * pour tous'
)
COMMENT = 'Table de correspondance rôle -> dépôt lue par la politique RAP_DEPOT. Un rôle absent ne voit aucune ligne des tables du domaine RH. Tenue par le rôle GOUVERNANCE.';

-- Le contenu est décrit ici, en entier : le script est la source de vérité (rejouable).
DELETE FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT;
INSERT INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT (role_name, depot) VALUES
    ('TRANSFORMER',       '*'),       -- sans cette ligne, MART_DRIVER_MONTHLY se reconstruirait sans noms, sans erreur
    ('RH_PAIE',           '*'),
    ('ANALYSTE',          '*'),
    ('RESP_DEPOT_QUEENS', 'Queens'),
    ('RESP_DEPOT_BRONX',  'Bronx');
-- Brooklyn n'a pas encore de responsable (écart signalé dans le README). Le jour où il en a un :
--   ('RESP_DEPOT_BROOKLYN', 'Brooklyn')   -- une ligne de plus, la politique ne change pas

-- 2. La politique : appelée pour chaque ligne, avec la valeur de sa colonne depot.
--    La sous-requête lit ACCES_DEPOT avec les droits du propriétaire de la politique (GOUVERNANCE) :
--    les rôles métier n'ont pas besoin de lire cette table.
CREATE ROW ACCESS POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.RAP_DEPOT
  AS (depot_ligne VARCHAR) RETURNS BOOLEAN -> FALSE
  COMMENT = 'Filtre les lignes du domaine RH par dépôt, selon GOUVERNANCE.ACCES_DEPOT';

ALTER ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT SET BODY ->
  EXISTS (
    SELECT 1
    FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT a
    WHERE a.role_name = CURRENT_ROLE()          -- le rôle principal, pas les rôles secondaires
      AND a.depot IN (depot_ligne, '*')
  );

-- 3. L'attacher aux deux tables du domaine RH de MARTS, sur la colonne depot.
--    DROP ALL ne fait rien s'il n'y a rien ; ADD échouerait si la politique était déjà attachée.
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER          DROP ALL ROW ACCESS POLICIES;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER          ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY DROP ALL ROW ACCESS POLICIES;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY ADD ROW ACCESS POLICY NYC_TAXI.GOUVERNANCE.RAP_DEPOT ON (depot);

-- 4. Vérifier (contrat, section 7)
SELECT * FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT ORDER BY role_name;
SELECT policy_name, policy_kind, ref_entity_name, ref_column_name, tag_name
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER', REF_ENTITY_DOMAIN => 'TABLE'));
