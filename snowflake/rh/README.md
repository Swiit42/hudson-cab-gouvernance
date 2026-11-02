# snowflake/rh

Placer ici les scripts SQL du kit (installation, chargement, transformations de Priya),
modifiés si besoin, puis les scripts de gouvernance du domaine RH (`10_` à `40_`).

> Rappel : remplacer tout `CREATE OR REPLACE TABLE` du pipeline par
> `INSERT OVERWRITE` (ou `TRUNCATE` + `INSERT`) pour que tags et politiques survivent.
