# hudson-cab-gouvernance

Gouvernance de l'entrepôt Snowflake du domaine **personnel** de Hudson Cab Partners :
catalogue, contrôle des accès, conservation et qualité des données des chauffeurs.

> Question directrice : **qui peut voir quelle donnée, pendant combien de temps, et peut-on s'y fier ?**

## Arborescence
```
CONTRAT_GOUVERNANCE.md      règles imposées (référence, non modifiée)
GUIDE_BRIEF_GOUVERNANCE.md  guide étape par étape
data/                       fichiers RH — NON versionnés (.gitignore)
exemples/                   exemples commentés du kit (bac à sable)
snowflake/
  00_installation.sql
  gouvernance/              rôle de gouvernance, tags, rôles métier, masquage, accès par dépôt,
                            cahier de tests exécutable, référentiel qualité, audit
  rh/                       chargement, staging, marts (SQL de Priya), catalogue/, controles/,
                            purge, conservation, tâches planifiées
docs/                       VEILLE.md, REGISTRE.md, ACCES.md, captures/
```

## Gouvernance

### Ce qui est protégé et comment

| Question | Réponse | Où |
|---|---|---|
| **Qui voit quoi ?** | 4 rôles métier (`RH_PAIE`, `RESP_DEPOT_QUEENS`, `RESP_DEPOT_BRONX`, `ANALYSTE`) lisent `MARTS` seulement. Deux politiques de masquage (`MASK_TEXTE`, `MASK_DATE`) attachées **au tag** `DONNEE_PERSONNELLE` protègent toute colonne taguée, `RAW` comme `MARTS`, `driver_name` compris. Une politique d'accès par ligne (`RAP_DEPOT`) filtre `DIM_DRIVER` et `MART_DRIVER_MONTHLY` par dépôt selon la table de correspondance `GOUVERNANCE.ACCES_DEPOT`. Masquage **par défaut** : tout rôle absent de la matrice (`ACCOUNTADMIN`, `SYSADMIN`, `GOUVERNANCE`) ne voit aucune valeur personnelle et aucune ligne de `MARTS`. | `snowflake/gouvernance/02` à `04` ; cahier : `docs/ACCES.md` (37 / 37 verts) |
| **Pendant combien de temps ?** | R1 : purge quotidienne des chauffeurs partis depuis plus de 5 ans, dans les 4 tables (46 supprimés le 03/11/2026). R2 : Time Travel limité à 1 jour (+ 7 jours de Fail-safe). R3 : stage vidé après chaque chargement. | `snowflake/rh/purge_rh.sql`, `conservation_rh.sql`, `taches_rh.sql` |
| **Peut-on s'y fier ?** | 8 règles de qualité mesurées chaque jour sur `RAW`, enregistrées dans `QUALITE_RESULTATS` ; la règle bloquante `service_rattache` empêche la reconstruction de `MARTS`. Un catalogue (descriptions + tags) lisible par tous les rôles métier dans `V_CATALOGUE`. Une requête d'audit dit qui a lu quelles colonnes personnelles, avec quel rôle. | `snowflake/rh/controles/`, `gouvernance/regles_qualite.sql`, `rh/catalogue/`, `gouvernance/06_audit.sql` |

Séparation des pouvoirs : `GOUVERNANCE` écrit les règles mais n'a aucun `SELECT` sur les données ; `TRANSFORMER` (rôle des outils) lit tout pour faire tourner le pipeline mais ne possède ni les politiques ni la table de correspondance ; les rôles métier ne possèdent rien.

### Données du personnel hors du dépôt
Les fichiers `data/*.csv` sont exclus par `.gitignore` : un dépôt public est lisible par tous, un fichier du personnel — même fictif — se traite comme un vrai (minimisation, art. 5 RGPD), et un fichier poussé une fois reste dans l'historique Git. Les docs et le cahier de tests ne recopient aucune valeur du fichier (exemples inventés, tests qui renvoient « clair / masqué »). Aucun secret : la connexion Snowflake (clé privée) reste hors du dépôt.

### Ordre d'exécution des scripts

Chaque script commence par son `USE ROLE` et se termine par une requête de vérification. Tous sont rejouables.

| # | Script | Rôle | Contrôle |
|---|---|---|---|
| 1 | `snowflake/00_installation.sql` | ACCOUNTADMIN | schémas RAW, STAGING, MARTS |
| 2 | `snowflake/rh/chargement_rh_1_preparer.sql` | TRANSFORMER | stage `RH_STAGE` créé |
| 3 | Dépôt des 2 CSV sur `RH_STAGE` (Snowsight, ou `PUT 'file://…/data/drivers.csv' @NYC_TAXI.RAW.RH_STAGE AUTO_COMPRESS = FALSE`) | TRANSFORMER | `LIST` : 2 fichiers |
| 4 | `snowflake/rh/chargement_rh_2_copier.sql` | TRANSFORMER | 400 / 25 951 lignes, stage vide |
| 5 | `snowflake/rh/00_tables_rh.sql` | TRANSFORMER | 3 tables dans MARTS |
| 6 | `snowflake/rh/staging/stg_rh__drivers.sql`, `stg_rh__driver_shifts.sql` | TRANSFORMER | 25 933 services |
| 7 | `snowflake/rh/marts/dim_depot.sql`, `dim_driver.sql`, `mart_driver_monthly.sql` | TRANSFORMER | 3 / 400 / 914 lignes |
| 8 | `snowflake/gouvernance/01_gouvernance.sql` | ACCOUNTADMIN puis GOUVERNANCE | 3 tags, `QUALITE_RESULTATS` |
| 9 | `snowflake/gouvernance/modele_catalogue_dim_depot.sql`, puis `snowflake/rh/catalogue/catalogue_*.sql` (4 fiches) | TRANSFORMER | aucune colonne sans description |
| 10 | `snowflake/gouvernance/02_roles_metier.sql` | ACCOUNTADMIN | 4 rôles métier |
| 11 | `snowflake/gouvernance/03_masquage.sql` | GOUVERNANCE | 2 politiques sur le tag |
| 12 | `snowflake/gouvernance/04_acces_depot.sql` | GOUVERNANCE | `ACCES_DEPOT`, `RAP_DEPOT` sur 2 tables |
| 13 | `snowflake/gouvernance/05_tests_acces.sql` (un test à la fois, avec le rôle indiqué) | chaque rôle | 37 / 37 verts |
| 14 | `snowflake/gouvernance/regles_qualite.sql` | GOUVERNANCE | 8 règles, 1 bloquante |
| 15 | `snowflake/rh/conservation_rh.sql` | TRANSFORMER | `retention_time = 1` |
| 16 | `snowflake/rh/purge_rh.sql` | TRANSFORMER | 46 supprimés ; Time Travel relit 400 |
| 17 | `snowflake/rh/controles/*.sql` | TRANSFORMER | 1 nombre par règle |
| 18 | `snowflake/rh/catalogue/v_catalogue.sql` | TRANSFORMER | `ANALYSTE` lit les 3 tables |
| 19 | `snowflake/rh/taches_rh.sql` | TRANSFORMER | 3 tâches en `SUCCEEDED` |
| 20 | `snowflake/gouvernance/06_audit.sql` | ACCOUNTADMIN | rôles ayant lu les colonnes personnelles |
| — | `snowflake/gouvernance/demo_ajout_depot.sql` (démonstration, bloc par bloc) | ACCOUNTADMIN, GOUVERNANCE | Brooklyn ouvert sans toucher aux politiques |

À la fin du brief : `ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;` (une tâche active consomme des crédits chaque jour).

### Chargement : format de fichier, stage, COPY INTO, PURGE

- **Format de fichier** (`RAW.CSV_RH`) : dit à Snowflake comment lire le CSV — séparateur, une ligne d'en-tête à sauter, guillemets optionnels, espaces conservés (`TRIM_SPACE = FALSE` : `RAW` est une copie fidèle, `BRONX ` compris).
- **Stage** (`RAW.RH_STAGE`) : un espace de dépôt interne, chiffré côté serveur, où l'on pose les fichiers avant de les copier dans une table.
- **`COPY INTO`** : lit les fichiers du stage avec le format, type les colonnes (`$6::date`…), ajoute le nom du fichier et l'heure de chargement (`METADATA$FILENAME`, `METADATA$START_SCAN_TIME`), et s'arrête à la première erreur (`ON_ERROR = ABORT_STATEMENT`). Il se souvient des fichiers déjà chargés : relancé, il ne charge rien deux fois (vérifié : `LOAD_SKIPPED`, « File was loaded before »).
- **`PURGE = TRUE`** : retire du stage chaque fichier chargé (règle R3). **Ajout** : un fichier redéposé est ignoré par `COPY` et donc **pas** purgé ; un `REMOVE @RH_STAGE` final vide le stage dans tous les cas.

### Choix techniques

| Choix | Pourquoi |
|---|---|
| **Masquer plutôt que supprimer** les colonnes personnelles de `DIM_DRIVER` et `MART_DRIVER_MONTHLY` | Une même table sert quatre rôles : la paie a besoin de l'e-mail, de la licence et de la date de naissance ; les supprimer les retirerait à la paie. Le masquage donne à chacun sa vue de la même table. Alternative écartée : une vue par rôle (multiplie les objets à gouverner). `driver_name` est gardé (utile aux responsables de dépôt) mais tagué `nom`, donc masqué pour l'analyste. |
| **Masquage attaché au tag**, pas aux colonnes | Une colonne taguée demain est protégée sans toucher aux politiques ; le catalogue et la protection ne peuvent pas diverger. Exception codée dans la politique : `identifiant_interne` (`driver_id`) visible de tous. |
| Une politique **par type** (`MASK_TEXTE`, `MASK_DATE`) | Une politique renvoie le type qu'elle reçoit : la date masquée est `NULL`, la date de l'analyste le 1er janvier de l'année de naissance (reste une date). |
| Masque `'*****'`, mais **`NULL` reste `NULL`** | Un masque ne doit pas faire croire qu'un téléphone existe. |
| Responsables de dépôt reconnus par **convention de nom** `RESP_DEPOT_*` dans `MASK_TEXTE` | Ouvrir un dépôt = créer `RESP_DEPOT_<DÉPÔT>` + une ligne dans `ACCES_DEPOT`, sans modifier aucune politique (démontré : `demo_ajout_depot.sql`). La création d'un rôle reste réservée à `ACCOUNTADMIN`. |
| `'*'` dans `ACCES_DEPOT` = tous les dépôts ; `TRANSFORMER` y figure | Sans cette ligne, le pipeline ne verrait aucune ligne de `DIM_DRIVER` et `MART_DRIVER_MONTHLY` se reconstruirait avec `driver_name` vide, sans erreur. |
| Politiques basées sur `CURRENT_ROLE()` | Le rôle principal seulement : les rôles secondaires n'élargissent rien (test L3). Conséquence : `ACCOUNTADMIN` a le droit de lire (héritage `SYSADMIN` → `TRANSFORMER`) mais ne voit **aucune ligne** de `MARTS` et des valeurs masquées dans `RAW`. |
| **R1 appliquée aussi aux services** (`RAW.DRIVER_SHIFTS`) | Les heures et recettes d'un chauffeur sont ses données (R1 : « partout où la donnée a été copiée »). Sans cela, ses services deviendraient des orphelins qui feraient monter la règle bloquante `service_rattache`. |
| **La purge supprime aussi dans `MARTS`** | `T_TABLES` ne part pas si la qualité échoue : sans purge directe, une alerte bloquante prolongerait la conservation dans `MARTS`. |
| Seuils et gravités dans **`GOUVERNANCE.QUALITE_REGLES`** | Les règles sont documentées (énoncé, seuil, gravité) là où la tâche les lit ; abaisser un seuil = un `UPDATE` par `GOUVERNANCE`, sans réécrire la tâche ni la suspendre (blocage prouvé ainsi). |
| Mesure enregistrée **avant** l'erreur bloquante | La trace reste même quand la chaîne s'arrête. |
| Noms d'utilisateur entre guillemets (`SET moi = '"' || CURRENT_USER() || '"'`) | Un nom avec des points (`prenom.nom`) est lu par `IDENTIFIER()` comme `base.schéma.objet` : correctif apporté à `00_installation.sql`. |

### Lignage

`data/drivers.csv` → `RH_STAGE` → `RAW.DRIVERS` → vue `STAGING.STG_RH__DRIVERS` (e-mail en minuscules, dépôt normalisé) → `MARTS.DIM_DRIVER` (+ `is_active`, `tenure_years`) → `MARTS.MART_DRIVER_MONTHLY` (`driver_name` = prénom + nom).
`data/driver_shifts.csv` → `RH_STAGE` → `RAW.DRIVER_SHIFTS` → vue `STAGING.STG_RH__DRIVER_SHIFTS` (doublons retirés : 25 951 → 25 933) → `MARTS.MART_DRIVER_MONTHLY` (agrégé par chauffeur, mois, dépôt).
Capture de l'onglet *Lineage* de `MART_DRIVER_MONTHLY` : `docs/captures/`.

### Écarts entre le contrat et les textes
Analyse complète : [`docs/VEILLE.md`](docs/VEILLE.md), section 4. Le RGPD s'applique (art. 3.1 : traitement dans le cadre des activités de Hudson Cab Europe, établie à Paris) ; responsable du traitement : Hudson Cab Europe ; sous-traitant : Snowflake (région Paris) ; autorité : CNIL. Nous signalons, nous ne réécrivons pas le contrat :

| # | Règle du contrat | Écart | Proposition |
|---|---|---|---|
| 1 | Préambule | Rédigé avant le transfert : ni RGPD, ni responsable du traitement, ni finalité, ni base légale (art. 4.7, 6, 30). | Validation du contrat par Hudson Cab Europe et son DPO ; finalités et bases légales proposées dans la note. |
| 2 | **R1 — 5 ans après la fin du contrat** | **Écart principal.** Pendant 5 ans, un chauffeur parti reste en base active, visible comme un chauffeur en poste (64 chauffeurs partis encore présents après la purge) ; la CNIL demande un archivage intermédiaire à accès restreint après le départ. La durée de 5 ans vient du droit du travail français ; New York impose 6 ans pour les relevés de paie. | Sortir les chauffeurs partis de la vue des responsables de dépôt et de l'analyste (filtre `is_active` dans la politique de lignes, ou table d'archive lisible par `RH_PAIE` seule) ; faire trancher la durée par le juriste. |
| 3 | R2 — Time Travel 1 jour | Fail-safe : 7 jours de plus, non réductibles sur une table permanente : suppression effective à 8 jours. | Documenté dans le registre (alternative : tables `TRANSIENT`, sans Fail-safe). |
| 4 | Matrice des accès | Aucun responsable pour le dépôt de Brooklyn ; `RH_PAIE` voit date de naissance et licence sans besoin démontré ; les accès depuis New York sont des transferts hors UE. | Signaler ; la table de correspondance permet d'ajouter `RESP_DEPOT_BROOKLYN` sans toucher aux politiques. |
| 5 | Règles de qualité | Mesurées, mais personne n'est chargé de rectifier (art. 5.1 d, 16) : 6 règles sur 8 en `ALERTE` au premier passage. | Désigner le service RH destinataire des alertes (bonus : `CREATE ALERT`). |
| 6 | Absent du contrat | Information des chauffeurs, droits d'accès et d'effacement, transferts. | Compléter via le registre (`docs/REGISTRE.md`). |

### Limites connues

- **Ré-identification indirecte** : l'analyste ne voit aucun identifiant direct, mais `driver_id` + dépôt + date d'embauche + année de naissance peuvent désigner un chauffeur rare. Ses données sont pseudonymisées, pas anonymes (piste : politique d'agrégation, bonus 3).
- **Rôle des outils** : `TRANSFORMER` voit tout et peut retirer un tag de ses tables (donc démasquer une colonne). Mitigé par le catalogue rejoué depuis Git, le test n° 12 et l'audit ; non empêché.
- **Convention `RESP_DEPOT_*`** : un rôle nommé ainsi verrait noms et téléphones (de son dépôt seulement, et seulement s'il a une ligne dans `ACCES_DEPOT`). La création de rôles est réservée à `ACCOUNTADMIN`.
- **Chauffeurs partis** encore en base active jusqu'à 5 ans (écart n° 2), et purge quotidienne : jusqu'à 9 jours entre le 5e anniversaire et la disparition définitive (tâche + Time Travel + Fail-safe).
- **Audit** : `ACCESS_HISTORY` dit qu'une colonne a été lue, pas si elle a été vue en clair ; latence jusqu'à 3 h.
- **Seuil `telephone_renseigne`** : 5 % des chauffeurs en poste, arrondi à 2 décimales (14,50 lignes au 03/11/2026).
