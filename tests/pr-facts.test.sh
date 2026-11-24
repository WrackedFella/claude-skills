# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# pr-facts: deterministic review facts, in dry-run (two commits) and PR mode.

export GITHUB_REPOSITORY=o/r ISSUE_BODY="" CHECKS='[]'
setup() {
  git_repo
  git config uploadpack.allowAnySHA1InWant true
  printf '# Project\n- **Domain-logic paths:**\n  - `core/**`\n  - `rules/src/a.rs`\n' >CLAUDE.md
  mkdir -p core app
  echo a >app/x.txt
  base=$(commit base)
  git remote add origin "$PWD"
}
gh_stub() {
  case "$*" in
    "api repos/o/r/issues/7") jq -cn --arg b "$ISSUE_BODY" '{title:"[ENG-F1-02] Thing", body:$b}' ;;
    "api repos/o/r/pulls/9") jq -cn --arg h "$HEAD" '{head:{sha:$h, ref:"feat/ENG-F1-02-thing"}, base:{ref:"main"},
        user:{login:"bot"}, draft:false, state:"open", labels:[], mergeable_state:"clean",
        body:"Closes #7", created_at:"2026-01-01T00:00:00Z"}' ;;
    "api repos/o/r/compare/"*) jq -cn --arg b "$BASE" '{merge_base_commit:{sha:$b}}' ;;
    "api repos/o/r/commits/"*"/check-runs"*) jq -cn --argjson c "$CHECKS" '{check_runs:$c}' ;;
    "api repos/o/r/commits/"*"/status") echo '{"statuses":[]}' ;;
    "api repos/o/r/"*"comments"*|"api repos/o/r/pulls/9/reviews"*) echo '[]' ;;
    "api repos/o/r/actions/runs/200"*) echo 55 ;;
    "api repos/o/r/actions/workflows/55/runs"*) echo '["100","200"]' ;;
    "api graphql"*) echo '{"data":{"repository":{"issue":{"lastEditedAt":"2025-12-01T00:00:00Z"}}}}' ;;
    *) echo "unexpected gh $*"; return 1 ;;
  esac
}

t "a glue item with no domain paths is a light review"
setup
ISSUE_BODY='<!-- board: gate=glue; eligible=yes -->'
echo b >>app/x.txt
head=$(commit change)
use_gh_stub
run "$SCRIPTS/pr-facts" --range "$base..$head" --issue 7
assert_rc 0
assert_json '[.mode, .gate_class, .tier, .files, .changed_lines, .stop]' '["dry-run","glue","light",["app/x.txt"],1,null]'
assert_json .signoff_triggers '[]'

t "a glue item that touches a domain path is a full review"
setup
ISSUE_BODY='Gate class: glue'
echo b >core/y.rs
head=$(commit change)
use_gh_stub
run "$SCRIPTS/pr-facts" --range "$base..$head" --issue 7
assert_json '[.gate_class, .tier, .domain_hits]' '["glue","full",["core/y.rs"]]'

t "an item with no gate class is a full review"
setup
ISSUE_BODY='no header'
echo b >>app/x.txt
head=$(commit change)
use_gh_stub
run "$SCRIPTS/pr-facts" --range "$base..$head" --issue 7
assert_json '[.gate_class, .tier]' '["unknown","full"]'

t "config, dependency and Visual: changes are sign-off triggers"
setup
ISSUE_BODY=$'gate=glue\n- [ ] Visual: the menu fits @ 390x844'
mkdir -p .github && echo x >.github/ci.yml && echo x >Cargo.toml
head=$(commit change)
use_gh_stub
run "$SCRIPTS/pr-facts" --range "$base..$head" --issue 7
assert_json '.signoff_triggers | length' '3'
assert_contains "gate, CI or agent configuration changed: .github/ci.yml"
assert_contains "dependencies or licenses changed: Cargo.toml"
assert_contains "Visual: criteria"

t "lockfiles don't count toward changed lines"
setup
ISSUE_BODY='gate=glue'
seq 1 500 >Cargo.lock
head=$(commit change)
use_gh_stub
run "$SCRIPTS/pr-facts" --range "$base..$head" --issue 7
assert_json .changed_lines '0'

t "a PR with failing CI stops with a reject routed to fix"
setup
ISSUE_BODY='gate=glue'
echo b >>app/x.txt
HEAD=$(commit change) BASE=$base CHECKS='[{"name":"test","status":"completed","conclusion":"failure","details_url":"u"}]'
export HEAD BASE CHECKS
use_gh_stub
run "$SCRIPTS/pr-facts" 9
assert_rc 0
assert_json '[.mode, .issue, .id_match, .ci.state, .stop.verdict, .stop.route]' '["pr",7,true,"failing","reject","fix"]'

t "a PR with green CI has no stop"
CHECKS='[{"name":"test","status":"completed","conclusion":"success","details_url":"u"}]'
use_gh_stub
run "$SCRIPTS/pr-facts" 9
assert_json '[.ci.state, .stop]' '["green",null]'

t "an earlier failed run of the review workflow on the head is not CI, but another workflow's failure is"
CHECKS='[{"name":"Review and fix","status":"completed","conclusion":"failure","details_url":"https://x/runs/100/job/1"},{"name":"Review and fix","status":"in_progress","conclusion":null,"details_url":"https://x/runs/200/job/2"},{"name":"test","status":"completed","conclusion":"success","details_url":"https://x/runs/300/job/3"}]'
use_gh_stub
GITHUB_RUN_ID=200 run "$SCRIPTS/pr-facts" 9
assert_json '[.ci.state, .ci.failing, .stop]' '["green",[],null]'
CHECKS='[{"name":"Review and fix","status":"completed","conclusion":"failure","details_url":"https://x/runs/100/job/1"},{"name":"test","status":"completed","conclusion":"failure","details_url":"https://x/runs/300/job/3"}]'
use_gh_stub
GITHUB_RUN_ID=200 run "$SCRIPTS/pr-facts" 9
assert_json '[.ci.state, .ci.failing]' '["failing",["test"]]'

t "a CI covers line binds a command to its passing check"
printf '# Project\n- **CI covers:** gate (`^Gate`), mutation (`^Mutants`)\n' >CLAUDE.md
git add CLAUDE.md && base=$(commit base2) && git remote set-url origin "$PWD"
echo c >>app/x.txt
HEAD=$(commit change2) BASE=$base
CHECKS='[{"name":"Gate (linux)","status":"completed","conclusion":"success","details_url":"u"},{"name":"Mutants (diff)","status":"completed","conclusion":"success","details_url":"u"}]'
export HEAD BASE CHECKS
use_gh_stub
run "$SCRIPTS/pr-facts" 9
assert_json '[.ci_covers.gate.state, .ci_covers.mutation.state]' '["passed","passed"]'

t "a covered command whose check is absent or not green is not passed"
CHECKS='[{"name":"Gate (linux)","status":"completed","conclusion":"success","details_url":"u"},{"name":"Gate (macos)","status":"completed","conclusion":"success","details_url":"u"},{"name":"Gate (windows)","status":"completed","conclusion":"skipped","details_url":"u"}]'
use_gh_stub
run "$SCRIPTS/pr-facts" 9
assert_json '[.ci_covers.gate.state, .ci_covers.mutation.state]' '["failed","missing"]'

t "no CI covers setting leaves every command missing"
setup
ISSUE_BODY='gate=glue'
echo b >>app/x.txt
HEAD=$(commit change) BASE=$base CHECKS='[{"name":"Gate","status":"completed","conclusion":"success","details_url":"u"}]'
export HEAD BASE CHECKS
use_gh_stub
run "$SCRIPTS/pr-facts" 9
assert_json '[.ci_covers.gate.state, .ci_covers.mutation.state]' '["missing","missing"]'

t "no PR and no range is a usage error"
run "$SCRIPTS/pr-facts"
assert_rc 1
