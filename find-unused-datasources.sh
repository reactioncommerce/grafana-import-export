#!/usr/bin/env bash

# Please Use Google Shell Style: https://google.github.io/styleguide/shell.xml

# ---- Start unofficial bash strict mode boilerplate
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit  # always exit on error
set -o errtrace # trap errors in functions as well
set -o pipefail # don't ignore exit codes when piping output
set -o posix    # more strict failures in subshells
# set -x          # enable debugging

IFS=$'\n\t'
# ---- End unofficial bash strict mode boilerplate

##### Prereqs #####
# Install jq from ( https://stedolan.github.io/jq/ )

##### Usage #####
# ./find-unused-datasources.sh path/to/grafana/export/base

export_base="$1"
used=$(find "${export_base}/dashboards" -type f -name '*.json' -print0 |
  xargs -0 jq -r '.dashboard.panels[].datasource' 2>/dev/null | grep -v null | sort | uniq)

find "${export_base}/datasources" -type f -name '*.json' -print0 |
  xargs -0 jq -r '.name' |
  {
    while IFS= read -r name; do
      if echo "${used}" | grep -q "^${name}\$"; then
        echo "✓ ${name}"
      else
        echo "× ${name}"
      fi
    done
  }
