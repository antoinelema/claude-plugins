# nabc-dev

```bash
/plugin marketplace add antoinelema/claude-plugins
/plugin install nabc-dev@nabc
```

Méthode de développement Not a Bad Company, partagée par tous les projets : spec BDD → tests d'acceptance écrits avant le code → plan → implémentation → vérification déterministe → revue contre la spec → livraison. La relecture et la fusion restent humaines.

Schéma d'utilisation (couches, chaîne d'une fonctionnalité, hooks, paliers de délégation) : [`docs/schema.html`](docs/schema.html), à ouvrir dans un navigateur, ou en ligne sur https://claude.ai/artifact/DFG6mnynhpQRq97zCT8xD6 (privé). À mettre à jour quand une étape, un hook ou une skill change.

Le plugin est générique : il lit la configuration de chaque projet dans `.claude/nabc.json`. Sans ce fichier, aucun hook n'agit.

## Utilisation

| Commande | Rôle |
|---|---|
| `/nabc-dev:init [stack]` | Configure un projet : `nabc.json`, `CLAUDE.md`, règle d'architecture, script gate, CI |
| `/nabc-dev:feature <besoin>` | Chaîne complète avec arrêts de validation : spec → tests d'acceptance → plan → implémentation → vérification → revue → livraison |
| `/nabc-dev:spec`, `acceptance`, `plan`, `implement`, `verify`, `review`, `finish` | Chaque étape isolée |
| `/nabc-dev:secrets-audit` | Avant un push : secrets et données personnelles sur tout le dépôt et tout l'historique (scanner, vraies valeurs du `.env`, fichiers sensibles), avec la conduite à tenir selon que la fuite est déjà publiée ou non |
| `/nabc-dev:crap [--changed]` | Score CRAP par méthode (complexité × manque de couverture), pire en tête, avec l'action : couvrir ou découper. PHP via le Clover de PHPUnit, TS/JS et autres via [crapper](https://github.com/unclebob/crapper). Appelée par `verify` (fichiers modifiés) et `maintenance` |
| `/nabc-dev:parallel <chantier>` | Lots indépendants, un worktree par agent, fusion validée lot par lot |
| `/nabc-dev:maintenance` | Session de réduction de dette (diagnostic navigateur, réparer → mesurer → couvrir → mutation → auditer → refactorer) |
| `/nabc-dev:context-audit` | Audit mensuel de `CLAUDE.md`, agents et skills du projet |

Les skills de workflow ne se lancent que sur demande. Seule `e2e` peut être invoquée automatiquement par Claude.

Agents (`nabc-dev:<nom>`) : `spec-analyst`, `test-writer`, `implementation-planner`, `code-implementer`, `code-reviewer`, `code-refactorer`, `doc-researcher`.

## Hooks (garanties mécaniques)

| Événement | Script | Effet |
|---|---|---|
| `SessionStart` | `session-start.sh` | Photo de l'état du dépôt, base de test par worktree, court contexte injecté |
| `CwdChanged` | `session-start.sh --env-only` | Réexporte la base de test en entrant dans un worktree |
| `PreToolUse` | `guard.sh` | Bloque `--no-verify` / `commit -n`, push sur branche protégée, `git.blocked_commands`, toute modification des tests d'acceptance hors test-writer (session principale comprise, sauf lancement avec `NABC_ALLOW_ACCEPTANCE_EDIT=1` ; jamais pour l'implémenteur et le refactoreur), le test-writer qui touche au code de production. Plante → action bloquée |
| `PostToolUse` | `check-file.sh` | Analyse statique du fichier modifié : chaque entrée de `commands.check_files` dont le `glob` correspond (plus l'ancien couple `check_file` / `check_file_glob`) ; `{file}` = chemin absolu, `{relfile}` = chemin depuis la racine (outil en conteneur, Sail). Erreurs renvoyées à Claude |
| `Stop` | `stop-gate.sh` | Si la session a modifié le dépôt : lance `commands.gate`. Rouge → Claude continue. Après `gate.max_attempts` échecs → « intervention manuelle requise » |

Dépendances : `bash`, `jq`, `git`, `realpath` (GNU coreutils). Pour `/nabc-dev:crap` : `python3` ≥ 3.10, un pilote de couverture PHP (PCOV), `uv` pour la source crapper.

## Configuration d'un projet

`.claude/nabc.json` (généré par `/nabc-dev:init` à partir d'un preset de `templates/presets/`) :

```json
{
  "stack": "laravel",
  "paths": { "specs": "docs/specs", "acceptance_tests": "tests/Acceptance", "test_dirs": ["tests", "e2e"] },
  "commands": { "check_files": [{ "glob": "\\.php$", "command": "vendor/bin/phpstan analyse --no-progress --error-format=raw {file}" }, { "glob": "\\.(ts|tsx|js|jsx)$", "command": "npx eslint --no-warn-ignored {file}" }], "gate": "composer gate && npm run gate" },
  "git": { "protected_branches": ["main", "production"], "blocked_commands": [] },
  "worktree": { "db_per_worktree": true, "db_env_var": "DB_DATABASE", "db_prefix": "testing_" },
  "gate": { "max_attempts": 3 },
  "crap": {
    "threshold": 30,
    "sources": [
      { "label": "php", "format": "clover", "command": "php -d pcov.enabled=1 vendor/bin/phpunit --coverage-clover .metrics/clover.xml", "report": ".metrics/clover.xml" },
      { "label": "js", "format": "crapper", "command": "uvx --from git+https://github.com/unclebob/crapper@<commit> crapper --root . -s resources/js", "report": ".metrics/crap.edn" }
    ]
  }
}
```

Source `crapper` sur un front Vitest : déclarer `@vitest/coverage-v8` en devDependency **à la version exacte de Vitest**. Sans lui, crapper l'installe par `npm install --no-save --no-package-lock`, qui re-résout tout `node_modules` hors du verrou sans trace dans `git status` ; `crap.py` refuse donc la source tant qu'il manque (sortie 1). Garde-fou général : si une commande de source modifie `node_modules/.package-lock.json`, `crap.py` l'annonce et sort en 3 — lancer `npm ci` avant toute autre vérification.

## Tests

```bash
bats tests/
shellcheck -x -P scripts scripts/*.sh
claude plugin validate . --strict
```
