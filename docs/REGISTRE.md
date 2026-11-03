# Registre du traitement — données du personnel

Il se remplit en deux temps :

- **Partie 1, jour 1** : l'inventaire des données personnelles des deux fichiers, avant tout chargement ;
- **Partie 2, jour 3** : la fiche de registre, qui s'appuie sur l'inventaire et sur ce que nous avons construit.

---

## Partie 1 — Inventaire des données personnelles (jour 1)

Une donnée personnelle est une information qui se rapporte à une personne identifiée ou identifiable (RGPD, art. 4.1). Trois cas :

- **identifiant direct** : la colonne suffit à désigner la personne (un nom, un e-mail) ;
- **identifiant indirect** : la colonne ne suffit pas seule, mais permet d'identifier quelqu'un une fois combinée à d'autres (une date de naissance et un dépôt) ;
- **pas une donnée personnelle** : la colonne ne dit rien d'une personne.

Les exemples de valeurs ci-dessous sont **inventés** (même format que le fichier) : aucune ligne du fichier RH n'est recopiée dans le dépôt.

### `drivers.csv` : les colonnes

| Colonne | Exemple de valeur | Donnée personnelle ? | Valeur du tag `DONNEE_PERSONNELLE` | Qui en a besoin, et pour quoi faire |
|---|---|---|---|---|
| `driver_id` | `D0000` | **indirect** : pseudonyme, ré-identifiable avec la table des chauffeurs | `identifiant_interne` | tous les rôles métier : compter et joindre sans nommer (contrat, section 4) |
| `first_name` | `Jean` | **direct** (avec le nom) | `nom` | paie (bulletins), responsables de dépôt (appeler, planifier) |
| `last_name` | `Dupont` | **direct** | `nom` | paie, responsables de dépôt |
| `email` | `jean.dupont0@post.example` | **direct** : contient le nom | `email` | paie (envoi des bulletins) ; ni les responsables de dépôt ni l'analyste |
| `phone` | `+1 (917) 555-0000` | **direct** | `telephone` | paie, responsables de dépôt (joindre un chauffeur pendant un service) |
| `birth_date` | `1980-01-01` | **indirect** : avec le dépôt et la date d'embauche, désigne presque toujours une seule personne | `date_naissance` | paie (déclarations sociales) ; l'analyste n'a besoin que de l'année (pyramide des âges) |
| `tlc_license_number` | `5000000` | **direct** : la TLC publie la liste des licences avec le nom du titulaire | `identifiant_officiel` | paie (vérifier que le chauffeur est autorisé à conduire) |
| `depot` | `Queens` | **indirect** : dit où travaille la personne ; ne l'identifie pas seul | non tagué (aucune valeur du contrat) | tous : c'est la clé du filtre par dépôt |
| `hire_date` | `2015-06-01` | **indirect** : vie professionnelle | non tagué (aucune valeur du contrat) | paie (ancienneté), analyste (ancienneté) |
| `end_date` | vide ou `2023-12-31` | **indirect** : vie professionnelle ; déclenche la purge (R1) | non tagué (aucune valeur du contrat) | paie, pipeline (purge) |
| `_source_file`, `_loaded_at` (techniques, ajoutées au chargement) | `drivers.csv` | non | — | pipeline : traçabilité du chargement |

### `driver_shifts.csv` : les colonnes

| Colonne | Exemple de valeur | Donnée personnelle ? | Valeur du tag `DONNEE_PERSONNELLE` | Qui en a besoin, et pour quoi faire |
|---|---|---|---|---|
| `shift_id` | `S000000` | non seul ; rattaché à un chauffeur par `driver_id` | — | pipeline (dédoublonnage) |
| `driver_id` | `D0000` | **indirect** | `identifiant_interne` | tous : joindre à la dimension chauffeur |
| `shift_date` | `2025-01-15` | **indirect** : activité d'une personne identifiable | non tagué | paie, responsables de dépôt, analyste |
| `depot` | `Brooklyn` | **indirect** | non tagué | filtre par dépôt |
| `start_hour` | `6` | **indirect** : horaires de travail d'une personne | non tagué | responsables de dépôt (planning) |
| `hours_worked` | `8.5` | **indirect** : temps de travail, sert à la paie | non tagué | paie, analyste |
| `trips_count` | `22` | **indirect** : performance individuelle | non tagué | analyste, responsables de dépôt |
| `revenue_usd` | `650.00` | **indirect** : recette individuelle, sert à la paie | non tagué | paie, analyste |
| `_source_file`, `_loaded_at` | `driver_shifts.csv` | non | — | pipeline |

Les colonnes « indirectes non taguées » restent des données personnelles au sens du RGPD : elles sont protégées par le **filtre de lignes** (un rôle ne voit que les chauffeurs de son dépôt) plutôt que par le masquage. Le tag `DONNEE_PERSONNELLE` est réservé aux six natures listées dans le contrat, qui déclenchent le masquage.

### Où cette donnée est-elle copiée ?

| Colonne d'origine | Table ou vue | Colonne | Sous quelle forme |
|---|---|---|---|
| `first_name`, `last_name` | `STAGING.STG_RH__DRIVERS` | `first_name`, `last_name` | telles quelles |
| `first_name`, `last_name` | `MARTS.DIM_DRIVER` | `first_name`, `last_name` | telles quelles |
| `first_name`, `last_name` | `MARTS.MART_DRIVER_MONTHLY` | `driver_name` | **colonne calculée** : `first_name || ' ' || last_name` → tag `nom` |
| `email` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `email` | en minuscules, sans espaces |
| `phone` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `phone` | vide remplacé par `NULL` |
| `birth_date` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `birth_date` | telle quelle |
| `tlc_license_number` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `tlc_license_number` | telle quelle |
| `driver_id` | toutes les tables et vues du domaine RH | `driver_id` | tel quel |
| `hire_date`, `end_date` | `MARTS.DIM_DRIVER` | `hire_date`, `end_date`, `is_active`, `tenure_years` | telles quelles, et **deux colonnes calculées** (en poste ou non, ancienneté en années) |
| `depot` | `STAGING.*`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY` | `depot` | normalisé (`INITCAP(TRIM())`) |
| activité (`hours_worked`, `trips_count`, `revenue_usd`) | `MARTS.MART_DRIVER_MONTHLY` | mêmes noms, `nb_shifts` | **agrégée par chauffeur et par mois** : reste personnelle, car rattachée à `driver_id` et `driver_name` |

### Ce qui a surpris

- **`driver_name`** dans `MART_DRIVER_MONTHLY` : une table « d'activité » qui recopie le nom en clair. Une colonne calculée à partir d'une donnée personnelle est une donnée personnelle, et elle doit porter le tag.
- **La date de naissance complète** n'est utile qu'à la paie ; l'analyste n'a besoin que de l'année. Le numéro de licence, bien que public à New York, identifie directement le chauffeur.
- **Le fichier contient des erreurs** (profilage avant chargement) : 9 dépôts mal écrits (`queens`, `BRONX `), 7 e-mails sans `@` (`… at post.example`), 12 téléphones vides, 4 numéros de licence partagés par deux chauffeurs, 5 fins de contrat antérieures à l'embauche, 1 embauche dans le futur ; côté services, 25 services rattachés à des chauffeurs inconnus (`D9xxx`) et 18 identifiants de service en double.
- **110 chauffeurs sur 400 sont partis**, dont 46 depuis plus de 5 ans (au 03/11/2026) : ils n'auraient plus dû être dans le fichier transmis.

---

## Partie 2 — Fiche de registre (jour 3)

Version réduite du registre des activités de traitement (RGPD, art. 30), limitée à ce qu'un Data Engineer peut renseigner et prouver. Trame complète : CNIL, https://www.cnil.fr/fr/RGPD-le-registre-des-activites-de-traitement. Chaque réponse renvoie à la requête ou au fichier qui la prouve. Mise à jour : 03/11/2026.

### Le traitement

| Rubrique | Réponse |
|---|---|
| Nom du traitement | Entrepôt du personnel des chauffeurs (domaine RH de l'entrepôt Snowflake `NYC_TAXI`) |
| Responsable du traitement | Hudson Cab Europe (Paris), qui décide depuis cette année de ce que deviennent ces données (RGPD art. 4.7 ; voir `VEILLE.md`, section 1). Sous-traitant : Snowflake (hébergement, région `AWS_EU_WEST_3`, Paris) |
| Finalités : à quoi servent ces données | 1. Paie des chauffeurs (base légale : exécution du contrat de travail, art. 6.1 b, et obligations légales, art. 6.1 c). 2. Organisation des dépôts : joindre et planifier les chauffeurs de son dépôt (contrat de travail, art. 6.1 b). 3. Pilotage de l'activité de la flotte par dépôt et par mois (intérêt légitime, art. 6.1 f — à valider par le DPO, `VEILLE.md` section 5) |
| Personnes concernées | Chauffeurs de taxi de Hudson Cab Partners, en poste ou partis depuis moins de 5 ans (354 au 03/11/2026, après purge) |
| Service responsable des données | Service RH (source du fichier, rectification) ; équipe data de Hudson Cab Europe (entrepôt, règles) |

### Les données

| Catégorie de données | Colonnes concernées | Tables où elles se trouvent |
|---|---|---|
| Identité | `first_name`, `last_name`, `driver_name` (calculée), `birth_date`, `driver_id` | `RAW.DRIVERS`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY` (`driver_name`, `driver_id`), vue `STAGING.STG_RH__DRIVERS` |
| Coordonnées | `email`, `phone` | `RAW.DRIVERS`, `MARTS.DIM_DRIVER`, vue `STAGING.STG_RH__DRIVERS` |
| Identifiant officiel | `tlc_license_number` | `RAW.DRIVERS`, `MARTS.DIM_DRIVER` |
| Vie professionnelle | `depot`, `hire_date`, `end_date`, `is_active`, `tenure_years` ; activité : `shift_date`, `start_hour`, `hours_worked`, `trips_count`, `revenue_usd` | `RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY` |

Preuve : `SELECT * FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE WHERE donnee_personnelle IS NOT NULL;` (lisible par `ANALYSTE`) ; fiches de `snowflake/rh/catalogue/`.

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| `RH_PAIE` | Tous les dépôts, toutes les colonnes en clair ; pas `RAW` | Établir la paie, les déclarations, vérifier la licence | `05_tests_acces.sql` : tests 1, 8, V1, V5 |
| `RESP_DEPOT_QUEENS`, `RESP_DEPOT_BRONX` | Leur dépôt seulement ; nom, prénom, téléphone en clair ; e-mail et licence `*****`, date de naissance `NULL` | Joindre et planifier leurs chauffeurs | tests 2, 3, 3b, 4, V2, V3, V6, L3, L4 |
| `ANALYSTE` | Tous les dépôts, tout `MARTS` ; identifiants directs `*****`, année de naissance seulement ; `driver_id` en clair | Analyser l'activité sans nommer personne | tests 5, 5b, 9, V4, V7, L1, L2 |
| `TRANSFORMER` (rôle des outils) | Tout, en clair | Charger, purger, contrôler, reconstruire (sinon il recopierait des masques) | tests 7c, 10, 11b |
| `GOUVERNANCE` | Rien (aucun `SELECT`) ; écrit les règles | Séparation des pouvoirs | tests 6, 9d |
| `ACCOUNTADMIN`, `SYSADMIN` | 0 ligne dans `MARTS` ; `RAW` avec colonnes personnelles masquées | Administrer, pas lire | tests 7, 7b, 9 bis, 9c |

Cahier complet et résultats : `docs/ACCES.md` (37 / 37 verts, y compris après une exécution des tâches planifiées).

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | `DELETE` des chauffeurs dont `end_date` < aujourd'hui − 5 ans, dans `RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER` et `MARTS.MART_DRIVER_MONTHLY` ; chaque jour à 6 h (tâche `MARTS.T_PURGE`). Le 03/11/2026 : 46 chauffeurs supprimés (400 → 354), 0 service | `snowflake/rh/purge_rh.sql` (comptage avant / après) ; `taches_rh.sql` ; `TASK_HISTORY` |
| R2 : pas de restauration au-delà de 1 jour | `DATA_RETENTION_TIME_IN_DAYS = 1` sur les 4 tables de chauffeurs. Preuve que Time Travel relit une ligne supprimée : `SELECT COUNT(*) FROM RAW.DRIVERS BEFORE (STATEMENT => <purge>)` → 400 juste après la purge | `snowflake/rh/conservation_rh.sql` (`retention_time = 1`) ; `purge_rh.sql`, étape 4 |
| R3 : pas de fichier sur le stage | `COPY INTO … PURGE = TRUE`, puis `REMOVE @RH_STAGE` (un fichier redéposé est ignoré par `COPY` et ne serait pas purgé) | `LIST @NYC_TAXI.RAW.RH_STAGE;` → aucun fichier (`conservation_rh.sql`, étape 3) |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : **8 jours** (1 jour de Time Travel, lisible avec `AT`/`BEFORE` par le propriétaire de la table, puis 7 jours de Fail-safe, non lisibles, récupérables seulement par le support Snowflake, non réductibles sur une table permanente). Plus jusqu'à 24 h d'attente de la tâche quotidienne : jusqu'à 9 jours après le 5e anniversaire de la fin du contrat.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | Oui : utilisateur, rôle, table, colonnes lues et requête, sur 7 jours (jusqu'à 3 h de latence). Au 03/11/2026 : lectures de colonnes personnelles par `TRANSFORMER` (dont l'utilisateur `SYSTEM` des tâches), `RH_PAIE`, `ANALYSTE`, `RESP_DEPOT_QUEENS`, `ACCOUNTADMIN` (sur `RAW`, valeurs masquées) et le rôle de démonstration `RESP_DEPOT_BROOKLYN`. Une lecture n'est pas une vue en clair : le masquage s'applique à la lecture | `snowflake/gouvernance/06_audit.sql` (`ACCESS_HISTORY` joint à `QUERY_HISTORY`) ; capture dans `docs/captures/` |
| Sait-on quand une donnée est fausse ? | Oui : 8 règles mesurées chaque jour sur `RAW` (tâche `T_QUALITE`), une ligne par règle et par exécution dans `QUALITE_RESULTATS`. Au 03/11/2026 : 6 règles en `ALERTE` (licences en double, e-mails invalides, dates incohérentes, dépôts mal écrits, services en double, services trop longs), 2 `OK`. La règle bloquante `service_rattache` (25 orphelins, seuil 50) arrête la reconstruction de `MARTS` si elle dépasse : prouvé en abaissant le seuil à 10 (`T_QUALITE` en échec, `T_TABLES` non lancée) | `SELECT * FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS ORDER BY mesure_le DESC;` ; `GOUVERNANCE.QUALITE_REGLES` (énoncé, seuil, gravité) ; `TASK_HISTORY` |
| Que se passe-t-il si le rôle des outils est compromis ? | Il lit tout en clair (nécessaire au pipeline) et peut retirer un tag de ses tables, donc démasquer une colonne. Il ne peut ni modifier les politiques (propriété de `GOUVERNANCE`) ni changer `ACCES_DEPOT`. Détection : test n° 12 du cahier, audit des `UNSET TAG` et des lectures de `SYSTEM` hors de 6 h. Réponse : révoquer `TRANSFORMER` à l'utilisateur concerné, rejouer le catalogue depuis Git | `docs/ACCES.md`, partie 1 (« ce que cette carte permet de défaire ») |

### Limites connues

- Les chauffeurs partis depuis moins de 5 ans restent dans la base active, visibles des responsables de dépôt et de l'analyste comme les chauffeurs en poste : la CNIL recommande un archivage intermédiaire à accès restreint (écart principal, `README.md`).
- L'analyste ne voit aucun identifiant direct, mais `driver_id` + dépôt + date d'embauche + année de naissance permettent, pour un chauffeur rare, une ré-identification indirecte : les données de l'analyste sont pseudonymisées, pas anonymes.
- `ACCESS_HISTORY` a jusqu'à 3 h de retard ; les fichiers RH déposés sur le poste de l'utilisateur (dossier `data/`, hors Git) échappent à l'entrepôt et doivent être supprimés après chargement.
