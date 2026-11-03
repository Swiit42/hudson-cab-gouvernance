# Les accès : carte des droits et cahier de tests

Ce document a deux parties. La carte des droits a été complétée au fur et à mesure que nous créions les rôles et les objets. Dans le cahier de tests, la colonne « attendu » a été écrite avant les politiques, et la colonne « obtenu » remplie après.

---

## Partie 1. Carte des droits

Dans Snowflake, pour faire une action, il faut être propriétaire de l'objet ou avoir reçu un privilège précis. Nous avons vérifié chaque ligne avec `SHOW GRANTS TO ROLE …`.

### Qui possède quoi

Le propriétaire d'un objet est le rôle qui l'a créé.

| Objet | Propriétaire |
|---|---|
| Tables de `RAW` et de `MARTS`, vues de `STAGING`, stage, format de fichier | le rôle des outils (`TRANSFORMER`) |
| Schémas `RAW`, `STAGING`, `MARTS` | `ACCOUNTADMIN` (créés par `00_installation.sql`) |
| Schéma `GOUVERNANCE` | `GOUVERNANCE` (créé par `ACCOUNTADMIN`, qui lui en transfère la propriété dans `01_gouvernance.sql`) |
| Tags | `GOUVERNANCE` |
| Politiques de masquage (`MASK_TEXTE`, `MASK_DATE`) | `GOUVERNANCE` |
| Politique d'accès par ligne (`RAP_DEPOT`) | `GOUVERNANCE` |
| Table `ACCES_DEPOT` | `GOUVERNANCE` |
| Table `QUALITE_RESULTATS` | `GOUVERNANCE` |
| Vue `V_CATALOGUE` | `TRANSFORMER`, seul rôle qui voit les tables de `MARTS` et qui a `CREATE VIEW` sur le schéma |

### Qui fait quoi, avec quel droit

| Action | Rôle qui la fait | Privilège nécessaire | Accordé par (script) |
|---|---|---|---|
| Créer un tag | `GOUVERNANCE` | être propriétaire du schéma `GOUVERNANCE` | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Trouver les tables à protéger, sans les lire | `GOUVERNANCE` | `USAGE` sur la base, sur les schémas `RAW` et `MARTS` et sur le warehouse, et **aucun** `SELECT` | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Poser un tag sur une colonne de `DIM_DRIVER` | `TRANSFORMER` | être propriétaire de la table, avoir `APPLY` sur le tag et `USAGE` sur le schéma `GOUVERNANCE` | `GOUVERNANCE` (`01_gouvernance.sql`) |
| Créer une politique de masquage | `GOUVERNANCE` | être propriétaire du schéma `GOUVERNANCE` | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Attacher une politique de masquage à un tag | `GOUVERNANCE` | `APPLY MASKING POLICY` sur le compte, et être propriétaire du tag | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Ajouter une politique d'accès par ligne à une table | `GOUVERNANCE` | `APPLY ROW ACCESS POLICY` sur le compte | `ACCOUNTADMIN` (`01_gouvernance.sql`) |
| Lire `ACCES_DEPOT` pendant l'évaluation de `RAP_DEPOT` | la politique elle-même | les droits du propriétaire de la politique (`GOUVERNANCE`). Les rôles métier n'ont aucun droit sur la table | — |
| Écrire une ligne dans `QUALITE_RESULTATS` | `TRANSFORMER` (tâche `T_QUALITE`) | `INSERT` et `SELECT` sur la table, mais ni `UPDATE` ni `DELETE` | `GOUVERNANCE` (`01_gouvernance.sql`) |
| Créer la vue `V_CATALOGUE` | `TRANSFORMER` | `CREATE VIEW` sur le schéma `GOUVERNANCE` | `GOUVERNANCE` (`01_gouvernance.sql`) |
| Lire `DIM_DRIVER`, `MART_DRIVER_MONTHLY`, `DIM_DEPOT` | `RH_PAIE`, `RESP_DEPOT_QUEENS`, `RESP_DEPOT_BRONX` | `USAGE` sur la base et le schéma `MARTS`, `SELECT` sur chaque table | `ACCOUNTADMIN` (`02_roles_metier.sql`) |
| Lire tout `MARTS`, y compris les tables futures | `ANALYSTE` | `SELECT ON ALL TABLES` et `ON FUTURE TABLES IN SCHEMA MARTS` | `ACCOUNTADMIN` (`02_roles_metier.sql`) |
| Lire la vue du catalogue | chaque rôle métier | `USAGE` sur le schéma `GOUVERNANCE` et `SELECT ON FUTURE VIEWS` | `ACCOUNTADMIN` (`02_roles_metier.sql`) |
| Exécuter une requête | chaque rôle | `USAGE` sur le warehouse `NYC_TAXI_WH` | `ACCOUNTADMIN` (`00_installation.sql`, `01_gouvernance.sql`, `02_roles_metier.sql`) |
| Faire tourner les tâches planifiées | `TRANSFORMER` | `EXECUTE TASK` sur le compte, `CREATE TASK` sur `MARTS` | `ACCOUNTADMIN` (`00_installation.sql`) |

La hiérarchie créée à l'installation va de `ACCOUNTADMIN` à `SYSADMIN`, puis à `TRANSFORMER`. `GOUVERNANCE` et les quatre rôles métier ne sont rattachés à aucun autre rôle, si bien que chacun se limite à son métier.

### Ce que cette carte permet à un rôle de défaire

| Rôle | Ce qu'il pourrait défaire | Est-ce acceptable ? Qui surveille ? |
|---|---|---|
| `TRANSFORMER` | Il est propriétaire des tables et a `APPLY` sur les trois tags. Il peut donc retirer le tag `DONNEE_PERSONNELLE` d'une colonne (`UNSET TAG`), ce qui la démasque pour tout le monde. Il peut aussi recréer une table avec `CREATE OR REPLACE`, qui perd alors ses tags et son filtre de lignes. Il voit déjà tout en clair. | C'est le risque principal, et nous l'assumons, car c'est le rôle des outils et non celui d'une personne. Pour le limiter : le catalogue est rejoué depuis des fichiers versionnés, le test n° 12 du cahier tourne après chaque exécution des tâches, et l'audit cherche les `ALTER TABLE ... UNSET TAG` dans `QUERY_HISTORY`. |
| `GOUVERNANCE` | Il est propriétaire des politiques, des tags et de `ACCES_DEPOT`. Il peut changer le corps d'une politique ou s'ajouter la ligne `('GOUVERNANCE', '*')` dans `ACCES_DEPOT`. Mais il n'a **aucun `SELECT`** sur les tables, donc il ne lit rien lui-même. | C'est acceptable, car les pouvoirs sont séparés : celui qui écrit les règles ne lit pas les données, et celui qui lit les données ne change pas les règles. Toute modification passe par un fichier SQL versionné et relu. |
| `ACCOUNTADMIN` | Il peut tout s'attribuer, par exemple `GRANT ROLE GOUVERNANCE`, puis modifier une politique. | Snowflake ne permet pas de l'éviter. Il faut réserver ce rôle à deux personnes, avec MFA, et l'auditer en filtrant `QUERY_HISTORY` sur `role_name = 'ACCOUNTADMIN'`. |
| Rôles métier | Rien, ils ne sont propriétaires de rien et n'ont aucun `APPLY`. | Oui. |

---

## Partie 2. Cahier de tests

Le cahier s'exécute : il s'agit de [`snowflake/gouvernance/05_tests_acces.sql`](../snowflake/gouvernance/05_tests_acces.sql), où chaque test porte une annotation `-- @test n | rôle | attendu`. Nous avons écrit la colonne « attendu » avant les politiques, à partir de la matrice du contrat.

Une valeur masquée vaut `'*****'` pour un texte et `NULL` pour une date, car une politique renvoie le type qu'elle reçoit. Pour l'analyste, la date de naissance devient le 1er janvier de l'année de naissance. Une valeur absente, comme un téléphone vide, reste `NULL`. Les tests de valeurs renvoient une catégorie (clair, masqué, NULL ou année) et jamais la valeur elle-même, si bien qu'aucune donnée du fichier RH n'est recopiée ici.

Avant chaque test : `USE SECONDARY ROLES NONE; USE ROLE <rôle>; USE WAREHOUSE NYC_TAXI_WH;`

Le cahier a été exécuté trois fois le 03/11/2026 :

| Moment | Résultat |
|---|---|
| Rôles métier créés, **avant** les politiques | 19 / 37 verts (les tests échouent là où ils doivent échouer) |
| Après `03_masquage.sql` et `04_acces_depot.sql` | **37 / 37 verts** |
| Après une seconde exécution de 02, 03 et 04 (rejouables), puis relance des SQL de `staging/` et `marts/` | **37 / 37 verts** |

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

Pourquoi `ACCOUNTADMIN` obtient-il zéro ligne et non un refus ? Parce qu'il hérite de `SYSADMIN`, qui hérite lui-même de `TRANSFORMER` depuis l'installation, et qu'il a donc le droit `SELECT` sur les tables. Mais la politique de lignes ne regarde que `CURRENT_ROLE()`, pas l'étendue des droits du rôle. Comme `ACCOUNTADMIN` ne figure pas dans `ACCES_DEPOT`, il ne voit aucune ligne de `MARTS`. Dans `RAW`, qui n'a pas de filtre de lignes (contrat, section 4), il voit les 400 lignes, avec toutes les colonnes personnelles masquées. `GOUVERNANCE`, qui n'a aucun `SELECT`, reçoit un refus.

### Valeurs visibles

Pour le chauffeur `D0003`, du dépôt de Queens :

| Colonne | `RH_PAIE` | `RESP_DEPOT_QUEENS` | `RESP_DEPOT_BRONX` | `ANALYSTE` |
|---|---|---|---|---|
| `driver_id` | clair | clair | ligne invisible | clair |
| nom et prénom | clair | clair | ligne invisible | `*****` |
| e-mail | clair | `*****` | ligne invisible | `*****` |
| téléphone | clair | clair | ligne invisible | `*****` |
| date de naissance | complète | `NULL` | ligne invisible | 1er janvier de l'année |
| numéro de licence | clair | `*****` | ligne invisible | `*****` |
| `driver_name` dans `MART_DRIVER_MONTHLY` (3 mois) | clair (3/3) | clair (3/3) | ligne invisible | `*****` (0/3 en clair) |

Les tests V1 à V7 du fichier passent tous les sept, avec un résultat identique à l'attendu.

### Cas limites

| N° | Rôle | Ce qu'on vérifie | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|---|
| L1 | `ANALYSTE` | avec `WHERE email LIKE '%@%'`, le masque s'applique avant le filtre | 0 | 0 | oui |
| L2 | `ANALYSTE` | avec `WHERE last_name <> '*****'`, on ne peut pas deviner un nom par filtre | 0 | 0 | oui |
| L3 | `RESP_DEPOT_QUEENS` + `USE SECONDARY ROLES ALL` | les rôles secondaires n'ouvrent ni plus de lignes ni plus de valeurs | 161, 0 | 161, 0 | oui |
| L4 | `RESP_DEPOT_BRONX` | `WHERE depot = 'Queens'` sur `MART_DRIVER_MONTHLY` | 0 | 0 | oui |
| L5 | `RESP_DEPOT_BRONX` | lire `GOUVERNANCE.ACCES_DEPOT` | refusé | refusé | oui |
| L6 | `RH_PAIE` | chauffeurs de Brooklyn (dépôt sans responsable) | 117 | 117 | oui |
| L7 | `RH_PAIE` | les téléphones vides sont restés `NULL` | 12 | 12 | oui |

**Ajouter un dépôt sans toucher aux politiques** ([`demo_ajout_depot.sql`](../snowflake/gouvernance/demo_ajout_depot.sql)). Une fois créé avec ses droits de lecture, `RESP_DEPOT_BROOKLYN` ne voit aucune ligne. Après l'ajout de `('RESP_DEPOT_BROOKLYN', 'Brooklyn')` dans `ACCES_DEPOT`, il voit le dépôt de Brooklyn et ses 117 chauffeurs, avec les 117 noms en clair et aucun e-mail en clair. Aucune politique n'a été modifiée, et le script remet le compte dans l'état prévu par le contrat à la fin.

### Le pipeline fonctionne toujours

| N° | Vérification | Attendu | Obtenu | Vert ? |
|---|---|---|---|---|
| 10 | Nombre de lignes de `DIM_DRIVER` et de `MART_DRIVER_MONTHLY`, avec le rôle des outils, après relance des fichiers SQL | 400, 914 | 400, 914 | oui |
| 11 | Avec `RH_PAIE`, l'e-mail de `D0003` est toujours une vraie adresse | clair | clair | oui |
| 11b | `driver_name` n'est vide que pour les services orphelins (chauffeurs inconnus) | 25 | 25 | oui |
| 12 | Les politiques sont toujours attachées à `DIM_DRIVER` après la relance | MASK_DATE, MASK_TEXTE, RAP_DEPOT | MASK_DATE, MASK_TEXTE, RAP_DEPOT | oui |
