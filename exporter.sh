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
    api_request "${1}" "${2}" \
      | jq -r "if type==\"array\" then .[] else . end| .${3}"
}

for row in "${ORGS[@]}" ; do
    ORG=${row%%:*}
    KEY=${row#*:}
    DIR="$FILE_DIR/$ORG"

    mkdir -p "$DIR/dashboards"
    mkdir -p "$DIR/datasources"
    mkdir -p "$DIR/alert-notifications"

    for dash in $(fetch_fields "${KEY}" '/search?query=&' 'uri'); do
        DB=$(echo "${dash}" | sed 's,db/,,g').json
        echo "$DB"
        api_request "${KEY}" "/dashboards/${dash}" | jq 'del(.overwrite,.dashboard.version,.meta.created,.meta.createdBy,.meta.updated,.meta.updatedBy,.meta.expires,.meta.version)' > "$DIR/dashboards/$DB"
    done

    for id in $(fetch_fields "${KEY}" '/datasources' 'id'); do
        DS=$(echo "$(fetch_fields "${KEY}" "/datasources/${id}" 'name')" | sed 's/ /-/g').json
        echo "${DS}"
        api_request "$KEY" "/datasources/${id}" | jq '' > "$DIR/datasources/${id}.json"
    done

    for id in $(fetch_fields "${KEY}" '/alert-notifications' 'id'); do
        FILENAME=${id}.json
        echo "${FILENAME}"
        api_request "/alert-notifications/${id}" \
          | jq 'del(.created,.updated)' > "$DIR/alert-notifications/$FILENAME"
    done
done
