#!/bin/sh

# Calculate best chunksize for trasnfer speed.
AvailableRam=$(free --giga -w | grep Mem | awk '{print $8}')
case "$AvailableRam" in
[1-9][0-9] | [1-9][0-9][0-9]) driveChunkSize="1G" ;;
[6-9]) driveChunkSize="512M" ;;
5) driveChunkSize="256M" ;;
4) driveChunkSize="128M" ;;
3) driveChunkSize="64M" ;;
2) driveChunkSize="32M" ;;
[0-1]) driveChunkSize="8M" ;;
esac
