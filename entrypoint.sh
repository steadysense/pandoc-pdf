#!/bin/sh -l

set -euf -o pipefail

pwd
ls -la "templates"
ls -la "/github/workspace"

for f in $(find "/documents" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
