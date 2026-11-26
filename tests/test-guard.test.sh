# shellcheck shell=bash disable=SC2016,SC2089,SC2090 # fixtures hold literal $, backticks and JSON
# test-guard: after the test commit, test code may grow but never shrink or change.

setup() {
  git_repo
  mkdir -p tests src
  printf 'test_a\ntest_b\n' >tests/a.txt
  printf 'fn main() {}\n\n#[cfg(test)]\nmod tests {\n  fn t() {}\n}\n' >src/lib.rs
  since=$(commit tests)
}
guard() { run "$SCRIPTS/test-guard" --since "$since" --marker '#\[cfg\(test\)\]' 'tests/**' "$@"; }

t "adding tests and changing code above the marker is clean"
setup
printf 'test_c\n' >>tests/a.txt
sed -i 's/fn main() {}/fn main() { run(); }/' src/lib.rs
commit impl >/dev/null
guard
assert_rc 0

t "a changed line in a test file is a violation"
setup
sed -i 's/test_a/test_x/' tests/a.txt
c=$(commit weaken)
guard
assert_rc 1
assert_contains "tests/a.txt:1: test code removed or changed in ${c:0:12}"

t "a removed line below the inline test marker is a violation"
setup
sed -i '/fn t()/d' src/lib.rs
commit weaken >/dev/null
guard
assert_rc 1
assert_contains "src/lib.rs:5:"

t "an allowed commit may change test code"
setup
sed -i '/test_b/d' tests/a.txt
c=$(commit review)
guard --allow "$c"
assert_rc 0

t "an uncommitted change to test code is a violation"
setup
sed -i 's/test_b/test_y/' tests/a.txt
guard
assert_rc 1
assert_contains "the uncommitted working tree"

t "missing --since is a usage error"
setup
run "$SCRIPTS/test-guard" 'tests/**'
assert_rc 2

t "--base protects test code present in the base"
setup
base=$since
sed -i 's/test_a/test_x/' tests/a.txt
commit weaken >/dev/null
run "$SCRIPTS/test-guard" --base "$base" --marker '#\[cfg\(test\)\]' 'tests/**'
assert_rc 1
assert_contains "tests/a.txt:1:"

t "--base lets the branch edit a test it added itself"
setup
base=$since
printf 'test_new\n' >tests/b.txt
commit add-test >/dev/null
sed -i 's/test_new/test_newer/' tests/b.txt
commit edit-own-test >/dev/null
run "$SCRIPTS/test-guard" --base "$base" --marker '#\[cfg\(test\)\]' 'tests/**'
assert_rc 0

t "--base still protects inline test code below the marker"
setup
base=$since
sed -i '/fn t()/d' src/lib.rs
commit weaken >/dev/null
run "$SCRIPTS/test-guard" --base "$base" --marker '#\[cfg\(test\)\]' 'tests/**'
assert_rc 1
