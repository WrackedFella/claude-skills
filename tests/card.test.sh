# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# card: files an issue, links it under its feature, optionally sets board fields.

body=$(mktemp)
echo "spec" >"$body"

gh_stub() {
  case "$*" in
    "repo view --json nameWithOwner") echo '{"nameWithOwner":"o/r"}' ;;
    "issue create"*) echo "https://github.com/o/r/issues/12" ;;
    "api repos/o/r/issues/12") echo '{"id":999}' ;;
    "api repos/o/r/issues/5/sub_issues"*) [[ ${LINK_FAILS:-} ]] && { echo "HTTP 422"; return 1; }; echo '{}' ;;
    "api users/o") echo "HTTP 403"; return 1 ;;
    *) echo "unexpected gh $*"; return 1 ;;
  esac
}

t "publish files, links and prints the issue"
use_gh_stub
run "$SCRIPTS/card" publish 5 "[X-F1-01] Title" "$body" --label agent-ready
assert_rc 0
assert_out "#12 https://github.com/o/r/issues/12"
grep -q -- "--label agent-ready" "$GH_LOG" || _fail "label not passed to gh issue create"
grep -q "sub_issue_id=999" "$GH_LOG" || _fail "sub-issue not linked by issue id"

t "an issue that can't be linked is an error that still prints its URL"
use_gh_stub
run env LINK_FAILS=1 "$SCRIPTS/card" publish 5 "T" "$body"
assert_rc 1
assert_out "https://github.com/o/r/issues/12"
assert_err_contains "could not link it under #5"

t "an unreachable board exits 5 after filing and linking"
use_gh_stub
run "$SCRIPTS/card" publish 5 "T" "$body" --board o 1 Status=Ready
assert_rc 5
assert_err_contains "board unreachable"
grep -q "sub_issue_id=999" "$GH_LOG" || _fail "issue not linked before the board call"

t "a non-numeric feature is rejected before any gh call"
use_gh_stub
run "$SCRIPTS/card" publish five "T" "$body"
assert_rc 1
[[ ! -s $GH_LOG ]] || _fail "gh was called"

t "a board pair without = is rejected"
use_gh_stub
run "$SCRIPTS/card" publish 5 "T" "$body" --board o 1 Status
assert_rc 1
assert_err_contains "expected Field=Option"
