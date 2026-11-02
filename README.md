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
  gouvernance/              rôles, droits, tags, politiques, table de correspondance, audit
  rh/                       chargement, staging, marts, catalogue/, controles/, purge, conservation, tâches
docs/                       VEILLE.md, REGISTRE.md, ACCES.md, captures/
```

## Gouvernance

### Ce qui est protégé et comment
_À compléter._

### Données du personnel hors du dépôt
Les fichiers `data/*.csv` sont exclus par `.gitignore` : un dépôt public est lisible par tous, et un
fichier du personnel — même fictif — se traite comme un vrai (minimisation, art. 5 RGPD) ; un fichier
poussé une fois reste dans l'historique Git.

### Ordre d'exécution des scripts
| # | Script | Rôle | Contrôle |
|---|---|---|---|
| 1 | `snowflake/00_installation.sql` | ACCOUNTADMIN | schémas RAW, STAGING, MARTS |
| 2 | `snowflake/rh/chargement_rh_1_preparer.sql` | TRANSFORMER | stage `RH_STAGE` créé |
| 3 | Dépôt des 2 CSV sur `RH_STAGE` (Snowsight) | TRANSFORMER | `LIST` : 2 fichiers |
| 4 | `snowflake/rh/chargement_rh_2_copier.sql` | TRANSFORMER | 400 / 25 951 lignes, stage vide |
| 5 | `snowflake/rh/00_tables_rh.sql` | TRANSFORMER | 3 tables dans MARTS |
| 6 | `snowflake/rh/staging/stg_rh__drivers.sql`, `stg_rh__driver_shifts.sql` | TRANSFORMER | 25 933 services |
| 7 | `snowflake/rh/marts/dim_depot.sql`, `dim_driver.sql`, `mart_driver_monthly.sql` | TRANSFORMER | 3 / 400 / 914 lignes |
| 8 | `snowflake/gouvernance/01_gouvernance.sql` | ACCOUNTADMIN puis GOUVERNANCE | 3 tags |
| 9 | `snowflake/gouvernance/modele_catalogue_dim_depot.sql`, `snowflake/rh/catalogue/*.sql` | TRANSFORMER | descriptions + tags |
| 10 | `snowflake/gouvernance/02_roles_metier.sql` | ACCOUNTADMIN | |
| 11 | `snowflake/gouvernance/03_masquage.sql` | GOUVERNANCE | |
| 12 | `snowflake/gouvernance/04_acces_depot.sql` | GOUVERNANCE | |
| 13 | `snowflake/rh/purge_rh.sql` | TRANSFORMER | |
| 14 | `snowflake/rh/conservation_rh.sql` | TRANSFORMER | |
| 15 | `snowflake/rh/controles/*.sql` | TRANSFORMER | |
| 16 | `snowflake/rh/catalogue/v_catalogue.sql` | TRANSFORMER | ANALYSTE lit la vue |
| 17 | `snowflake/rh/taches_rh.sql` | TRANSFORMER | 3 tâches en succès |
| 18 | `snowflake/gouvernance/06_audit.sql` | ACCOUNTADMIN | |

### Chargement (format de fichier, stage, COPY INTO, PURGE)
_À compléter._

### Choix techniques
_À compléter (masquer ou supprimer chaque colonne, notation « tous les dépôts », purge des services…)._

### Écarts entre le contrat et les textes
_À compléter (voir `docs/VEILLE.md`, section 4)._

### Limites connues
_À compléter._
