#!/data/data/com.termux/files/usr/bin/bash
set -e
pkg install -y rclone tmux termux-api jq git
termux-setup-storage
mkdir -p ~/photobk/logs ~/photobk/reports ~/.shortcuts
chmod 700 ~/.shortcuts
chmod +x ~/photobk/*.sh
for s in Backup Verify Preflight; do
  f=$(echo "$s" | tr 'A-Z' 'a-z')
  printf '#!/data/data/com.termux/files/usr/bin/bash\nbash ~/photobk/%s.sh\n' "$f" > ~/.shortcuts/$s
  chmod +x ~/.shortcuts/$s
done
echo "alias status='ls -t ~/photobk/reports/*-summary.txt | head -1 | xargs cat'" >> ~/.bashrc
echo
echo "Done. Next:"
echo "1. rclone config   (remote name: gdrive)"
echo "2. edit ~/photobk/config.sh"
echo "3. mkdir -p ~/storage/shared/ToBackup"
echo "4. add Termux widget to home screen"
