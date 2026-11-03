# Note de veille réglementaire — données du personnel de Hudson Cab Partners

Une veille n'est pas une recherche faite une fois : c'est un dispositif qui continue de nous prévenir quand un texte change. Chaque affirmation de cette note cite sa source (texte, article, date de publication ; consultation le 03/11/2026).

## 1. Le droit applicable

Le traitement : les données de chauffeurs employés à New York, gérées depuis Paris par Hudson Cab Europe, à qui le groupe a confié leur gestion.

| Question | Réponse | Source (texte et article) |
|---|---|---|
| Le RGPD s'applique-t-il à ce traitement ? | **Oui.** | RGPD, art. 3, paragraphe 1 |
| Pourquoi, alors que les chauffeurs ne sont pas en Europe ? | L'art. 3.1 regarde **l'entreprise**, pas les personnes : il s'applique au traitement effectué « dans le cadre des activités d'un établissement » d'un responsable dans l'Union, « que le traitement ait lieu ou non dans l'Union ». Hudson Cab Europe est une filiale installée à Paris, avec une équipe data qui porte l'entrepôt : c'est un établissement stable (considérant 22). **3.1 : oui.** L'art. 3.2 (entreprise sans établissement dans l'UE qui vise des personnes dans l'UE) ne joue pas : les chauffeurs sont à New York et l'entreprise a un établissement. **3.2 : non, et inutile.** La nationalité ou la résidence des chauffeurs est indifférente (considérant 14). | RGPD art. 3.1, 3.2, considérants 14 et 22 ; CEPD, lignes directrices 3/2018, partie 1 (critère d'établissement) |
| Qui est responsable du traitement ? Qui est sous-traitant ? | **Responsable : Hudson Cab Europe** : depuis cette année, c'est elle qui « décide désormais de ce que deviennent ces données » (finalités et moyens). **Sous-traitant : Snowflake**, qui héberge et calcule sur instruction, sans décider des finalités. Hudson Cab Partners (New York), qui transmet le fichier RH et fixe les règles « avec son conseil juridique », pourrait être **responsable conjoint** (art. 26) : question renvoyée en section 5. | RGPD art. 4.7, 4.8, 26, 28 ; CEPD, lignes directrices 07/2020 |
| Quelle autorité de contrôle est compétente ? | **La CNIL**, autorité du lieu de l'établissement principal du responsable (France). | RGPD art. 4.16, 55, 56 |
| Les données sortent-elles de l'UE ? | Selon la région du compte Snowflake (`SELECT CURRENT_REGION();` → **à compléter : _____**). **Région UE** (ex. `AWS_EU_WEST_3` Paris, `AWS_EU_CENTRAL_1` Francfort) : pas de transfert pour le stockage. **Région US** : transfert vers un pays tiers, à fonder sur la décision d'adéquation *EU-US Data Privacy Framework* (si Snowflake Inc. est certifié) ou sur des clauses contractuelles types. Dans tous les cas, tout accès de la direction new-yorkaise aux données est un transfert. | RGPD art. 44 à 46 ; décision d'exécution (UE) 2023/1795 du 10/07/2023 |

## 2. Le dispositif de veille

| Source | Type | Ce qu'on y surveille | Fréquence | Outil de suivi |
|---|---|---|---|---|
| CNIL — actualités (flux https://www.cnil.fr/fr/rss.xml) | officielle (autorité de contrôle française, compétente ici) | référentiels (RH, durées de conservation), recommandations, sanctions liées aux données des salariés | hebdomadaire (lundi) | lecteur RSS (Feedly) : flux abonné, capture `docs/captures/veille_abonnement.png` |
| CEPD / EDPB — actualités (https://edpb.europa.eu/news/news_fr) | officielle (comité européen) | lignes directrices (transferts, responsables / sous-traitants, art. 3), avis sur les décisions d'adéquation | hebdomadaire | même lecteur RSS |
| EUR-Lex — RGPD (CELEX 32016R0679) et décision 2023/1795 | officielle (Journal officiel de l'UE) | modification ou invalidation d'un texte (ex. recours contre le Data Privacy Framework) | mensuelle | alerte « Mon EUR-Lex » sur les deux documents |
| Légifrance — Code du travail (registre unique du personnel, paie) | officielle (droit français) | durées de conservation imposées à l'employeur | mensuelle | alerte Légifrance sur les articles suivis |
| NYS Department of Labor | officielle (droit de l'État de New York) | obligations de conservation des relevés de paie | trimestrielle | page suivie dans le lecteur RSS (ou contrôle manuel inscrit au calendrier) |
| Snowflake — notes de version | professionnelle (éditeur) | évolutions du masquage, des tags, de Time Travel et d'`ACCESS_HISTORY` | hebdomadaire | même lecteur RSS |

Qui lit et décide : chaque membre du binôme lit les nouveautés de la semaine dans le lecteur RSS ; celle ou celui qui repère un texte qui touche l'entrepôt ouvre une *issue* GitHub étiquetée `veille` ; le binôme décide en revue hebdomadaire (action / aucune action / à signaler au DPO). Dans l'équipe : le lead data tranche, le DPO de Hudson Cab Europe valide.

## 3. Les fiches de veille

### Fiche 1 — Le champ d'application territorial du RGPD

- **Source** : Règlement (UE) 2016/679 (RGPD), art. 3 et considérants 14 et 22, EUR-Lex, https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679
- **Date** : publié au JOUE le 04/05/2016, applicable depuis le 25/05/2018 · consulté le 03/11/2026
- **Ce que dit le texte** : le RGPD s'applique à tout traitement fait dans le cadre des activités d'un établissement situé dans l'UE, même si les personnes et les serveurs sont ailleurs. Le lieu où vivent les personnes ne compte que pour les entreprises sans établissement dans l'UE (art. 3.2).
- **Ce que cela change pour notre entrepôt** : depuis le transfert de la gestion à Hudson Cab Europe, **toutes** les tables du domaine RH (`RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY`) relèvent du RGPD, y compris les vues de `STAGING`.
- **Action** : à faire dans ce brief (registre, durées, accès) ; à signaler à la direction (le contrat ne mentionne pas le RGPD).

### Fiche 2 — Le critère d'établissement, vu par le CEPD

- **Source** : CEPD, lignes directrices 3/2018 relatives au champ d'application territorial du RGPD (article 3), version 2.1, https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-32018-territorial-scope-gdpr-article-3-version_fr
- **Date** : adoptées le 12/11/2019 · consultées le 03/11/2026
- **Ce que dit le texte** : un établissement suppose une « installation stable » et l'exercice effectif d'une activité, même minime ; une filiale suffit. Le traitement relève de l'art. 3.1 dès qu'il est fait « dans le cadre des activités » de cet établissement, où qu'il soit exécuté. Le recours à un sous-traitant situé hors de l'UE ne fait pas sortir le traitement du RGPD.
- **Ce que cela change pour notre entrepôt** : héberger le compte Snowflake aux États-Unis ne ferait pas échapper le traitement au RGPD ; le choix de la région ne change que la question des transferts (fiche 6).
- **Action** : aucune (confirme la section 1).

### Fiche 3 — Les principes : minimisation, limitation de la conservation, sécurité

- **Source** : RGPD, art. 5.1 c), d), e), f), art. 25 (protection des données dès la conception et par défaut) et art. 32 (sécurité), EUR-Lex (même lien que fiche 1)
- **Date** : 27/04/2016 · consulté le 03/11/2026
- **Ce que dit le texte** : on ne traite que les données nécessaires à la finalité (minimisation), on les tient exactes, on ne les garde pas plus longtemps que nécessaire, et on limite par défaut leur accès « aux personnes qui en ont besoin ». Le RGPD ne fixe **aucune durée en années** : elle se justifie par la finalité.
- **Ce que cela change pour notre entrepôt** : masquage par défaut (un rôle absent de la matrice ne voit rien, `ACCOUNTADMIN` compris) ; suppression ou masquage de colonnes inutiles pour un rôle (e-mail et licence pour l'analyste) ; règles de qualité au titre de l'exactitude (art. 5.1 d) ; purge datée ; `driver_name` dans `MART_DRIVER_MONTHLY` est une copie du nom, à protéger comme lui.
- **Action** : à faire dans ce brief (jours 2 et 3).

### Fiche 4 — Le référentiel CNIL « gestion du personnel »

- **Source** : CNIL, délibération n° 2019-160 du 21 novembre 2019 portant adoption d'un référentiel relatif aux traitements de données à caractère personnel mis en œuvre aux fins de gestion du personnel, section 7 « Durées de conservation », https://www.cnil.fr/sites/cnil/files/atoms/files/referentiel_grh_novembre_2019_0.pdf
- **Date** : 21/11/2019 · consulté le 03/11/2026
- **Ce que dit le texte** : les données d'un salarié restent en **base active** le temps de la relation de travail ; après son départ, celles qui doivent encore être gardées (obligation légale, preuve en cas de contentieux) passent en **archivage intermédiaire**, une base séparée à accès restreint, puis sont supprimées. Le registre unique du personnel se conserve **5 ans à compter du départ** du salarié (Code du travail, art. R. 1221-26).
- **Ce que cela change pour notre entrepôt** : R1 (5 ans) reprend la durée du registre unique du personnel. Mais pendant ces 5 ans, un chauffeur parti ne devrait plus être visible comme un chauffeur en poste : aujourd'hui, 110 chauffeurs partis restent dans `DIM_DRIVER` avec les mêmes accès que les autres (voir section 4, écart principal).
- **Action** : à signaler à la direction ; proposition technique en section 4.

### Fiche 5 — Responsable du traitement et sous-traitant

- **Source** : CEPD, lignes directrices 07/2020 concernant les notions de responsable du traitement et de sous-traitant dans le RGPD, version 2.0, https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-072020-concepts-controller-and-processor-gdpr_fr ; RGPD art. 4.7, 4.8, 26, 28, 30
- **Date** : adoptées le 07/07/2021 · consultées le 03/11/2026
- **Ce que dit le texte** : est responsable celui qui détermine **pourquoi** (finalités) et les éléments essentiels du **comment** (quelles données, combien de temps, qui y accède). Le sous-traitant agit sur instruction et doit être lié par un contrat conforme à l'art. 28. Si deux entités décident ensemble, elles sont responsables conjointes et doivent répartir leurs obligations par un accord (art. 26).
- **Ce que cela change pour notre entrepôt** : Hudson Cab Europe tient le registre (art. 30, notre `REGISTRE.md`) et porte les choix d'accès et de conservation ; Snowflake est sous-traitant (contrat de traitement des données de Snowflake à vérifier). Le contrat de gouvernance, signé par la direction new-yorkaise avant le transfert, ne désigne pas le responsable.
- **Action** : à signaler à la direction (section 5).

### Fiche 6 — Les transferts vers les États-Unis : le Data Privacy Framework

- **Source** : Commission européenne, décision d'exécution (UE) 2023/1795 du 10 juillet 2023 constatant le niveau de protection adéquat du cadre de protection des données UE–États-Unis, EUR-Lex, https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32023D1795 ; RGPD art. 44 à 46
- **Date** : 10/07/2023 · consultée le 03/11/2026
- **Ce que dit le texte** : un transfert vers une organisation américaine **certifiée** au Data Privacy Framework est possible sans autre garantie ; sinon, il faut des clauses contractuelles types (art. 46). La décision est réexaminée périodiquement par la Commission et peut être contestée devant la CJUE (comme le Privacy Shield en 2020, arrêt « Schrems II »).
- **Ce que cela change pour notre entrepôt** : si le compte est en région US, le stockage est un transfert ; tout accès depuis New York (direction, responsables de dépôt, analyste) l'est aussi. Ce texte est l'exemple même d'un texte à surveiller : son invalidation changerait l'hébergement.
- **Action** : vérifier la région du compte et la certification DPF de Snowflake Inc. (liste officielle : https://www.dataprivacyframework.gov) ; à signaler à la direction.

### Fiche 7 — La conservation des relevés de paie dans l'État de New York

- **Source** : New York State Labor Law, § 195 (4) et 12 NYCRR (réglementations du NYS Department of Labor) — obligation de tenir les relevés de paie (heures travaillées, rémunération) ; https://dol.ny.gov
- **Date** : texte en vigueur · consulté le 03/11/2026 (à faire valider par un juriste américain)
- **Ce que dit le texte** : l'employeur conserve les relevés de paie de chaque salarié **au moins six ans**.
- **Ce que cela change pour notre entrepôt** : R1 supprime toutes les données d'un chauffeur 5 ans après son départ, y compris ses services (`RAW.DRIVER_SHIFTS` : heures, recettes). Si ces relevés servent de justificatifs de paie, l'obligation new-yorkaise de 6 ans pourrait l'emporter. Le RGPD permet de garder une donnée pour respecter une obligation légale (art. 6.1 c, 17.3 b), à condition de l'archiver à part.
- **Action** : à signaler à la direction (section 5) ; on applique R1 telle qu'écrite dans le brief.

## 4. Le contrat face aux textes

| Règle du contrat | Ce que disent les textes | Source | Conforme ? | Écart et proposition |
|---|---|---|---|---|
| **Préambule : décisions prises par la direction de Hudson Cab Partners** | Le responsable du traitement est celui qui décide : désormais Hudson Cab Europe. Il doit tenir un registre, choisir une base légale par finalité, informer les salariés. | RGPD art. 4.7, 6, 13, 30 | **Non** | Le contrat est antérieur au transfert : il ne cite pas le RGPD, ne nomme ni responsable, ni finalité, ni base légale. **Proposition** : faire valider le contrat par Hudson Cab Europe (et son DPO) ; finalités proposées : paie (base : contrat de travail, art. 6.1 b, et obligations légales, art. 6.1 c), organisation des dépôts (contrat, art. 6.1 b), pilotage de l'activité (intérêt légitime, art. 6.1 f). |
| **R1 : suppression 5 ans après la fin du contrat** | Le RGPD ne fixe pas de durée : elle doit être justifiée. La CNIL distingue base active (durée du contrat) et archivage intermédiaire (après le départ, accès restreint). 5 ans = durée du registre unique du personnel (droit français) ; New York impose 6 ans pour les relevés de paie. | RGPD art. 5.1 e ; référentiel CNIL 2019, section 7 ; C. trav. R. 1221-26 ; NYLL § 195 | **Partiellement** | **Écart principal** : pendant 5 ans, un chauffeur parti reste dans la base active, visible des responsables de dépôt et de l'analyste comme un chauffeur en poste (110 chauffeurs partis sur 400). **Proposition** : sortir les chauffeurs partis de la base active (filtre `is_active` ajouté à la politique de lignes pour les responsables de dépôt, ou table d'archive lisible seulement par `RH_PAIE`) ; justifier les 5 ans par une finalité écrite ; faire trancher la durée des services (6 ans à New York ?). |
| **R2 : Time Travel limité à 1 jour** | Une donnée supprimée doit l'être réellement. Snowflake garde en plus **7 jours de Fail-safe** sur une table permanente, non réductibles et non lisibles par le client. | RGPD art. 5.1 e, 17 ; documentation Snowflake (Fail-safe) | **Partiellement** | La suppression effective prend 1 + 7 = **8 jours**, pas 1. **Proposition** : l'écrire dans le registre ; le Fail-safe n'est accessible qu'au support Snowflake (sous-traitant), ce qui est acceptable si c'est documenté. Alternative : tables `TRANSIENT` (pas de Fail-safe), au prix de la perte de cette protection. |
| **R3 : fichier RH retiré du stage** | Minimisation : pas de copie inutile ; sécurité. | RGPD art. 5.1 c, 32 | **Oui** | `PURGE = TRUE` dans `COPY INTO`. Le fichier reste aussi sur le poste qui l'a déposé : à supprimer après chargement, jamais dans le dépôt Git. |
| **Matrice des accès (qui voit quoi)** | Accès limité aux personnes qui en ont besoin, par défaut. | RGPD art. 5.1 c, 25.2, 32 | **Oui, avec réserves** | Conforme dans l'esprit (masquage par défaut, admin masqué, analyste sans identifiant direct, année de naissance seule). Réserves : `RH_PAIE` voit « tout », y compris la date de naissance et la licence, dont la paie n'a pas forcément besoin ; le dépôt de **Brooklyn** n'a aucun responsable (ses 117 chauffeurs ne sont visibles que de la paie) ; les chauffeurs partis restent visibles (voir R1). |
| **Licence TLC visible de la paie seulement** | Le numéro de licence est publié par la TLC (open data) avec le nom du titulaire : c'est un identifiant direct. | RGPD art. 4.1 | **Oui** | Une donnée publique reste une donnée personnelle : le masquage pour les responsables et l'analyste est justifié. |
| **Règles de qualité (section 6)** | Les données doivent être exactes et tenues à jour ; les inexactes rectifiées sans tarder. | RGPD art. 5.1 d, 16 | **Partiellement** | Les règles mesurent, mais personne n'est chargé de corriger : 7 e-mails invalides, 12 téléphones manquants, 4 licences en double, 5 contrats aux dates incohérentes. **Proposition** : désigner le service RH comme destinataire des alertes et responsable de la rectification. |
| **Absent du contrat** | Information des salariés, droits d'accès / rectification / effacement, registre, sécurité, transferts. | RGPD art. 13, 15 à 17, 30, 32, 44 | **Non** | **Proposition** : compléter par le registre (`REGISTRE.md`) ; prévoir une procédure pour répondre à une demande d'accès d'un chauffeur (requête par `driver_id` sur les quatre tables). |

Les écarts sont reportés dans le `README.md`, section « Gouvernance ».

## 5. Ce que la veille ne tranche pas

| Question | À qui la poser |
|---|---|
| Hudson Cab Partners (New York) est-elle responsable conjointe avec Hudson Cab Europe (art. 26), puisqu'elle a fixé les règles et reçoit les analyses ? | DPO de Hudson Cab Europe, juriste RGPD |
| La durée de 5 ans (droit du travail français) est-elle la bonne pour des contrats de travail new-yorkais, alors que New York impose 6 ans pour les relevés de paie ? | Conseil juridique du groupe (droit du travail new-yorkais) |
| Le suivi mensuel de l'activité et de la recette par chauffeur (`MART_DRIVER_MONTHLY`) est-il une surveillance des salariés qui exige une analyse d'impact (AIPD, art. 35) ? | DPO, CNIL (liste des traitements soumis à AIPD) |
| Quelle base légale pour le pilotage de l'activité par l'analyste : intérêt légitime (art. 6.1 f), avec quelle mise en balance ? | DPO |
