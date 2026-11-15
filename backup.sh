#!/data/data/com.termux/files/usr/bin/bash
source ~/photobk/config.sh
source ~/photobk/guards.sh
source ~/photobk/layout.sh

N=$(find "$SRC" -type f ! -name .nomedia | wc -l)
if [ "$N" -eq 0 ]; then
  termux-notification -t "Nothing to upload" -c "ToBackup is empty"; exit 0
fi

if ! check_wifi; then
  termux-notification -t "Not on WiFi" -c "Connect to WiFi and try again"; exit 1
fi

if ! check_battery; then
  termux-notification -t "Battery too low" -c "Charge or plug in first"; exit 1
fi

if ! check_lock; then
  termux-notification -t "Already running" -c "A backup is in progress"; exit 1
fi
trap release_lock EXIT

# Storage guard: do not start an upload that cannot fit in the Google storage plan.
NEED=$(find "$SRC" -type f ! -name .nomedia -printf '%s\n' | awk '{s+=$1} END {printf "%.0f", s}')
FREE=$(timeout 60 rclone about "${DST%%:*}:" --json 2>/dev/null | jq -r '.free // empty')
if [ -n "$FREE" ]; then
  if [ $((NEED + ${MIN_FREE_GB:-10} * 1073741824)) -gt "$FREE" ]; then
    termux-notification -t "Drive is almost full - NOT uploading" \
      -c "Need $((NEED / 1073741824)) GB, free $((FREE / 1073741824)) GB. Free up space or enlarge the plan."
    exit 1
  fi
else
  termux-notification -t "Could not read Drive free space" -c "Uploading anyway - check the storage plan"
fi

TS=$(date +%Y-%m-%d_%H%M)
mkdir -p "$BK/logs" "$BK/reports"
MAP="$BK/reports/$TS-targets.tsv"
each_target > "$MAP"
cp "$MAP" "$BK/last-targets.tsv"

if grep -q $'\t!undecided$' "$MAP"; then
  termux-notification -t "Upload NOT started" -c "A folder has no dated files - see $(basename "$MAP")"; exit 1
fi

termux-wake-lock
termux-notification -i pbk -t "Uploading $N files" -c "Started $TS" --ongoing

RC=0
while IFS=$'\t' read -r local target; do
  case "$local" in
    @loose:*)
      LIST="$BK/reports/$TS-loose-${local#@loose:}.txt"
      loose_list "${local#@loose:}" > "$LIST"
      rclone copy "$SRC" "$DST/$target" $COMMON --max-depth 1 --files-from-raw "$LIST" -P --log-file "$BK/logs/$TS.log" || RC=1 ;;
    *)
      rclone copy "$local" "$DST/$target" $COMMON -P --log-file "$BK/logs/$TS.log" || RC=1 ;;
  esac
done < "$MAP"

termux-wake-unlock
termux-notification-remove pbk
if [ $RC -eq 0 ]; then
  termux-notification -t "Upload done: $N files" -c "Now run Verify"
else
  termux-notification -t "Upload FAILED" -c "Tap Backup again to resume"
fi
