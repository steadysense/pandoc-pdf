#!/bin/sh -l

set -euf -o pipefail

echo env | sort
echo ls -la

for f in $(find "/documents" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
