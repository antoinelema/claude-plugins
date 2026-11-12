---
name: init
description: Configurer un projet pour la méthode NABC — nabc.json depuis un preset, CLAUDE.md, règle d'architecture, script gate, CI, dossiers specs et ADR.
argument-hint: [laravel|nextjs|flutter|astro]
disable-model-invocation: true
---
Stack demandée : $ARGUMENTS

Les templates sont dans `../../templates/` (relatif au dossier de cette skill).

**Règle absolue : ne remplace rien d'existant sans montrer le diff et obtenir l'accord d'Antoine.** Pour un fichier existant, propose une fusion, pas un écrasement.

1. **Stack** — si elle n'est pas donnée, détecte-la : `composer.json` avec `laravel/framework` → laravel ; `package.json` avec `next` → nextjs ; `astro` → astro ; `pubspec.yaml` → flutter. En cas de doute, demande.
2. **`.claude/nabc.json`** — copie `templates/presets/<stack>.json`, puis ajuste chaque chemin et chaque commande à la réalité du projet : vérifie que les dossiers existent, que les outils sont installés (PHPStan, Pest/PHPUnit, Infection, ESLint, Playwright…) et la commande d'exécution (Sail, Docker, npm/pnpm/bun). Pour un projet Laravel avec `./vendor/bin/sail`, préfixe les commandes PHP par Sail et remplace `{file}` par `{relfile}` (le conteneur ne voit pas le chemin de l'hôte). Une commande dont l'outil manque reste vide et va dans la liste « à installer ». Section `crap` : vérifier le pilote de couverture PHP (`php -m | grep pcov`, dans Sail si Sail), `uv` pour la source `crapper`, ajuster les dossiers `-s` ; front Vitest : `@vitest/coverage-v8` en devDependency à la version exacte de Vitest installée (sinon `crap.py` refuse la source, voir la skill `crap`) ; retirer une source sans objet (pas de front JS) ; ajouter `.metrics/` au `.gitignore`.
3. **Règles d'architecture** — deux règles, et la décision qui les fonde :
   - **Relevé** : par couche, nombre de fichiers qui dépendent de l'infrastructure ou d'un accès direct à la base (`grep` des imports), daté. Repère où vivent les cas d'usage et les adaptateurs d'entrée (contrôleurs, commandes, jobs, tools MCP) : un même rôle à plusieurs endroits est à signaler.
   - **ADR** : `docs/adr/<AAAA-MM-JJ>-decoupage-des-couches.md` depuis `templates/adr/decoupage-des-couches.md.tpl`, rempli avec le relevé, au statut **brouillon**. **ARRÊT : Antoine tranche les questions de l'ADR** (où va un cas d'usage, quels dossiers sont des adaptateurs) avant d'écrire la règle de l'application ; l'ADR passe alors au statut « acceptée ».
   - **Règle du domaine** — laravel : `templates/arch/phpat-domain-rule.php` ; nextjs : `templates/arch/dependency-cruiser.cjs` (règle `domain-independant`). Adaptée aux namespaces ou dossiers réels.
   - **Règle de l'application** — laravel : `templates/arch/phpat-application-rule.php`, limitée aux dossiers d'orchestration retenus dans l'ADR ; nextjs : règle `application-sans-infrastructure` du même fichier dependency-cruiser. Les adaptateurs d'entrée restent hors de la règle.
   - Déclarer les règles (laravel : services taggés `phpat.test` dans `phpstan.neon`) et lancer l'analyse. Les violations existantes vont en baseline (laravel : `phpstan analyse --generate-baseline phpstan-baseline.neon`, incluse dans `phpstan.neon` avec un commentaire qui renvoie à l'ADR ; JS : `--output-type baseline` et `--ignore-known`), elles ne sont pas corrigées pendant `init`.
   - **Preuve** : une fuite injectée dans un cas d'usage est bloquée par le hook d'analyse de fichier, et un fichier déjà en baseline, analysé seul, passe. Retirer la fuite.
4. **Script gate** — laravel : script `gate` dans `composer.json` (analyse statique + suites Domain, Application, Acceptance) ; s'il y a un front JS, aussi un script `gate` dans `package.json` (`tsc --noEmit` si `tsconfig.json`, `eslint .`, `vitest run`), sinon retirer `&& npm run gate` et l'analyse front de `check_files`. JS : script `gate` dans `package.json`. Une dette existante (erreurs de types ou de lint déjà là) ne doit pas rendre la gate rouge au premier jour : baseline (PHPStan `--generate-baseline`, ESLint limité aux règles tenues, `tsc` sur les seuls fichiers TS), à rapporter à Antoine. Elle doit rester **rapide** : pas d'E2E ni de mutation. Lance-la et chronomètre-la.
5. **`CLAUDE.md`** — depuis `templates/CLAUDE.md.tpl`. S'il en existe un, propose de le réduire : ce qui est une carte du code (listes de fichiers, chiffres, arborescence) ou une règle vérifiée par un hook en sort.
6. **CI** — `.github/workflows/ci.yml` depuis `templates/ci/github-actions.yml`, avec le setup de la stack et les commandes de `nabc.json`.
7. **Dossiers** — `paths.specs` et `docs/adr/` (avec un `README.md` d'une ligne s'ils sont vides), `paths.acceptance_tests`. Ajoute `.claude/plans/` au `.gitignore`.
8. **Rapport** — fichiers créés / modifiés, commandes vérifiées, outils à installer, violations d'architecture en baseline (par règle, avec les fichiers), questions de l'ADR encore ouvertes, durée de la gate. Propose un commit `chore: configuration nabc-dev`.
