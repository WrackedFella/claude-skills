# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# intake-agree: a blocker pauses only when both intake reports raise it under the same rule.

dir=$(mktemp -d)
finding() { # <title> <kind> <rule or empty>
  printf '### B4 %s\nKind: %s\nFix: needs-decision\n' "$1" "$2"
  [[ -z $3 ]] || printf 'Rule: %s\n' "$3"
  printf '\n'
}

t "the same blocker under differently written rule keys is confirmed"
{ echo "## Findings"; finding "Layering broken" blocker '`plugins/devflow/skills/engineering-standards/SKILL.md#layering`'
  finding "Issue conflict" blocker "https://github.com/o/r/issues/42"; } >"$dir/a.md"
{ echo "## Findings"; finding "Wrong layer" blocker "skill:engineering-standards"
  finding "Unrelated" blocker "ADR-0003"; } >"$dir/b.md"
run "$SCRIPTS/intake-agree" "$dir/a.md" "$dir/b.md"
assert_rc 3
assert_contains "Confirmed: 1"
assert_contains "### B4 Layering broken"
assert_contains "Unconfirmed:"
assert_contains "### B4 Issue conflict"
assert_contains "### B4 Unrelated"

t "an issue link and #n are the same key"
finding "A" blocker "#42 (spec)" >"$dir/c.md"
finding "B" blocker "https://github.com/o/r/issues/42" >"$dir/d.md"
run "$SCRIPTS/intake-agree" "$dir/c.md" "$dir/d.md"
assert_rc 3

t "paths match without ./ prefix, line suffix or case"
finding "A" blocker "./Docs/ADR/0003.md:12" >"$dir/e.md"
finding "B" blocker "docs/adr/0003.md" >"$dir/f.md"
run "$SCRIPTS/intake-agree" "$dir/e.md" "$dir/f.md"
assert_rc 3

t "blockers only one report raises proceed"
run "$SCRIPTS/intake-agree" "$dir/a.md" "$dir/e.md"
assert_rc 0
assert_contains "Confirmed: none"

t "findings that are not blockers never pause"
finding "A" concern "#42" >"$dir/g.md"
run "$SCRIPTS/intake-agree" "$dir/g.md" "$dir/c.md"
assert_rc 0

t "a blocker with no Rule line stays unconfirmed"
finding "A" blocker "" >"$dir/h.md"
run "$SCRIPTS/intake-agree" "$dir/h.md" "$dir/h.md"
assert_rc 0
assert_contains "### B4 A"

t "a missing report is a usage error"
run "$SCRIPTS/intake-agree" "$dir/a.md" "$dir/missing.md"
assert_rc 2
run "$SCRIPTS/intake-agree" "$dir/a.md"
assert_rc 2
