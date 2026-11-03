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

Le registre des activités de traitement décrit ce qu'une organisation fait des données personnelles qu'elle détient. Cette fiche en est une version réduite, limitée à ce qu'un Data Engineer peut renseigner et prouver. La trame complète est celle de la CNIL (lien dans les ressources).

Chaque réponse de la colonne de droite doit pouvoir être vérifiée dans l'entrepôt : indiquez la requête ou le fichier qui le prouve.

### Le traitement

| Rubrique | Réponse |
|---|---|
| Nom du traitement | |
| Finalité : à quoi servent ces données | |
| Personnes concernées | |
| Service responsable des données | |

### Les données

| Catégorie de données | Colonnes concernées | Tables où elles se trouvent |
|---|---|---|
| Identité | | |
| Coordonnées | | |
| Vie professionnelle | | |

### Qui y accède

| Rôle | Ce qu'il voit | Pourquoi il en a besoin | Preuve (requête ou test) |
|---|---|---|---|
| | | | |

### Combien de temps

| Règle | Comment elle est appliquée | Preuve |
|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | | |
| R2 : pas de restauration au-delà de 1 jour | | |
| R3 : pas de fichier sur le stage | | |

Délai réel entre l'exécution de la purge et la disparition définitive d'une donnée dans Snowflake, en tenant compte de Time Travel et de Fail-safe : ______ jours.

### Comment on le contrôle

| Question | Réponse | Preuve |
|---|---|---|
| Peut-on dire qui a lu ces données la semaine dernière ? | | |
| Sait-on quand une donnée est fausse ? | | |
| Que se passe-t-il si le rôle des outils est compromis ? | | |

### Limites connues

Ce que votre mise en œuvre ne couvre pas : deux ou trois lignes, sans détour.
