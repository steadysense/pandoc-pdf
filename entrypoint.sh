#!/bin/sh -l

set -euf -o pipefail

for f in $(find "/data/documents" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
