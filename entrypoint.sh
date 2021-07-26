#!/bin/bash
env

set -euf -o pipefail

echo "Document Directory: $INPUT_DOCUMENT_DIRECTORY"
DOCUMENT_DIR="$(realpath "$INPUT_DOCUMENT_DIRECTORY")"
echo "Document Directory: $DOCUMENT_DIR"
export DOCUMENT_DIR

echo "Template Directory: $INPUT_TEMPLATE_DIRECTORY"
TEMPLATE_DIR="$(realpath "$INPUT_TEMPLATE_DIRECTORY")"
echo "Template Directory: $TEMPLATE_DIR"
export TEMPLATE_DIR
TEMPLATE_DIR="$(realpath "$INPUT_TEMPLATE_DIRECTORY")"

export TEXINPUTS=".:$TEMPLATE_DIR:"

exec "$@"

