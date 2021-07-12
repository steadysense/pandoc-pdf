#!/bin/sh -l

set -euf -o pipefail

env | sort
ls -la

for f in $(find "/documents" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
