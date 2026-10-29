#!/usr/bin/env bash
# Shared helpers for nabc-dev hooks. Dependencies: bash, jq, git.
# Sourced by every hook script: reads the hook JSON input from stdin.
set -euo pipefail

INPUT="$(cat)"
field() { jq -r "$1 // empty" <<<"$INPUT"; }

CWD="$(field '.cwd')"
CWD="${CWD:-$PWD}"
SESSION_ID="$(field '.session_id')"
SESSION_ID="${SESSION_ID:-unknown}"
# Project root = git toplevel (the worktree dir inside a worktree), so hooks
# keep working when Claude cd's into a subdirectory.
ROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")"
CONFIG="$ROOT/.claude/nabc.json"
STATE_DIR="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/nabc-dev}/sessions"
mkdir -p "$STATE_DIR"

has_config() { [[ -f "$CONFIG" ]]; }
cfg() { jq -r "$1 // empty" "$CONFIG"; }

deny() {
  jq -nc --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Path relative to the project root
relpath() {
  realpath -m --relative-to="$ROOT" "$1"
}

# Fingerprint of the working tree: HEAD + staged/unstaged/untracked changes.
# Used to know whether the session changed anything since its start.
snapshot() {
  {
    git -C "$ROOT" rev-parse HEAD 2>/dev/null || true
    git -C "$ROOT" status --porcelain 2>/dev/null || true
    git -C "$ROOT" diff HEAD 2>/dev/null || true
    git -C "$ROOT" ls-files -o --exclude-standard -z 2>/dev/null \
      | (cd "$ROOT" && xargs -0r sha256sum) || true
  } | sha256sum | cut -d' ' -f1
}
