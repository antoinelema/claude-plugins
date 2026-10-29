load test_helper
setup() {
  common_setup
  set_cfg '.commands.gate = "echo sortie-de-la-gate; exit 1"'
  bash "$SCRIPTS/session-start.sh" <<<"$(session_input)" >/dev/null
}
teardown() { common_teardown; }

stop() { run bash "$SCRIPTS/stop-gate.sh" <<<"$(session_input)"; }
attempts() { cat "$CLAUDE_PLUGIN_DATA/sessions/t.attempts"; }

@test "la session n'a rien modifié : la gate n'est pas lancée" {
  stop
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "gate rouge : Claude reçoit la sortie et continue, compteur à 1" {
  echo change >"$REPO/new.txt"
  stop
  [ "$status" -eq 2 ]
  [[ "$output" == *"sortie-de-la-gate"* ]]
  [[ "$output" == *"tentative 1/3"* ]]
  [ "$(attempts)" = 1 ]
}

@test "un commit pendant la session déclenche la gate" {
  echo change >"$REPO/new.txt"
  git -C "$REPO" add -A && git -C "$REPO" commit -qm x
  stop
  [ "$status" -eq 2 ]
}

@test "trois échecs : Claude peut s'arrêter avec intervention manuelle requise" {
  echo change >"$REPO/new.txt"
  stop; [ "$status" -eq 2 ]
  stop; [ "$status" -eq 2 ]
  stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"intervention manuelle requise"* ]]
  [[ "$output" == *'"systemMessage"'* ]]
}

@test "gate verte : arrêt autorisé, puis tour sans modification ignoré" {
  set_cfg '.commands.gate = "touch '"$TMP"'/ran"'
  bash "$SCRIPTS/session-start.sh" <<<"$(session_input)" >/dev/null
  echo change >"$REPO/new.txt"
  stop
  [ "$status" -eq 0 ]
  [ -f "$TMP/ran" ]
  rm "$TMP/ran"
  stop
  [ ! -f "$TMP/ran" ]
}

@test "modifications antérieures à la session : pas de gate" {
  echo avant >"$REPO/dirty.txt"
  bash "$SCRIPTS/session-start.sh" <<<"$(session_input)" >/dev/null
  stop
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
