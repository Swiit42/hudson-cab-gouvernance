-- =====================================================================
-- 03_masquage.sql — masquer les colonnes personnelles selon le rôle (guide, jour 2, étape 5)
-- Les politiques sont attachées AU TAG DONNEE_PERSONNELLE, pas aux colonnes : toute colonne taguée
-- (RAW, MARTS, aujourd'hui ou demain, y compris driver_name) est protégée sans toucher à ce script.
-- À exécuter en entier avec GOUVERNANCE (propriétaire du tag ; APPLY MASKING POLICY reçu au jour 1). Rejouable.
--
-- Ce que chaque rôle voit en clair (contrat, section 4) :
--   identifiant_interne (driver_id) : tous les rôles (compter et joindre sans nommer)
--   TRANSFORMER                      : tout (sinon il recopierait des masques dans les tables, définitivement)
--   RH_PAIE                          : tout
--   RESP_DEPOT_*                     : nom, prénom, téléphone
--   ANALYSTE                         : rien d'autre que l'année de naissance
--   tout autre rôle (ACCOUNTADMIN, SYSADMIN, GOUVERNANCE...) : rien — masquage par défaut
-- Valeur masquée : '*****' pour un texte ; NULL pour une date (une politique renvoie le type qu'elle reçoit).
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. Texte : noms, e-mail, téléphone, licence, identifiant, driver_name
--    Rejouable : créer avec un corps provisoire, puis écrire le vrai corps (SET BODY marche même attachée).
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_TEXTE
  AS (val STRING) RETURNS STRING -> '*****'
  COMMENT = 'Masque les colonnes texte taguées DONNEE_PERSONNELLE selon le rôle (contrat, section 4)';

ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE SET BODY ->
  CASE
    -- L'identifiant interne reste visible de tous
    WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE') = 'identifiant_interne'
      THEN val
    -- Le pipeline et la paie voient tout
    WHEN CURRENT_ROLE() IN ('TRANSFORMER', 'RH_PAIE')
      THEN val
    -- Les responsables de dépôt : nom, prénom (et driver_name), téléphone.
    -- Convention de nommage : un nouveau dépôt = un rôle RESP_DEPOT_<DÉPÔT>, sans modifier cette politique.
    WHEN STARTSWITH(CURRENT_ROLE(), 'RESP_DEPOT_')
         AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN('NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE') IN ('nom', 'telephone')
      THEN val
    -- Une valeur absente reste absente : un masque ne doit pas faire croire qu'un téléphone existe
    WHEN val IS NULL
      THEN NULL
    ELSE '*****'
  END;

-- 2. Date : la date de naissance
CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_DATE
  AS (val DATE) RETURNS DATE -> NULL
  COMMENT = 'Masque les colonnes date taguées DONNEE_PERSONNELLE : complète pour la paie, année pour l''analyste';

ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE SET BODY ->
  CASE
    WHEN CURRENT_ROLE() IN ('TRANSFORMER', 'RH_PAIE') THEN val
    -- L'année seulement : le 1er janvier de l'année de naissance (une date reste une date)
    WHEN CURRENT_ROLE() = 'ANALYSTE'                  THEN DATE_TRUNC('year', val)
    ELSE NULL
  END;

-- 3. Attacher les deux politiques au tag. Échoue si c'est déjà fait : le bloc attrape l'erreur (rejouable).
EXECUTE IMMEDIATE $$
BEGIN
  ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET
    MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_TEXTE,
    MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DATE;
  RETURN 'Politiques attachées au tag DONNEE_PERSONNELLE.';
EXCEPTION
  WHEN STATEMENT_ERROR THEN
    RETURN 'Non attachées, lire le message (déjà attachées ?) : ' || SQLERRM;
END;
$$;

-- 4. Vérifier : le tag porte les deux politiques
SELECT policy_name, policy_kind, ref_entity_name, ref_column_name, tag_name
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE', REF_ENTITY_DOMAIN => 'TAG'));
