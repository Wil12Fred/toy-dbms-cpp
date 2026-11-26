#!/usr/bin/env bash
# Golden tests: run each tests/cases/<name>.sql through the engine in an empty
# directory and compare stdout (timing lines removed), the exit status and the
# data files it wrote with tests/cases/<name>.expected.
# UPDATE=1 tests/run.sh rewrites the .expected files instead of comparing.
set -u
here=$(cd "$(dirname "$0")" && pwd)
bin=$(cd "$here/.." && pwd)/build/bdii
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
fail=0
for sql in "$here"/cases/*.sql; do
  name=$(basename "$sql" .sql)
  dir="$work/$name"; mkdir -p "$dir"
  out="$work/$name.actual"
  ( cd "$dir" && "$bin" < "$sql" > stdout.log 2> stderr.log; echo "exit status: $?" > status )
  {
    echo "### stdout"
    grep -v -E '^(Query|Execution) Time: ' "$dir/stdout.log" | sed -E 's/(Query|Execution) Time: [0-9.e+-]+//'
    echo "### $(cat "$dir/status")"
    for f in $(cd "$dir" && ls | grep -v -E '^(stdout|stderr)\.log$|^status$' | sort); do
      echo "### file $f"
      cat "$dir/$f"; echo
    done
  } > "$out"
  if [ "${UPDATE:-0}" = 1 ]; then
    cp "$out" "$here/cases/$name.expected"; echo "updated $name"
  elif diff -u "$here/cases/$name.expected" "$out" > "$work/$name.diff"; then
    echo "PASS $name"
  else
    echo "FAIL $name"; cat "$work/$name.diff"; fail=1
  fi
done
exit $fail
