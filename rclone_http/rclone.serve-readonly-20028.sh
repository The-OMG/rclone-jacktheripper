#!/bin/bash
rclone serve http remote: --addr 127.0.0.1:20028 \
--stats 30s \
--read-only \
--drive-shared-with-me \
--vfs-cache-mode full \
--cache-total-chunk-size 50G \
-vv --log-file=$HOME/logs/remote-rclone.serve20028.log &
