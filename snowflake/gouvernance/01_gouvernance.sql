-- =====================================================================
-- 01_gouvernance.sql — ce qui porte les règles, et les droits (guide, jour 1, étape 10)
-- Crée le rôle GOUVERNANCE (écrit les règles, ne lit pas les données), son schéma, les trois tags
-- du contrat (section 3) et la table QUALITE_RESULTATS (section 1), puis donne au rôle des outils
-- les droits dont il aura besoin (poser les tags, écrire les résultats de qualité, créer la vue du catalogue).
-- À exécuter en entier (Cmd+Maj+Entrée), après 00_installation.sql. Rejouable.
-- =====================================================================

-- ===================================================================== 1. ACCOUNTADMIN
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
SET moi = CURRENT_USER();

-- Le rôle de gouvernance : ni rattaché à SYSADMIN, ni au rôle des outils.
-- Il ne reçoit aucun SELECT sur les tables : il écrit les règles sans voir les données.
CREATE ROLE IF NOT EXISTS GOUVERNANCE COMMENT = 'Écrit les règles : tags, politiques, table de correspondance. Ne lit pas les données';
GRANT ROLE GOUVERNANCE TO USER IDENTIFIER($moi);

-- Exécuter des requêtes, et trouver les tables auxquelles il attachera ses politiques (USAGE seulement, pas SELECT)
GRANT USAGE ON WAREHOUSE NYC_TAXI_WH TO ROLE GOUVERNANCE;
GRANT USAGE ON DATABASE NYC_TAXI TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.RAW   TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.MARTS TO ROLE GOUVERNANCE;

-- Son schéma : créé ici, puis donné. Le propriétaire d'un schéma y crée ce qu'il veut sans autre droit.
CREATE SCHEMA IF NOT EXISTS NYC_TAXI.GOUVERNANCE COMMENT = 'Tags, politiques et tables de la gouvernance des données RH';
GRANT OWNERSHIP ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE GOUVERNANCE COPY CURRENT GRANTS;

-- Attacher ses politiques (jour 2) à des tables qu'il ne possède pas : droits « sur tout le compte »
GRANT APPLY MASKING POLICY    ON ACCOUNT TO ROLE GOUVERNANCE;
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE GOUVERNANCE;

-- ===================================================================== 2. GOUVERNANCE : tags et résultats de qualité
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.SENSIBILITE
  ALLOWED_VALUES 'public', 'interne', 'confidentiel'
  COMMENT = 'Sensibilité d''une table cataloguée. Posé sur la table, hérité par ses colonnes.';

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
  ALLOWED_VALUES 'nom', 'email', 'telephone', 'date_naissance', 'identifiant_officiel', 'identifiant_interne'
  COMMENT = 'Nature de la donnée personnelle d''une colonne. Déclenche le masquage (jour 2).';

-- Texte libre (contrat, section 3) : pas de ALLOWED_VALUES
CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION
  COMMENT = 'Durée de conservation d''une table cataloguée, en clair (ex. « 5 ans après la fin du contrat »).';

CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS (
    regle         VARCHAR       COMMENT 'Nom de la règle de qualité (contrat, section 6), ex. service_rattache',
    mesure_le     TIMESTAMP_NTZ COMMENT 'Date et heure de la mesure',
    nb_anomalies  NUMBER        COMMENT 'Nombre de lignes en anomalie au moment de la mesure',
    seuil         NUMBER(18,2)  COMMENT 'Seuil toléré, converti en nombre de lignes au moment de la mesure',
    statut        VARCHAR       COMMENT 'OK si nb_anomalies <= seuil, sinon ALERTE'
)
COMMENT = 'Historique des contrôles de qualité : une ligne par règle et par exécution de la tâche T_QUALITE. Alimentée chaque jour par le rôle des outils.';

-- ===================================================================== 3. GOUVERNANCE : droits du rôle des outils
-- Voir le schéma
GRANT USAGE ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;
-- Poser les tags sur ses propres tables (catalogue, étape 11) : APPLY sur CHAQUE tag, pas sur tous les tags du compte
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.SENSIBILITE        TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION TO ROLE TRANSFORMER;
-- Enregistrer et relire les résultats de qualité (tâches, jour 3) : ni UPDATE ni DELETE, l'historique ne se réécrit pas
GRANT INSERT, SELECT ON TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS TO ROLE TRANSFORMER;
-- Créer la vue V_CATALOGUE (jour 3)
GRANT CREATE VIEW ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;

-- ===================================================================== 4. Vérifier
SHOW TAGS IN SCHEMA NYC_TAXI.GOUVERNANCE;   -- 3 lignes
-- SHOW GRANTS TO ROLE demande d'avoir la main sur le rôle interrogé : on revient à ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;
SHOW GRANTS TO ROLE GOUVERNANCE;
SHOW GRANTS TO ROLE TRANSFORMER;            -- APPLY sur les 3 tags, INSERT et SELECT sur QUALITE_RESULTATS, CREATE VIEW
