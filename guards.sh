check_lock() {
  local L="$BK/.lock"
  if mkdir "$L" 2>/dev/null; then echo $$ > "$L/pid"; return 0; fi
  local old=$(cat "$L/pid" 2>/dev/null)
  if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then return 1; fi
  rm -rf "$L"; mkdir "$L" && echo $$ > "$L/pid"; return 0
}
release_lock() { rm -rf "$BK/.lock"; }

check_wifi() {
  [ "$REQUIRE_WIFI" = "1" ] || return 0
  termux-wifi-connectioninfo 2>/dev/null | grep -q '"supplicant_state": *"COMPLETED"'
}

check_battery() {
  local j=$(termux-battery-status 2>/dev/null)
  local p=$(echo "$j" | jq -r .percentage 2>/dev/null)
  local s=$(echo "$j" | jq -r .status 2>/dev/null)
  [ "$s" = "CHARGING" ] || [ "$s" = "FULL" ] && return 0
  [ -n "$p" ] && [ "$p" -ge "$MIN_BATTERY" ]
}
