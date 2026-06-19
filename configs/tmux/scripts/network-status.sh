#!/usr/bin/env sh

WIFI_ICON=''
ETH_ICON='󰈀'
MAX_SSID_LEN=20
CACHE_TTL=30
CACHE_FILE="${TMPDIR:-/tmp}/tmux-network-status-${UID:-$(id -u)}"

now=$(date +%s)
if [ -r "$CACHE_FILE" ]; then
  cache_age=$((now - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [ "$cache_age" -lt "$CACHE_TTL" ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

truncate() {
  text=$1
  len=$(printf '%s' "$text" | awk '{ print length }')
  if [ "$len" -gt "$MAX_SSID_LEN" ]; then
    printf '%s…' "$(printf '%s' "$text" | cut -c 1-$MAX_SSID_LEN)"
  else
    printf '%s' "$text"
  fi
}

text_fg() {
  bg=$(tmux show -gv status-bg 2>/dev/null || printf '')
  case "$bg" in
    '#c0c0c0'|'white'|'colour7'|'color7'|'brightwhite') printf 'colour235' ;;
    *) printf 'colour250' ;;
  esac
}

emit() {
  icon=$1
  label=$2
  icon_color=$3
  label_color=$(text_fg)
  [ "$icon_color" = normal ] && icon_color=$label_color
  printf '#[fg=%s,bold]%s  #[fg=%s,bold]%s#[default]' "$icon_color" "$icon" "$label_color" "$label"
}

internet_ok() {
  case "$(uname -s)" in
    Darwin) ping -q -c 1 -W 1000 1.1.1.1 >/dev/null 2>&1 ;;
    *) ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 ;;
  esac
}

mac_wifi_device() {
  networksetup -listallhardwareports 2>/dev/null | awk '
    /Hardware Port: (Wi-Fi|AirPort)/ { wifi=1; next }
    wifi && /Device:/ { print $2; exit }
  '
}

mac_default_iface() {
  route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }'
}

mac_ssid() {
  dev=$(mac_wifi_device)
  [ -n "$dev" ] || return 1

  if command -v get-ssid >/dev/null 2>&1; then
    ssid=$(get-ssid "$dev" 2>/dev/null)
    [ -n "$ssid" ] && [ "$ssid" != '<redacted>' ] && printf '%s' "$ssid" && return 0
  fi

  app="$HOME/Applications/wifi-unredactor.app/Contents/MacOS/wifi-unredactor"
  if [ -x "$app" ]; then
    ssid=$("$app" 2>/dev/null | awk -F'"' '/"ssid"[[:space:]]*:/ { print $4; exit }')
    [ -n "$ssid" ] && [ "$ssid" != '<redacted>' ] && printf '%s' "$ssid" && return 0
  fi

  ssid=$(networksetup -getairportnetwork "$dev" 2>/dev/null | awk -F': ' '/Current Wi-Fi Network:/ { print $2 }')
  [ -n "$ssid" ] && [ "$ssid" != '<redacted>' ] && printf '%s' "$ssid" && return 0

  system_profiler SPAirPortDataType 2>/dev/null | awk '
    /Current Network Information:/ { getline; name=$0; sub(/^[[:space:]]*/, "", name); sub(/:$/, "", name); if (name != "<redacted>") print name; exit }
  '
}

linux_status() {
  command -v nmcli >/dev/null 2>&1 || { emit "$WIFI_ICON" Unknown colour244; return; }

  eth=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null |
    awk -F: '$1 == "ethernet" && $2 == "connected" { print $3; exit }')
  wifi=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null |
    awk -F: '$1 == "wifi" && $2 == "connected" { print $3; exit }')

  if [ -n "$eth" ]; then
    internet_ok && emit "$ETH_ICON" Ethernet normal || emit "$WIFI_ICON" 'No Internet' yellow
  elif [ -n "$wifi" ]; then
    internet_ok && emit "$WIFI_ICON" "$(truncate "$wifi")" normal || emit "$WIFI_ICON" 'No Internet' yellow
  else
    emit "$WIFI_ICON" Offline red
  fi
}

mac_status() {
  iface=$(mac_default_iface)
  wifi_dev=$(mac_wifi_device)

  if [ -n "$iface" ] && [ "$iface" != "$wifi_dev" ]; then
    internet_ok && emit "$ETH_ICON" Ethernet normal || emit "$WIFI_ICON" 'No Internet' yellow
  elif [ -n "$iface" ] && [ "$iface" = "$wifi_dev" ]; then
    ssid=$(mac_ssid)
    [ -n "$ssid" ] || ssid=Wi-Fi
    internet_ok && emit "$WIFI_ICON" "$(truncate "$ssid")" normal || emit "$WIFI_ICON" 'No Internet' yellow
  else
    emit "$WIFI_ICON" Offline red
  fi
}

case "$(uname -s)" in
  Darwin) output=$(mac_status) ;;
  Linux) output=$(linux_status) ;;
  *) output=$(emit "$WIFI_ICON" Unknown colour244) ;;
esac

printf '%s' "$output" | tee "$CACHE_FILE"
