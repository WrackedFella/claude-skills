# Assertions for the fixture tests. A test file calls `t <name>` before each case, then
# `run <cmd>...` and the assert_* helpers; tests/run calls `finish` at the end.
# shellcheck shell=bash

export SCRIPTS=$REPO/plugins/devflow/scripts
_fails=0 _count=0 _name=""
out="" err="" rc=0

t() { _name=$1; _count=$((_count + 1)); }

_fail() { echo "  FAIL $_name: $*"; _fails=$((_fails + 1)); }

# Runs a command, capturing stdout in $out, stderr in $err and the exit code in $rc.
run() {
  local o e
  o=$(mktemp) e=$(mktemp)
  rc=0
  "$@" >"$o" 2>"$e" || rc=$?
  out=$(cat "$o") err=$(cat "$e")
  rm -f "$o" "$e"
}

assert_rc() { [[ $rc -eq $1 ]] || _fail "exit $rc, expected $1; stdout: $out; stderr: $err"; }
assert_out() { [[ $out == "$1" ]] || _fail "stdout was: $out; expected: $1"; }
assert_contains() { [[ $out == *"$1"* ]] || _fail "stdout lacks '$1': $out"; }
assert_lacks() { [[ $out != *"$1"* ]] || _fail "stdout has '$1': $out"; }
assert_err_contains() { [[ $err == *"$1"* ]] || _fail "stderr lacks '$1': $err"; }
# assert_json <jq-filter> <expected>: the filter's compact output on $out.
assert_json() {
  local got
  got=$(jq -c "$1" <<<"$out" 2>&1) || { _fail "stdout is not JSON: $out"; return; }
  [[ $got == "$2" ]] || _fail "$1 was $got, expected $2"
}

# A fresh git repository in a temp directory, as the working directory.
git_repo() {
  cd "$(mktemp -d)" || exit 1
  git init -q -b main
  git config user.email test@example.com
  git config user.name test
  git config commit.gpgsign false
}
commit() { git add -A && git commit -q -m "${1:-change}" && git rev-parse HEAD; }

# Puts the gh stub first on PATH. The test defines `gh_stub` (args in "$@"), which prints
# the raw response and returns gh's exit code; the stub applies any -q/--jq filter.
use_gh_stub() {
  export PATH=$TESTS/bin:$PATH GH_LOG
  GH_LOG=$(mktemp)
  export -f gh_stub
}

finish() {
  echo "  $((_count - _fails))/$_count passed"
  [[ $_fails -eq 0 ]]
}
