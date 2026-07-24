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

  # Typst resolves relative image paths from the directory pandoc runs in, NOT
  # from the input file's location. Author-relative paths in the markdown (e.g.
  # "assets/foo.png", relative to the document) therefore only resolve when
  # pandoc runs from the document's own directory — otherwise the build either
  # fails or, depending on the engine, silently comes out image-less. So we run
  # pandoc from INPUT_DIR and make the template logo available there too
  # (a symlink we create and clean up, never touching a logo the doc ships).
  local LOGO_LINK="${INPUT_DIR}/steadylogo.pdf"
  local CLEAN_LOGO=0
  if [[ ! -e "$LOGO_LINK" ]]; then
    if ln -sf "${TEMPLATE_DIR}/steadylogo.pdf" "$LOGO_LINK" 2>/dev/null; then
      CLEAN_LOGO=1
    fi
  fi

  logi "Converting ${INPUT_ABS} -> ${OUTPUT}"

  local rc=0
  (
    cd "$INPUT_DIR"
    pandoc "$INPUT_ABS" \
      --from markdown+emoji \
      --to typst \
      --wrap=none \
      --template "${TEMPLATE_DIR}/template.typ" \
      --toc \
      --number-sections \
      --lua-filter "${TEMPLATE_DIR}/fix-internal-links.lua" \
      --lua-filter "${TEMPLATE_DIR}/strip-toc-marker.lua" \
      --lua-filter "${TEMPLATE_DIR}/table-columns.lua" \
      --lua-filter "${TEMPLATE_DIR}/fix-typst-escaping.lua" \
      --resource-path "${TEMPLATE_DIR}:${INPUT_DIR}" \
      --metadata "release-tag=${RELEASE}" \
      --metadata "body-font=Liberation Sans" \
      --metadata "code-font=Liberation Mono" \
      --output "${OUTPUT}"
  ) || rc=$?

  if [[ "$CLEAN_LOGO" = 1 ]]; then rm -f "$LOGO_LINK"; fi
  return "$rc"
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
