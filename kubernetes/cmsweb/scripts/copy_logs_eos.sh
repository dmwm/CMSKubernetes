#!/bin/bash
# This script is a quick custom way to transfer logs older than 30 days to EOS and get rid of the source files.
# Requested by DMWM team for /cephfs/product/dmwm-logs and /cephfs/preprod/dmwm-logs
KEYTAB_PATH="/home/cmsweb/cmsweb.keytab"
TMP_LIST="/tmp/old_logs_to_copy_$(date +%Y%m%d_%H%M%S)_$$.txt"

SRC_DIR="$1"
DEST_DIR="$2"

if [ -z "$SRC_DIR" ] || [ -z "$DEST_DIR" ]; then
  echo "Usage: $0 <source_directory> <destination_directory>"
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "[ERROR] Source directory does not exist: $SRC_DIR"
  exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
  echo "[INFO] Destination directory does not exist, creating: $DEST_DIR"
  mkdir -p "$DEST_DIR" || { echo "[ERROR] Cannot create $DEST_DIR"; exit 1; }
fi

if [ -f "$KEYTAB_PATH" ]; then
  echo "[INFO] Found keytab, performing kinit..."
  principal=$(klist -k "$KEYTAB_PATH" | tail -1 | awk '{print $2}')
  kinit "$principal" -k -t "$KEYTAB_PATH" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "[ERROR] Unable to perform kinit for $principal"
    exit 1
  fi
  echo "[INFO] Kerberos authentication successful."
else
  echo "[ERROR] Keytab not found at $KEYTAB_PATH"
  exit 1
fi

echo "[INFO] Finding files older than 30 days in $SRC_DIR..."
cd "$SRC_DIR" || { echo "[ERROR] Cannot cd into $SRC_DIR"; exit 1; }
find . -type f -mtime +30 -print0 > "$TMP_LIST"

if [ ! -s "$TMP_LIST" ]; then
  echo "[INFO] No old files to transfer."
  rm -f "$TMP_LIST"
  kdestroy
  exit 0
fi

echo "[INFO] Copying files to $DEST_DIR..."
rsync -av --progress --from0 --files-from="$TMP_LIST" ./ "$DEST_DIR"/
RSYNC_STATUS=$?

if [ $RSYNC_STATUS -ne 0 ]; then
  echo "[ERROR] rsync failed (exit code $RSYNC_STATUS). Aborting removal."
  rm -f "$TMP_LIST"
  kdestroy
  exit 1
fi

echo "[INFO] Copy successful. Removing source files..."
xargs -0 rm -f < "$TMP_LIST"

find "$SRC_DIR" -type d -empty -delete

rm -f "$TMP_LIST"
kdestroy
echo "[INFO] Transfer completed successfully. Source files removed."

