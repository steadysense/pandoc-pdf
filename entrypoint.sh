#!/bin/sh -l

set -euf -o pipefail

echo "Github workspace files:"
ls -la "/github/workspace"

echo "Template directory file:"
ls -la "templates"

echo "Documents to convert:"
ls -la "documents"

for f in $(find "/documents" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
