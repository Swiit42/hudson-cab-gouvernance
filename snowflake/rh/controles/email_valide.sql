-- Une requête qui renvoie UNE ligne et UNE colonne : le nombre de lignes en anomalie. Zéro = règle respectée.
-- Règle (seuil : 0, avertissement) : l'e-mail contient un @.
-- Référentiel : GOUVERNANCE.QUALITE_REGLES ; mesurée chaque jour par la tâche MARTS.T_QUALITE.
SELECT COUNT_IF(email IS NULL OR email NOT LIKE '%@%') AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS;
