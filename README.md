# hudson-cab-gouvernance

Gouvernance de l'entrepôt Snowflake du domaine **personnel** de Hudson Cab Partners :
catalogue, contrôle des accès, conservation et qualité des données des chauffeurs.

> Question directrice : **qui peut voir quelle donnée, pendant combien de temps, et peut-on s'y fier ?**

Les données RH sont fictives et **ne sont pas versionnées** (voir `.gitignore`).

## Arborescence
```
snowflake/gouvernance/   schéma, rôles et droits, tags, politiques, table de correspondance, audit
snowflake/rh/            SQL du domaine RH, catalogue, conservation, purge, qualité, tâches
docs/                    VEILLE.md, REGISTRE.md, ACCES.md, captures/
```

## Gouvernance

### Ce qui est protégé et comment
_À compléter._

### Ordre d'exécution des scripts
| # | Script | Rôle |
|---|---|---|
| 1 | Installation du kit | ACCOUNTADMIN |
| 2 | Chargement RH (kit) | TRANSFORMER |
| 3 | Transformations RH (kit) | TRANSFORMER |
| 4 | `snowflake/gouvernance/00_schema.sql` | SYSADMIN |
| 5 | `snowflake/gouvernance/01_roles_droits.sql` | SECURITYADMIN |
| 6 | `snowflake/gouvernance/02_tags.sql` | GOUVERNANCE |
| 7 | `snowflake/gouvernance/03_correspondance_depot.sql` | GOUVERNANCE |
| 8 | `snowflake/gouvernance/04_politiques_masquage.sql` | GOUVERNANCE |
| 9 | `snowflake/gouvernance/05_politique_lignes.sql` | GOUVERNANCE |
| 10 | `snowflake/rh/10_catalogue_descriptions.sql` | TRANSFORMER |
| 11 | `snowflake/rh/11_v_catalogue.sql` | TRANSFORMER |
| 12 | `snowflake/rh/20_conservation.sql` | TRANSFORMER |
| 13 | `snowflake/rh/21_purge.sql` | TRANSFORMER |
| 14 | `snowflake/rh/30_regles_qualite.sql` | TRANSFORMER |
| 15 | `snowflake/rh/40_taches.sql` | TRANSFORMER |
| 16 | `snowflake/gouvernance/90_audit_acces.sql` | GOUVERNANCE |

### Choix techniques
_À compléter._

### Écarts entre le contrat et les textes
_À compléter (voir `docs/VEILLE.md`)._

### Limites connues
_À compléter._
