#!/usr/bin/env bash
# PostToolUse: static analysis of the edited file; errors are fed back to Claude.
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"
has_config || exit 0

FILE="$(field '.tool_input.file_path')"
CMD_TPL="$(cfg '.commands.check_file')"
GLOB="$(cfg '.commands.check_file_glob')"
[[ -z "$FILE" || -z "$CMD_TPL" ]] && exit 0
[[ -n "$GLOB" && ! "$FILE" =~ $GLOB ]] && exit 0
[[ -f "$FILE" ]] || exit 0

CMD="${CMD_TPL//\{file\}/$(printf '%q' "$FILE")}"
if ! out="$(cd "$ROOT" && bash -c "$CMD" 2>&1)"; then
  echo "Analyse statique en échec sur $(relpath "$FILE") :" >&2
  tail -n 40 <<<"$out" >&2
  exit 2   # PostToolUse: stderr is shown to Claude, which fixes it
fi
exit 0
