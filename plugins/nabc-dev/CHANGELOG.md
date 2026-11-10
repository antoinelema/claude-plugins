# Changelog

## Non publiée

- `init` : seconde règle d'architecture (l'application ne dépend pas de l'infrastructure), template PHPat et règle dependency-cruiser ; relevé des dépendances par couche, ADR du découpage des couches en brouillon depuis `templates/adr/` avec arrêt pour qu'Antoine tranche, violations existantes en baseline, preuve qu'une fuite injectée est bloquée.
- `check-file` : `commands.check_files` (liste `{glob, command}`), toutes les analyses correspondantes sont lancées ; l'ancien couple `check_file` / `check_file_glob` reste lu ; `{relfile}` donne le chemin depuis la racine pour les outils en conteneur (Sail). Preset Laravel : PHPStan sur le PHP et ESLint sur le front, gate `composer gate && npm run gate` ; `init` pose une baseline pour que la dette existante ne rende pas la gate rouge.
- Skill `crap` et `scripts/crap.py` : score CRAP (`CC² × (1 − couverture)³ + CC`) par méthode, pire en tête, avec l'action conseillée (couvrir jusqu'à N % ou découper quand CC dépasse le seuil). Sources fusionnées : Clover de PHPUnit (PHP, chemins de conteneur ramenés au projet) et [unclebob/crapper](https://github.com/unclebob/crapper) épinglé par commit (TS/JS, Python, Go…). `--changed` limite aux fichiers modifiés depuis la base. Section `crap` dans les presets ; branchée dans `verify` et `maintenance`.
- Skill `secrets-audit` : audit avant push sur tout l'historique — gitleaks (image Docker si absent), recherche des vraies valeurs du `.env` (le scanner ne voit que des motifs), en écartant d'abord les placeholders identiques au `.env.example`, fichiers sensibles, données personnelles ; distingue fuite déjà publiée (rotation) et locale (retrait avant push). Appelée par `finish`.
- Guard : la session principale ne modifie plus les tests d'acceptance (contournement explicite : `NABC_ALLOW_ACCEPTANCE_EDIT=1` au lancement). Le champ `agent_type` a été vérifié sur un payload réel (Claude Code 2.1.312) : présent dans un sous-agent, absent de la session principale.
- Tests : fixtures `tests/fixtures/payloads/` tirées de payloads PreToolUse réels.

## 0.1.0 — non publiée

- Squelette du plugin et marketplace `nabc`.
- Hooks : `session-start`, `guard`, `check-file`, `stop-gate`, avec tests bats.
- Agents : `spec-analyst`, `test-writer`, `implementation-planner`, `code-implementer`, `code-reviewer`, `code-refactorer`, `doc-researcher`.
- Skills : `init`, `feature`, `spec`, `acceptance`, `plan`, `implement`, `verify`, `review`, `finish`, `parallel`, `context-audit` ; `maintenance` et `e2e` migrées depuis `~/.claude/skills/`.
- Templates : `CLAUDE.md`, spec, presets (laravel, nextjs, flutter, astro), règles d'architecture (PHPat, dependency-cruiser), CI GitHub Actions.
