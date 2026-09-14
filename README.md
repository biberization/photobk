# photobk - verified phone-to-Drive photo backup

Move photos into `~/storage/shared/ToBackup/<folder name>/`.
Tap **Backup**, wait for the notification, tap **Verify**.
Only delete locally after "VERIFIED: N files".

## Scripts
- backup.sh  - uploads ToBackup -> gdrive:Backup, then dedupes that batch
- verify.sh  - MD5-compares local vs Drive, writes reports/
- preflight.sh - flags duplicate filenames and identical content before upload
- guards.sh  - wifi / battery / lock checks
- config.sh  - per-device settings (edit this, not the scripts)

## Rules
- Never `rclone sync` - only `copy`. Sync deletes.
- Green requires: missing=0, differ=0, errors=0, ok==local count.
- Reports in reports/ are the permanent record once locals are deleted.
