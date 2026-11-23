# shellcheck shell=bash
# version-check: SessionStart warning when the loaded plugin differs from the default branch.

# An upstream repository holding plugins/devflow, and a loaded copy of it outside git.
setup() {
  git_repo
  upstream=$PWD
  mkdir -p plugins/devflow/.claude-plugin plugins/devflow/skills/a
  echo '{"name": "devflow", "repository": "https://example.invalid/x"}' >plugins/devflow/.claude-plugin/plugin.json
  echo "a" >plugins/devflow/skills/a/SKILL.md
  commit base >/dev/null
  root=$(mktemp -d)/abc123def456
  cp -r plugins/devflow "$root"
}
check() { run env -u GITHUB_ACTIONS "$SCRIPTS/version-check" --plugin-root "$root" --upstream "$upstream"; }

t "a loaded plugin equal to the default branch prints nothing"
setup
check
assert_rc 0
assert_out ""

t "a file changed upstream is reported to the user and the model"
setup
echo "b" >plugins/devflow/skills/a/SKILL.md
commit change >/dev/null
check
assert_rc 0
assert_json '.hookSpecificOutput.hookEventName' '"SessionStart"'
assert_contains "loaded abc123def456; 1 file(s) differ"
assert_contains "skills/a/SKILL.md"
assert_contains "devflow-stamp:"
assert_json '.systemMessage | contains("out of date")' 'true'

t "a directory added upstream is reported"
setup
mkdir -p plugins/devflow/agents && echo "x" >plugins/devflow/agents/new.md
commit add >/dev/null
check
assert_contains "for example: agents."

t "the plugin manager's marker files in the loaded root are ignored"
setup
touch "$root/.in_use"
check
assert_out ""

t "a change outside the plugin directory prints nothing"
setup
echo "docs" >README.md
commit docs >/dev/null
check
assert_out ""

t "an unreachable upstream prints nothing and exits 0"
setup
run env -u GITHUB_ACTIONS "$SCRIPTS/version-check" --plugin-root "$root" --upstream "$upstream/missing"
assert_rc 0
assert_out ""

t "under GitHub Actions the check is skipped"
setup
echo "b" >plugins/devflow/skills/a/SKILL.md
commit change >/dev/null
run env GITHUB_ACTIONS=true "$SCRIPTS/version-check" --plugin-root "$root" --upstream "$upstream"
assert_out ""

t "a plugin root inside a git checkout is skipped"
setup
echo "b" >plugins/devflow/skills/a/SKILL.md
root=$upstream/plugins/devflow
check
assert_out ""

t "without --upstream the repository in plugin.json is used"
setup
jq -n --arg r "$upstream" '{name: "devflow", repository: $r}' >"$root/.claude-plugin/plugin.json"
check_default() { run env -u GITHUB_ACTIONS "$SCRIPTS/version-check" --plugin-root "$root"; }
check_default
assert_contains ".claude-plugin/plugin.json"
