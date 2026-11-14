# photobk - verified phone-to-Drive photo backup

Move photos into `~/storage/shared/ToBackup/<folder name>/`.
Tap **Backup**, wait for the notification, tap **Verify**.
Only delete locally after "VERIFIED: N files".

## Scripts
- backup.sh  - uploads each ToBackup folder to its place in the Drive layout (see below)
- verify.sh  - MD5-compares local vs Drive using the same mapping, writes reports/
- layout.sh  - decides where a folder goes in Drive (shared by backup and verify)
- migrate-layout.sh - one-time move of old Drive month folders into the year layout
- preflight.sh - flags duplicate filenames and identical content before upload
- guards.sh  - wifi / battery / lock checks
- config.sh  - per-device settings (edit this, not the scripts)

## Rules
- Never `rclone sync` - only `copy`. Sync deletes.
- Green requires: missing=0, differ=0, errors=0, ok==local count.
- Reports in reports/ are the permanent record once locals are deleted.

## Drive layout
`Backup/<year>/<year>-<MM> <Hebrew month>/[event folder]/file`

| Folder in ToBackup | Goes to |
|---|---|
| `נובמבר 2026` (or `2026-11 נובמבר`) | `2026/2026-11 נובמבר` |
| any other name (an event) | `<year>/<year>-<MM> <month>/<name>`, month = where most of its files fall |
| loose files directly in ToBackup | the month of each file's date |

Dates come from the file name (`20261101_...`), else the file's modification time.
Each run records its mapping in `reports/<timestamp>-targets.tsv`.

The Drive-side dedupe step was removed from backup: `rclone copy` never creates
duplicates, and dedupe was the only step that deleted anything.
