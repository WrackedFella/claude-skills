# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# board: reads and sets board fields by name.

project='{"data":{"user":{"projectV2":{"id":"P","fields":{"nodes":[
  {"id":"F1","name":"Status","options":[{"id":"o1","name":"Ready"},{"id":"o2","name":"Done"}]},
  {"id":"F2","name":"Title"}]}}}}}'
item() { # <url> <state> <status> <eligible> <priority> <blocker state or empty>
  jq -cn --arg u "$1" --arg s "$2" --arg st "$3" --arg e "$4" --arg p "$5" --arg b "$6" '
    {content:{url:$u, state:$s, blockedBy:{nodes:(if $b == "" then [] else [{state:$b}] end)}},
     fieldValues:{nodes:[{name:$st, field:{name:"Status"}}, {name:$e, field:{name:"Agent-eligible"}},
                         {name:$p, field:{name:"Priority"}}, {}]}}'
}
export project ITEMS=""

gh_stub() {
  case "$*" in
    "api users/down") echo "HTTP 502"; return 1 ;;
    "api users/o") echo '{"type":"User"}' ;;
    *"items(first:100"*) jq -cn --argjson n "[${ITEMS}]" '{data:{user:{projectV2:{items:{nodes:$n}}}}}' ;;
    *"node(id:"*) echo '{"data":{"node":{"fieldValues":{"nodes":[{"name":"Ready","field":{"name":"Status"}},{}]}}}}' ;;
    "api graphql"*) echo "$project" ;;
    "project item-list"*) echo '{"items":[{"id":"I1","content":{"url":"https://github.com/o/r/issues/1"}}]}' ;;
    "project item-add"*) echo '{"id":"I1"}' ;;
    "project item-edit"*) echo '{}' ;;
    *) echo "unexpected gh $*"; return 1 ;;
  esac
}

t "an unreachable owner is exit 5"
use_gh_stub
run "$SCRIPTS/board" probe down 1
assert_rc 5
assert_err_contains "project board unreachable"

t "probe lists single-select fields and their options"
use_gh_stub
run "$SCRIPTS/board" probe o 1
assert_rc 0
assert_out $'board: o/1 reachable\nStatus: Ready, Done'

t "get prints an item's field values"
use_gh_stub
run "$SCRIPTS/board" get o 1 https://github.com/o/r/issues/1
assert_rc 0
assert_out "Status=Ready"

t "get of an issue not on the board is exit 4 and adds nothing"
use_gh_stub
run "$SCRIPTS/board" get o 1 https://github.com/o/r/issues/2
assert_rc 4
grep -q "item-add" "$GH_LOG" && _fail "get added the item"

t "set edits the option by its ID"
use_gh_stub
run "$SCRIPTS/board" set o 1 https://github.com/o/r/issues/1 Status=Done
assert_rc 0
grep -q -- "--field-id F1 --single-select-option-id o2" "$GH_LOG" || _fail "wrong field or option ID"

t "set with an unknown option is an error"
use_gh_stub
run "$SCRIPTS/board" set o 1 https://github.com/o/r/issues/1 Status=Blocked
assert_rc 1
assert_err_contains "has no option 'Blocked'"

t "next picks the highest-priority open, ready, eligible, unblocked issue"
ITEMS="$(item u/p3 OPEN Ready Yes P3 ""),$(item u/p1-blocked OPEN Ready Yes P1 OPEN),$(item u/p2 OPEN Ready Yes P2 CLOSED),$(item u/p0-closed CLOSED Ready Yes P0 ""),$(item u/p0-ineligible OPEN Ready No P0 "")"
use_gh_stub
run "$SCRIPTS/board" next o 1
assert_rc 0
assert_out "u/p2"

t "next with nothing ready is exit 3"
ITEMS="$(item u/a OPEN Backlog Yes P1 "")"
use_gh_stub
run "$SCRIPTS/board" next o 1
assert_rc 3

t "set and probe are silent no-ops in a GitHub Actions run"
use_gh_stub
GITHUB_ACTIONS=true run "$SCRIPTS/board" set down 1 https://github.com/o/r/issues/1 Status=Done
assert_rc 0
assert_out ""
