# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# e2e-guard: acceptance tests are frozen after the test commit and never skipped.

setup() {
  git_repo
  mkdir -p e2e app
  echo "base" >app/a.txt
  base=$(commit base)
  printf "test('signs up', async () => {});\n" >e2e/signup.spec.ts
  since=$(commit tests)
}
guard() { run "$SCRIPTS/e2e-guard" --base "$base" --since "$since" 'e2e/**' "$@"; }

t "changes outside the acceptance paths are clean"
setup
echo "impl" >>app/a.txt
commit impl >/dev/null
guard
assert_rc 0

t "an acceptance test changed after the test commit is a violation"
setup
echo "// tweak" >>e2e/signup.spec.ts
c=$(commit weaken)
guard
assert_rc 1
assert_contains "e2e/signup.spec.ts: changed in ${c:0:12}"

t "an allowed commit may change acceptance tests"
setup
printf "test('logs in', async () => {});\n" >>e2e/signup.spec.ts
c=$(commit challenge)
guard --allow "$c"
assert_rc 0

t "an untracked acceptance file is a violation"
setup
echo "x" >e2e/new.spec.ts
guard
assert_rc 1
assert_contains "changed in the uncommitted working tree"

t "test.only added since the base is a violation even in an allowed commit"
setup
printf "test.only('logs in', async () => {});\n" >>e2e/signup.spec.ts
c=$(commit focus)
guard --allow "$c"
assert_rc 1
assert_contains "adds test.only"

t "describe.skip is a violation"
setup
printf "test.describe.skip('all', () => {});\n" >>e2e/signup.spec.ts
c=$(commit skip)
guard --allow "$c"
assert_rc 1
assert_contains "adds test.describe.skip"

t "missing --base is a usage error"
setup
run "$SCRIPTS/e2e-guard" --since "$since" 'e2e/**'
assert_rc 2
