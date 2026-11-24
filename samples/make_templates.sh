#!/usr/bin/env bash
# Regenerate the template outputs in the sample folder using the
# executable built in this repository. WARNING: overwrites the templates.
set -eu

SAMPLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXE="$(dirname "$SAMPLES_DIR")/bin/sources4d"

[ -x "$EXE" ] || { echo "Executable not found: build the code first (make)." >&2; exit 1; }

for test_dir in "$SAMPLES_DIR"/test*/; do
  echo "*** $(basename "$test_dir") ***"
  (
    cd "$test_dir"
    rm -rf tape6 tape7 tape8 tape9 pdata sdata outp outp2
    for n in 2 3 4 5; do
      ln -sf "../../data/tape${n}.txt" "tape${n}"
    done
    "$EXE"
  )
  echo
done