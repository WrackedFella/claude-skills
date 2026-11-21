# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# ci/check-links: relative Markdown links and their anchors resolve.

fixture() {
  root=$(mktemp -d)
  mkdir -p "$root/wiki" "$root/docs"
  printf '# Guide\n\n## Set up `just` (once)\n\n## Notes\n\n## Notes\n\n```md\n## Not a heading\n```\n' >"$root/wiki/guide.md"
  printf '# Doc\n' >"$root/docs/doc.md"
}
check() { run "$REPO/ci/check-links" "$root"; }

t "files, headings, duplicate headings and directories resolve"
fixture
printf '# Guide\n[a](guide.md) [b](guide.md#set-up-just-once) [c](guide.md#notes-1) [d](../docs/) [e](#guide) [f](https://x.y/z.md)\n' >"$root/wiki/README.md"
check
assert_rc 0
assert_out ""

t "this repository's links resolve"
run "$REPO/ci/check-links" "$REPO"
assert_rc 0

t "a missing file fails with its line"
fixture
printf 'line one\n[a](../docs/gone.md)\n' >"$root/wiki/README.md"
check
assert_rc 1
assert_out "wiki/README.md:2: ../docs/gone.md: no such file"

t "a missing heading fails"
fixture
printf '[a](guide.md#setup)\n' >"$root/wiki/README.md"
check
assert_out "wiki/README.md:1: guide.md#setup: no such heading"

t "a heading inside a code fence is not an anchor"
fixture
printf '[a](guide.md#not-a-heading)\n' >"$root/wiki/README.md"
check
assert_contains "no such heading"

t "links in code are ignored"
fixture
printf '`[a](gone.md)`\n\n```\n[b](gone.md)\n```\n' >"$root/wiki/README.md"
check
assert_rc 0
