# shellcheck shell=bash disable=SC2016,SC2154 # fixtures hold literal JSON
# pr-verdict: one fixture per pr-review §5 rule and the §4 later-round goalpost rule.

dir=$(mktemp -d)
# facts [prior-routes...]: pr-facts JSON with one prior review per route given.
facts() {
  local prior='[]' r
  for r in "$@"; do prior=$(jq -c --arg r "$r" '. + [{verdict:"reject",route:$r}]' <<<"$prior"); done
  jq -nc --argjson p "$prior" '{head_sha:"abc",tier:"light",signoff_triggers:[],prior_reviews:$p,stop:null}' >"$dir/facts.json"
}
# find <prior_blockers> <finding-json>...: the findings file.
find_() {
  local prior=$1 arr='[]'; shift
  for f in "$@"; do arr=$(jq -c --argjson f "$f" '. + [$f]' <<<"$arr"); done
  jq -nc --argjson a "$arr" --argjson p "$prior" '{prior_blockers:$p,findings:$a}' >"$dir/findings.json"
}
verdict() { run "$SCRIPTS/pr-verdict" --facts "$dir/facts.json" --findings "$dir/findings.json" "$@"; }

B1='{"id":"X1","class":"B1","kind":"blocker","fix":"auto","in_changed_lines":true}'

t "no findings approve with no route and agent sign-off"
facts; find_ 0
verdict
assert_rc 0
assert_contains $'Verdict: approve\nRoute: none\nSign-off: agent\nRound: 1'
assert_contains "Blockers: none"

t "the same inputs print identical output"
facts; find_ 0 "$B1"
verdict; first=$out
verdict
[[ $out == "$first" ]] || _fail "second run differs: $out"

t "a surviving blocker rejects with route fix in round 1"
facts; find_ 0 "$B1"
verdict
assert_contains $'Verdict: reject\nRoute: fix\nSign-off: agent'
assert_contains "Blockers: X1"

t "a follow-up alone approves and is listed"
facts; find_ 0 '{"id":"F1","class":"B1","kind":"followup"}'
verdict
assert_contains $'Verdict: approve\nRoute: none'
assert_contains "Follow-ups: F1"

t "B2, B4 and B6 rated follow-up become blockers"
facts; find_ 0 '{"id":"X1","class":"B2","kind":"followup"}' '{"id":"X2","class":"B4","kind":"followup"}' '{"id":"X3","class":"B6","kind":"followup"}'
verdict
assert_contains "Verdict: reject"
assert_contains "Blockers: X1 X2 X3"
assert_contains "Promoted: X2"

t "B1, B3 and B5 rated follow-up stay follow-ups"
facts; find_ 0 '{"id":"F1","class":"B1","kind":"followup"}' '{"id":"F3","class":"B3","kind":"followup"}' '{"id":"F5","class":"B5","kind":"followup"}'
verdict
assert_contains "Verdict: approve"
assert_contains "Follow-ups: F1 F3 F5"

t "a needs-decision blocker routes to a human"
facts; find_ 0 '{"id":"X1","class":"B4","kind":"blocker","fix":"needs-decision"}'
verdict
assert_contains "Route: human"
assert_contains "Route because: a blocker is needs-decision"

t "a declined carried blocker routes to a human"
facts fix; find_ 1 '{"id":"X1","class":"B1","kind":"blocker","fix":"auto","carried":true,"declined":true}'
verdict
assert_contains "Route: human"
assert_contains "Route because: a carried blocker was declined"

t "a blocker carried through two fix rounds routes to a human"
facts fix fix; find_ 3 '{"id":"X1","class":"B1","kind":"blocker","fix":"auto","carried":true,"rounds_survived":2}' '{"id":"X2","class":"B1","kind":"blocker","fix":"auto","in_changed_lines":true}'
verdict
assert_contains "Round: 3"
assert_contains "Route because: a blocker survived two rounds"
assert_lacks "no progress"

t "a blocker carried once with fewer blockers than the last round routes to fix"
facts fix; find_ 3 '{"id":"X1","class":"B1","kind":"blocker","fix":"auto","carried":true,"rounds_survived":1}'
verdict
assert_contains "Route: fix"

t "a round with as many blockers as the last routes to a human"
facts fix; find_ 1 "$B1"
verdict
assert_contains "Route: human"
assert_contains "Route because: no progress: 1 blockers, 1 in the last review"

t "fewer blockers than the last round keeps route fix"
facts fix; find_ 2 "$B1"
verdict
assert_contains "Route: fix"

t "a round past the cap routes to a human"
facts fix fix fix; find_ 5 "$B1"
verdict
assert_contains "Round: 4"
assert_contains "Route because: round 4 exceeds the cap of 3"
verdict --max-rounds 4
assert_contains "Route: fix"

t "only prior reviews with route fix count as rounds"
facts fix human none; find_ 0
verdict
assert_contains "Round: 2"

t "a facts trigger needs a human sign-off"
jq -nc '{head_sha:"abc",tier:"light",signoff_triggers:["PR touches a Human-only path"],prior_reviews:[],stop:null}' >"$dir/facts.json"
find_ 0
verdict
assert_contains "Verdict: approve"
assert_contains "Sign-off: human"
assert_contains "Sign-off because: facts trigger: PR touches a Human-only path"

t "a standing question does not reject but needs a human sign-off"
facts; find_ 0 '{"id":"Q1","class":"B4","kind":"question"}'
verdict
assert_contains $'Verdict: approve\nRoute: none\nSign-off: human'
assert_contains "Questions: Q1"

t "a confirmed C2 follow-up needs a human sign-off"
facts; find_ 0 '{"id":"F1","class":"B5","kind":"followup","c2":true}'
verdict
assert_contains $'Verdict: approve\nRoute: none\nSign-off: human'
assert_contains "Sign-off because: a C2 finding was confirmed"

t "judgment flags are inputs and nothing is inferred without them"
facts; find_ 0
verdict
assert_contains "Sign-off: agent"
verdict --security-relevant
assert_contains "Sign-off because: security-relevant code"
verdict --undeclared-api
assert_contains "Sign-off because: public API or persisted format the spec does not name"
verdict --toolchain-incomplete
assert_contains "Sign-off because: a full-tier toolchain could not run"

t "round 2: a new blocker outside the changed lines becomes a follow-up"
facts fix; find_ 1 '{"id":"X2","class":"B1","kind":"blocker","fix":"auto"}'
verdict
assert_contains "Verdict: approve"
assert_contains "Follow-ups: X2"
assert_contains "Demoted: X2"

t "round 2: a new B1 proven by a failing test stays a blocker"
facts fix; find_ 2 '{"id":"X2","class":"B1","kind":"blocker","fix":"auto","failing_test":true}'
verdict
assert_contains "Blockers: X2"

t "round 2: a new B3 outside the changed lines is demoted"
facts fix; find_ 2 '{"id":"X2","class":"B3","kind":"blocker","fix":"auto","failing_test":true}'
verdict
assert_contains "Demoted: X2"

t "round 2: B2 and B4 outside the changed lines stay blockers, rated either way"
facts fix; find_ 3 '{"id":"X2","class":"B2","kind":"blocker","fix":"auto"}' '{"id":"X3","class":"B4","kind":"followup"}'
verdict
assert_contains "Verdict: reject"
assert_contains "Blockers: X2 X3"
assert_contains "Promoted: X3"
assert_lacks "Demoted"

t "an unknown kind, class or fix is a usage error, never dropped"
facts; find_ 0 '{"id":"X1","class":"B1","kind":"Blocker"}'
verdict
assert_rc 2
find_ 0 '{"id":"X1","class":"b4","kind":"followup"}'
verdict
assert_rc 2
find_ 0 '{"id":"X1","class":"B1","kind":"blocker","fix":"maybe"}'
verdict
assert_rc 2

t "round 2: a new B6 stays a blocker"
facts fix; find_ 2 '{"id":"X2","class":"B6","kind":"blocker","fix":"auto"}'
verdict
assert_contains "Blockers: X2"

t "round 1 keeps every blocker whatever its lines"
facts; find_ 0 '{"id":"X1","class":"B1","kind":"blocker","fix":"auto"}'
verdict
assert_contains "Blockers: X1"

t "a set facts.stop is refused"
jq -nc '{head_sha:"abc",prior_reviews:[],stop:{verdict:"wait",route:null,reason:"CI pending"}}' >"$dir/facts.json"
find_ 0
verdict
assert_rc 2
assert_err_contains "facts.stop is set"

t "bad arguments are a usage error"
run "$SCRIPTS/pr-verdict" --bogus
assert_rc 2
run "$SCRIPTS/pr-verdict" --facts "$dir/nope" --findings "$dir/nope"
assert_rc 2
