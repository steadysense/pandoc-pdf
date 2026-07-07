#!/bin/bash

set -euf -o pipefail

echo "Document Directory: $INPUT_DOCUMENT_DIRECTORY"
DOCUMENT_DIR="$(realpath "$INPUT_DOCUMENT_DIRECTORY")"
echo "Document Directory: $DOCUMENT_DIR"
export DOCUMENT_DIR

# Use external template directory if provided, otherwise fall back to bundled /typst
if [[ -n "${INPUT_TEMPLATE_DIRECTORY:-}" ]]; then
  TEMPLATE_DIR="$(realpath "$INPUT_TEMPLATE_DIRECTORY")"
  echo "Template Directory: $TEMPLATE_DIR (external)"
else
  TEMPLATE_DIR="/typst"
  echo "Template Directory: $TEMPLATE_DIR (bundled)"
fi
export TEMPLATE_DIR

exec "$@"
