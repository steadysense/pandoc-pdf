#!/bin/bash

set -euf -o pipefail

echo "Document Directory: $INPUT_DOCUMENT_DIRECTORY"
DOCUMENT_DIR="$(realpath "$INPUT_DOCUMENT_DIRECTORY")"
echo "Document Directory: $DOCUMENT_DIR"
export DOCUMENT_DIR

exec "$@"
