#!/bin/bash
###############################################################################
#  Wrapper script for rclone to distribute transfers over multiple accounts.  #
###############################################################################
#
#							      ___           ___           ___
#							     /  /\         /__/\         /  /\
#							    /  /::\       |  |::\       /  /:/_
#							   /  /:/\:\      |  |:|:\     /  /:/ /\
#							  /  /:/  \:\   __|__|:|\:\   /  /:/_/::\
#							 /__/:/ \__\:\ /__/::::| \:\ /__/:/__\/\:\
#							 \  \:\ /  /:/ \  \:\~~\__\/ \  \:\ /~~/:/
#							  \  \:\  /:/   \  \:\        \  \:\  /:/
#							   \  \:\/:/     \  \:\        \  \:\/:/
#							    \  \::/       \  \:\        \  \::/
#							     \__\/         \__\/         \__\/
#
###############################################################################
# PERMISSIONS

## Gloabal Variables
SOURCE_PATH="${SOURCE}:${SOURCE_SUBDIR}/"
DEST_PATH="${DEST}:${DEST_SUBDIR}/"

SOURCE_FILES="${HOME}/.config/rclone/${SOURCE}filelist.txt"

## Global Functions
function _ask_yes_or_no() {
  read -r -p "$1 ([y]es or [N]o): "
  case $(echo "$REPLY" | tr '[A-Z]' '[a-z]') in
  y | yes) echo "yes" ;;
  *) echo "no" ;;
  esac
}
## Rclone functions
function _rclone_list_files() {
  local rcloneARGS=(
    --files-only
    -R
    --fast-list
  )

  echo "Creating input filelist"
  sleep 2
  rclone lsf "${SOURCE_PATH}" "${rcloneARGS[@]}" >>"${SOURCE_FILES}"
}

function merged_listed_input_files() {
  echo "${SOURCE_PATH}_rclone_list_files"
}

## User input
function _source_interactive_input() {
  rclone listremotes
  echo "Name of the rclone remote above that you want to download from."
  echo "Example: 'mygsuite' or 'this-cool-http-site' etc"
  read -r -p 'Source Remote: ' SOURCE
  echo "Subdirectory of ${SOURCE}, if any you want to download from"
  echo "Leave blank if you want to mirror ${SOURCE}"
  echo "Example: 'Public/uploads/year'"
  read -r -p 'Source Subdirectory: ' SOURCE_SUBDIR
  sleep 2
  echo "${SOURCE_PATH}"
  if "no" == "$('_ask_yes_or_no' "Are you sure you want to download from here?")"; then
    echo "Exiting."
    exit 0
  fi
}

function _destination_interactive_input() {
  rclone listremotes
  echo "Name of the rclone remote above that you want to save to."
  echo "Example: 'mygsuite' or '${HOME}/files' etc"
  read -r -p 'Destination Remote: ' DEST
  echo "Subdirectory of ${DEST}, if any you want to download from"
  echo "Leave blank if you want to mirror ${DEST}"
  echo "Example: 'Public/uploads/year'"
  read -r -p 'Destination Subdirectory: ' DEST_SUBDIR
  sleep 2
  echo "${DEST_PATH}"
  if "no" == "$('_ask_yes_or_no' "Are you sure you want to download from here?")"; then
    echo "Exiting."
    exit 0
  fi
}

function _jacktheripper() {
  local parallel_log="${HOME}/logs/jacktheripper-rclone.log"
  local rclone_log="${HOME}/logs/jacktheripper.log"
  local parallelARGS=(
    "--link"
    "-j12"
    "--joblog=${parallel_log}"
    "-X"
    "--progress"
    "--load=50%"
    "--retries 3"
    "--noswap"
    "--memfree 128M"
    "--resume-failed"
    "--delay"
  )
  local rcloneARGS=(
    "--fast-list"
    "-vv"
    "--log-file=${rclone_log}"
    "--checksum"
    "--transfers=2"
    "--checkers=2"
    "--low-level-retries=20"
    "--stats=10s"
    "--retries=20"
    "--ignore-existing"
    "--min-size=0"
    "--contimeout=60s"
    "--timeout=300s"
    "--retries=3"
    "--fast-list"
    "--low-level-retries=10"
  )

  parallel "${parallelARGS[@]}" rclone copy "${rcloneARGS[@]}" {1}{2}:"${DEST_SUBDIR}" :::: "$ACCOUNTS" "$PORTS"
}

## final script
_source_interactive_input
_destination_interactive_input
_rclone_list_files
_jacktheripper
