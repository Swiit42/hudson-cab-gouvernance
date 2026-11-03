# Les accès — carte des droits et cahier de tests

- **Partie 1** : la carte des droits, complétée au fur et à mesure de la création des rôles et des objets ;
- **Partie 2** : le cahier de tests, « attendu » écrit avant les politiques, « obtenu » après.

---

## Partie 1 — Carte des droits

Dans Snowflake, faire une action demande d'être propriétaire de l'objet ou d'avoir reçu un privilège précis. Chaque ligne a été vérifiée avec `SHOW GRANTS TO ROLE …`.

### Qui possède quoi

Le propriétaire d'un objet est le rôle qui l'a créé.

| Objet | Propriétaire |
|---|---|
| Tables de `RAW` et de `MARTS`, vues de `STAGING`, stage, format de fichier | le rôle des outils (`TRANSFORMER`) |
| Schémas `RAW`, `STAGING`, `MARTS` | `ACCOUNTADMIN` (créés par `00_installation.sql`) |
| Schéma `GOUVERNANCE` | `GOUVERNANCE` (créé par `ACCOUNTADMIN`, propriété transférée dans `01_gouvernance.sql`) |
| Tags | `GOUVERNANCE` |
| Politiques de masquage (`MASK_TEXTE`, `MASK_DATE`) | `GOUVERNANCE` |
| Politique d'accès par ligne (`RAP_DEPOT`) | `GOUVERNANCE` |
| Table `ACCES_DEPOT` | `GOUVERNANCE` |
| Table `QUALITE_RESULTATS` | `GOUVERNANCE` |
| Vue `V_CATALOGUE` | `TRANSFORMER` (seul rôle qui voit les tables de `MARTS` et a `CREATE VIEW` sur le schéma) |

### Qui fait quoi, avec quel droit

| Action | Rôle qui la fait | Privilège nécessaire | Accordé par (script) |
|---|---|---|---|
| Créer un tag | `GOUVERNANCE` | propriétaire du schéma `GOUVERNANCE` | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Trouver les tables à protéger, sans les lire | `GOUVERNANCE` | `USAGE` sur la base, les schémas `RAW` et `MARTS` et le warehouse ; **aucun** `SELECT` | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Poser un tag sur une colonne de `DIM_DRIVER` | `TRANSFORMER` | propriétaire de la table + `APPLY` sur le tag + `USAGE` sur le schéma `GOUVERNANCE` | `GOUVERNANCE` (`01_gouvernance.sql`) |
| Créer une politique de masquage | `GOUVERNANCE` | propriétaire du schéma `GOUVERNANCE` | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Attacher une politique de masquage à un tag | `GOUVERNANCE` | `APPLY MASKING POLICY` sur le compte (et propriétaire du tag) | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Ajouter une politique d'accès par ligne à une table | `GOUVERNANCE` | `APPLY ROW ACCESS POLICY` sur le compte | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Lire `ACCES_DEPOT` pendant l'évaluation de `RAP_DEPOT` | (la politique) | droits du **propriétaire** de la politique (`GOUVERNANCE`) : les rôles métier n'ont aucun droit sur la table | — |
| Écrire une ligne dans `QUALITE_RESULTATS` | `TRANSFORMER` (tâche `T_QUALITE`) | `INSERT` (et `SELECT`) sur la table ; ni `UPDATE` ni `DELETE` | `GOUVERNANCE` (`01_gouvernance.sql`) |
| Créer la vue `V_CATALOGUE` | `TRANSFORMER` | `CREATE VIEW` sur le schéma `GOUVERNANCE` | `GOUVERNANCE` (`01_gouvernance.sql`) |
| Lire `DIM_DRIVER`, `MART_DRIVER_MONTHLY`, `DIM_DEPOT` | `RH_PAIE`, `RESP_DEPOT_QUEENS`, `RESP_DEPOT_BRONX` | `USAGE` base + schéma `MARTS`, `SELECT` sur chaque table | `ACCOUNTADMIN` (`02_roles_metier.sql`) |
| Lire tout `MARTS`, y compris les tables futures | `ANALYSTE` | `SELECT ON ALL TABLES` + `ON FUTURE TABLES IN SCHEMA MARTS` | `ACCOUNTADMIN` (`02_roles_metier.sql`) |
| Lire la vue du catalogue | chaque rôle métier | `USAGE` sur le schéma `GOUVERNANCE` + `SELECT ON FUTURE VIEWS` | `ACCOUNTADMIN` (`02_roles_metier.sql`) |
| Exécuter une requête | chaque rôle | `USAGE` sur le warehouse `NYC_TAXI_WH` | `ACCOUNTADMIN` (`00_installation.sql`, `01_gouvernance.sql`, `02_roles_metier.sql`) |
| Faire tourner les tâches planifiées | `TRANSFORMER` | `EXECUTE TASK` sur le compte, `CREATE TASK` sur `MARTS` | `ACCOUNTADMIN` (`00_installation.sql`) |

Hiérarchie : `ACCOUNTADMIN` → `SYSADMIN` → `TRANSFORMER` (installation). `GOUVERNANCE` et les quatre rôles métier ne sont rattachés à aucun rôle : chacun ne fait que son métier.

### Ce que cette carte permet à un rôle de défaire

| Rôle | Ce qu'il pourrait défaire | Acceptable ? Qui surveille ? |
|---|---|---|
| `TRANSFORMER` | Propriétaire des tables et titulaire de `APPLY` sur les trois tags : il peut **retirer le tag `DONNEE_PERSONNELLE`** d'une colonne (`UNSET TAG`) et la démasquer pour tous, ou recréer une table (`CREATE OR REPLACE`) et perdre tags et filtre de lignes. Il voit déjà tout en clair. | Risque principal, assumé : c'est le rôle des outils, pas un humain. Mitigation : catalogue rejoué depuis des fichiers versionnés, test n° 12 du cahier après chaque exécution des tâches, audit des `ALTER TABLE ... UNSET TAG` dans `QUERY_HISTORY`. |
| `GOUVERNANCE` | Propriétaire des politiques, des tags et de `ACCES_DEPOT` : il peut changer le corps d'une politique ou s'ajouter `('GOUVERNANCE', '*')` dans `ACCES_DEPOT`. Mais il n'a **aucun `SELECT`** sur les tables : il ne lit rien lui-même. | Acceptable : séparation des pouvoirs (celui qui écrit les règles ne lit pas les données, celui qui lit ne change pas les règles). Toute modification passe par un fichier SQL versionné et relu. |
| `ACCOUNTADMIN` | Peut tout s'attribuer (`GRANT ROLE GOUVERNANCE`, puis modifier une politique). | Inévitable dans Snowflake ; à réserver à deux personnes, avec MFA, et à auditer (`QUERY_HISTORY` filtré sur `role_name = 'ACCOUNTADMIN'`). |
| Rôles métier | Rien : ni propriétaires, ni `APPLY`. | Oui. |

---

## Partie 2 — Cahier de tests

Le cahier est exécutable : [`snowflake/gouvernance/05_tests_acces.sql`](../snowflake/gouvernance/05_tests_acces.sql), une annotation `-- @test n | rôle | attendu` par test. La colonne « attendu » a été écrite **avant** les politiques, à partir de la matrice du contrat.

**Valeur masquée** : `'*****'` pour un texte ; `NULL` pour une date (une politique renvoie le type qu'elle reçoit) ; pour l'analyste, la date de naissance devient le 1er janvier de l'année de naissance. Une valeur absente (téléphone vide) reste `NULL`. Les tests de valeurs renvoient une catégorie (clair / masqué / NULL / année) et non la valeur : aucune donnée du fichier RH n'est recopiée ici.

Avant chaque test : `USE SECONDARY ROLES NONE; USE ROLE <rôle>; USE WAREHOUSE NYC_TAXI_WH;`

**Exécutions** (03/11/2026) :

| Moment | Résultat |
|---|---|
| Rôles métier créés, **avant** les politiques | 19 / 37 verts (le cahier échoue là où il doit échouer) |
| Après `03_masquage.sql` et `04_acces_depot.sql` | **37 / 37 verts** |
| Après une seconde exécution de 02, 03, 04 (rejouables), puis relance des SQL de `staging/` et `marts/` | **37 / 37 verts** |

### Lignes visibles

| N° | Rôle | Requête | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| 1 | `RH_PAIE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | 400 | 400 | oui |
| 2 | `RESP_DEPOT_QUEENS` | la même | 161 | 161 | oui |
| 3 | `RESP_DEPOT_QUEENS` | `SELECT DISTINCT depot FROM NYC_TAXI.MARTS.DIM_DRIVER` | Queens | Queens | oui |
| 3b | `RESP_DEPOT_BRONX` | `SELECT depot, COUNT(*) … GROUP BY depot` | Bronx, 122 | Bronx, 122 | oui |
| 4 | `RESP_DEPOT_BRONX` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY` | 290 | 290 | oui |
| 4b | `RESP_DEPOT_QUEENS` | la même | 365 | 365 | oui |
| 5 | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | 400 | 400 | oui |
| 5b | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY` | 914 | 914 | oui |
| 6 | `GOUVERNANCE` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER` | refusé | refusé | oui |
| 7 | `ACCOUNTADMIN` | la même | 0 | 0 | oui |
| 7b | `SYSADMIN` | la même | 0 | 0 | oui |
| 7c | `TRANSFORMER` | la même | 400 | 400 | oui |
| 8 | `RH_PAIE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS` | refusé | refusé | oui |
| 9 | `ANALYSTE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS` | refusé | refusé | oui |
| 9 bis | `ACCOUNTADMIN` | `SELECT COUNT(*), COUNT_IF(first_name = '*****' AND email = '*****') FROM NYC_TAXI.RAW.DRIVERS` | 400, 400 | 400, 400 | oui |
| 9c | `ACCOUNTADMIN` | la même sur la vue `STAGING.STG_RH__DRIVERS` (nom, date de naissance) | 400, 400 | 400, 400 | oui |
| 9d | `GOUVERNANCE` | `SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS` | refusé | refusé | oui |
| 9e | `RESP_DEPOT_BRONX` | `SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT` | 3 | 3 | oui |
| 9f | `ANALYSTE` | la même | 3 | 3 | oui |

**`ACCOUNTADMIN` : refusé ou aucune ligne ?** Aucune ligne. `ACCOUNTADMIN` hérite de `SYSADMIN`, qui hérite de `TRANSFORMER` (installation) : il a donc le droit `SELECT` sur les tables. Mais la politique de lignes ne regarde que `CURRENT_ROLE()`, pas la puissance du rôle : `ACCOUNTADMIN` n'est pas dans `ACCES_DEPOT`, donc 0 ligne dans `MARTS`. Dans `RAW` (sans filtre de lignes, contrat section 4), il voit les 400 lignes, toutes colonnes personnelles masquées. `GOUVERNANCE`, lui, n'a aucun `SELECT` : refusé.

### Valeurs visibles

Pour le chauffeur `D0003` (dépôt de Queens) :

| Colonne | `RH_PAIE` | `RESP_DEPOT_QUEENS` | `RESP_DEPOT_BRONX` | `ANALYSTE` |
|---|---|---|---|---|
| `driver_id` | clair | clair | ligne invisible | clair |
| nom et prénom | clair | clair | ligne invisible | `*****` |
| e-mail | clair | `*****` | ligne invisible | `*****` |
| téléphone | clair | clair | ligne invisible | `*****` |
| date de naissance | complète | `NULL` | ligne invisible | 1er janvier de l'année |
| numéro de licence | clair | `*****` | ligne invisible | `*****` |
| `driver_name` dans `MART_DRIVER_MONTHLY` (3 mois) | clair (3/3) | clair (3/3) | ligne invisible | `*****` (0/3 en clair) |

Tests V1 à V7 du fichier : 7 / 7 verts, obtenu identique à l'attendu.

### Cas limites

| N° | Rôle | Ce qu'on vérifie | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| L1 | `ANALYSTE` | `WHERE email LIKE '%@%'` : le masque s'applique avant le filtre | 0 | 0 | oui |
| L2 | `ANALYSTE` | `WHERE last_name <> '*****'` : pas de nom devinable par filtre | 0 | 0 | oui |
| L3 | `RESP_DEPOT_QUEENS` + `USE SECONDARY ROLES ALL` | les rôles secondaires n'élargissent ni les lignes ni les valeurs | 161, 0 | 161, 0 | oui |
| L4 | `RESP_DEPOT_BRONX` | `WHERE depot = 'Queens'` sur `MART_DRIVER_MONTHLY` | 0 | 0 | oui |
| L5 | `RESP_DEPOT_BRONX` | lire `GOUVERNANCE.ACCES_DEPOT` | refusé | refusé | oui |
| L6 | `RH_PAIE` | chauffeurs de Brooklyn (aucun responsable) | 117 | 117 | oui |
| L7 | `RH_PAIE` | téléphones vides restés `NULL` | 12 | 12 | oui |

**Ajouter un dépôt sans toucher aux politiques** ([`demo_ajout_depot.sql`](../snowflake/gouvernance/demo_ajout_depot.sql)) : `RESP_DEPOT_BROOKLYN` créé avec ses droits de lecture → 0 ligne ; une ligne `('RESP_DEPOT_BROOKLYN', 'Brooklyn')` dans `ACCES_DEPOT` → Brooklyn, 117 chauffeurs, 117 noms en clair, 0 e-mail en clair. Aucune politique modifiée ; l'état du contrat est rétabli à la fin du script.

### Le pipeline fonctionne toujours

| N° | Vérification | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|
| 10 | Avec le rôle des outils, après relance des fichiers SQL : lignes de `DIM_DRIVER`, de `MART_DRIVER_MONTHLY` | 400, 914 | 400, 914 | oui |
| 11 | Avec `RH_PAIE` : l'e-mail de `D0003` est toujours une vraie adresse | clair | clair | oui |
| 11b | `driver_name` vide seulement pour les services orphelins (chauffeurs inconnus) | 25 | 25 | oui |
| 12 | Les politiques sont toujours attachées à `DIM_DRIVER` après la relance | MASK_DATE, MASK_TEXTE, RAP_DEPOT | MASK_DATE, MASK_TEXTE, RAP_DEPOT | oui |
