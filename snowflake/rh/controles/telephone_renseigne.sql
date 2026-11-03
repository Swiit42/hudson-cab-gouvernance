-- Une requête qui renvoie UNE ligne et UNE colonne : le nombre de lignes en anomalie. Zéro = règle respectée.
-- Règle (seuil : 5 % des chauffeurs en poste, avertissement) : chaque chauffeur en poste a un téléphone.
-- Une chaîne vide compte comme un téléphone absent.
-- Référentiel : GOUVERNANCE.QUALITE_REGLES ; mesurée chaque jour par la tâche MARTS.T_QUALITE.
SELECT COUNT_IF(end_date IS NULL AND NULLIF(TRIM(phone), '') IS NULL) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS;
