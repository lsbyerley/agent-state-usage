#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BIN="$ROOT/bin/agent-state-usage"
DEFAULT_PATHS="$ROOT/data/agent-paths.txt"
TMP_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

fail() {
  echo "not ok - $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  [[ "$haystack" == *"$needle"* ]] || fail "$label"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  [[ "$haystack" != *"$needle"* ]] || fail "$label"
}

make_fixture() {
  local dir="$TMP_ROOT/state"
  mkdir -p "$dir/sessions" "$dir/cache"
  printf "session data\n" > "$dir/sessions/session.log"
  printf "cache data\n" > "$dir/cache/cache.bin"
  printf "config\n" > "$dir/config.json"
  printf "%s" "$dir"
}

bash -n "$BIN"
[[ -f "$DEFAULT_PATHS" ]] || fail "default paths config should exist"

help_output="$("$BIN" --help)"
assert_contains "$help_output" "agent-state-usage" "help should show primary command"
assert_contains "$help_output" "AI agent state" "help should describe state directories"
assert_contains "$help_output" "data/agent-paths.txt" "help should mention default path config"

defaults_output="$("$BIN" --list-defaults)"
assert_contains "$defaults_output" "~/.codex" "defaults should include Codex"
assert_contains "$defaults_output" "~/.claude" "defaults should include Claude"
assert_contains "$defaults_output" "Cursor/User/globalStorage" "defaults should include Cursor"
assert_not_contains "$defaults_output" "#" "defaults should not include comments"

version_output="$("$BIN" --version)"
[[ "$version_output" == "0.1.0" ]] || fail "version should print package version"

fixture="$(make_fixture)"
human_output="$("$BIN" --top 10 "$fixture")"
assert_contains "$human_output" "Agent state disk usage" "human output should use state naming"
assert_contains "$human_output" "$fixture/config.json" "human output should include regular files"
assert_not_contains "$human_output" "$fixture/sessions"$'\n' "largest files should not include directories"
assert_not_contains "$human_output" "$fixture/cache"$'\n' "largest files should not include directories"

top_output="$("$BIN" --top 1 "$fixture")"
largest_count="$(printf "%s\n" "$top_output" | awk '/\/state\// { count += 1 } END { print count + 0 }')"
[[ "$largest_count" == "1" ]] || fail "--top should limit largest files"

json_output="$("$BIN" --json --top 10 "$fixture")"
assert_contains "$json_output" '"total_bytes":' "json should include total_bytes"
assert_contains "$json_output" '"largest_files":[' "json should include largest_files"
assert_contains "$json_output" '/config.json' "json should include regular files"
assert_not_contains "$json_output" '/sessions"' "json should not include directories"
assert_not_contains "$json_output" '/cache"' "json should not include directories"

special_dir="$TMP_ROOT/special"
mkdir -p "$special_dir"
tab_file="$special_dir/file"$'\t'"name.txt"
newline_file="$special_dir/file"$'\n'"name.txt"
printf "tab\n" > "$tab_file"
printf "newline\n" > "$newline_file"
special_json="$("$BIN" --json --top 10 "$special_dir")"
printf "%s" "$special_json" | SPECIAL_TAB="$tab_file" SPECIAL_NEWLINE="$newline_file" node -e '
  const fs = require("fs");
  const data = JSON.parse(fs.readFileSync(0, "utf8"));
  const paths = data.largest_files.map((entry) => entry.path);
  if (!paths.includes(process.env.SPECIAL_TAB)) process.exit(1);
  if (!paths.includes(process.env.SPECIAL_NEWLINE)) process.exit(1);
' || fail "json should be valid and preserve tab/newline filenames"

empty_dir="$TMP_ROOT/empty"
mkdir -p "$empty_dir"
empty_output="$("$BIN" --top 10 "$empty_dir")"
assert_contains "$empty_output" "$empty_dir" "empty directory should be reported"
assert_contains "$empty_output" "Total" "empty directory output should include total"

small_dir="$TMP_ROOT/order-small"
large_dir="$TMP_ROOT/order-large"
mkdir -p "$small_dir" "$large_dir"
printf "small\n" > "$small_dir/file.txt"
printf "%9000s\n" "large" > "$large_dir/file.txt"
ordered_output="$("$BIN" --top 0 "$large_dir" "$small_dir")"
ordered_paths="$(printf "%s\n" "$ordered_output" | awk -v small="$small_dir" -v large="$large_dir" 'index($0, small) { print "small" } index($0, large) { print "large" }')"
[[ "$ordered_paths" == $'large\nsmall' ]] || fail "path summary should be sorted by size descending"

default_home="$TMP_ROOT/home"
mkdir -p "$default_home/.codex"
printf "codex session\n" > "$default_home/.codex/session.log"
default_output="$(HOME="$default_home" "$BIN" --top 10)"
assert_contains "$default_output" "$default_home/.codex" "default paths should be loaded from config"

missing_output="$("$BIN" "$TMP_ROOT/does-not-exist")"
assert_contains "$missing_output" "No agent state paths found." "missing paths should be handled"

echo "ok - CLI behavior"
