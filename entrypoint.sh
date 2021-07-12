#!/bin/sh -l

set -euf -o pipefail

for f in $(find $2 -name "*.md" | grep "FB\|PB\|DA"); do
  build.sh $f
done
