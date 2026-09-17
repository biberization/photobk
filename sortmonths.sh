#!/data/data/com.termux/files/usr/bin/bash
SRC="$HOME/storage/dcim/Camera"
DST="$HOME/storage/dcim"
cd "$SRC" || exit 1
m01=$'\u05d9\u05e0\u05d5\u05d0\u05e8'; m02=$'\u05e4\u05d1\u05e8\u05d5\u05d0\u05e8'
m03=$'\u05de\u05e8\u05e5'; m04=$'\u05d0\u05e4\u05e8\u05d9\u05dc'
m05=$'\u05de\u05d0\u05d9'; m06=$'\u05d9\u05d5\u05e0\u05d9'
m07=$'\u05d9\u05d5\u05dc\u05d9'; m08=$'\u05d0\u05d5\u05d2\u05d5\u05e1\u05d8'
m09=$'\u05e1\u05e4\u05d8\u05de\u05d1\u05e8'; m10=$'\u05d0\u05d5\u05e7\u05d8\u05d5\u05d1\u05e8'
m11=$'\u05e0\u05d5\u05d1\u05de\u05d1\u05e8'; m12=$'\u05d3\u05e6\u05de\u05d1\u05e8'
NOW=$(date +%Y%m)
DRY=1; [ "$1" = "go" ] && DRY=0
for f in *; do
  [ -f "$f" ] || continue
  d=$(echo "$f" | grep -oE '20[0-9]{6}' | head -1)
  [ -z "$d" ] && continue
  [ "${d:0:6}" = "$NOW" ] && continue
  eval "mn=\$m${d:4:2}"
  t="$DST/$mn ${d:0:4}"
  if [ $DRY -eq 1 ]; then echo "$t"; else mkdir -p "$t"; mv -n "$f" "$t"/; fi
done | sort | uniq -c
[ $DRY -eq 1 ] && echo "--- dry run. rerun with: bash ~/photobk/sortmonths.sh go"
