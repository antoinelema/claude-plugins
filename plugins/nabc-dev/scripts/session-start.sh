#!/usr/bin/env bash
# SessionStart (and CwdChanged with --env-only): per-worktree test DB,
# start-of-session snapshot, short context for Claude.
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"
has_config || exit 0

# 1. One test database per worktree (parallel agents must not share a DB)
if [[ "$(cfg '.worktree.db_per_worktree')" == "true" && -n "${CLAUDE_ENV_FILE:-}" ]]; then
  var="$(cfg '.worktree.db_env_var')"
  prefix="$(cfg '.worktree.db_prefix')"
  if [[ -n "$var" ]]; then
    name="${prefix}$(basename "$ROOT" | tr -c 'a-zA-Z0-9_\n' '_')"
    echo "export ${var}=${name}" >> "$CLAUDE_ENV_FILE"
  fi
fi

[[ "${1:-}" == "--env-only" ]] && exit 0

# 2. Start snapshot, so the Stop gate knows whether the session changed code
snapshot > "$STATE_DIR/$SESSION_ID.start"
rm -f "$STATE_DIR/$SESSION_ID.attempts"

# 3. Short context (plain stdout is added to Claude's context)
echo "Projet configuré avec nabc-dev (stack : $(cfg '.stack'))."
gate="$(cfg '.commands.gate')"
[[ -n "$gate" ]] && echo "Gate de qualité : \`$gate\` (lancée automatiquement en fin de tâche)."
smoke="$(cfg '.commands.e2e_smoke')"
[[ -n "$smoke" ]] && echo "Parcours de référence à lancer pour vérifier que le produit fonctionne (« Green is not working ») : \`$smoke\`."
echo "Specs : $(cfg '.paths.specs'). Tests d'acceptance : $(cfg '.paths.acceptance_tests') — modifiés uniquement via /nabc-dev:acceptance."
exit 0
