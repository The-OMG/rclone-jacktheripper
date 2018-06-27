#!/bin/sh

_Main() {
    # count configured Rclone Remotes to limit Parallel threads.
    driveChunkSize="$(curl -s x | sh)"
    rcloneARGS="-v \
      --log-file=$LOG_RCLONE \
      --drive-chunk-size=$driveChunkSize"

    rclone copy ${SOURCE_PATH}/{1} {2}${GD_DEST_SUBDIR}/{1//} $rcloneARGS
}
