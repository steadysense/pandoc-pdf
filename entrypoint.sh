#!/bin/sh -l

set -euf -o pipefail

echo "Template directory file:"
ls -la "templates"

echo "Github workspace files:"
ls -la "/github/workspace"

for f in $(find "/documents" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
