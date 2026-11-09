#!/usr/bin/env bash
# PostToolUse: static analysis of the edited file; errors are fed back to Claude.
# Checks: commands.check_files [{glob, command}] plus the legacy pair
# commands.check_file / commands.check_file_glob. Every matching check runs.
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"
has_config || exit 0

FILE="$(field '.tool_input.file_path')"
[[ -n "$FILE" && -f "$FILE" ]] || exit 0

CHECKS="$(jq -c '
  [(.commands.check_files // [])[]]
  + (if (.commands.check_file // "") != ""
     then [{glob: (.commands.check_file_glob // ""), command: .commands.check_file}]
     else [] end)
  | .[] | select((.command // "") != "")' "$CONFIG")"

failed=0
while IFS= read -r check; do
  [[ -z "$check" ]] && continue
  glob="$(jq -r '.glob // ""' <<<"$check")"
  [[ -n "$glob" && ! "$FILE" =~ $glob ]] && continue
  tpl="$(jq -r '.command' <<<"$check")"
  cmd="${tpl//\{file\}/$(printf '%q' "$FILE")}"
  if ! out="$(cd "$ROOT" && bash -c "$cmd" 2>&1)"; then
    echo "Analyse statique en échec sur $(relpath "$FILE") ($tpl) :" >&2
    tail -n 40 <<<"$out" >&2
    failed=1
  fi
done <<<"$CHECKS"

(( failed )) && exit 2   # PostToolUse: stderr is shown to Claude, which fixes it
exit 0
