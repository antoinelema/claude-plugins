load test_helper
setup() { common_setup; }
teardown() { common_teardown; }

@test "agents en parallèle : une base de test par worktree" {
  git -C "$REPO" worktree add -q "$TMP/feat-a" -b feat-a
  git -C "$REPO" worktree add -q "$TMP/feat-b" -b feat-b
  for wt in feat-a feat-b; do
    export CLAUDE_ENV_FILE="$TMP/$wt.env"
    bash "$SCRIPTS/session-start.sh" <<<"$(session_input "$TMP/$wt")" >/dev/null
  done
  grep -qx 'export DB_DATABASE=testing_feat_a' "$TMP/feat-a.env"
  grep -qx 'export DB_DATABASE=testing_feat_b' "$TMP/feat-b.env"
}

@test "--env-only : exporte la base sans injecter de contexte" {
  export CLAUDE_ENV_FILE="$TMP/env"
  run bash "$SCRIPTS/session-start.sh" --env-only <<<"$(session_input)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  grep -q DB_DATABASE "$TMP/env"
}

@test "injecte un contexte court avec la stack" {
  run bash "$SCRIPTS/session-start.sh" <<<"$(session_input)"
  [[ "$output" == *"stack : laravel"* ]]
  [[ "$output" == *"Green is not working"* ]]
}
