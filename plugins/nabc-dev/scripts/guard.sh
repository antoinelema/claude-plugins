#!/usr/bin/env bash
# PreToolUse guard: blocks verification bypasses, pushes to protected branches,
# project-blocked commands, and edits outside each agent's allowed scope.
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"
# Fail closed: if this script crashes, the tool call is blocked (exit 2).
trap 'echo "nabc-dev guard.sh a échoué (ligne $LINENO) : action bloquée par sécurité." >&2; exit 2' ERR
has_config || exit 0
# Errors inside <(...) do not trigger ERR: validate the config explicitly
jq empty "$CONFIG" 2>/dev/null || { echo "nabc-dev : $CONFIG est invalide, action bloquée par sécurité." >&2; exit 2; }

TOOL="$(field '.tool_name')"
AGENT="$(field '.agent_type')"   # e.g. "nabc-dev:code-implementer" inside a subagent
AGENT="${AGENT##*:}"

if [[ "$TOOL" == "Bash" ]]; then
  CMD="$(field '.tool_input.command')"
  # "git [options] <sub>" where options may sit between git and the subcommand
  git_sub() { [[ "$CMD" =~ (^|[;\&|[:space:]\(])git([[:space:]]+[^;\&|]*)?[[:space:]]+$1([[:space:]]|$) ]]; }

  if [[ "$CMD" =~ --no-verify ]] || { git_sub commit && [[ "$CMD" =~ [[:space:]]-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$) ]]; }; then
    deny "Interdit : contourner les vérifications (--no-verify). Corrige la cause."
  fi

  if git_sub push; then
    current="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
    while read -r b; do
      [[ -z "$b" ]] && continue
      if [[ "$current" == "$b" || "$CMD" =~ (^|[[:space:]:])"$b"([[:space:]]|$) ]]; then
        deny "Push vers la branche protégée '$b' interdit. Pousse une branche de travail ; la fusion est humaine."
      fi
    done < <(cfg '.git.protected_branches[]')
  fi

  while read -r re; do
    if [[ -n "$re" && "$CMD" =~ $re ]]; then
      deny "Commande bloquée par la configuration du projet : $re"
    fi
  done < <(cfg '.git.blocked_commands[]')
  exit 0
fi

# Edit / Write / MultiEdit
FILE="$(field '.tool_input.file_path')"
[[ -z "$FILE" ]] && exit 0
REL="$(relpath "$FILE")"
ACC="$(cfg '.paths.acceptance_tests')"
in_acceptance=false
if [[ -n "$ACC" && "$REL" == "$ACC"/* ]]; then in_acceptance=true; fi

case "$AGENT" in
  "")
    # Main thread: real payloads carry no agent_type. Acceptance tests are
    # written by test-writer only; a supervised manual fix needs an opt-in
    # set by the human when launching Claude, which Claude cannot set itself.
    if $in_acceptance && [[ "${NABC_ALLOW_ACCEPTANCE_EDIT:-}" != "1" ]]; then
      deny "Les tests d'acceptance encodent la spec validée : ils se modifient via /nabc-dev:acceptance. Pour une correction manuelle supervisée, Antoine relance Claude avec NABC_ALLOW_ACCEPTANCE_EDIT=1."
    fi
    ;;
  code-implementer|code-refactorer)
    if $in_acceptance; then
      deny "Les tests d'acceptance encodent la spec validée : $AGENT ne peut pas les modifier. Si la spec est fausse, arrête-toi et signale-le."
    fi
    ;;
  test-writer)
    in_tests=false
    while read -r d; do
      if [[ -n "$d" && "$REL" == "$d"/* ]]; then in_tests=true; fi
    done < <(cfg '.paths.test_dirs[]')
    $in_tests || deny "Le code de production est la source de vérité : test-writer ne modifie que les fichiers de test."
    ;;
esac
exit 0
