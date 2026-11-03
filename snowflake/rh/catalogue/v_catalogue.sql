-- =====================================================================
-- v_catalogue.sql — la vue GOUVERNANCE.V_CATALOGUE (guide, jour 3, étape 5)
-- Une ligne par colonne des tables que lisent les rôles métier (MARTS : DIM_DRIVER, MART_DRIVER_MONTHLY,
-- DIM_DEPOT) : sa table, la description de la table et de la colonne, son type, ses tags.
-- Avec le rôle des outils : GOUVERNANCE ne voit pas les tables ; TRANSFORMER a reçu CREATE VIEW au jour 1.
-- Les rôles métier la lisent grâce au SELECT ON FUTURE VIEWS donné dans 02_roles_metier.sql.
-- Pourquoi MARTS seulement : INFORMATION_SCHEMA ne montre que ce que le rôle qui interroge a le droit de voir ;
-- une vue sur RAW reviendrait vide pour l'analyste. Rejouable (CREATE OR REPLACE : une vue ne porte ni tag ni politique).
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

CREATE OR REPLACE VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE
  COMMENT = 'Catalogue du domaine RH : 1 ligne = 1 colonne d''une table de MARTS, avec descriptions et tags. Source : INFORMATION_SCHEMA et TAG_REFERENCES_ALL_COLUMNS ; à jour à chaque lecture.'
AS
WITH tags AS (
    -- TAG_REFERENCES_ALL_COLUMNS s'appelle pour une table à la fois : un bloc par table.
    -- Elle renvoie aussi les tags posés sur la table (SENSIBILITE, DUREE_CONSERVATION), hérités par chaque colonne.
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'table'))
    UNION ALL
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'))
    UNION ALL
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DEPOT', 'table'))
)
SELECT
    c.table_schema                                                         AS schema_name,
    c.table_name,
    t.comment                                                              AS description_table,
    c.ordinal_position                                                     AS position,
    c.column_name,
    c.data_type,
    c.comment                                                              AS description_colonne,
    MAX(IFF(g.tag_name = 'DONNEE_PERSONNELLE', g.tag_value, NULL))         AS donnee_personnelle,
    MAX(IFF(g.tag_name = 'SENSIBILITE',        g.tag_value, NULL))         AS sensibilite,
    MAX(IFF(g.tag_name = 'DUREE_CONSERVATION', g.tag_value, NULL))         AS duree_conservation
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS c
JOIN NYC_TAXI.INFORMATION_SCHEMA.TABLES t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
LEFT JOIN tags g
  ON g.object_schema = c.table_schema AND g.object_name = c.table_name AND g.column_name = c.column_name
WHERE c.table_schema = 'MARTS'
  AND c.table_name IN ('DIM_DRIVER', 'MART_DRIVER_MONTHLY', 'DIM_DEPOT')
GROUP BY 1, 2, 3, 4, 5, 6, 7;

-- Vérifier avec le propriétaire : 24 lignes (12 + 8 + 4), 9 colonnes personnelles
SELECT table_name, COUNT(*) AS colonnes, COUNT(donnee_personnelle) AS personnelles, COUNT(description_colonne) AS decrites
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE GROUP BY table_name ORDER BY table_name;

-- Vérifier avec l'analyste : les trois tables, les mêmes tags
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT table_name, column_name, donnee_personnelle, sensibilite, description_colonne
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
WHERE donnee_personnelle IS NOT NULL
ORDER BY table_name, position;
