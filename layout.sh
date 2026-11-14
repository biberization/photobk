# layout.sh - where a ToBackup folder goes in Drive.
# Drive layout:  Backup/<year>/<year>-<MM> <Hebrew month>/[event folder]/file
#   "נובמבר 2026"        -> 2026/2026-11 נובמבר
#   "2026-11 נובמבר"     -> 2026/2026-11 נובמבר
#   any other name (event) -> <year>/<year>-<MM> <month>/<name>, month = where most of its files fall
# Hebrew month names are written as escapes so the file survives any editor/encoding.
HM=( "" $'ינואר' $'פברואר' $'מרץ'
     $'אפריל' $'מאי' $'יוני' $'יולי'
     $'אוגוסט' $'ספטמבר' $'אוקטובר'
     $'נובמבר' $'דצמבר' )

# month_dir YYYY MM  ->  "YYYY/YYYY-MM <month>"
month_dir() { local y=$1 m=$((10#$2)); printf '%s/%s-%02d %s' "$y" "$y" "$m" "${HM[$m]}"; }

# ym_of_file <path> -> YYYYMM, from the first date in the file name, else the file's modification time
ym_of_file() {
  local b d; b=$(basename "$1")
  d=$(printf '%s' "$b" | grep -oE '(19|20)[0-9]{2}[-_.]?(0[1-9]|1[0-2])[-_.]?(0[1-9]|[12][0-9]|3[01])' | head -1 | tr -d '._-')
  if [ -n "$d" ]; then printf '%s' "${d:0:6}"; else date -r "$1" +%Y%m 2>/dev/null; fi
}

# target_for <folder path> -> Drive path relative to $DST (empty if it cannot be decided)
target_for() {
  local dir=${1%/} name i ym
  name=$(basename "$dir")
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    if [[ "$name" =~ ^"${HM[$i]}"\ ((19|20)[0-9]{2})$ ]]; then month_dir "${BASH_REMATCH[1]}" "$i"; return 0; fi
    if [[ "$name" =~ ^((19|20)[0-9]{2})-([0-9]{2})\ "${HM[$i]}"$ ]] && [ "$((10#${BASH_REMATCH[3]}))" -eq "$i" ]; then
      month_dir "${BASH_REMATCH[1]}" "$i"; return 0; fi
  done
  # event folder: majority month of its files
  ym=$(find "$dir" -type f ! -name .nomedia | while IFS= read -r f; do ym_of_file "$f"; echo; done \
        | grep -E '^[0-9]{6}$' | sort | uniq -c | sort -k1,1nr -k2,2r | head -1 | awk '{print $2}')
  [ -n "$ym" ] || return 1
  printf '%s/%s' "$(month_dir "${ym:0:4}" "${ym:4:2}")" "$name"
}

# each_target: prints "<local folder>\t<drive target>" for every folder in $SRC, and for loose files
# in $SRC itself one line per month: "@loose:<YYYYMM>\t<drive target>"
each_target() {
  local d t f ym
  for d in "$SRC"/*/; do
    [ -d "$d" ] || continue
    [ -n "$(find "$d" -type f ! -name .nomedia -print -quit)" ] || continue
    if t=$(target_for "$d"); then printf '%s\t%s\n' "${d%/}" "$t"; else printf '%s\t%s\n' "${d%/}" "!undecided"; fi
  done
  find "$SRC" -maxdepth 1 -type f ! -name .nomedia | while IFS= read -r f; do ym_of_file "$f"; echo; done \
    | grep -E '^[0-9]{6}$' | sort -u | while read -r ym; do
      printf '@loose:%s\t%s\n' "$ym" "$(month_dir "${ym:0:4}" "${ym:4:2}")"
    done
}

# loose_list <YYYYMM> -> names of loose files in $SRC belonging to that month (for --files-from-raw)
loose_list() {
  local f
  find "$SRC" -maxdepth 1 -type f ! -name .nomedia | while IFS= read -r f; do
    [ "$(ym_of_file "$f")" = "$1" ] && basename "$f"
  done
}
