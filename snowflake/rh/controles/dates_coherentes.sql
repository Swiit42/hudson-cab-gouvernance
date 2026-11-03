-- Une requête qui renvoie UNE ligne et UNE colonne : le nombre de lignes en anomalie. Zéro = règle respectée.
-- Règle (seuil : 0, avertissement) : pas d'embauche dans le futur, pas de fin de contrat avant l'embauche.
-- Référentiel : GOUVERNANCE.QUALITE_REGLES ; mesurée chaque jour par la tâche MARTS.T_QUALITE.
SELECT COUNT_IF(hire_date > CURRENT_DATE() OR end_date < hire_date) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS;
