-- =====================================================================
-- bonus_classification.sql — bonus 1 : la classification automatique de Snowflake face à notre inventaire
-- SYSTEM$CLASSIFY lit un échantillon des valeurs et propose une catégorie par colonne.
-- auto_tag = false : on regarde les propositions, on ne laisse pas Snowflake poser ses propres tags.
-- Consomme des crédits. Résultat et comparaison : docs/REGISTRE.md, partie 1.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;          -- il faut un rôle qui voit les valeurs EN CLAIR (voir plus bas)
USE WAREHOUSE NYC_TAXI_WH;

CALL SYSTEM$CLASSIFY('NYC_TAXI.RAW.DRIVERS', {'auto_tag': false});

-- Lancée avec ACCOUNTADMIN, la même procédure ne propose RIEN : elle n'échantillonne que des '*****'
-- (masquage par défaut). Une classification se lance avec le rôle propriétaire des données, pas avec l'administrateur.
