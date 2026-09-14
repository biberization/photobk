#!/data/data/com.termux/files/usr/bin/bash
source ~/photobk/config.sh
source ~/photobk/guards.sh

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

TS=$(date +%Y-%m-%d_%H%M)
termux-wake-lock
termux-notification -i pbk -t "Uploading $N files" -c "Started $TS" --ongoing

rclone copy "$SRC" "$DST" $COMMON -P --log-file "$BK/logs/$TS.log"
RC=$?

termux-notification -i pbk -t "Deduplicating" -c "Cleaning this batch" --ongoing
for d in "$SRC"/*/; do
  [ -d "$d" ] || continue
  rclone dedupe --by-hash --dedupe-mode newest "$DST/$(basename "$d")" \
    --tpslimit 4 --transfers 1 --log-file "$BK/logs/$TS-dedupe.log"
done

termux-wake-unlock
termux-notification-remove pbk
if [ $RC -eq 0 ]; then
  termux-notification -t "Upload done: $N files" -c "Now run Verify"
else
  termux-notification -t "Upload FAILED (rc=$RC)" -c "Tap Backup again to resume"
fi
