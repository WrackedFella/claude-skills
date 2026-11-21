# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# step-check: required orchestrate calls from a transcript, report and hook modes.

dir=$(mktemp -d)
user() { jq -cn --arg t "$1" '{type:"user", message:{content:$t}}'; }
call() { jq -cn --arg n "$1" --argjson i "$2" '{type:"assistant", message:{content:[{type:"tool_use", name:$n, input:$i}]}}'; }
agent() { call Agent "$(jq -cn --arg s "devflow:$1" --arg p "${2:-}" '{subagent_type:$s, prompt:$p}')"; }
skill() { call Skill "$(jq -cn --arg s "$1" '{skill:$s}')"; }
bash_call() { call Bash "$(jq -cn --arg c "$1" '{command:$c}')"; }
say() { jq -cn --arg t "$1" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; }

full_run() {
  user "/devflow:orchestrate 12 <!-- board: gate=glue; eligible=yes -->"
  agent design-critic "Mode: intake"
  agent test-writer
  agent implementer
  agent test-writer "challenge"
  skill simplify
  bash_call "just mutants"
  skill devflow:comment-audit
  skill devflow:wiki
  agent reviewer
  say "Done."
}
printf '# Project\nDocs directory: wiki/\nDomain-test review: `agent`\n' >"$dir/CLAUDE.md"

t "a complete glue run reports nothing missing"
full_run >"$dir/full.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/full.jsonl"
assert_rc 0
assert_json .missing '[]'
assert_json .gate_class '"glue"'

t "a run without the challenge round is missing it"
full_run | grep -v '"prompt":"challenge"' >"$dir/nochallenge.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/nochallenge.jsonl"
assert_rc 1
assert_json .missing '["challenge"]'

t "mutation testing before the last code change does not count"
{ user "/devflow:orchestrate 12 gate=glue"; agent design-critic; agent test-writer; agent implementer
  bash_call "just mutants"; agent test-writer challenge; skill simplify; skill comment-audit; skill wiki; agent reviewer
} >"$dir/late.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/late.jsonl"
assert_rc 1
assert_json .missing '["mutation"]'

t "a domain item requires test review when the project delegates it to an agent"
full_run | sed 's/gate=glue/gate=domain/' >"$dir/domain.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/domain.jsonl"
assert_rc 1
assert_json .missing '["test-review"]'

t "a domain item needs no test-critic call when a human reviews tests"
printf 'Domain-test review: required\n' >"$dir/human.md"
run "$SCRIPTS/step-check" --claude-md "$dir/human.md" "$dir/domain.jsonl"
assert_rc 0
assert_json .required '["intake","tests","implement","challenge","simplify","mutation","comments","review"]'

t "builder briefs stand in for test-writer and implementer"
{ user "/devflow:orchestrate 3 gate=glue"; agent design-critic; agent builder "Mode: tests"
  call SendMessage '{"to":"builder","message":"Mode: implement"}'
  call SendMessage '{"to":"builder","message":"Mode: challenge"}'
  skill simplify; bash_call "just mutants"; skill comment-audit; skill wiki; agent reviewer
} >"$dir/builder.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/builder.jsonl"
assert_rc 0

t "intake after the first test-writer call does not count"
{ user "/devflow:orchestrate 3 gate=glue"; agent test-writer; agent design-critic; agent implementer
  agent test-writer; skill simplify; bash_call "just mutants"; skill comment-audit; skill wiki; agent reviewer
} >"$dir/lateintake.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/lateintake.jsonl"
assert_rc 1
assert_json .missing '["intake"]'

t "subagent calls do not count toward the main loop"
full_run | jq -c 'if ((.message.content | arrays | .[0].input.subagent_type) // "") == "devflow:reviewer" then .isSidechain = true else . end' >"$dir/side.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/side.jsonl"
assert_rc 1
assert_json .missing '["review"]'

t "a run that labelled itself agent-paused owes no later step"
{ user "/devflow:orchestrate 3"; agent design-critic; bash_call "gh issue edit 3 --add-label agent-paused"; } >"$dir/paused.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/paused.jsonl"
assert_rc 0
assert_json .paused 'true'

t "a run that reports the pause comment has paused"
{ user "/devflow:orchestrate 3"; agent design-critic; say "**Paused: needs a human answer**"; } >"$dir/reported.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/reported.jsonl"
assert_rc 0
assert_json .paused 'true'

t "a resumed run owes everything but intake"
{ user "/devflow:orchestrate 3 gate=glue"; bash_call "gh issue edit 3 --remove-label agent-paused"; } >"$dir/resumed.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/resumed.jsonl"
assert_rc 1
assert_json '.missing | index("intake")' 'null'
assert_json .paused 'false'

t "docs are required only when the project names a docs directory"
printf 'Domain-test review: agent\n' >"$dir/nodocs.md"
full_run | grep -v '"skill":"devflow:wiki"' >"$dir/nowiki.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/nodocs.md" "$dir/nowiki.jsonl"
assert_rc 0
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/nowiki.jsonl"
assert_json .missing '["docs"]'

t "a headless execution log (one JSON array) reads the same as JSONL"
jq -s . "$dir/nochallenge.jsonl" >"$dir/array.json"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/array.json"
assert_rc 1
assert_json .missing '["challenge"]'

t "a transcript that is not an orchestrate run exits 3"
{ user "fix the typo"; say "Done."; } >"$dir/other.jsonl"
run "$SCRIPTS/step-check" --claude-md "$dir/CLAUDE.md" "$dir/other.jsonl"
assert_rc 3

t "a missing transcript is a usage error"
run "$SCRIPTS/step-check" "$dir/nope.jsonl"
assert_rc 2

hook_input() { jq -cn --arg p "$1" --argjson a "${2:-false}" --arg c "$dir" '{transcript_path:$p, stop_hook_active:$a, cwd:$c}'; }

t "the hook blocks a headless stop with missing steps and names them"
run env GITHUB_ACTIONS=true CLAUDE_PROJECT_DIR="$dir" bash -c '"$1" --hook <<<"$2"' _ "$SCRIPTS/step-check" "$(hook_input "$dir/nochallenge.jsonl")"
assert_rc 0
assert_json .decision '"block"'
assert_contains "challenge"

t "the hook lets the second stop through"
run env GITHUB_ACTIONS=true CLAUDE_PROJECT_DIR="$dir" bash -c '"$1" --hook <<<"$2"' _ "$SCRIPTS/step-check" "$(hook_input "$dir/nochallenge.jsonl" true)"
assert_rc 0
assert_out ""

t "the hook does nothing outside Actions"
run env -u GITHUB_ACTIONS CLAUDE_PROJECT_DIR="$dir" bash -c '"$1" --hook <<<"$2"' _ "$SCRIPTS/step-check" "$(hook_input "$dir/nochallenge.jsonl")"
assert_rc 0
assert_out ""

t "the hook passes a complete run"
run env GITHUB_ACTIONS=true CLAUDE_PROJECT_DIR="$dir" bash -c '"$1" --hook <<<"$2"' _ "$SCRIPTS/step-check" "$(hook_input "$dir/full.jsonl")"
assert_rc 0
assert_out ""
