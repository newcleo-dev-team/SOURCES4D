#!/usr/bin/env bash
# Run tests in SOURCES4D/run_samples and compare the results
# with the templates stored in the sample folder.
set -u

SAMPLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SAMPLES_DIR")"
EXE="$ROOT_DIR/bin/sources4d"
DATA_DIR="$ROOT_DIR/data"
RUN_ROOT="$ROOT_DIR/run_samples"

# Output files to be compared
OUTPUT_FILES=(outp outp2 pdata tape6 tape7 tape8 tape9)

[ -x "$EXE" ] || { echo "Executable not found: build the code first (make)." >&2; exit 1; }

# Start from a clean run directory
rm -rf "$RUN_ROOT"
mkdir -p "$RUN_ROOT"
DIFFS="$RUN_ROOT/diffs"
: > "$DIFFS"
echo "Results in: $RUN_ROOT"

failed_tests=()
total=0

for template_dir in "$SAMPLES_DIR"/test*/; do
  name="$(basename "$template_dir")"
  run_dir="$RUN_ROOT/$name"
  total=$((total + 1))

  echo "*** $name ***" >> "$DIFFS"
  ok=1

  # Copy tape1 from the template
  mkdir -p "$run_dir"
  if [ -e "$template_dir/tape1" ]; then
    cp "$template_dir/tape1" "$run_dir/"
  else
    echo "  missing input file tape1" >> "$DIFFS"
    ok=0
  fi

  # Links to the data files
  for n in 2 3 4 5; do
    ln -sf "$DATA_DIR/tape${n}.txt" "$run_dir/tape${n}"
  done

  # Run
  ( cd "$run_dir" && "$EXE" > run.log 2>&1 )
  run_status=$?
  [ "$run_status" -eq 0 ] || ok=0

  # Compare
  for f in "${OUTPUT_FILES[@]}"; do
    [ -e "$template_dir/$f" ] || continue
    echo "diff $f (run) $f (template)" >> "$DIFFS"
    if [ ! -e "$run_dir/$f" ]; then
      echo "  missing output file" >> "$DIFFS"
      ok=0
    elif ! diff "$run_dir/$f" "$template_dir/$f" >> "$DIFFS"; then
      ok=0
    fi
  done

  if [ "$ok" -eq 1 ]; then
    echo "PASS  $name"
  else
    echo "FAIL  $name (see $run_dir/run.log or $DIFFS)"
    failed_tests+=("$name")
  fi
done

echo
echo "$((total - ${#failed_tests[@]}))/$total tests identical to the templates."
if [ "${#failed_tests[@]}" -gt 0 ]; then
  echo "Failed: ${failed_tests[*]}"
  echo "Differences in: $DIFFS"
  exit 1
fi