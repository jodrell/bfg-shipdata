#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

DIR="$(dirname "$0")"
PATH="${PATH}:${DIR}"

pushd "$DIR" > /dev/null

generate_site() {
  rm -rf "${DIR}/_site"

  bfgdata.pl
}

generate_site

php -S 127.0.0.1:8080 -t _site &

open http://127.0.0.1:8080

fswatch -or "${DIR}" -e "${DIR}/_site" | while read e ; do generate_site ; done

wait
