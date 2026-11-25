# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# card: files an issue, links it under its feature, optionally sets board fields.

body=$(mktemp)
echo "spec" >"$body"

export GH_REPO=o/r

gh_stub() {
  case "$*" in
    "issue create"*) echo "https://github.com/o/r/issues/12" ;;
    "api repos/o/r/issues/12") echo '{"id":999}' ;;
    "api repos/o/r/issues/5/sub_issues"*) [[ ${LINK_FAILS:-} ]] && { echo "HTTP 422"; return 1; }; echo '{}' ;;
    "api repos/o/r/issues/7") echo '{"id":777}' ;;
    "api -X POST repos/o/r/issues/8/dependencies/blocked_by"*) [[ ${DEP_FAILS:-} ]] && { echo "$DEP_FAILS"; return 1; }; echo '{}' ;;
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

t "link posts the blocker's numeric id"
use_gh_stub
run "$SCRIPTS/card" link 8 7
assert_rc 0
assert_out "#8 blocked by #7"
grep -q "issue_id=777" "$GH_LOG" || _fail "blocker not linked by issue id"

t "linking an existing dependency is not an error"
use_gh_stub
run env DEP_FAILS="HTTP 422: dependency already exists" "$SCRIPTS/card" link 8 7
assert_rc 0

t "any other link failure is an error"
use_gh_stub
run env DEP_FAILS="HTTP 403" "$SCRIPTS/card" link 8 7
assert_rc 1
assert_err_contains "could not link #8"

t "link rejects non-numbers and self-links before any gh call"
use_gh_stub
run "$SCRIPTS/card" link 8 x
assert_rc 1
run "$SCRIPTS/card" link 8 8
assert_rc 1
assert_err_contains "cannot block itself"
[[ ! -s $GH_LOG ]] || _fail "gh was called"

t "link makes REST calls only"
use_gh_stub
run "$SCRIPTS/card" link 8 7
assert_rc 0
! grep -qE "^(repo|issue|graphql)|graphql" "$GH_LOG" || _fail "link used a non-REST gh call"

t "the repository comes from the origin remote when GH_REPO is unset"
use_gh_stub
d=$(mktemp -d); git -C "$d" init -q; git -C "$d" remote add origin http://127.0.0.1:1/git/o/r
run env -u GH_REPO bash -c 'cd "$1" && "$2/card" link 8 7' _ "$d" "$SCRIPTS"
assert_rc 0
grep -q "repos/o/r/issues/8/dependencies" "$GH_LOG" || _fail "wrong repository"
