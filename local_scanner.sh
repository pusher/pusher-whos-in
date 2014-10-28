#!/usr/bin/env bash

APP_USERNAME="foo"
APP_PASSWORD="bar"
WHOSIN_URL="http://localhost:9393/people"

local_scan() {
  macs=( $(sudo nmap -sn 192.168.1.0/24 | grep -Eio "([0-9A-F]{2}:){5}[0-9A-F]{2}") )
}

update_offline_since() {
  local json=()
  local DATE=$(date)

  for i in "${!macs[@]}"; do
    # json[$i]="\"${macs[$i]}\":{\"last_seen\": \"${DATE}\"}"

    json[$i]="{\"mac\": \"${macs[$i]}\"}"

    # json[$i]= "'mac': '${macs[$i]}', 'last_seen': '${DATE}'"

    # json[$i]="'mac':"

  done

  json=$( IFS=, ; echo "${json[*]}")
  json="[$json]"

  curl -X POST -d "$json" $WHOSIN_URL > /dev/null &

  echo $json
}

local_scan

if [ ${#macs[@]} -eq 0 ]; then
  echo "{'error': 'Nobody here'}"
else
  update_offline_since
fi