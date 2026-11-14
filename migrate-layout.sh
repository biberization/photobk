#!/data/data/com.termux/files/usr/bin/bash
# migrate-layout.sh - one-time: move Drive month folders into the year layout.
#   "Backup/נובמבר 2026"  ->  "Backup/2026/2026-11 נובמבר"
# Moves happen inside Drive (nothing is uploaded, downloaded or deleted).
#   bash ~/photobk/migrate-layout.sh        dry run: only prints what would move
#   bash ~/photobk/migrate-layout.sh go     performs the moves
source ~/photobk/config.sh
source ~/photobk/layout.sh
GO=0; [ "$1" = "go" ] && GO=1
echo "Before:"; rclone size "$DST"
rclone lsf --dirs-only "$DST" | sed 's:/$::' | while IFS= read -r name; do
  new=""
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    if [[ "$name" =~ ^"${HM[$i]}"\ ((19|20)[0-9]{2})$ ]]; then new=$(month_dir "${BASH_REMATCH[1]}" "$i"); break; fi
  done
  if [ -z "$new" ]; then
    [[ "$name" =~ ^(19|20)[0-9]{2}$ ]] || echo "left as is (not a month folder): $name"
    continue
  fi
  if [ $GO -eq 1 ]; then
    echo "moving: $name  ->  $new"
    rclone move "$DST/$name" "$DST/$new" --delete-empty-src-dirs < /dev/null || { echo "FAILED on $name - stopping"; exit 1; }
  else
    echo "[dry run] $name  ->  $new"
  fi
done
if [ $GO -eq 1 ]; then echo "After (must equal Before):"; rclone size "$DST"
else echo; echo "Dry run only. To perform: bash ~/photobk/migrate-layout.sh go"; fi
