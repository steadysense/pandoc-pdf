#!/bin/sh -l

set -euf -o pipefail

echo "Github workspace files:"
ls -la "/github/workspace"

echo "Template directory file:"
#ls -la "/github/workspace/$1"
ls -la "/github/workspace/templates"

echo "Documents to convert:"
#ls -la "/github/workspace/$2"
ls -la "/github/workspace/documents"


for f in $(find "/github/workspace/$2" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
