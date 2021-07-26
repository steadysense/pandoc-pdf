#!/bin/sh -l

set -euf -o pipefail

echo "$(pwd)"
echo "$(ls -la)"

echo "$(env)"

echo "Document Directory: $INPUT_DOCUMENT_DIRECTORY"
echo "Template Directory: $INPUT_TEMPLATE_DIRECTORY"

DOCUMENT_GLOB="$(pwd)/$INPUT_DOCUMENT_DIRECTORY/"'**/*.md'

cd "${INPUT_TEMPLATE_DIRECTORY}"
exec "$@" "${DOCUMENT_GLOB}"

