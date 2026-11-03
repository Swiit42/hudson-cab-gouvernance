# Note de veille réglementaire : les données du personnel de Hudson Cab Partners

Une veille ne se limite pas à une recherche faite une fois. C'est un dispositif qui doit continuer à nous prévenir quand un texte change. Chaque affirmation de cette note cite sa source (texte, article, date de publication). Toutes les sources ont été consultées le 03/11/2026.

## 1. Le droit applicable

Le traitement porte sur les données de chauffeurs employés à New York. Le groupe en a confié la gestion à Hudson Cab Europe, qui les gère depuis Paris.

| Question | Réponse | Source (texte et article) |
|---|---|---|
| Le RGPD s'applique-t-il à ce traitement ? | Oui. | RGPD, art. 3, paragraphe 1 |
| Pourquoi, alors que les chauffeurs ne sont pas en Europe ? | L'article 3.1 regarde l'entreprise, pas les personnes. Il vise le traitement effectué « dans le cadre des activités d'un établissement » d'un responsable dans l'Union, « que le traitement ait lieu ou non dans l'Union ». Hudson Cab Europe est une filiale installée à Paris, avec une équipe data qui porte l'entrepôt. C'est un établissement stable (considérant 22), donc l'article 3.1 s'applique. L'article 3.2 concerne les entreprises sans établissement dans l'UE qui visent des personnes dans l'UE. Il ne joue pas ici, puisque les chauffeurs sont à New York et que l'entreprise a un établissement, et on n'en a de toute façon pas besoin. La nationalité ou la résidence des chauffeurs ne change rien (considérant 14). | RGPD art. 3.1, 3.2, considérants 14 et 22 ; CEPD, lignes directrices 3/2018, partie 1 (critère d'établissement) |
| Qui est responsable du traitement ? Qui est sous-traitant ? | Hudson Cab Europe est responsable : depuis cette année, c'est elle qui « décide désormais de ce que deviennent ces données », c'est-à-dire des finalités et des moyens. Snowflake est sous-traitant. Il héberge les données et calcule sur instruction, sans décider des finalités. Hudson Cab Partners (New York) transmet le fichier RH et fixe les règles « avec son conseil juridique ». Elle pourrait donc être responsable conjointe (art. 26), question que nous renvoyons à la section 5. | RGPD art. 4.7, 4.8, 26, 28 ; CEPD, lignes directrices 07/2020 |
| Quelle autorité de contrôle est compétente ? | La CNIL, autorité du pays où se trouve l'établissement principal du responsable, la France. | RGPD art. 4.16, 55, 56 |
| Les données sortent-elles de l'UE ? | Pour le stockage, non. Le compte Snowflake est en région `AWS_EU_WEST_3` (Paris), ce que nous avons vérifié avec `SELECT CURRENT_REGION();` le 03/11/2026. Pour l'accès, oui. Les responsables de dépôt et l'analyste lisent l'entrepôt depuis New York, ce qui constitue un transfert hors UE. Il doit reposer sur la décision d'adéquation *EU-US Data Privacy Framework*, si le destinataire américain est certifié, ou sur des clauses contractuelles types. Le support de Snowflake Inc., aux États-Unis, peut lui aussi accéder aux données, ce que le contrat de sous-traitance doit couvrir. | RGPD art. 44 à 46 ; décision d'exécution (UE) 2023/1795 du 10/07/2023 |

## 2. Le dispositif de veille

| Source | Type | Ce qu'on y surveille | Fréquence | Outil de suivi |
|---|---|---|---|---|
| CNIL, actualités (flux https://www.cnil.fr/fr/rss.xml) | officielle (autorité de contrôle française, compétente ici) | référentiels (RH, durées de conservation), recommandations, sanctions liées aux données des salariés | chaque lundi | lecteur RSS (Feedly) avec le flux abonné, capture `docs/captures/veille_abonnement.png` |
| CEPD / EDPB, actualités (https://edpb.europa.eu/news/news_fr) | officielle (comité européen) | lignes directrices (transferts, responsables et sous-traitants, art. 3), avis sur les décisions d'adéquation | hebdomadaire | même lecteur RSS |
| EUR-Lex : RGPD (CELEX 32016R0679) et décision 2023/1795 | officielle (Journal officiel de l'UE) | modification ou invalidation d'un texte, par exemple un recours contre le Data Privacy Framework | mensuelle | alerte « Mon EUR-Lex » sur les deux documents |
| Légifrance : Code du travail (registre unique du personnel, paie) | officielle (droit français) | durées de conservation imposées à l'employeur | mensuelle | alerte Légifrance sur les articles suivis |
| NYS Department of Labor | officielle (droit de l'État de New York) | obligations de conservation des relevés de paie | trimestrielle | page suivie dans le lecteur RSS, ou contrôle manuel inscrit au calendrier |
| Snowflake, notes de version | professionnelle (éditeur) | évolutions du masquage, des tags, de Time Travel et d'`ACCESS_HISTORY` | hebdomadaire | même lecteur RSS |

Chaque membre du binôme lit les nouveautés de la semaine dans le lecteur RSS. Celui ou celle qui repère un texte touchant l'entrepôt ouvre une *issue* GitHub avec l'étiquette `veille`, et le binôme décide en revue hebdomadaire : action, aucune action, ou point à signaler au DPO. Dans l'équipe, le lead data tranche et le DPO de Hudson Cab Europe valide.

## 3. Les fiches de veille

### Fiche 1. Le champ d'application territorial du RGPD

- **Source** : Règlement (UE) 2016/679 (RGPD), art. 3 et considérants 14 et 22, EUR-Lex, https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679
- **Date** : publié au JOUE le 04/05/2016, applicable depuis le 25/05/2018, consulté le 03/11/2026
- **Ce que dit le texte** : le RGPD s'applique à tout traitement fait dans le cadre des activités d'un établissement situé dans l'UE, même si les personnes et les serveurs sont ailleurs. Le lieu où vivent les personnes ne compte que pour les entreprises qui n'ont pas d'établissement dans l'UE (art. 3.2).
- **Ce que cela change pour notre entrepôt** : depuis que la gestion a été confiée à Hudson Cab Europe, toutes les tables du domaine RH relèvent du RGPD (`RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY`), ainsi que les vues de `STAGING`.
- **Action** : à faire dans ce brief (registre, durées, accès), et à signaler à la direction, car le contrat ne mentionne pas le RGPD.

### Fiche 2. Le critère d'établissement, vu par le CEPD

- **Source** : CEPD, lignes directrices 3/2018 relatives au champ d'application territorial du RGPD (article 3), version 2.1, https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-32018-territorial-scope-gdpr-article-3-version_fr
- **Date** : version 2.0 adoptée le 12/11/2019 après consultation publique, version 2.1 (mise en forme) du 07/01/2020, consultées le 03/11/2026
- **Ce que dit le texte** : un établissement suppose une « installation stable » et l'exercice effectif d'une activité, même minime. Une filiale suffit. Le traitement relève de l'article 3.1 dès qu'il est fait « dans le cadre des activités » de cet établissement, où qu'il soit exécuté. Confier le traitement à un sous-traitant situé hors de l'UE ne le fait pas sortir du RGPD.
- **Ce que cela change pour notre entrepôt** : héberger le compte Snowflake aux États-Unis ne ferait pas échapper le traitement au RGPD. Le choix de la région ne joue que sur la question des transferts (fiche 6).
- **Action** : aucune, la fiche confirme la section 1.

### Fiche 3. Les principes : minimisation, limitation de la conservation, sécurité

- **Source** : RGPD, art. 5.1 c), d), e) et f), art. 25 (protection des données dès la conception et par défaut) et art. 32 (sécurité), EUR-Lex (même lien que la fiche 1)
- **Date** : 27/04/2016, consulté le 03/11/2026
- **Ce que dit le texte** : on ne traite que les données nécessaires à la finalité, on les tient exactes, on ne les garde pas plus longtemps que nécessaire, et on limite par défaut leur accès « aux personnes qui en ont besoin ». Le RGPD ne fixe aucune durée en années. C'est la finalité qui la justifie.
- **Ce que cela change pour notre entrepôt** : plusieurs choix en découlent. Le masquage s'applique par défaut, donc un rôle absent de la matrice ne voit rien, `ACCOUNTADMIN` compris. Les colonnes inutiles à un rôle sont masquées ou retirées pour lui, comme l'e-mail et la licence pour l'analyste. Les règles de qualité répondent à l'exigence d'exactitude (art. 5.1 d), et la purge est datée. Enfin, `driver_name` dans `MART_DRIVER_MONTHLY` est une copie du nom et doit être protégé comme lui.
- **Action** : à faire dans ce brief (jours 2 et 3).

### Fiche 4. Le référentiel CNIL « gestion du personnel »

- **Source** : CNIL, délibération n° 2019-160 du 21 novembre 2019 portant adoption d'un référentiel relatif aux traitements de données à caractère personnel mis en œuvre aux fins de gestion du personnel, section « Durées de conservation ». Version en vigueur : https://www.cnil.fr/sites/cnil/files/2023-09/referentiel_gestion_des_ressources_humaines.pdf (version de 2019 citée par le kit : https://www.cnil.fr/sites/cnil/files/atoms/files/referentiel_grh_novembre_2019_0.pdf)
- **Date** : adopté le 21/11/2019, publié au Journal officiel le 15/04/2020, modifié le 23/05/2022, consulté le 03/11/2026. La veille doit suivre la version modifiée.
- **Ce que dit le texte** : les données d'un salarié restent en base active pendant toute la relation de travail. Après son départ, celles qu'il faut encore garder (pour une obligation légale ou comme preuve en cas de contentieux) passent en archivage intermédiaire, dans une base séparée à accès restreint, puis sont supprimées. Le registre unique du personnel se conserve 5 ans à compter du départ du salarié (Code du travail, art. R. 1221-26).
- **Ce que cela change pour notre entrepôt** : R1 reprend la durée de 5 ans du registre unique du personnel. Mais pendant ces 5 ans, un chauffeur parti ne devrait plus apparaître comme un chauffeur en poste. Or 110 chauffeurs partis figuraient dans `DIM_DRIVER` au chargement, et 64 y sont encore après la purge, avec les mêmes accès que les autres (voir la section 4, écart principal).
- **Action** : à signaler à la direction. La proposition technique est en section 4.

### Fiche 5. Responsable du traitement et sous-traitant

- **Source** : CEPD, lignes directrices 07/2020 concernant les notions de responsable du traitement et de sous-traitant dans le RGPD, version 2.0, https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-072020-concepts-controller-and-processor-gdpr_fr ; RGPD art. 4.7, 4.8, 26, 28, 30
- **Date** : adoptées le 07/07/2021, consultées le 03/11/2026
- **Ce que dit le texte** : le responsable est celui qui détermine pourquoi on traite les données (les finalités) et les éléments essentiels du comment : quelles données, combien de temps, qui y accède. Le sous-traitant agit sur instruction et doit être lié par un contrat conforme à l'article 28. Quand deux entités décident ensemble, elles sont responsables conjointes et doivent répartir leurs obligations par un accord (art. 26).
- **Ce que cela change pour notre entrepôt** : Hudson Cab Europe tient le registre (art. 30, notre `REGISTRE.md`) et assume les choix d'accès et de conservation. Snowflake est sous-traitant, et son contrat de traitement des données reste à vérifier. Le contrat de gouvernance a été signé par la direction new-yorkaise avant le transfert et ne désigne pas de responsable.
- **Action** : à signaler à la direction (section 5).

### Fiche 6. Les transferts vers les États-Unis : le Data Privacy Framework

- **Source** : Commission européenne, décision d'exécution (UE) 2023/1795 du 10 juillet 2023 constatant le niveau de protection adéquat du cadre de protection des données UE–États-Unis, EUR-Lex, https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32023D1795 ; RGPD art. 44 à 46
- **Date** : 10/07/2023, consultée le 03/11/2026
- **Ce que dit le texte** : on peut transférer des données vers une organisation américaine certifiée au Data Privacy Framework sans autre garantie. Sinon, il faut des clauses contractuelles types (art. 46). La Commission réexamine la décision périodiquement, et elle peut être contestée devant la CJUE, comme l'a été le Privacy Shield en 2020 avec l'arrêt « Schrems II ».
- **Ce que cela change pour notre entrepôt** : avec un compte en région US, le stockage lui-même serait un transfert. Tout accès depuis New York en est un, que ce soit celui de la direction, des responsables de dépôt ou de l'analyste. C'est typiquement un texte à surveiller, car son invalidation obligerait à revoir l'hébergement et les accès.
- **Action** : la région du compte est vérifiée (`AWS_EU_WEST_3`, Paris), donc le stockage n'est pas un transfert. Snowflake Inc. se déclare auto-certifié aux cadres UE–États-Unis, à l'extension Royaume-Uni et au cadre Suisse–États-Unis (https://www.snowflake.com/en/legal/privacy/data-privacy-framework-notice/, à recouper sur https://www.dataprivacyframework.gov). Il reste à vérifier la situation de chaque destinataire new-yorkais (Hudson Cab Partners) et à signaler le point à la direction.

### Fiche 7. La conservation des relevés de paie dans l'État de New York

- **Source** : New York State Labor Law, § 195 (4), https://www.nysenate.gov/legislation/laws/LAB/195 ; NYS Department of Labor, https://dol.ny.gov
- **Date** : la loi de 2011 (Wage Theft Prevention Act) a porté la durée de 3 à 6 ans. Texte en vigueur, consulté le 03/11/2026, à faire valider par un juriste américain.
- **Ce que dit le texte** : l'employeur tient des relevés de paie exacts et établis au fur et à mesure (heures travaillées chaque jour, taux et base de rémunération) et les conserve au moins six ans.
- **Ce que cela change pour notre entrepôt** : R1 supprime toutes les données d'un chauffeur 5 ans après son départ, y compris ses services (`RAW.DRIVER_SHIFTS`, avec les heures et les recettes). Si ces relevés servent de justificatifs de paie, l'obligation new-yorkaise de 6 ans pourrait l'emporter. Le RGPD permet de garder une donnée pour respecter une obligation légale (art. 6.1 c, 17.3 b), à condition de l'archiver à part.
- **Action** : à signaler à la direction (section 5). En attendant, nous appliquons R1 telle que le brief l'écrit.

## 4. Le contrat face aux textes

| Règle du contrat | Ce que disent les textes | Source | Conforme ? | Écart et proposition |
|---|---|---|---|---|
| Préambule : les décisions sont prises par la direction de Hudson Cab Partners | Le responsable du traitement est celui qui décide, c'est-à-dire désormais Hudson Cab Europe. Il doit tenir un registre, choisir une base légale pour chaque finalité et informer les salariés. | RGPD art. 4.7, 6, 13, 30 | **Non** | Le contrat date d'avant le transfert. Il ne cite pas le RGPD et ne nomme ni responsable, ni finalité, ni base légale. Nous proposons de le faire valider par Hudson Cab Europe et son DPO, avec trois finalités : la paie (exécution du contrat de travail, art. 6.1 b, et obligations légales, art. 6.1 c), l'organisation des dépôts (contrat, art. 6.1 b) et le pilotage de l'activité (intérêt légitime, art. 6.1 f). |
| R1 : suppression 5 ans après la fin du contrat | Le RGPD ne fixe pas de durée, il demande de la justifier. La CNIL distingue la base active, pendant le contrat, et l'archivage intermédiaire, après le départ, avec un accès restreint. Les 5 ans correspondent à la durée du registre unique du personnel en droit français, alors que New York impose 6 ans pour les relevés de paie. | RGPD art. 5.1 e ; référentiel CNIL 2019, section 7 ; C. trav. R. 1221-26 ; NYLL § 195 | **En partie** | C'est l'écart principal. Pendant 5 ans, un chauffeur parti reste dans la base active, et les responsables de dépôt comme l'analyste le voient comme un chauffeur en poste. Au chargement, 110 chauffeurs sur 400 étaient partis. Nous proposons de sortir les chauffeurs partis de la base active, soit en ajoutant un filtre `is_active` à la politique de lignes des responsables de dépôt, soit avec une table d'archive que seul `RH_PAIE` peut lire. Il faudrait aussi justifier les 5 ans par une finalité écrite et faire trancher la durée de conservation des services (6 ans, comme à New York ?). |
| R2 : Time Travel limité à 1 jour | Une donnée supprimée doit l'être réellement. Sur une table permanente, Snowflake garde en plus 7 jours de Fail-safe, que le client ne peut ni réduire ni lire. | RGPD art. 5.1 e, 17 ; documentation Snowflake (Fail-safe) | **En partie** | La suppression effective prend 1 + 7 = 8 jours, et non 1. Nous proposons de l'écrire dans le registre. Seul le support de Snowflake, qui est sous-traitant, peut accéder au Fail-safe, ce qui reste acceptable à condition de le documenter. L'autre option serait des tables `TRANSIENT`, sans Fail-safe, mais on perdrait cette protection. |
| R3 : le fichier RH est retiré du stage | La minimisation interdit les copies inutiles, et la sécurité va dans le même sens. | RGPD art. 5.1 c, 32 | **Oui** | `COPY INTO` utilise `PURGE = TRUE`. Le fichier reste aussi sur le poste qui l'a déposé : il faut le supprimer après chargement et ne jamais le mettre dans le dépôt Git. |
| Matrice des accès (qui voit quoi) | L'accès doit être limité par défaut aux personnes qui en ont besoin. | RGPD art. 5.1 c, 25.2, 32 | **Oui, avec réserves** | L'esprit est respecté : masquage par défaut, administrateur masqué, aucun identifiant direct pour l'analyste, qui ne voit que l'année de naissance. Trois réserves cependant. `RH_PAIE` voit « tout », y compris la date de naissance et la licence, dont la paie n'a pas forcément besoin. Le dépôt de Brooklyn n'a aucun responsable, et seule la paie voit ses 117 chauffeurs. Les chauffeurs partis restent visibles (voir R1). |
| Licence TLC visible de la paie seulement | La TLC publie les numéros de licence en open data, avec le nom du titulaire. C'est donc un identifiant direct. | RGPD art. 4.1 | **Oui** | Une donnée publique reste une donnée personnelle, ce qui justifie de la masquer pour les responsables de dépôt et l'analyste. |
| Règles de qualité (section 6) | Les données doivent être exactes et tenues à jour, et les données inexactes rectifiées sans tarder. | RGPD art. 5.1 d, 16 | **En partie** | Les règles mesurent, mais personne n'est chargé de corriger. Nous avons trouvé 7 e-mails invalides, 12 téléphones manquants, 4 licences en double et 5 contrats aux dates incohérentes. Nous proposons de désigner le service RH comme destinataire des alertes et responsable de la rectification. |
| Absent du contrat | Le contrat ne dit rien de l'information des salariés, de leurs droits d'accès, de rectification et d'effacement, du registre, de la sécurité ni des transferts. | RGPD art. 13, 15 à 17, 30, 32, 44 | **Non** | Nous proposons de compléter avec le registre (`REGISTRE.md`) et de prévoir une procédure pour répondre à la demande d'accès d'un chauffeur, avec une requête par `driver_id` sur les quatre tables. |

Ces écarts sont repris dans la section « Gouvernance » du `README.md`.

## 5. Ce que la veille ne tranche pas

| Question | À qui la poser |
|---|---|
| Hudson Cab Partners (New York) a fixé les règles et reçoit les analyses. Est-elle responsable conjointe avec Hudson Cab Europe (art. 26) ? | DPO de Hudson Cab Europe, juriste RGPD |
| La durée de 5 ans vient du droit du travail français. Est-elle la bonne pour des contrats de travail new-yorkais, alors que New York impose 6 ans pour les relevés de paie ? | Conseil juridique du groupe (droit du travail new-yorkais) |
| Le suivi mensuel de l'activité et de la recette de chaque chauffeur (`MART_DRIVER_MONTHLY`) est-il une surveillance des salariés qui exige une analyse d'impact (AIPD, art. 35) ? | DPO, CNIL (liste des traitements soumis à AIPD) |
| Sur quelle base légale repose le pilotage de l'activité par l'analyste ? Si c'est l'intérêt légitime (art. 6.1 f), avec quelle mise en balance ? | DPO |
