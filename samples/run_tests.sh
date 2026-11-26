#!/usr/bin/env bash
# Run the sample tests in SOURCES4D/run_samples and compare the results
# with the reference outputs stored in the samples folder.
#
# Usage: run_tests.sh [testN ...]   (default: all the tests in samples/)
# Examples:
#   ./samples/run_tests.sh                 # all the tests
#   ./samples/run_tests.sh test3           # only test3
#   ./samples/run_tests.sh test1 test3     # more than one test
#   ./samples/run_tests.sh 3 10            # short form: same as test3 test10
# Usage with Makefile: make test TESTS="testN ..."  
# Examples:
#   make test                     # all the tests
#   make test TESTS="test3"       # only test3
#   make test TESTS="3"           # only test3 short form
#   make test TESTS="test1 3"     # only test1 and test3

set -u

SAMPLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SAMPLES_DIR")"
EXE="$ROOT_DIR/bin/sources4d"
DATA_DIR="$ROOT_DIR/data"
RUN_ROOT="$ROOT_DIR/run_samples"

# Output files written by the code
OUTPUT_FILES=(outp outp2 pdata sdata tape6 tape7 tape8 tape9)

[ -x "$EXE" ] || { echo "Executable not found: build the code first (make)." >&2; exit 1; }

# Tests to run: the ones given as arguments, or all of them in natural order
# accepts "N", "testN" and "testN/" for the same test
mapfile -t available < <(cd "$SAMPLES_DIR" && ls -d test*/ 2>/dev/null | tr -d / | sort -V)
[ "${#available[@]}" -gt 0 ] || { echo "No tests found in $SAMPLES_DIR." >&2; exit 1; }

if [ "$#" -gt 0 ]; then
  tests=()
  invalid=()
  for arg in "$@"; do
    arg="${arg%/}"                 # accept "test3/"
    name="test${arg#test}"         # accept "3" and "test3"
# accepts only names that match an existing test (fixed-string match)
    if printf '%s\n' "${available[@]}" | grep -qxF -- "$name"; then
      tests+=("$name")
    else
      invalid+=("$arg")
    fi
  done
# stop before running anything if some argument is not valid
  if [ "${#invalid[@]}" -gt 0 ]; then
    echo "Unknown test(s): ${invalid[*]}" >&2
    echo "Available tests: ${available[*]}" >&2
    echo "Usage: $0 [testN ...]   e.g. $0 test1 3" >&2
    exit 2
  fi
else
  tests=("${available[@]}")
fi

# Clean the whole run directory only when all the tests are run;
# with a subset, only the directories of the selected tests are replaced.
if [ "$#" -eq 0 ]; then
  rm -rf "$RUN_ROOT"
fi
mkdir -p "$RUN_ROOT"
DIFFS="$RUN_ROOT/diffs"      # refers to the last run only
: > "$DIFFS"
echo "# Tests run: ${tests[*]}" > "$DIFFS"
echo "Results in: $RUN_ROOT"

failed_tests=()

for name in "${tests[@]}"; do
  template_dir="$SAMPLES_DIR/$name"
  run_dir="$RUN_ROOT/$name"
  problems=()

  if [ ! -f "$template_dir/tape1" ]; then
    echo "FAIL  $name (input file $template_dir/tape1 not found)"
    failed_tests+=("$name")
    continue
  fi

  # Prepare the run directory: input file and links to the data files
  rm -rf "$run_dir"          
  mkdir -p "$run_dir"
  cp "$template_dir/tape1" "$run_dir/"
  for n in 2 3 4 5; do
    ln -sf "$DATA_DIR/tape${n}.txt" "$run_dir/tape${n}"
  done

  # Run. On many errors the code stops with exit status 0 (e.g. "STOP Error
  # in input"), so a run is considered successful only if it ends with
  # "Normal Execution".
  if ! ( cd "$run_dir" && "$EXE" > run.log 2>&1 ) ||
     ! grep -q "Normal Execution" "$run_dir/run.log"; then
    problems+=("abnormal termination: see $name/run.log")
  fi

  # Compare each output file with the reference, in both directions.
  # Skipped if the run failed: its outputs are not meaningful.
  if [ "${#problems[@]}" -eq 0 ]; then
    for f in "${OUTPUT_FILES[@]}"; do
      ref="$template_dir/$f"
      out="$run_dir/$f"
      if [ -e "$ref" ] && [ ! -e "$out" ]; then
        problems+=("$f missing")
        echo "=== $name/$f: missing in the run" >> "$DIFFS"
      elif [ ! -e "$ref" ] && [ -e "$out" ]; then
        problems+=("$f not in reference")
        echo "=== $name/$f: produced by the run, not present in the reference" >> "$DIFFS"
      elif [ -e "$ref" ] && ! cmp -s "$ref" "$out"; then
        problems+=("$f differs")
        echo "=== $name/$f" >> "$DIFFS"
        diff -u --label "reference $name/$f" --label "run $name/$f" "$ref" "$out" >> "$DIFFS"
      fi
    done
  fi

  if [ "${#problems[@]}" -eq 0 ]; then
    echo "PASS  $name"
    echo "PASS  $name" >> "$DIFFS"
  else
    printf -v msg '%s, ' "${problems[@]}"
    echo "FAIL  $name (${msg%, })"
    echo "FAIL  $name (${msg%, })" >> "$DIFFS"
    failed_tests+=("$name")
  fi
done

echo
echo "$((${#tests[@]} - ${#failed_tests[@]}))/${#tests[@]} tests identical to the reference outputs."
if [ "${#failed_tests[@]}" -gt 0 ]; then
  echo "Failed: ${failed_tests[*]}"
  [ -s "$DIFFS" ] && echo "Differences in: $DIFFS"
  exit 1
fi