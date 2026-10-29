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
2. **`.claude/nabc.json`** — copie `templates/presets/<stack>.json`, puis ajuste chaque chemin et chaque commande à la réalité du projet : vérifie que les dossiers existent, que les outils sont installés (PHPStan, Pest/PHPUnit, Infection, ESLint, Playwright…) et la commande d'exécution (Sail, Docker, npm/pnpm/bun). Pour un projet Laravel avec `./vendor/bin/sail`, préfixe les commandes PHP par Sail. Une commande dont l'outil manque reste vide et va dans la liste « à installer ».
3. **Règle d'architecture** — laravel : `templates/arch/phpat-domain-rule.php` adapté aux namespaces réels, déclaré dans `phpstan.neon` (service taggé `phpat.test`). nextjs : `templates/arch/dependency-cruiser.cjs` adapté aux dossiers réels. Lance-la une fois : les violations existantes sont rapportées, pas corrigées.
4. **Script gate** — laravel : script `gate` dans `composer.json` (analyse statique + suites Domain, Application, Acceptance). JS : script `gate` dans `package.json`. Elle doit rester **rapide** : pas d'E2E ni de mutation. Lance-la et chronomètre-la.
5. **`CLAUDE.md`** — depuis `templates/CLAUDE.md.tpl`. S'il en existe un, propose de le réduire : ce qui est une carte du code (listes de fichiers, chiffres, arborescence) ou une règle vérifiée par un hook en sort.
6. **CI** — `.github/workflows/ci.yml` depuis `templates/ci/github-actions.yml`, avec le setup de la stack et les commandes de `nabc.json`.
7. **Dossiers** — `paths.specs` et `docs/adr/` (avec un `README.md` d'une ligne s'ils sont vides), `paths.acceptance_tests`. Ajoute `.claude/plans/` au `.gitignore`.
8. **Rapport** — fichiers créés / modifiés, commandes vérifiées, outils à installer, violations d'architecture existantes, durée de la gate. Propose un commit `chore: configuration nabc-dev`.
