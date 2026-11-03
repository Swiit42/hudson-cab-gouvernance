-- Une requête qui renvoie UNE ligne et UNE colonne : le nombre de lignes en anomalie. Zéro = règle respectée.
-- Règle (seuil : 0, avertissement) : un service ne dure pas plus de 16 heures.
-- Référentiel : GOUVERNANCE.QUALITE_REGLES ; mesurée chaque jour par la tâche MARTS.T_QUALITE.
SELECT COUNT_IF(hours_worked > 16) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
