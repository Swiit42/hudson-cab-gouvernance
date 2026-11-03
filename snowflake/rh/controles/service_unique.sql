-- Une requête qui renvoie UNE ligne et UNE colonne : le nombre de lignes en anomalie. Zéro = règle respectée.
-- Règle (seuil : 0, avertissement) : un identifiant de service n'apparaît qu'une fois.
-- Référentiel : GOUVERNANCE.QUALITE_REGLES ; mesurée chaque jour par la tâche MARTS.T_QUALITE.
SELECT COUNT(*) - COUNT(DISTINCT shift_id) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
