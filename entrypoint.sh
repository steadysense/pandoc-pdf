#!/bin/sh -l -x

set -euf -o pipefail

for f in $(find $2 -name "*.md" | grep "FB\|PB\|DA"); do
  echo "Converting $f"
  build.sh $f
done
