# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# ci/check-plugin: manifests, frontmatter, scripts and the paths and names files refer to.

fixture() {
  root=$(mktemp -d)
  mkdir -p "$root/.claude-plugin" "$root/p/.claude-plugin" "$root/p/agents" "$root/p/skills/s/" \
    "$root/p/skills/base" "$root/p/scripts" "$root/p/hooks"
  echo '{"name":"m","owner":{"name":"o"},"plugins":[{"name":"p","source":"./p"}]}' >"$root/.claude-plugin/marketplace.json"
  echo '{"name":"p"}' >"$root/p/.claude-plugin/plugin.json"
  printf -- '---\nname: a\ndescription: "Does a: the thing"\ntools: Read, Bash, mcp__x__y\nskills: base\nmodel: opus\n---\nUse p:s and ${CLAUDE_PLUGIN_ROOT}/scripts/go.\n' >"$root/p/agents/a.md"
  printf -- '---\nname: s\ndescription: Skill s\n---\nRead ${CLAUDE_SKILL_DIR}/more.md and ${CLAUDE_SKILL_DIR}/../base/SKILL.md; spawn p:a.\n' >"$root/p/skills/s/SKILL.md"
  echo "more" >"$root/p/skills/s/more.md"
  mkdir -p "$root/wiki"
  echo 'Agents: a.' >"$root/README.md"
  echo '## a' >"$root/wiki/agents.md"
  printf -- '---\nname: base\ndescription: Base\nuser-invocable: false\n---\n' >"$root/p/skills/base/SKILL.md"
  printf '#!/usr/bin/env bash\n' >"$root/p/scripts/go" && chmod +x "$root/p/scripts/go"
  echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/go --hook"}]}]}}' >"$root/p/hooks/hooks.json"
}
check() { run "$REPO/ci/check-plugin" "$root"; }

t "a valid plugin passes"
fixture
check
assert_rc 0
assert_out ""

t "this repository passes"
run "$REPO/ci/check-plugin" "$REPO"
assert_rc 0

t "an unquoted colon in a description is invalid YAML"
fixture
sed -i 's/^description: "Does a: the thing"/description: Does a: the thing/' "$root/p/agents/a.md"
check
assert_rc 1
assert_contains "p/agents/a.md: frontmatter is not valid YAML"

t "a name that does not match its file fails"
fixture
sed -i 's/^name: s$/name: other/' "$root/p/skills/s/SKILL.md"
check
assert_contains "p/skills/s/SKILL.md: name 'other' does not match 's'"

t "unknown keys, tools, models and skills fail"
fixture
sed -i 's/^model: opus/model: gpt-4\nuser-invokable: true/; s/^tools: Read/tools: Raed/; s/^skills: base/skills: nope/' "$root/p/agents/a.md"
check
assert_contains "unknown frontmatter key 'user-invokable'"
assert_contains "tools names unknown tool 'Raed'"
assert_contains "model 'gpt-4'"
assert_contains "skills names 'nope'"

t "a missing description fails"
fixture
sed -i '/^description:/d' "$root/p/skills/base/SKILL.md"
check
assert_contains "p/skills/base/SKILL.md: description is missing or empty"

t "a version in either manifest fails"
fixture
echo '{"name":"p","version":"1.0.0"}' >"$root/p/.claude-plugin/plugin.json"
check
assert_contains "sets version"

t "a plugin name that differs from the marketplace entry fails"
fixture
echo '{"name":"q"}' >"$root/p/.claude-plugin/plugin.json"
check
assert_contains "does not match marketplace entry 'p'"

t "a missing plugin root or skill dir path fails"
fixture
echo 'See ${CLAUDE_PLUGIN_ROOT}/scripts/gone and ${CLAUDE_SKILL_DIR}/gone.md' >>"$root/p/skills/s/SKILL.md"
check
assert_contains '${CLAUDE_PLUGIN_ROOT}/scripts/gone does not exist'
assert_contains '${CLAUDE_SKILL_DIR}/gone.md does not exist'

t "a reference to an agent or skill that does not exist fails"
fixture
echo 'Then run p:nothing.' >>"$root/p/agents/a.md"
check
assert_contains "p:nothing is not an agent or skill of p"

t "a script that is not executable or has no shebang fails"
fixture
echo 'echo hi' >"$root/p/scripts/plain"
check
assert_contains "p/scripts/plain: not executable"
assert_contains "p/scripts/plain: no shebang"

t "a hook command that does not exist fails"
fixture
sed -i 's#scripts/go --hook#scripts/missing#' "$root/p/hooks/hooks.json"
check
assert_contains "hook command \${CLAUDE_PLUGIN_ROOT}/scripts/missing is missing or not executable"

t "invalid JSON in a manifest fails"
fixture
echo '{"name":' >"$root/.claude-plugin/marketplace.json"
check
assert_rc 1
assert_contains "marketplace.json: invalid JSON"

t "an agent not named in README.md or wiki/agents.md fails"
fixture
printf -- '---\nname: b\ndescription: Agent b\n---\n' >"$root/p/agents/b.md"
check
assert_rc 1
assert_contains "p/agents/b.md: agent is not named in README.md"
assert_contains "p/agents/b.md: agent is not named in wiki/agents.md"

t "an agent named only inside a longer hyphenated name is not documented"
fixture
printf -- '---\nname: b\ndescription: Agent b\n---\n' >"$root/p/agents/b.md"
echo 'Agents: a, a-b, b-a.' >"$root/README.md"
echo '## a' >>"$root/wiki/agents.md"
check
assert_contains "p/agents/b.md: agent is not named in README.md"
