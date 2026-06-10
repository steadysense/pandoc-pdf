#!/bin/bash

set -euf -o pipefail

TEMPLATE_DIR="${TEMPLATE_DIR:-/typst}"
DOC_ID="${DOC_ID:-FB\|PB\|DA\|AA\|QMH}"
RELEASE="${RELEASE:-draft}"
ORIG_PATH="$(pwd)"

logi() {
  echo "$@"
}

mkpdf() {
  local INPUT="$1"
  local INPUT_ABS
  INPUT_ABS="$(realpath "$INPUT")"
  local INPUT_DIR
  INPUT_DIR="$(dirname "$INPUT_ABS")"

  local OUTPUT="${ORIG_PATH}/build${INPUT#$DOCUMENT_DIR}"
  OUTPUT="${OUTPUT//.md/.pdf}"
  mkdir -p "$(dirname "$OUTPUT")"

  logi "Converting ${INPUT_ABS} -> ${OUTPUT}"

  pandoc "$INPUT_ABS" \
    --to typst \
    --template "${TEMPLATE_DIR}/template.typ" \
    --toc \
    --number-sections \
    --lua-filter "${TEMPLATE_DIR}/strip-toc-marker.lua" \
    --lua-filter "${TEMPLATE_DIR}/table-columns.lua" \
    --lua-filter "${TEMPLATE_DIR}/fix-typst-escaping.lua" \
    --resource-path "${TEMPLATE_DIR}:${INPUT_DIR}" \
    --metadata "release-tag=${RELEASE}" \
    --output "${OUTPUT}"
}

export -f mkpdf logi

if [[ "${1:-}" = "-h" || "${1:-}" = "--help" ]]; then
  cat <<-END
Usage: build.sh

Environment variables:
    DOCUMENT_DIR   Directory containing the documents to convert
    DOC_ID         Regex pattern to filter documents (default: FB|PB|DA|AA|QMH)
    RELEASE        Release tag shown in the PDF header (default: draft)
END
  exit 0
fi

logi "Searching for documents in: $DOCUMENT_DIR"
logi "Filter pattern: $DOC_ID"
logi "Release tag:    $RELEASE"

for f in $(find "$DOCUMENT_DIR" -name "*.md" | grep -E "$DOC_ID"); do
  mkpdf "$f"
done
