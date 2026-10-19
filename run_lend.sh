#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter nu este in PATH. Instaleaza Flutter si adauga flutter/bin in PATH." >&2
  exit 1
fi

# Read values as data; never execute the contents of .env.
read_env() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  awk -v key="$key" '
    function trim(s) { sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
    /^[ \t]*#/ { next }
    {
      pos = index($0, "=")
      if (pos && trim(substr($0, 1, pos - 1)) == key) {
        value = trim(substr($0, pos + 1))
        quote = substr(value, 1, 1)
        if ((quote == "\"" || quote == sprintf("%c", 39)) && substr(value, length(value), 1) == quote)
          value = substr(value, 2, length(value) - 2)
        result = value
      }
    }
    END { printf "%s", result }
  ' "$file"
}

config() {
  local value
  value="$(read_env .env "$1")"
  if [[ -z "$value" ]]; then value="${!1:-}"; fi
  printf '%s' "$value"
}

local_url="$(config APP_BASE_URL_LOCAL)"
dev_url="$(config APP_BASE_URL_DEV)"
dev_url="${dev_url:-https://lend.bcmenu.ro}"
ios_client="$(config GOOGLE_IOS_CLIENT_ID)"
server_client="$(config GOOGLE_SERVER_CLIENT_ID)"
client_ids="$(config GOOGLE_CLIENT_IDS)"
if [[ -z "$client_ids" ]]; then client_ids="$(read_env backend/.env GOOGLE_CLIENT_IDS)"; fi
IFS=',' read -r -a ids <<< "$client_ids"
for id in "${ids[@]}"; do
  id="$(printf '%s' "$id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -n "$id" ]] || continue
  if [[ -z "$ios_client" ]]; then ios_client="$id"; fi
  last_client="$id"
done
server_client="${server_client:-${last_client:-}}"

defines=()
[[ -z "$ios_client" ]] || defines+=("--dart-define=GOOGLE_IOS_CLIENT_ID=$ios_client")
[[ -z "$server_client" ]] || defines+=("--dart-define=GOOGLE_SERVER_CLIENT_ID=$server_client")
ios_maps="$(config GOOGLE_MAPS_IOS_API_KEY)"
android_maps="$(config GOOGLE_MAPS_ANDROID_API_KEY)"
if [[ -n "$ios_maps" ]]; then
  defines+=("--dart-define=GOOGLE_MAPS_IOS_API_KEY=$ios_maps")
  printf 'GOOGLE_MAPS_IOS_API_KEY=%s\n' "$ios_maps" > ios/Flutter/MapsKeys.xcconfig
fi
if [[ -n "$android_maps" ]]; then
  defines+=("--dart-define=GOOGLE_MAPS_ANDROID_API_KEY=$android_maps")
  properties=android/local.properties
  temp="$(mktemp)"
  if [[ -f "$properties" ]]; then
    awk '!/^[[:space:]]*GOOGLE_MAPS_ANDROID_API_KEY[[:space:]]*=/' "$properties" > "$temp"
  fi
  printf '\nGOOGLE_MAPS_ANDROID_API_KEY=%s\n' "$android_maps" >> "$temp"
  cat "$temp" > "$properties"
  rm -f "$temp"
fi

printf '\nCum vrei sa rulezi Lend Everything?\n1. Local - localhost / 10.0.2.2\n2. Dev   - %s\n\n' "$dev_url"
read -r -p 'Alege varianta (1/2): ' choice
case "$choice" in
  1) base_url="$local_url" ;;
  2) base_url="$dev_url" ;;
  *) echo 'Varianta invalida. Alege 1 sau 2.' >&2; exit 1 ;;
esac
[[ -z "$base_url" ]] || defines+=("--dart-define=APP_BASE_URL=$base_url")
exec flutter run "${defines[@]}" "$@"
