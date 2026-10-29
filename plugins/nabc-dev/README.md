# nabc-dev

```bash
/plugin marketplace add <compte-github>/claude-plugins
/plugin install nabc-dev@nabc
```

Méthode de développement Not a Bad Company, partagée par tous les projets : spec BDD → tests d'acceptance écrits avant le code → plan → implémentation → vérification déterministe → revue contre la spec → livraison. La relecture et la fusion restent humaines.

Le plugin est générique : il lit la configuration de chaque projet dans `.claude/nabc.json`. Sans ce fichier, aucun hook n'agit.

## Utilisation

| Commande | Rôle |
|---|---|
| `/nabc-dev:init [stack]` | Configure un projet : `nabc.json`, `CLAUDE.md`, règle d'architecture, script gate, CI |
| `/nabc-dev:feature <besoin>` | Chaîne complète avec arrêts de validation : spec → tests d'acceptance → plan → implémentation → vérification → revue → livraison |
| `/nabc-dev:spec`, `acceptance`, `plan`, `implement`, `verify`, `review`, `finish` | Chaque étape isolée |
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
| `PostToolUse` | `check-file.sh` | Analyse statique du fichier modifié (`commands.check_file`), erreurs renvoyées à Claude |
| `Stop` | `stop-gate.sh` | Si la session a modifié le dépôt : lance `commands.gate`. Rouge → Claude continue. Après `gate.max_attempts` échecs → « intervention manuelle requise » |

Dépendances : `bash`, `jq`, `git`, `realpath` (GNU coreutils).

## Configuration d'un projet

`.claude/nabc.json` (généré par `/nabc-dev:init` à partir d'un preset de `templates/presets/`) :

```json
{
  "stack": "laravel",
  "paths": { "specs": "docs/specs", "acceptance_tests": "tests/Acceptance", "test_dirs": ["tests", "e2e"] },
  "commands": { "check_file": "vendor/bin/phpstan analyse --no-progress --error-format=raw {file}", "check_file_glob": "\\.php$", "gate": "composer gate" },
  "git": { "protected_branches": ["main", "production"], "blocked_commands": [] },
  "worktree": { "db_per_worktree": true, "db_env_var": "DB_DATABASE", "db_prefix": "testing_" },
  "gate": { "max_attempts": 3 }
}
```

## Tests

```bash
bats tests/
shellcheck -x -P scripts scripts/*.sh
claude plugin validate . --strict
```
