#!/usr/bin/env bash

###############################################################################
#  Wrapper script for rclone to distribute transfers over multiple accounts.  #
###############################################################################

# Set to home tmp folder in the event that /tmp is full.
# Yes, it happened to me.
export TMPDIR="${HOME}"

set -eo pipefail

_Main() {

  #  Paths
  #  local DIR_APP="${HOME}/.config/jacktheripper"
  local DIR_LOG="${HOME}/logs"

  #  Log Files
  local LOG_SCRIPT="$DIR_LOG/jacktheripper.log"
  local LOG_RCLONE="$DIR_LOG/jacktheripper-Rclone.log"
  local LOG_PARALLEL="$DIR_LOG/jacktheripper-Parallel.log"

  local SCRATCH
  SCRATCH="$(mktemp -d)"
  _Finish() {
    rm -rf "$SCRATCH"
  }

  _setup() {
    _DependancyCheck() {
      local REQUIRE=('rclone' 'parallel' 'mktemp' 'echo' 'cat' 'mkdir')
      for app in "${REQUIRE[@]}"; do
        ! type "$app" >/dev/null 2>&1 &&
          echo -e "$app dependency not met/nPlease install $app" 1>&2 && return 1
      done
      return 0
    }

    # Setup working directories
    _workdirs() {
      [ ! -d "$DIR_LOG" ] || {
        echo "Creating log folder at $DIR_LOG"
        mkdir -p "$DIR_LOG" &>/dev/null
      }
      [ ! -d "$DIR_TMP" ] || {
        echo "Creating log folder at $DIR_TMP"
        mkdir -p "$DIR_TMP" &>/dev/null
      }
    }
    _DependancyCheck
    _workdirs
  }
  _job_printer() {
    # Config Files
    local SOURCE_DIRS
    SOURCE_DIRS="$(mktemp -q "$SCRATCH"/dirs.XXXX)" || {
      echo "filelist: Can't create temp file, exiting..."
      exit 1
    }
    local SOURCE_FILES
    SOURCE_FILES="$(mktemp -q "$SCRATCH"/filelist.XXXX)" || {
      echo "filelist: Can't create temp file, exiting..."
      exit 1
    }
    local JOBS
    JOBS="$(mktemp -q "$SCRATCH"/joblist.XXXX)" || {
      echo "joblist: Can't create temp file, exiting..."
      exit 1
    }
    local ACCOUNTS
    ACCOUNTS="$(mktemp -q "$SCRATCH"/accounts.XXXX)" || {
      echo "accounts: Can't create temp file, exiting..."
      exit 1
    }

    #  Rclone Variables
    local SOURCE="WWWtheeye"
    local SOURCE_SUBDIR="Images/PartyParrot"
    local SOURCE_PATH="${SOURCE}:${SOURCE_SUBDIR}"

    #local GD_DEST="ACCOUNT"
    local GD_DEST_SUBDIR="theeye/images"
    #local GD_DEST_PATH="${GD_DEST}:${GD_DEST_SUBDIR}/"

    _TmpRcloneConf() {
      local TmpRcloneConf
      TmpRcloneConf="$(mktemp -q "$SCRATCH"/rclone.XXXX)" || {
        echo "rclone: Can't create temp file, exiting..."
        exit 1
      }
      # copy Users rclone.config to tmp location
      cp "$HOME/.config/rclone/rclone.conf" "$TmpRcloneConf"
      # Add new remote for the user's home directory
      (
        echo ""
        echo '[local]'
        echo 'type = local'
        echo 'nounc =' >>"$TmpRcloneConf" || exit 1
      )
    }
    _rclone_list_files() {

      #  rclone lsf --dirs-only "${SOURCE_PATH}" >"$SOURCE_DIRS"

      local rcloneARGS=(
        "--files-only"
        "--recursive"
        "--checkers=40"
        "--fast-list"
        "--exclude=\"**partial~\""
        "--exclude=\"**_HIDDEN~\""
      )
      echo "Creating input filelist" | tee -a "$LOG_SCRIPT"
      #sleep 2
      echo "This process may take a long time."
      # Prints rclone Source file with path to a file. Overwrites file every time.
      #  parallel "rclone lsf ${SOURCE_PATH}/{} ${rcloneARGS[*]}" :::: "$SOURCE_DIRS" | tee "$SOURCE_FILES"
      rclone lsf "${SOURCE_PATH}" "${rcloneARGS[@]}" | tee "$SOURCE_FILES"
    }
    _jacktheripper() {
      # Calculate best chunksize for trasnfer speed.
      local driveChunkSize
      local AvailableRam
      AvailableRam=$(free --giga -w | tee -a "$LOG_SCRIPT" | grep Mem | awk '{print $8}')
      case "$AvailableRam" in
      [1-9][0-9] | [1-9][0-9][0-9]) driveChunkSize="1024M" ;;
      [6-9]) driveChunkSize="512M" ;;
      5) driveChunkSize="256M" ;;
      4) driveChunkSize="128M" ;;
      3) driveChunkSize="64M" ;;
      2) driveChunkSize="32M" ;;
      [0-1]) driveChunkSize="8M" ;;
      esac

      local rcloneARGS=(
        '-v'
        "--log-file=$LOG_RCLONE"
        "--drive-chunk-size=$driveChunkSize"
      )
      rclone listremotes | grep TDreq >"$ACCOUNTS"

      local parallelARGS=(
        '--tmux'
        "--joblog=$LOG_PARALLEL"
        "--progress"
        #    '--load=50%'
        '--retries=3'
        '--noswap'
        #    '--memfree=128M'
        '--resume-failed'
        '--delay'
        '--link'
        '-X'
      )
      parallel "${parallelARGS[@]}" "rclone copy ${SOURCE_PATH}/{1} {2}${GD_DEST_SUBDIR}/"{1//}" ${rcloneARGS[*]}" :::: ${SOURCE_FILES} :::: ${ACCOUNTS} | tee "$JOBS"
    }

    _TmpRcloneConf
    _rclone_list_files
    _jacktheripper
  }

  _setup
  _job_printer

  trap _Finish EXIT
}
################################################################################
_Main
