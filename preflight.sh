#!/data/data/com.termux/files/usr/bin/bash
source ~/photobk/config.sh
echo "=== Files with (N) suffix ==="
find "$SRC" -type f -name '*([0-9])*' | head -20
echo "count: $(find "$SRC" -type f -name '*([0-9])*' | wc -l)"
echo
echo "=== Identical content (wasted uploads) ==="
find "$SRC" -type f ! -name .nomedia -exec md5sum {} + \
  | sort | uniq -w32 -d --all-repeated=separate | head -40
