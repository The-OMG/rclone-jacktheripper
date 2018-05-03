#!/bin/bash
# PERMISSIONS
#	chmod u+x *.sh

# EXECUTE
#	./jacktheripper.sh

# Gloabal Variables
SOURCE=""
SOURCE_SUBDIR=""
DEST="$1"
DEST_SUBDIR="DataHoarder"

rc() {
  rclone sync ${SOURCE}:${SOURCE_SUBDIR} "${DEST}":${DEST_SUBDIR} \
    --backup-dir=${SOURCE}:${SOURCE_SUBDIR}-archive \
    --checksum \
    --transfers=8 \
    --checkers=8 \
    --low-level-retries=20 \
    --stats=10s \
    --retries=20 \
    --ignore-existing \
    --min-size=0 \
    --contimeout=60s \
    --timeout=300s \
    --retries=3 \
    --low-level-retries=10 \
    --log-file="$HOME/logs/rclone-$GDRIVE_SOURCE-$SOURCE.log" \
    --fast-list \
    -vvv
  echo "thread complete"
}
  rclone lsf ${SOURCE}:${SOURCE_SUBDIR} | parallel -j4 --joblog="${HOME}/logs/jacktheripper.log" "rc {}"
