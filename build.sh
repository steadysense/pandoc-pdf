#!/bin/bash

HELP=$(cat <<-END
Usage: ./build.sh [OPTIONS] [ARGUMENTS]

Arguments:
    filename   markdown file to be converted

Options:
    --all   Recursively convert all *.md files in the working directory to *.pdf files.
            Output files are stored in ./build

Examples:
    Single file: ./build.sh '2.2_Entwicklung/FB_2.2_02_Requirement-Specification.md'
    All files:   ./build.sh --all
END
)

logd () {
  if [[ $DEBUG ]]; then
    logd "$@";
  fi
}

logi () {
  echo "$@";
}

spushd () {
    command pushd "$@" || exit 1 > /dev/null
}

spopd () {
    command popd || exit 1 > /dev/null
}

mkpdf () {
  ORIG_PATH=$(pwd)

  INPUT="$1"
  INPUT_FILE=$(basename "$INPUT")
  INPUT_PATH=$(dirname "$INPUT")
  OUTPUT=${ORIG_PATH}/build${INPUT#$DOCUMENT_DIR}
  OUTPUT=${OUTPUT//.md/.pdf}
  OUTPUT_PATH=$(dirname "${OUTPUT}")
  logd "INPUT $INPUT"
  logd "INPUT_FILE $INPUT_FILE"
  logd "INPUT_PATH $INPUT_PATH"
  logd "OUTPUT_PATH $OUTPUT_PATH"
  logd "OUTPUT $OUTPUT"

  PANDOC_TEMPLATE="main.tex"
  PANDOC_FILTER="/usr/local/bin/pandoc_filter"

  mkdir -p "$OUTPUT_PATH"

  logi "Converting ${INPUT} to ${OUTPUT}"
  spushd "$INPUT_PATH"
  pandoc "$INPUT_FILE" \
    -o "$OUTPUT" \
    --top-level-division=chapter \
    --template="$PANDOC_TEMPLATE" \
    --toc \
    --listings \
    --filter "$PANDOC_FILTER" \
    --resource-path="$TEMPLATE_DIR" \
    --data=dir="$TEMPLATE_DIR" \
    --pdf-engine=lualatex \
    --variable build-version="$VERSION"
  spopd
}

export -f mkpdf logi logd spushd spopd

logd "Working Directory $(pwd)"
logd "$@"

for arg in "$@"; do
  logd "$arg";
done

logd "Finished checking args"

if [[ $1 = "-h" || $1 = "--help" ]]; then
    logd "$HELP"
    exit 0
fi

logd "Searching documents in DOCUMENT_DIR $DOCUMENT_DIR"
find "$DOCUMENT_DIR" -name "*.md" | grep "FB\|PB\|DA" | parallel --jobs 200% mkpdf {}
