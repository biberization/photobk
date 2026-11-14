#!/data/data/com.termux/files/usr/bin/bash
source ~/photobk/config.sh
source ~/photobk/guards.sh
source ~/photobk/layout.sh

N=$(find "$SRC" -type f ! -name .nomedia | wc -l)
if [ "$N" -eq 0 ]; then
  termux-notification -t "Nothing to verify" -c "ToBackup is empty"; exit 0
fi

if ! check_lock; then
  termux-notification -t "Busy" -c "Backup is running - wait for it"; exit 1
fi
trap release_lock EXIT

TS=$(date +%Y-%m-%d_%H%M)
mkdir -p "$BK/reports"
R="$BK/reports/$TS"
: > "$R-all.txt"; : > "$R-missing.txt"; : > "$R-differ.txt"; : > "$R-error.txt"
MAP="$R-targets.tsv"
each_target > "$MAP"

termux-wake-lock
i=0
while IFS=$'\t' read -r local target; do
  i=$((i+1)); P="$R-part$i"
  if [ "$target" = "!undecided" ]; then echo "$local: no dated files, target undecided" >> "$R-error.txt"; continue; fi
  case "$local" in
    @loose:*)
      loose_list "${local#@loose:}" > "$P-list.txt"
      rclone check "$SRC" "$DST/$target" $COMMON --one-way --max-depth 1 --files-from-raw "$P-list.txt" \
        --combined "$P-all.txt" --missing-on-dst "$P-missing.txt" --differ "$P-differ.txt" --error "$P-error.txt" ;;
    *)
      rclone check "$local" "$DST/$target" $COMMON --one-way \
        --combined "$P-all.txt" --missing-on-dst "$P-missing.txt" --differ "$P-differ.txt" --error "$P-error.txt" ;;
  esac
  # prefix every reported path with its Drive folder, so the report reads as Drive paths
  [ -f "$P-all.txt" ] && T="$target" awk '{print substr($0,1,2) ENVIRON["T"] "/" substr($0,3)}' "$P-all.txt" >> "$R-all.txt"
  for k in missing differ error; do
    [ -f "$P-$k.txt" ] && T="$target" awk '{print ENVIRON["T"] "/" $0}' "$P-$k.txt" >> "$R-$k.txt"
  done
  rm -f "$P-all.txt" "$P-missing.txt" "$P-differ.txt" "$P-error.txt"
  rm -f "$P-list.txt"
done < "$MAP"
termux-wake-unlock

OK=$(grep -c '^= ' "$R-all.txt")
MISS=$(wc -l < "$R-missing.txt")
DIFF=$(wc -l < "$R-differ.txt")
ERR=$(wc -l < "$R-error.txt")
echo "LOCAL:$N OK:$OK MISSING:$MISS DIFFER:$DIFF ERRORS:$ERR" | tee "$R-summary.txt"

if [ "$MISS" -eq 0 ] && [ "$DIFF" -eq 0 ] && [ "$ERR" -eq 0 ] && [ "$OK" -eq "$N" ]; then
  termux-notification -t "VERIFIED: $OK files" -c "Safe to delete locally"
else
  termux-notification -t "NOT VERIFIED" -c "miss:$MISS diff:$DIFF err:$ERR ok:$OK/$N"
fi
