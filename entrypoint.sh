#!/bin/bash -l

set -euf -o pipefail

echo "Document Directory: $INPUT_DOCUMENT_DIRECTORY"
echo "Template Directory: $INPUT_TEMPLATE_DIRECTORY"

DOCUMENT_DIR="$(pwd)/$INPUT_DOCUMENT_DIRECTORY"

echo "Document Directory: $DOCUMENT_DIR"

cd "${INPUT_TEMPLATE_DIRECTORY}"

echo '$@:' "$@" "$DOCUMENT_DIR"

arr=("$@" "$DOCUMENT_DIR")

exec "${arr[@]}"

