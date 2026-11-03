# Registre du traitement : les données du personnel

Le registre se remplit en deux temps. La partie 1, au jour 1, inventorie les données personnelles des deux fichiers avant tout chargement. La partie 2, au jour 3, est la fiche de registre. Elle s'appuie sur l'inventaire et sur ce que nous avons construit.

---

## Partie 1. Inventaire des données personnelles (jour 1)

Une donnée personnelle est une information qui se rapporte à une personne identifiée ou identifiable (RGPD, art. 4.1). Une colonne peut se trouver dans trois cas :

- elle est un **identifiant direct** si elle suffit à désigner la personne, comme un nom ou un e-mail ;
- elle est un **identifiant indirect** si elle ne suffit pas seule mais permet d'identifier quelqu'un une fois combinée à d'autres, comme une date de naissance avec un dépôt ;
- elle n'est **pas une donnée personnelle** si elle ne dit rien d'une personne.

Les exemples de valeurs ci-dessous sont inventés et suivent le format du fichier. Aucune ligne du fichier RH n'est recopiée dans le dépôt.

### Les colonnes de `drivers.csv`

| Colonne | Exemple de valeur | Donnée personnelle ? | Valeur du tag `DONNEE_PERSONNELLE` | Qui en a besoin, et pour quoi faire |
|---|---|---|---|---|
| `driver_id` | `D0000` | indirect : c'est un pseudonyme, qu'on peut ré-identifier avec la table des chauffeurs | `identifiant_interne` | tous les rôles métier, pour compter et faire des jointures sans nommer personne (contrat, section 4) |
| `first_name` | `Jean` | direct (avec le nom) | `nom` | la paie pour les bulletins, les responsables de dépôt pour appeler et planifier |
| `last_name` | `Dupont` | direct | `nom` | la paie, les responsables de dépôt |
| `email` | `jean.dupont0@post.example` | direct, car il contient le nom | `email` | la paie, pour envoyer les bulletins. Ni les responsables de dépôt ni l'analyste n'en ont besoin |
| `phone` | `+1 (917) 555-0000` | direct | `telephone` | la paie, et les responsables de dépôt pour joindre un chauffeur pendant un service |
| `birth_date` | `1980-01-01` | indirect : avec le dépôt et la date d'embauche, elle désigne presque toujours une seule personne | `date_naissance` | la paie pour les déclarations sociales. L'analyste n'a besoin que de l'année, pour la pyramide des âges |
| `tlc_license_number` | `5000000` | direct, car la TLC publie la liste des licences avec le nom du titulaire | `identifiant_officiel` | la paie, pour vérifier que le chauffeur a le droit de conduire |
| `depot` | `Queens` | indirect : dit où travaille la personne, sans l'identifier seul | non tagué (le contrat ne prévoit pas de valeur pour lui) | tout le monde, car c'est la clé du filtre par dépôt |
| `hire_date` | `2015-06-01` | indirect, car elle relève de la vie professionnelle | non tagué (le contrat ne prévoit pas de valeur pour lui) | la paie et l'analyste, pour l'ancienneté |
| `end_date` | vide ou `2023-12-31` | indirect : vie professionnelle, et c'est elle qui déclenche la purge (R1) | non tagué (le contrat ne prévoit pas de valeur pour lui) | la paie, et le pipeline pour la purge |
| `_source_file`, `_loaded_at` (colonnes techniques ajoutées au chargement) | `drivers.csv` | non | — | le pipeline, pour tracer le chargement |

### Les colonnes de `driver_shifts.csv`

| Colonne | Exemple de valeur | Donnée personnelle ? | Valeur du tag `DONNEE_PERSONNELLE` | Qui en a besoin, et pour quoi faire |
|---|---|---|---|---|
| `shift_id` | `S000000` | pas seule, mais `driver_id` la rattache à un chauffeur | — | le pipeline, pour retirer les doublons |
| `driver_id` | `D0000` | indirect | `identifiant_interne` | tout le monde, pour la jointure avec la dimension chauffeur |
| `shift_date` | `2025-01-15` | indirect, car elle décrit l'activité d'une personne identifiable | non tagué | la paie, les responsables de dépôt, l'analyste |
| `depot` | `Brooklyn` | indirect | non tagué | le filtre par dépôt |
| `start_hour` | `6` | indirect, car ce sont les horaires de travail d'une personne | non tagué | les responsables de dépôt, pour le planning |
| `hours_worked` | `8.5` | indirect : c'est du temps de travail, qui sert à la paie | non tagué | la paie, l'analyste |
| `trips_count` | `22` | indirect, car il mesure une performance individuelle | non tagué | l'analyste, les responsables de dépôt |
| `revenue_usd` | `650.00` | indirect : c'est une recette individuelle, qui sert à la paie | non tagué | la paie, l'analyste |
| `_source_file`, `_loaded_at` | `driver_shifts.csv` | non | — | le pipeline |

Les colonnes indirectes sans tag restent des données personnelles au sens du RGPD. Elles ne sont pas masquées, mais le filtre de lignes les protège, puisqu'un rôle ne voit que les chauffeurs de son dépôt. Le tag `DONNEE_PERSONNELLE`, qui déclenche le masquage, est réservé aux six natures de données listées dans le contrat.

### Où chaque donnée est copiée

| Colonne d'origine | Table ou vue | Colonne | Sous quelle forme |
|---|---|---|---|
| `first_name`, `last_name` | `STAGING.STG_RH__DRIVERS` | `first_name`, `last_name` | telles quelles |
| `first_name`, `last_name` | `MARTS.DIM_DRIVER` | `first_name`, `last_name` | telles quelles |
| `first_name`, `last_name` | `MARTS.MART_DRIVER_MONTHLY` | `driver_name` | colonne calculée, `first_name \|\| ' ' \|\| last_name`, qui porte donc le tag `nom` |
| `email` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `email` | en minuscules, sans espaces |
| `phone` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `phone` | une valeur vide devient `NULL` |
| `birth_date` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `birth_date` | telle quelle |
| `tlc_license_number` | `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `tlc_license_number` | telle quelle |
| `driver_id` | toutes les tables et vues du domaine RH | `driver_id` | tel quel |
| `hire_date`, `end_date` | `MARTS.DIM_DRIVER` | `hire_date`, `end_date`, `is_active`, `tenure_years` | telles quelles, plus deux colonnes calculées : en poste ou non, et ancienneté en années |
| `depot` | `STAGING.*`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY` | `depot` | normalisé avec `INITCAP(TRIM())` |
| activité (`hours_worked`, `trips_count`, `revenue_usd`) | `MARTS.MART_DRIVER_MONTHLY` | mêmes noms, et `nb_shifts` | agrégée par chauffeur et par mois. Elle reste personnelle, puisqu'elle est rattachée à `driver_id` et à `driver_name` |

### Comparaison avec la classification automatique de Snowflake (bonus 1)

Nous avons lancé `SYSTEM$CLASSIFY('NYC_TAXI.RAW.DRIVERS', {'auto_tag': false})` le 03/11/2026 avec le rôle `TRANSFORMER` ([`snowflake/rh/bonus_classification.sql`](../snowflake/rh/bonus_classification.sql)).

| Colonne | Notre inventaire (tag `DONNEE_PERSONNELLE`) | Snowflake (catégorie, confiance) | D'accord ? |
|---|---|---|---|
| `first_name`, `last_name` | direct, `nom` | IDENTIFIER / NAME, HIGH | oui |
| `email` | direct, `email` | IDENTIFIER / EMAIL, HIGH | oui |
| `phone` | direct, `telephone` | IDENTIFIER / PHONE_NUMBER, HIGH | oui |
| `birth_date` | indirect, `date_naissance` | QUASI_IDENTIFIER / DATE_OF_BIRTH, HIGH | oui |
| `tlc_license_number` | direct, `identifiant_officiel` | rien | **non** : un numéro à 7 chiffres ne ressemble à aucune catégorie connue. Seul le métier sait que la TLC le publie avec le nom du titulaire |
| `driver_id` | indirect, `identifiant_interne` | rien | **non** : on ne reconnaît un pseudonyme interne que si l'on connaît la table de correspondance |
| `depot`, `hire_date`, `end_date` | indirect, non tagué | rien | oui, aucun tag de part et d'autre |

L'outil retrouve les identifiants courants (nom, e-mail, téléphone, date de naissance), mais il manque les deux identifiants propres au métier. Il aide à faire l'inventaire, il ne le remplace pas. Lancée avec `ACCOUNTADMIN`, la même classification ne trouve rien, parce qu'elle n'échantillonne que des valeurs masquées. Cela confirme que le masquage par défaut fonctionne, et cela montre un piège : une classification doit se lancer avec le rôle propriétaire des données.

### Ce qui nous a surpris

- `MART_DRIVER_MONTHLY` est une table « d'activité », et pourtant elle recopie le nom en clair dans `driver_name`. Une colonne calculée à partir d'une donnée personnelle reste une donnée personnelle, et elle doit porter le tag.
- La date de naissance complète ne sert qu'à la paie, l'analyste n'a besoin que de l'année. Quant au numéro de licence, il est public à New York mais identifie directement le chauffeur.
- Le profilage avant chargement a révélé des erreurs dans le fichier : 9 dépôts mal écrits (`queens`, `BRONX `), 7 e-mails sans `@` (`… at post.example`), 12 téléphones vides, 4 numéros de licence partagés par deux chauffeurs, 5 fins de contrat antérieures à l'embauche et 1 embauche dans le futur. Côté services, 25 sont rattachés à des chauffeurs inconnus (`D9xxx`) et 18 identifiants de service sont en double.
- Sur 400 chauffeurs, 110 sont partis, dont 46 depuis plus de 5 ans au 03/11/2026. Ces 46 n'auraient plus dû figurer dans le fichier transmis.

---

## Partie 2. Fiche de registre (jour 3)

Cette fiche est une version réduite du registre des activités de traitement (RGPD, art. 30). Elle se limite à ce qu'un Data Engineer peut renseigner et prouver. La trame complète est sur le site de la CNIL : https://www.cnil.fr/fr/RGPD-le-registre-des-activites-de-traitement. Chaque réponse renvoie à la requête ou au fichier qui la prouve. Dernière mise à jour : 03/11/2026.

### Le traitement

| Rubrique | Réponse |
|---|---|
| Nom du traitement | Entrepôt du personnel des chauffeurs (domaine RH de l'entrepôt Snowflake `NYC_TAXI`) |
| Responsable du traitement | Hudson Cab Europe (Paris), qui décide depuis cette année de ce que deviennent ces données (RGPD art. 4.7, voir `VEILLE.md`, section 1). Le sous-traitant est Snowflake, qui héberge les données en région `AWS_EU_WEST_3` (Paris). |
| Finalités | 1. La paie des chauffeurs, sur deux bases légales : l'exécution du contrat de travail (art. 6.1 b) et les obligations légales (art. 6.1 c). 2. L'organisation des dépôts, c'est-à-dire joindre et planifier les chauffeurs de son dépôt (contrat de travail, art. 6.1 b). 3. Le pilotage de l'activité de la flotte par dépôt et par mois (intérêt légitime, art. 6.1 f, à faire valider par le DPO, voir `VEILLE.md`, section 5). |
| Personnes concernées | Les chauffeurs de taxi de Hudson Cab Partners, en poste ou partis depuis moins de 5 ans, soit 354 personnes au 03/11/2026 après la purge |
| Services responsables des données | Le service RH, qui fournit le fichier et rectifie les erreurs, et l'équipe data de Hudson Cab Europe, qui gère l'entrepôt et ses règles |

### Les données

| Catégorie de données | Colonnes concernées | Tables où elles se trouvent |
|---|---|---|
| Identité | `first_name`, `last_name`, `driver_name` (calculée), `birth_date`, `driver_id` | `RAW.DRIVERS`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY` (`driver_name`, `driver_id`), vue `STAGING.STG_RH__DRIVERS` |
| Coordonnées | `email`, `phone` | `RAW.DRIVERS`, `MARTS.DIM_DRIVER`, vue `STAGING.STG_RH__DRIVERS` |
| Identifiant officiel | `tlc_license_number` | `RAW.DRIVERS`, `MARTS.DIM_DRIVER` |
| Vie professionnelle | `depot`, `hire_date`, `end_date`, `is_active`, `tenure_years`, et pour l'activité `shift_date`, `start_hour`, `hours_worked`, `trips_count`, `revenue_usd` | `RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY` |

Pour le vérifier, `ANALYSTE` peut lancer `SELECT * FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE WHERE donnee_personnelle IS NOT NULL;`. Les fiches de catalogue sont dans `snowflake/rh/catalogue/`.

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| `RH_PAIE` | Tous les dépôts et toutes les colonnes en clair, mais pas `RAW` | Établir la paie et les déclarations, vérifier la licence | `05_tests_acces.sql`, tests 1, 8, V1, V5 |
| `RESP_DEPOT_QUEENS`, `RESP_DEPOT_BRONX` | Leur dépôt seulement. Nom, prénom et téléphone en clair, e-mail et licence remplacés par `*****`, date de naissance à `NULL` | Joindre et planifier leurs chauffeurs | tests 2, 3, 3b, 4, V2, V3, V6, L3, L4 |
| `ANALYSTE` | Tous les dépôts et tout `MARTS`. Identifiants directs remplacés par `*****`, année de naissance seulement, `driver_id` en clair | Analyser l'activité sans nommer personne | tests 5, 5b, 9, V4, V7, L1, L2 |
| `TRANSFORMER` (rôle des outils) | Tout, en clair | Charger, purger, contrôler et reconstruire les tables. Avec des valeurs masquées, il recopierait des masques | tests 7c, 10, 11b |
| `GOUVERNANCE` | Rien, il n'a aucun `SELECT`. Il écrit les règles | Séparer les pouvoirs | tests 6, 9d |
| `ACCOUNTADMIN`, `SYSADMIN` | Aucune ligne dans `MARTS`, et `RAW` avec les colonnes personnelles masquées | Administrer, pas lire | tests 7, 7b, 9 bis, 9c |

Le cahier complet et ses résultats sont dans `docs/ACCES.md`. Les 37 tests passent, y compris après une exécution des tâches planifiées.

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | Chaque jour à 6 h, la tâche `MARTS.T_PURGE` supprime (`DELETE`) les chauffeurs dont `end_date` est antérieure de plus de 5 ans à la date du jour, dans `RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER` et `MARTS.MART_DRIVER_MONTHLY`. Le 03/11/2026, elle a supprimé 46 chauffeurs (de 400 à 354) et aucun service. | `snowflake/rh/purge_rh.sql` (comptage avant et après), `taches_rh.sql`, `TASK_HISTORY` |
| R2 : pas de restauration au-delà de 1 jour | Les 4 tables de chauffeurs ont `DATA_RETENTION_TIME_IN_DAYS = 1`. Juste après la purge, `SELECT COUNT(*) FROM RAW.DRIVERS BEFORE (STATEMENT => <purge>)` renvoie 400, ce qui prouve que Time Travel relit les lignes supprimées. | `snowflake/rh/conservation_rh.sql` (`retention_time = 1`), `purge_rh.sql`, étape 4 |
| R3 : aucun fichier sur le stage | `COPY INTO … PURGE = TRUE`, suivi d'un `REMOVE @RH_STAGE`, parce qu'un fichier redéposé est ignoré par `COPY` et ne serait pas purgé | `LIST @NYC_TAXI.RAW.RH_STAGE;` ne renvoie aucun fichier (`conservation_rh.sql`, étape 3) |

Une fois la purge exécutée, une donnée met **8 jours** à disparaître définitivement de Snowflake. Pendant 1 jour, Time Travel permet encore au propriétaire de la table de la relire avec `AT` ou `BEFORE`. Viennent ensuite 7 jours de Fail-safe : la donnée n'est plus lisible, seul le support de Snowflake peut la récupérer, et cette durée n'est pas réductible sur une table permanente. Comme la tâche ne tourne qu'une fois par jour, il faut ajouter jusqu'à 24 h d'attente, soit jusqu'à 9 jours après le 5e anniversaire de la fin du contrat.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | Oui. Sur 7 jours, on retrouve l'utilisateur, le rôle, la table, les colonnes lues et la requête, avec jusqu'à 3 h de retard. Au 03/11/2026, des colonnes personnelles ont été lues par `TRANSFORMER` (y compris l'utilisateur `SYSTEM` des tâches), `RH_PAIE`, `ANALYSTE`, `RESP_DEPOT_QUEENS`, `ACCOUNTADMIN` (sur `RAW`, où il ne voit que des valeurs masquées) et le rôle de démonstration `RESP_DEPOT_BROOKLYN`. Lire une colonne ne veut pas dire la voir en clair, puisque le masquage s'applique à la lecture. | `snowflake/gouvernance/06_audit.sql` (`ACCESS_HISTORY` joint à `QUERY_HISTORY`), capture dans `docs/captures/` |
| Sait-on quand une donnée est fausse ? | Oui. La tâche `T_QUALITE` mesure 8 règles chaque jour sur `RAW` et écrit une ligne par règle et par exécution dans `QUALITE_RESULTATS`. Au 03/11/2026, 2 règles sont `OK` et 6 en `ALERTE` : licences en double, e-mails invalides, dates incohérentes, dépôts mal écrits, services en double et services trop longs. La règle bloquante `service_rattache` compte 25 orphelins pour un seuil de 50. Si elle dépasse son seuil, `MARTS` n'est pas reconstruit. Nous l'avons prouvé en abaissant le seuil à 10 : `T_QUALITE` a échoué et `T_TABLES` n'est pas partie. | `SELECT * FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS ORDER BY mesure_le DESC;`, `GOUVERNANCE.QUALITE_REGLES` (énoncé, seuil, gravité), `TASK_HISTORY` |
| Que se passe-t-il si le rôle des outils est compromis ? | Il lit tout en clair, parce que le pipeline en a besoin, et il peut retirer un tag de ses tables, donc démasquer une colonne. En revanche, il ne peut ni modifier les politiques, qui appartiennent à `GOUVERNANCE`, ni changer `ACCES_DEPOT`. On le détecte avec le test n° 12 du cahier et en auditant les `UNSET TAG` ainsi que les lectures de `SYSTEM` en dehors de 6 h. Pour réagir, on retire `TRANSFORMER` à l'utilisateur concerné et on rejoue le catalogue depuis Git. | `docs/ACCES.md`, partie 1 (« Ce que cette carte permet à un rôle de défaire ») |

### Limites connues

- Les chauffeurs partis depuis moins de 5 ans restent dans la base active, et les responsables de dépôt comme l'analyste les voient au même titre que les chauffeurs en poste. La CNIL recommande un archivage intermédiaire à accès restreint. C'est l'écart principal, décrit dans le `README.md`.
- L'analyste ne voit aucun identifiant direct. Mais pour un chauffeur au profil rare, `driver_id`, le dépôt, la date d'embauche et l'année de naissance suffisent parfois à le reconnaître. Les données de l'analyste sont pseudonymisées, pas anonymes.
- `ACCESS_HISTORY` peut avoir jusqu'à 3 h de retard. Les fichiers RH déposés sur le poste de l'utilisateur (dossier `data/`, hors Git) échappent à l'entrepôt et doivent être supprimés après chargement.
