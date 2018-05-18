#!/usr/bin/env bash

###############################################################################
#  Wrapper script for rclone to distribute transfers over multiple accounts.  #
###############################################################################

## Gloabal Variables
SOURCE="WWWtheeye"
SOURCE_SUBDIR="Images"
DEST_SUBDIR="theeye/images"

SOURCE_PATH="${SOURCE}:${SOURCE_SUBDIR}/"
#DEST_PATH="${DEST}:${DEST_SUBDIR}/"
SOURCE_FILES="${HOME}/.config/jacktheripper/filelist.txt"
LOGFILE="${HOME}/logs/jacktheripper.log"
JOBS="${HOME}/.config/jacktheripper/joblist.txt"

## Setup working directories
function _workdirs() {
  mkdir -p "${HOME}"/.config/jacktheripper
  mkdir -p ${HOME}/logs
}

## Rclone functions
function _rclone_list_files() {
  local rcloneARGS=(
    --files-only
    -R
    --checkers 20
    --fast-list
  )

  echo "Creating input filelist" | tee -a "$LOGFILE"
  sleep 2
  echo "This process may take a long time."
  rclone lsf "${SOURCE_PATH}" "${rcloneARGS[@]}" | tee "$SOURCE_FILES"
}

#function merged_listed_input_files() {
#  echo "${SOURCE_PATH}_rclone_list_files"
#}

function _job_printer() {
  local ACCOUNTS="${HOME}/.config/jacktheripper/accounts.txt"
  local rcloneARGS=(
    '-v'
    "--log-file=${HOME}/logs/jacktheripper-rclone.log"
  )
  parallel --link -x echo "rclone copy '\"'${SOURCE_PATH}{1}'\"' '\"'{2}${DEST_SUBDIR}/{1//}'\"'  ${rcloneARGS[*]}" :::: "$SOURCE_FILES" "$ACCOUNTS" | tee "$JOBS"
}

function _jacktheripper() {
  local parallelARGS=(
    '--tmux'
    "--joblog=${HOME}/logs/jacktheripper-parallel.log"
    "--progress"
    #    '--load=50%'
    '--retries=3'
    '--noswap'
    #    '--memfree=128M'
    '--resume-failed'
    '--delay'
  )

  parallel "${parallelARGS[@]}" {} :::: ${JOBS}
}

## final script
_workdirs
_rclone_list_files
_job_printer
_jacktheripper
