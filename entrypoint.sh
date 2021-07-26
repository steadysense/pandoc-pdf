#!/bin/sh -l

set -euf -o pipefail

echo "$(pwd)"
echo ""$(ls -la)"

exec "$@"

