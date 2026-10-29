# Shared setup: a temporary git repo configured with nabc-dev.
PLUGIN_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
SCRIPTS="$PLUGIN_ROOT/scripts"

make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email t@t.test
  git -C "$dir" config user.name t
  mkdir -p "$dir/.claude"
  cp "$BATS_TEST_DIRNAME/fixtures/nabc.laravel.json" "$dir/.claude/nabc.json"
  git -C "$dir" add -A
  git -C "$dir" commit -qm init
}

# set_cfg '.commands.gate = "false"'
set_cfg() {
  local tmp; tmp="$(mktemp)"
  jq "$1" "$REPO/.claude/nabc.json" >"$tmp" && mv "$tmp" "$REPO/.claude/nabc.json"
  git -C "$REPO" commit -qam cfg
}

common_setup() {
  TMP="$(mktemp -d)"
  REPO="$TMP/repo"
  make_repo "$REPO"
  export CLAUDE_PLUGIN_DATA="$TMP/data"
}

common_teardown() { rm -rf "$TMP"; }

bash_input() {
  jq -nc --arg cwd "$REPO" --arg c "$1" '{cwd:$cwd,session_id:"t",tool_name:"Bash",tool_input:{command:$c}}'
}

edit_input() { # agent file
  jq -nc --arg cwd "$REPO" --arg a "$1" --arg f "$REPO/$2" \
    '{cwd:$cwd,session_id:"t",agent_type:$a,tool_name:"Edit",tool_input:{file_path:$f}}'
}

# Real PreToolUse payload captured from Claude Code 2.1.312 (2026-10-29),
# local paths replaced by __REPO__. The main-thread payload has no agent_type
# key at all, unlike the synthetic edit_input ''.
real_payload() { # fixture name
  sed "s|__REPO__|$REPO|g" "$BATS_TEST_DIRNAME/fixtures/payloads/$1.json"
}

session_input() { jq -nc --arg cwd "${1:-$REPO}" '{cwd:$cwd,session_id:"t"}'; }

is_denied() { [[ "$output" == *'"permissionDecision":"deny"'* ]]; }
