load test_helper
setup() {
  TMP="$(mktemp -d)"; REPO="$TMP/repo"
  mkdir -p "$REPO"; git -C "$REPO" init -q -b main
  export CLAUDE_PLUGIN_DATA="$TMP/data" CLAUDE_ENV_FILE="$TMP/env"
}
teardown() { rm -rf "$TMP"; }

@test "projet sans configuration : aucun hook n'agit" {
  for s in guard check-file session-start stop-gate; do
    run bash "$SCRIPTS/$s.sh" <<<"$(bash_input 'git push --no-verify')"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done
  [ ! -s "$TMP/env" ]
}
