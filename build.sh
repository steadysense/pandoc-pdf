#!/bin/bash

ls -la /usr/local/bin

env

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

pushd () {
    command pushd "$@" || exit 1 > /dev/null
}

popd () {
    command popd || exit 1 > /dev/null
}

mkpdf () {
  ORIG_PATH=$(pwd)

  INPUT="$1"
  INPUT_FILE=$(basename "$INPUT")
  INPUT_PATH=$(dirname "$INPUT")
  OUTPUT=${ORIG_PATH}/build${INPUT#$DOCUMENT_DIR}
  OUTPUT=${OUTPUT//.md/.pdf}
  OUTPUT_PATH=$(dirname ${OUTPUT})
  echo "INPUT $INPUT"
  echo "INPUT_FILE $INPUT_FILE"
  echo "INPUT_PATH $INPUT_PATH"
  echo "OUTPUT_PATH $OUTPUT_PATH"
  echo "OUTPUT $OUTPUT"

  PANDOC_TEMPLATE="main.tex"
  PANDOC_FILTER="/usr/local/bin/pandoc_filter"
  PANDOC_TEMPLATE_DIR="$TEMPLATE_DIR"

  echo "Converting ${INPUT} to ${OUTPUT}"

  mkdir -p "$OUTPUT_PATH"
  pushd "$INPUT_PATH" || exit 1

  pandoc "$INPUT_FILE" \
    -o "$OUTPUT" \
    --top-level-division=chapter \
    --template="$PANDOC_TEMPLATE" \
    --toc \
	--listings \
    --filter "$PANDOC_FILTER" \
    --resource-path="$PANDOC_TEMPLATE_DIR" \
  --data=dir="$PANDOC_TEMPLATE_DIR" \
	--pdf-engine=lualatex \
	--variable build-version="$VERSION"

  popd || exit 1
}


echo "Working Directory $(pwd)"
echo "$@"

for arg in "$@"; do
  echo "$arg";
done

echo "Finished checking args"

if [[ $1 = "-h" || $1 = "--help" ]]; then
    echo "$HELP"
    exit 0
fi

echo "Searching documents in DOCUMENT_DIR $DOCUMENT_DIR"
for f in $(find "$DOCUMENT_DIR" -name "*.md" | grep "FB\|PB\|DA"); do
  echo "$f"
  mkpdf "${f}"
done
