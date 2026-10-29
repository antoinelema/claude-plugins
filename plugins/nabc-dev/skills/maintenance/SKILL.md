---
name: maintenance
description: Session de maintenance / réduction de dette technique sur un code existant. Diagnostic avec contrôles d'usage réel en navigateur, puis réparer → mesurer → couvrir → mutation → auditer → refactorer → externaliser la config, avec un critère d'acceptation à chaque étape. À lancer après une phase de rush feature ou quand la suite de tests dérive.
disable-model-invocation: true
---
# Maintenance

## Green is not working

Tests unitaires, analyse statique et lint ne font jamais tourner le produit comme un utilisateur. Une session qui ne mesure qu'eux peut finir « tout vert » avec l'application cassée dans le navigateur : POST rejetés après connexion, page blanche sous bloqueur de pub, inscription qui ne redirige jamais, mot de passe en clair dans les logs. **Le diagnostic inclut toujours les contrôles d'usage réel (phase 0b), et rien n'est déclaré sain sans eux.**

Lis d'abord `.claude/nabc.json` : les commandes (`gate`, `mutation`, `e2e_smoke`, `e2e_full`) et les chemins viennent de là.

## Principes

1. **Réparer avant de mesurer** — une suite rouge cache les vrais trous de couverture.
2. **Mesurer avant de refactorer** — on ne refactore jamais du code non couvert.
3. **Les tests d'abord, la prod ensuite** — découper des tests est sans risque et prépare la suite.
4. **Une responsabilité par phase** — ne pas mélanger « réparer les tests » et « refactorer » dans un même commit.
5. **Le comportement est sacré** — tout refactoring préserve le comportement à l'identique ; la suite de tests est le contrat.
6. **Ne pas déléguer la compréhension** — un agent reçoit des chemins, des contraintes exactes et un critère de fin, jamais « répare les tests ».

## L'échelle

Dans l'ordre. Chaque phase a un critère d'acceptation : on ne passe pas à la suivante sans lui.

### Phase 0 — Diagnostic (toujours)

En parallèle, dans un même message : suites backend, suites frontend, vérification de types, lint, gate.

Relever : réussites / échecs par suite, échecs regroupés par signature identique, fichiers les plus longs.

#### Phase 0b — Contrôles d'usage réel (toujours, après le lot parallèle)

**En séquence, jamais en même temps que la suite backend** si elles partagent la même base (les verrous font échouer des specs saines).

1. **Suite E2E** (`commands.e2e_full`), lancée depuis l'endroit prévu par le projet (hôte ou conteneur : lire la config du runner).
2. **Parcours de référence d'abord** (`commands.e2e_smoke`) : le spec qui rejoue un nouvel utilisateur de bout en bout (inscription → action principale → geste qui crée la valeur). S'il n'existe pas, l'écrire est la première tâche de la session. Rouge ici passe avant tout le reste.
3. **Pas de rechargement après authentification.** Le parcours n'appelle jamais `page.goto` / `reload` après connexion ou inscription : un rechargement rafraîchit les jetons CSRF et de session et masque tous les bugs « ça marche après F5 ». Une SPA (Inertia, Next, Vue Router) reste en navigation côté client, comme un utilisateur.
4. **Résistance aux bloqueurs de traqueurs.** Les bloqueurs coupent les URL contenant `analytics`, `tracking`, `posthog`, `gtag`, `segment`… y compris les noms de vos propres modules en dev. Vérifier : un test E2E qui bloque `/analytics|posthog/i` et constate que l'appli démarre ; aucun module importé statiquement dont le nom contient ces mots ; SDK d'analytics chargés par `import()` dynamique avec un `catch`.
5. **Secrets dans les logs.** Après le parcours joué avec un mot de passe de test connu, chercher ce mot de passe dans les logs. Toute occurrence est un constat de sécurité. Chercher aussi dans le code les logs qui reçoivent la requête ou les données entières près de la validation d'identifiants.
6. **Chaque formulaire aboutit.** Pour chaque envoi du parcours, vérifier le résultat visible (redirection, message, erreur), pas seulement le statut HTTP ou la ligne en base.
7. **Erreurs signalées par l'utilisateur et non reproductibles en headless** : inspecter son vrai navigateur (Claude in Chrome ou chrome-devtools) — extensions, onglets périmés, fichier `hot` du serveur de dev supprimé après un build. Ne pas conclure « chez moi ça marche ».

Relever : résultat E2E, résultat du parcours de référence, une ligne par contrôle (OK / constat).

Critère : aucun. Mesure pure.

### Phase 1 — Réparer (échecs → 0)

- Regrouper les échecs par signature de symptôme, pas par fichier : souvent une seule cause racine (signature modifiée, URL de mock, changement de portée).
- `git log -p` sur les fichiers de production cités : un commit récent explique en général la dérive.
- Préférer **aligner les tests sur la production actuelle** plutôt que revenir sur la production : c'est elle qui tourne. Exception : les tests d'acceptance encodent la spec ; s'ils échouent, c'est la production qui a tort, ou la spec qui doit être rediscutée avec Antoine.
- Pour un gros groupe d'échecs à cause unique : un agent d'analyse, puis `nabc-dev:code-implementer` pour la correction.

Critère : **0 échec**, suite verte du premier coup sans option — **E2E compris**, parcours de référence en premier, chaque constat de la phase 0b corrigé ou explicitement reporté par Antoine. Un spec instable n'est pas « vert » : le relancer seul ; s'il passe seul, le noter comme instabilité connue avec sa cause.

Pour chaque défaut corrigé, prouver que le test l'attrape : annuler la correction, voir le test rougir, restaurer. Un test qui reste vert sur le code cassé ne garde rien.

Un commit par cause racine.

### Phase 2 — Mesurer la couverture

Outils : PCOV pour PHP (bien plus rapide que Xdebug), `@vitest/coverage-v8` ou `--coverage` pour JS, `pytest --cov` pour Python.

Produire une liste classée par **risque × couverture actuelle** :

| Classe | Lignes % | Méthodes % | Risque (financier / sécurité / données) |
|---|---|---|---|

Critère : rapport trié par (lignes manquantes × risque) décroissant.

### Phase 3 — Couvrir la logique métier

Objectif : chaque classe à logique non triviale à ≥ 95 % des lignes et 100 % des méthodes.

Logique métier : domaine, cas d'usage, services, adaptateurs, jobs, listeners, contrôleurs, notifications. **Exclus** : validation déclarative, modèles triviaux, enums triviaux, code généré par le framework.

- **Paralléliser par classe**, un worktree par agent (voir `/nabc-dev:parallel`), en `nabc-dev:test-writer` : le hook lui interdit le code de production. Le contrat : « le code de production est la source de vérité ».
- Simuler tous les appels HTTP externes et SDK tiers.
- Utiliser en priorité les factories du domaine quand elles existent.
- Branches défensives mortes (gardes derrière une validation, bras de `match` inatteignables) : les documenter par un commentaire au lieu de forcer des chemins artificiels.

Critère : chaque classe visée ≥ 95 % lignes, 100 % méthodes ; suite toujours verte. Un commit par groupe de classes.

### Phase 4 — Mutation

La couverture dit qu'une ligne a été exécutée, pas qu'un test échouerait si elle changeait.

- Lancer `commands.mutation` sur le domaine et la couche application.
- Pour chaque mutant survivant significatif : ajouter ou renforcer l'assertion qui le tue (test unitaire, pas d'acceptance). Un mutant équivalent (sans effet observable) est noté comme tel.
- Ne jamais baisser le seuil configuré pour passer.

Critère : score de mutation au-dessus du seuil de la commande ; survivants restants listés avec leur raison.

### Phase 5 — Audit clean code (lecture seule)

Deux audits en parallèle (`nabc-dev:code-reviewer` ou agents en lecture seule) :

1. **Production** : plus gros fichiers, méthodes longues, complexité élevée, imbrication profonde, duplication, chaînes magiques, objets-dieux, logique métier hors du domaine.
2. **Tests** : fichiers monolithiques, blocs de mocks dupliqués, chaînes de factories en ligne, données magiques.

Rapport : **critique** (à refactorer tout de suite), **majeur** (bientôt), **mineur** (confort) ; pour chaque constat `fichier:ligne`, la mesure, et l'extraction concrète proposée.

**ARRÊT : présenter à Antoine.** Il choisit ce qui est refactoré. Pas de refactoring automatique après l'audit.

### Phase 6 — Refactorer, en quatre sous-phases

Dans cet ordre, suite verte entre chaque. Agent : `nabc-dev:code-refactorer` (ne touche pas aux tests d'acceptance).

1. **Découper les fichiers de test monolithiques** par scénario. Créer d'abord, en séquence, les supports partagés (TestCase de domaine avec constantes, un trait par API externe simulée, builders non persistés) ; puis un agent par fichier source, qui garde chaque méthode de test (renommer oui, supprimer non), remplace mocks et chaînes magiques par les supports, et supprime le monolithe. Critère : même nombre de tests, tous verts, plus de mocks dupliqués.
2. **Chaînes magiques → enums** (enums typés PHP, unions littérales TS, StrEnum Python). Cast ORM là où l'ensemble de valeurs est fermé ; les réponses HTTP continuent d'émettre des chaînes ; le schéma de base ne change pas. Critère : valeurs identiques octet pour octet ; suite verte.
3. **Extraire les points chauds** retenus à l'audit : méthodes longues → collaborateurs dédiés ; séquences répétées → flux partagé ; cascades `if/elseif` par plateforme → stratégie avec registre ; méthodes-dieux → pipeline d'étapes. Un agent par point chaud, en worktree ; comportement identique, tests existants inchangés ; la classe d'origine délègue ; nouveau collaborateur couvert comme en phase 3. Critère : complexité par méthode ≤ 10, tests verts.
4. **Externaliser la configuration** : constantes de données volumineuses → fichiers de config ; prompts et gabarits multilignes → vues / templates ; délais et limites magiques → clés de config. Critère : les services perdent leurs données en ligne ; tests verts.

## Parallélisation

- Un worktree par agent (voir `/nabc-dev:parallel`). Au-delà d'une dizaine d'agents, la coordination et la contention de base dominent.
- Base de test partagée entre worktrees → interblocages et tables manquantes. Parade : `worktree.db_per_worktree` dans `nabc.json`, ou worktrees en série quand les tests réinitialisent la base.
- Le conteneur monte souvent le checkout principal, pas le worktree : vérifier que le contenu final est bien là où on l'attend avant de déclarer un lot terminé.

## Rapport de session

Toujours finir par `docs/maintenance-<AAAA-MM>.md` :

- métriques avant / après (tests, couverture, score de mutation, tailles de fichiers) ;
- résultats de la phase 0b : E2E, parcours de référence, une ligne par contrôle ;
- causes racines de chaque groupe d'échecs, avec les commits ;
- classes couvertes, et classes restées sous le seuil avec la raison ;
- pour chaque phase : fait, pas fait, pourquoi ;
- pistes restantes.

C'est LE document de référence au prochain passage sur ce code.

## Anti-patterns

- **Déclarer le code sain sur la seule analyse statique** : sauter la phase 0b, c'est livrer une connexion cassée dans une session « propre ».
- **Lancer la suite backend et la suite E2E en même temps** sur une base partagée : les échecs sont des verrous, pas des bugs.
- **Refactorer du code non couvert** : phase 6 avant phase 3 = chirurgie à l'aveugle.
- **Découper des tests ET ajouter de la couverture dans le même commit.**
- **Refactorer sans accord après l'audit.**
- **Toucher à la production dans une tâche de couverture** : le contrat devient ambigu.
- **Oublier `git status` après la fusion de lots parallèles** : fichiers parasites, artefacts, copies miroir de worktree.
- **Enterrer un problème d'environnement récurrent dans un commit de maintenance** : le suivre à part.

## À quoi ressemble la réussite

- Suite verte avant fusion, E2E compris.
- Parcours de référence rejoué de bout en bout dans un navigateur, sans rechargement après connexion, et vert.
- L'appli démarre avec les analytics bloqués ; aucun identifiant dans les logs après le parcours.
- Classes visées couvertes au seuil ; score de mutation au-dessus du seuil.
- Pas de méthode à complexité > 10, pas de fichier de test monolithique, pas de chaîne magique pour les statuts.
- Un `docs/maintenance-AAAA-MM.md` qui relie chaque commit à son objectif.
