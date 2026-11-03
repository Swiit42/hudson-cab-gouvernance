-- =====================================================================
-- 06_audit.sql — qui a lu les données personnelles des chauffeurs, avec quel rôle (guide, jour 3, étape 8)
-- Avec ACCOUNTADMIN : la base SNOWFLAKE (ACCOUNT_USAGE) n'est lisible que par lui ici.
-- ACCESS_HISTORY dit QUELS objets et QUELLES colonnes ont été lus (base_objects_accessed : les tables réellement
-- lues, même à travers une vue) ; le RÔLE est dans QUERY_HISTORY, à joindre sur query_id.
-- Latence : jusqu'à 3 heures. Les lectures de la dernière heure peuvent manquer ; celles de la veille y sont.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;

-- 1. Le détail : qui a lu DIM_DRIVER ces 7 derniers jours, avec quel rôle, quelles colonnes
SELECT
    ah.query_start_time,
    ah.user_name,
    qh.role_name,
    obj.value:"objectName"::string                                         AS table_lue,
    ARRAY_TO_STRING(TRANSFORM(obj.value:"columns", c -> c:"columnName"::string), ', ') AS colonnes_lues,
    LEFT(qh.query_text, 120)                                               AS requete
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah
JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
  ON qh.query_id = ah.query_id,             -- la jointure AVANT le FLATTEN : un JOIN lie plus fort que la virgule
     LATERAL FLATTEN(input => ah.base_objects_accessed) obj
WHERE ah.query_start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
  AND obj.value:"objectName"::string = 'NYC_TAXI.MARTS.DIM_DRIVER'
ORDER BY ah.query_start_time DESC
LIMIT 100;

-- 2. La synthèse : par rôle, combien de requêtes ont lu une colonne PERSONNELLE de DIM_DRIVER ou de RAW.DRIVERS
--    (les colonnes taguées DONNEE_PERSONNELLE, hors identifiant interne), et quand pour la dernière fois
WITH colonnes_lues AS (
    SELECT ah.query_id, ah.query_start_time, ah.user_name,
           obj.value:"objectName"::string  AS table_lue,
           col.value:"columnName"::string  AS colonne
    FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
         LATERAL FLATTEN(input => ah.base_objects_accessed) obj,
         LATERAL FLATTEN(input => obj.value:"columns") col
    WHERE ah.query_start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
      AND obj.value:"objectName"::string IN ('NYC_TAXI.MARTS.DIM_DRIVER', 'NYC_TAXI.RAW.DRIVERS', 'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY')
      AND col.value:"columnName"::string IN ('FIRST_NAME', 'LAST_NAME', 'EMAIL', 'PHONE', 'BIRTH_DATE', 'TLC_LICENSE_NUMBER', 'DRIVER_NAME')
)
SELECT qh.role_name,
       cl.user_name,
       COUNT(DISTINCT cl.query_id)                        AS requetes,
       LISTAGG(DISTINCT cl.table_lue, ', ')               AS tables,
       LISTAGG(DISTINCT cl.colonne, ', ')                 AS colonnes_personnelles,
       MAX(cl.query_start_time)                           AS derniere_lecture
FROM colonnes_lues cl
JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh ON qh.query_id = cl.query_id
GROUP BY 1, 2
ORDER BY requetes DESC;

-- À lire avec la matrice : une lecture n'est pas une fuite. Le masquage s'applique à la lecture ;
-- ACCESS_HISTORY trace qu'une colonne a été LUE, pas qu'elle a été vue EN CLAIR (ANALYSTE lit email, il voit *****).
