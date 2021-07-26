#!/usr/bin/env bash

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
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

mkpdf () {
  ORIG_PATH=$(pwd)

  pushd "$(dirname "$0")"
  FILENAME=`basename "$1"`
  RESOURCE_PATH="$(dirname $1)"
  if [[ $RESOURCE_PATH = "." ]]; then
    RESOURCE_PATH=""
  fi

  OUTPUT_PATH="${ORIG_PATH}/build"
  TEMPLATE_NAME="main.tex"
  INPUT="${ORIG_PATH}/${RESOURCE_PATH}/${FILENAME}"
  OUTPUT="${OUTPUT_PATH}/$(echo ${FILENAME} | sed 's/md/pdf/')"

  echo "Converting ${INPUT} to ${OUTPUT}"

  mkdir -p $OUTPUT_PATH
  pandoc $INPUT \
    -o $OUTPUT \
    --top-level-division=chapter \
    --template=$TEMPLATE_NAME \
    --toc \
	--listings \
    --filter pandoc_filter \
    --resource-path=$RESOURCE_PATH \
	--pdf-engine=lualatex \
	--variable build-version=${VERSION}

  popd
}


echo "Working Directory $(pwd)"

if [[ $1 = "-h" || $1 = "--help" ]]; then
    echo "$HELP"
    exit 0
fi

if [[ $# -eq 0 || $1 = "--all" ]]; then
    echo "Searching documents in $2"
    for f in $(find "$2" -name "*.md" | grep "FB\|PB\|DA"); do
        mkpdf "${f}"
    done
else
  echo "Searching documents in $1"
  for f in $(find "$1" -name "*.md" | grep "FB\|PB\|DA"); do
    mkpdf "${f}"
  done
fi
