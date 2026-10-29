---
name: e2e
description: Lancer, diagnostiquer et écrire des tests E2E navigateur (Playwright, Cypress, WebdriverIO). À utiliser quand un dépôt a une config Playwright/Cypress, ou quand il est question de tests E2E, d'instabilités (flakes), ou de couvrir un parcours UI. S'adapte aux conventions du dépôt.
---
# Tests E2E navigateur

Si `.claude/nabc.json` existe, les commandes de référence sont `commands.e2e_smoke` (parcours de référence) et `commands.e2e_full` (suite complète).

## Phase 0 — Connaître le terrain (obligatoire)

**Ne jamais écrire ni diagnostiquer avant** d'avoir lu :

1. **La config du runner** (`playwright.config.*`, `cypress.config.*`, `wdio.conf.*`) : `baseURL`, dossier des specs, `webServer` ou prérequis externes, `globalSetup` / `globalTeardown`, état d'authentification (storageState), workers / parallélisme / relances, reporter.
2. **Les helpers du dépôt** (`helpers/`, `support/`, `fixtures/` à côté des specs). Ne **jamais** réinventer ce qui existe.
3. **Un spec existant, en entier** : c'est la source de vérité des conventions (préambule, sélecteurs, setup/teardown, appels API depuis un test).
4. **Les scripts dédiés** du `package.json` : les utiliser, ne pas inventer de commandes.
5. **`.gitignore`** : les artefacts (storageState, captures, traces) ne doivent pas être suivis ; sinon, le signaler.

Si l'un manque ou est minimaliste : **le signaler** avant de continuer. Ne pas combler par des valeurs par défaut inventées.

## Mode A — Lancer et diagnostiquer

### Avant tout lancement

- La stack tourne ? (`docker ps`, port ouvert, `curl` sur `baseURL`)
- Les assets front sont buildés ou le serveur de dev tourne ? (un manifeste Vite manquant casse silencieusement la SPA)
- La base de test est dans un état connu ? (commande de seed / reset)
- Aucune autre suite n'utilise la même base en même temps.

Si un prérequis manque, l'expliquer et proposer la commande — ne pas la lancer d'autorité (elle peut perturber une session de dev en cours).

### Démarche de diagnostic (ordre fixe)

1. **Lire le message d'erreur complet** : sélecteur, délai, attendu / reçu, ligne du spec.
2. **Vérifier l'environnement** avant d'accuser le test.
3. **Lire le spec et le helper concernés**, et leur préambule s'il y en a un : le respecter.
4. **Reproduire en mode UI / visible** quand le sélecteur ou le timing semble en cause.
5. **Inspecter les artefacts** : trace, capture, vidéo.
6. **Lire les logs serveur** du moment du lancement.

### Causes d'instabilité fréquentes

| Symptôme | Cause type | Première piste |
|---|---|---|
| 429 sur la connexion | Limitation de débit de l'authentification | Réutiliser un storageState déjà connecté au lieu de se reconnecter à chaque test ; réinitialiser le cache de limitation |
| CSRF manquant / 419 sur les POST | Jeton pas encore propagé, ou rechargement qui le change | Naviguer sur l'origine de l'appli avant d'appeler l'API ; préférer `page.evaluate(fetch)` à `page.request` pour une SPA à session |
| Données d'un test précédent | Pas d'isolation entre scénarios | Réinitialisation en `beforeEach`, ou entités uniques par test |
| Cache applicatif périmé | Le cache survit au vidage de la base | Purger la clé explicitement, ou changer d'identifiant entre tests |
| Sélecteur instable | Texte ou classe CSS modifiés | `getByRole` / `getByLabel` / `data-testid` plutôt que des sélecteurs CSS |
| Délai dépassé sur navigation | Serveur pas prêt, ou route lente | Vérifier le service ; délai local plutôt que global |
| Passe seul, échoue en suite | Couplage d'ordre | Découpler : chaque spec est autonome |
| Échecs aléatoires sur la base | Suite backend ou autre worktree sur la même base | Une base par worktree (`worktree.db_per_worktree`), ou suites en séquence |
| Page blanche chez certains utilisateurs | Bloqueur de traqueurs qui coupe un module nommé `analytics`, `tracking`… | Test qui bloque `/analytics\|posthog/i` ; chargement dynamique des SDK avec `catch` |

## Mode B — Écrire un spec

### Les dix règles

1. **Lire un spec existant en entier** avant d'écrire, et reprendre son modèle.
2. **Préambule** au-dessus de chaque `describe` : périmètre **et** ce qui est volontairement exclu, avec le pourquoi.
3. **Réutiliser les helpers du dépôt** : connexion, création d'entités par API, réinitialisation.
4. **Sélecteurs sémantiques** : `getByRole`, `getByLabel`, `getByPlaceholder`, `data-testid`.
5. **Préparer par l'API, vérifier par l'interface.** Plus déterministe que traverser six écrans pour atteindre l'état voulu.
6. **Pas de `page.goto` ni de `reload` après la connexion.** Un rechargement rafraîchit les jetons CSRF et de session et masque les bugs « ça marche après F5 ». Après connexion, on navigue par l'interface, comme un utilisateur.
7. **Un test = un comportement.**
8. **Délais explicites sur les assertions sensibles** (navigation, résultat d'une action) — pas de délai global magique.
9. **Pas de `test.only`.**
10. **Pas de `test.skip` silencieux** : toujours commenter pourquoi, avec une TODO.

### Données de test

- **Impossibles à confondre avec du réel** : identifiants hors plage (`99999`), e-mails en `.test` (domaine réservé, jamais délivrable), noms explicites (`Entreprise Test E2E`). Une donnée de test ne doit jamais pouvoir écrire à un vrai client ni ressembler à une vraie fiche.
- **Par l'API** (helper du dépôt) : à préférer.
- **Par une commande de seed** : pour les fixtures réutilisables.
- **Par l'interface** : uniquement quand le parcours est l'objet du test.
- **Par insertion SQL depuis le spec** : **interdit**. Si l'API ou la CLI ne le permet pas, créer ou étendre une commande backend dédiée.

### Quoi tester en E2E

1. **Le parcours de référence** et le chemin nominal de chaque parcours critique — toujours.
2. **Un ou deux cas limites prioritaires** : état vide, erreur d'API gérée, droits insuffisants.
3. **Les régressions historiques** : un test par bug critique passé en production.

Pas en E2E : la validation détaillée des formulaires, toutes les permutations d'une liste, un composant isolé. Les E2E coûtent cher ; ils servent à voir ce que les autres niveaux ne voient pas.

## Mode C — Après une fonctionnalité avec impact UI

1. Identifier les parcours touchés (lecture du diff).
2. Chercher un spec existant qui les couvre.
3. **Proposer** (ne pas écrire d'autorité) : le chemin nominal, un ou deux cas limites, les helpers à étendre.
4. Attendre l'accord, écrire, lancer le spec ciblé, rapporter.

## Garde-fous

- Ne jamais désactiver `globalSetup` ou équivalent.
- Ne jamais commiter storageState, cookies ou état d'authentification.
- Ne jamais écrire de test qui dépend de l'ordre d'exécution.
- Ne jamais contourner la limitation de débit en désactivant le middleware : corriger la cause.
- Si un spec casse sur une fonctionnalité en cours de refactoring : **en parler** avant de « réparer » ; c'est peut-être une vraie régression.

## Sortie attendue

- **Diagnostic** : cause racine, correction proposée ou appliquée, commande de validation.
- **Écriture** : spec créé, commande pour le lancer, résultat.
- **Lancement seul** : réussites / échecs, rapport HTML si échec, causes probables si instabilité.

Si le dépôt a ses propres conventions E2E, **elles priment** sur celles-ci. Règle d'or : lire le code existant avant d'écrire.
