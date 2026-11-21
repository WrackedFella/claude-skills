# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# ci/eval-tier: the eval tier of a change, from its paths and its agent/skill frontmatter.

setup() {
  git_repo
  mkdir -p plugins/devflow/agents plugins/devflow/skills/orchestrate plugins/devflow/skills/tech-lead \
    plugins/devflow/skills/engineering-standards wiki
  printf -- '---\nname: builder\nmodel: sonnet\n---\nBody\n' >plugins/devflow/agents/builder.md
  printf -- '---\nname: test-writer\nmodel: sonnet\n---\nBody\n' >plugins/devflow/agents/test-writer.md
  printf -- '---\nname: orchestrate\n---\nSteps\n' >plugins/devflow/skills/orchestrate/SKILL.md
  printf -- '---\nname: tech-lead\n---\nBody\n' >plugins/devflow/skills/tech-lead/SKILL.md
  printf -- '---\nname: engineering-standards\n---\nBody\n' >plugins/devflow/skills/engineering-standards/SKILL.md
  echo "# Wiki" >wiki/README.md
  base=$(commit base)
}
tier() { run "$REPO/ci/eval-tier" "$base" "$(commit change)"; }

t "docs and wiki only is none"
setup
echo more >>wiki/README.md
tier
assert_rc 0
assert_out none

t "a skill orchestrate never loads is none"
setup
echo more >>plugins/devflow/skills/tech-lead/SKILL.md
tier
assert_out none

t "worker agent wording is smoke"
setup
echo more >>plugins/devflow/agents/test-writer.md
tier
assert_out smoke

t "a plugin file no rule names is smoke"
setup
echo x >plugins/devflow/operations.md
tier
assert_out smoke

t "orchestrate's steps are standard"
setup
echo "step 12" >>plugins/devflow/skills/orchestrate/SKILL.md
tier
assert_out standard

t "a PR takes its highest tier"
setup
echo more >>wiki/README.md
echo more >>plugins/devflow/agents/test-writer.md
echo more >>plugins/devflow/agents/builder.md
tier
assert_out standard
assert_err_contains $'smoke\tplugins/devflow/agents/test-writer.md'

t "a model change in a worker agent is full"
setup
sed -i 's/model: sonnet/model: opus/' plugins/devflow/agents/test-writer.md
tier
assert_out full
assert_err_contains "model or effort changed"

t "an effort line added to a skill is full"
setup
sed -i 's/^name: tech-lead$/name: tech-lead\neffort: high/' plugins/devflow/skills/tech-lead/SKILL.md
tier
assert_out full

t "a model mentioned in body text is not a model change"
setup
echo "Run the critic on Opus; model: opus in the brief" >>plugins/devflow/agents/test-writer.md
tier
assert_out smoke

t "a new agent is full"
setup
printf -- '---\nname: x\n---\n' >plugins/devflow/agents/x.md
tier
assert_out full
assert_err_contains "agent or skill added"

t "a removed skill is full"
setup
git rm -q -r plugins/devflow/skills/tech-lead
tier
assert_out full

t "a renamed agent is full"
setup
git mv plugins/devflow/agents/test-writer.md plugins/devflow/agents/tester.md
tier
assert_out full
assert_err_contains "renamed"

t "the tier is measured from the merge base, not the base's later commits"
setup
git checkout -q -b pr
echo more >>wiki/README.md
head=$(commit pr)
git checkout -q main
echo "step" >>plugins/devflow/skills/orchestrate/SKILL.md
base=$(commit main-moves)
run "$REPO/ci/eval-tier" "$base" "$head"
assert_out none

t "a malformed rules file is a usage error"
setup
echo "huge plugins/*" >"$(mktemp -d)/rules" && rules=$_
echo more >>wiki/README.md
run "$REPO/ci/eval-tier" --rules "$rules" "$base" "$(commit change)"
assert_rc 2

t "every plugin file falls under a rule: the plugin catch-all exists"
grep -qE '^smoke[[:space:]]+plugins/\*$' "$REPO/ci/eval-tiers" || _fail "no smoke catch-all for plugin files"
