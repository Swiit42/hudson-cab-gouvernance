-- Une requête qui renvoie UNE ligne et UNE colonne : le nombre de lignes en anomalie. Zéro = règle respectée.
-- Règle BLOQUANTE (seuil : 50 services) : chaque service appartient à un chauffeur connu de RAW.DRIVERS.
-- Un service orphelin ne peut pas être purgé par R1 (on ne connaît pas la fin de contrat) ni rattaché à un dépôt fiable.
-- Référentiel : GOUVERNANCE.QUALITE_REGLES ; mesurée chaque jour par la tâche MARTS.T_QUALITE.
SELECT COUNT(*) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
WHERE NOT EXISTS (SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id = s.driver_id);
