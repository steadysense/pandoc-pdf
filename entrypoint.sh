#!/bin/sh -l

set -euf -o pipefail

echo "Template files"
echo "Changing pwd to $1"
cd "$(dirname "$1")"

echo "Directory of files to convert"
echo "$2"

for f in $(find $2 -name "*.md" | grep "FB\|PB\|DA"); do
  build.sh $f
done
