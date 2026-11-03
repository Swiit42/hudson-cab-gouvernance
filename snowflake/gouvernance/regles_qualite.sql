-- =====================================================================
-- regles_qualite.sql — le référentiel des règles de qualité (contrat, section 6)
-- Une ligne par règle : énoncé, seuil, gravité, fichier de contrôle. La tâche T_QUALITE lit les seuils
-- et la gravité ICI : changer un seuil = un UPDATE, sans toucher à la tâche.
-- À exécuter en entier avec GOUVERNANCE (propriétaire du schéma), après 01_gouvernance.sql. Rejouable.
-- =====================================================================
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.QUALITE_REGLES (
    regle       VARCHAR      NOT NULL COMMENT 'Nom de la règle (contrat, section 6)',
    enonce      VARCHAR      NOT NULL COMMENT 'Ce que la règle vérifie',
    table_cible VARCHAR      NOT NULL COMMENT 'Table RAW mesurée',
    seuil       NUMBER(18,2)          COMMENT 'Seuil toléré en nombre de lignes (NULL si exprimé en pourcentage)',
    seuil_pct   NUMBER(5,2)           COMMENT 'Seuil en pourcentage des chauffeurs en poste, converti en lignes au moment de la mesure',
    gravite     VARCHAR      NOT NULL COMMENT 'avertissement : on enregistre et on continue ; bloquant : on enregistre et la chaîne s''arrête',
    controle    VARCHAR               COMMENT 'Fichier SQL de la règle dans snowflake/rh/controles/'
)
COMMENT = 'Référentiel des règles de qualité du domaine RH : énoncé, seuil, gravité. Lu par la tâche MARTS.T_QUALITE.';

DELETE FROM NYC_TAXI.GOUVERNANCE.QUALITE_REGLES;
INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_REGLES (regle, enonce, table_cible, seuil, seuil_pct, gravite, controle) VALUES
    ('licence_unique',      'Un numéro de licence TLC n''appartient qu''à un chauffeur',                         'RAW.DRIVERS',          0,    NULL, 'avertissement', 'controles/licence_unique.sql'),
    ('telephone_renseigne', 'Chaque chauffeur en poste a un téléphone',                                          'RAW.DRIVERS',          NULL, 5,    'avertissement', 'controles/telephone_renseigne.sql'),
    ('email_valide',        'L''e-mail contient un @',                                                           'RAW.DRIVERS',          0,    NULL, 'avertissement', 'controles/email_valide.sql'),
    ('dates_coherentes',    'Pas d''embauche dans le futur, pas de fin de contrat avant l''embauche',            'RAW.DRIVERS',          0,    NULL, 'avertissement', 'controles/dates_coherentes.sql'),
    ('depot_connu',         'Le dépôt est écrit exactement Bronx, Brooklyn ou Queens',                           'RAW.DRIVERS, RAW.DRIVER_SHIFTS', 0, NULL, 'avertissement', 'controles/depot_connu.sql'),
    ('service_rattache',    'Chaque service appartient à un chauffeur connu',                                    'RAW.DRIVER_SHIFTS',    50,   NULL, 'bloquant',      'controles/service_rattache.sql'),
    ('service_unique',      'Un identifiant de service n''apparaît qu''une fois',                                'RAW.DRIVER_SHIFTS',    0,    NULL, 'avertissement', 'controles/service_unique.sql'),
    ('duree_plausible',     'Un service ne dure pas plus de 16 heures',                                          'RAW.DRIVER_SHIFTS',    0,    NULL, 'avertissement', 'controles/duree_plausible.sql');

-- La tâche T_QUALITE (rôle des outils) lit ce référentiel
GRANT SELECT ON TABLE NYC_TAXI.GOUVERNANCE.QUALITE_REGLES TO ROLE TRANSFORMER;

-- Vérifier : 8 règles, dont 1 bloquante
SELECT regle, seuil, seuil_pct, gravite FROM NYC_TAXI.GOUVERNANCE.QUALITE_REGLES ORDER BY gravite DESC, regle;
