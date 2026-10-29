# Changelog

## Non publiée

- Guard : la session principale ne modifie plus les tests d'acceptance (contournement explicite : `NABC_ALLOW_ACCEPTANCE_EDIT=1` au lancement). Le champ `agent_type` a été vérifié sur un payload réel (Claude Code 2.1.312) : présent dans un sous-agent, absent de la session principale.
- Tests : fixtures `tests/fixtures/payloads/` tirées de payloads PreToolUse réels.

## 0.1.0 — non publiée

- Squelette du plugin et marketplace `nabc`.
- Hooks : `session-start`, `guard`, `check-file`, `stop-gate`, avec tests bats.
- Agents : `spec-analyst`, `test-writer`, `implementation-planner`, `code-implementer`, `code-reviewer`, `code-refactorer`, `doc-researcher`.
- Skills : `init`, `feature`, `spec`, `acceptance`, `plan`, `implement`, `verify`, `review`, `finish`, `parallel`, `context-audit` ; `maintenance` et `e2e` migrées depuis `~/.claude/skills/`.
- Templates : `CLAUDE.md`, spec, presets (laravel, nextjs, flutter, astro), règles d'architecture (PHPat, dependency-cruiser), CI GitHub Actions.
