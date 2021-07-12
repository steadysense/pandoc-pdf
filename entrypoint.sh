#!/bin/sh -l

set -euf -o pipefail

echo "Github workspace files:"
ls -la "/github/workspace"

echo "Template directory file:"
ls -la $1

echo "Documents to convert:"
ls -la $2

for f in $(find "$2" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
