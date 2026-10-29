#!/usr/bin/env bash
# Stop: if the session changed something, run the quality gate.
# Red → Claude must continue (exit 2). After max_attempts → let it stop.
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"
has_config || exit 0
git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

START_FILE="$STATE_DIR/$SESSION_ID.start"
ATTEMPTS_FILE="$STATE_DIR/$SESSION_ID.attempts"
now="$(snapshot)"

# Nothing changed since session start (or since the last green gate) → skip
if [[ -f "$START_FILE" ]]; then
  [[ "$(cat "$START_FILE")" == "$now" ]] && exit 0
elif [[ -z "$(git -C "$ROOT" status --porcelain)" ]]; then
  exit 0
fi

GATE="$(cfg '.commands.gate')"
[[ -z "$GATE" ]] && exit 0
MAX="$(cfg '.gate.max_attempts')"
MAX="${MAX:-3}"

if out="$(cd "$ROOT" && bash -c "$GATE" 2>&1)"; then
  rm -f "$ATTEMPTS_FILE"
  # Green state becomes the new baseline: a later question-only turn skips the gate
  echo "$now" > "$START_FILE"
  exit 0
fi

n=$(( $(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0) + 1 ))
if (( n >= MAX )); then
  rm -f "$ATTEMPTS_FILE"
  jq -nc --arg m "Gate rouge après $MAX tentatives : intervention manuelle requise. Commande : $GATE" '{systemMessage:$m}'
  exit 0
fi
echo "$n" > "$ATTEMPTS_FILE"
{
  echo "Gate de qualité rouge (tentative $n/$MAX). Corrige la cause, n'affaiblis aucun test, ne touche pas aux tests d'acceptance :"
  tail -n 60 <<<"$out"
} >&2
exit 2   # Stop: Claude continues instead of stopping
