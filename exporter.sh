#!/usr/bin/env bash

# Load config.sh file passed as command line argument
. "$1"

function api_request() {
  local key=$1
  local resource=$2
  curl \
    --fail \
    --header "Authorization: Bearer $key" \
    --header "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}" \
    --header "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}" \
    --location \
    --show-error \
    --silent \
    "${HOST}/api${resource}"
}

fetch_fields() {
  local key=$1
  local resource=$2
  api_request "${1}" "${2}" |
    jq -r "if type==\"array\" then .[] else . end| .${3}"
}

for row in "${ORGS[@]}"; do
  ORG=${row%%:*}
  KEY=${row#*:}
  DIR="$FILE_DIR/$ORG"

  mkdir -p "$DIR/datasources"
  mkdir -p "$DIR/folders"
  mkdir -p "$DIR/dashboards"
  mkdir -p "$DIR/alert-notifications"

  for id in $(fetch_fields "${KEY}" '/datasources' 'id'); do
    out="datasources/${id}.json"
    echo -n "${out}…"
    api_request "$KEY" "/datasources/${id}" | jq '' >"${DIR}/${out}"
    echo ✓
  done

  for uid in $(fetch_fields "${KEY}" '/folders' 'uid'); do
    out="folders/${uid}.json"
    echo -n "${out}…"
    api_request "$KEY" "/folders/${uid}" | jq 'del(.id)' >"${DIR}/${out}"
    echo ✓
  done

  for dash in $(fetch_fields "${KEY}" '/search?query=&' 'uri'); do
    out="dashboards/$(echo "${dash}" | sed 's,db/,,g').json"
    echo -n "${out}…"
    api_request "${KEY}" "/dashboards/${dash}" | jq 'del(.dashboard.id,.dashboard.version,.meta) | .overwrite=true' >"$DIR/${out}"
    echo ✓
  done

  for id in $(fetch_fields "${KEY}" '/alert-notifications' 'id'); do
    FILENAME=${id}.json
    echo "alert: ${FILENAME}"
    api_request "${KEY}" "/alert-notifications/${id}" |
      jq 'del(.created,.updated)' >"$DIR/alert-notifications/$FILENAME"
  done
done
