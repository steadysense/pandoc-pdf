#!/bin/sh -l

set -euf -o pipefail

echo "pwd:"
pwd

echo "Env:"
env

echo "Find:"
find . -path '**/.git' -prune -false -o -name '*'

echo "Tree:"
tree

echo "Document Directory: $INPUT_DOCUMENT_DIRECTORY"
echo "Template Directory: $INPUT_TEMPLATE_DIRECTORY"

DOCUMENT_GLOB="$(pwd)/$INPUT_DOCUMENT_DIRECTORY/"'**/*.md'

cd "${INPUT_TEMPLATE_DIRECTORY}"
exec "$@" "${DOCUMENT_GLOB}"

