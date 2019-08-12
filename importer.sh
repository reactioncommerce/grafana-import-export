#!/usr/bin/env bash

curl_wrap() {
  FILE=$1
  KEY=$2
  URL=$3
  HTTP_VERB=$4

  declare -a opts=(
    --verbose
    --fail
    --show-error
    --include
    --header "Accept:application/json"
    --header "Authorization: Bearer ${KEY}"
    --header "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}"
    --header "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}"
    --header "Content-Type:application/json"
    --data-binary @$FILE
  )

  if [[ -n "${HTTP_VERB}" ]]; then
    opts+=(--request "${HTTP_VERB}")
  fi

  opts+=("${URL}")

  curl "${opts[@]}"
}

import_file() {
  FILE="$1"
  KEY="$2"
  TYPE="$3"

  if ! [ -f "$FILE" ]; then
    echo "$FILE not found." >>/dev/stderr
    return
  fi
  echo "Processing $FILE file..."
  curl_wrap "$FILE" "$KEY" "${HOST}/api/$TYPE"
  CURL_EXIT=$?
  echo

  if [[ ${CURL_EXIT} == 22 && $TYPE == "datasources" ]]; then
    echo "409 conflict error is normal. Retrying as update."
    id=$(basename $file .json)
    curl_wrap "$FILE" "$KEY" "${HOST}/api/$TYPE/$id" PUT
  elif [[ ${CURL_EXIT} == 22 && $TYPE == "alert-notifications" ]]; then
    echo "500 server error is normal. Retrying as update."
    id=$(basename $file .json)
    curl_wrap "$FILE" "$KEY" "${HOST}/api/$TYPE/$id" PUT
  fi
}

# Load config.sh file passed as command line argument
. "$1"
shift

declare -aa ORGMAP
for row in "${ORGS[@]}"; do
  IFS=':' read -r -a values <<<"$row"
  ORGMAP[${values[0]}]=${values[1]}
done

if [[ $# -eq 0 ]]; then
  ARGS=(${FILE_DIR}/*/*/*.json)
else
  ARGS=("$@")
fi

for FILE in "${ARGS[@]}"; do

  IFS='/' read -r -a args <<<"$FILE"
  if [ ${#args[@]} -ne 4 ]; then
    echo "Wrong param \"${FILE}\". Must be data/{organization}/{type}/{file}"
  fi

  KEY=${ORGMAP[${args[1]}]}
  TYPE=${args[2]}
  # FILE=${args[3]}

  case $TYPE in
    alert-notifications)
      import_file $FILE "$KEY" 'alert-notifications'
      ;;
    dashboards)
      import_file $FILE "$KEY" 'dashboards/db'
      ;;
    datasources)
      import_file $FILE "$KEY" 'datasources'
      ;;
    folders)
      import_file $FILE "$KEY" 'folders'
      ;;
    *)
      echo "Unknown type $TYPE"
      ;;
  esac
done
