#!/data/data/com.termux/files/usr/bin/bash
source ~/photobk/config.sh
source ~/photobk/guards.sh

N=$(find "$SRC" -type f ! -name .nomedia | wc -l)
if [ "$N" -eq 0 ]; then
  termux-notification -t "Nothing to verify" -c "ToBackup is empty"; exit 0
fi

if ! check_lock; then
  termux-notification -t "Busy" -c "Backup is running - wait for it"; exit 1
fi
trap release_lock EXIT

TS=$(date +%Y-%m-%d_%H%M)
R="$BK/reports/$TS"
termux-wake-lock
rclone check "$SRC" "$DST" $COMMON --one-way \
  --combined "$R-all.txt" --missing-on-dst "$R-missing.txt" \
  --differ "$R-differ.txt" --error "$R-error.txt"
termux-wake-unlock

OK=$(grep -c '^=' "$R-all.txt")
MISS=$(wc -l < "$R-missing.txt")
DIFF=$(wc -l < "$R-differ.txt")
ERR=$(wc -l < "$R-error.txt")
echo "LOCAL:$N OK:$OK MISSING:$MISS DIFFER:$DIFF ERRORS:$ERR" | tee "$R-summary.txt"

if [ "$MISS" -eq 0 ] && [ "$DIFF" -eq 0 ] && [ "$ERR" -eq 0 ] && [ "$OK" -eq "$N" ]; then
  termux-notification -t "VERIFIED: $OK files" -c "Safe to delete locally"
else
  termux-notification -t "NOT VERIFIED" -c "miss:$MISS diff:$DIFF err:$ERR ok:$OK/$N"
fi
