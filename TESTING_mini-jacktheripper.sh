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
  local DIR_APP="${HOME}/.config/jacktheripper"
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
      local REQUIRE=('rclone' 'parallel' 'mktemp' 'echo' 'cat' 'mkdir' 'jq')
      for app in "${REQUIRE[@]}"; do
        ! type "$app" >/dev/null 2>&1 &&
          echo -e "$app dependency not met/nPlease install $app" 1>&2 && return 1
      done
      return 0
    }
    _workdirs() {
      # Setup working directories
      [ ! -d "$DIR_LOG" ] || {
        echo "Creating log folder at $DIR_LOG"
        mkdir -p "$DIR_LOG" &>/dev/null
      }
      [ ! -d "$TMPDIR" ] || {
        echo "Creating log folder at $TMPDIR"
        mkdir -p "$TMPDIR" &>/dev/null
      }
      [ ! -d "$DIR_APP" ] || {
        echo "Creating log folder at $DIR_APP"
        mkdir -p "$DIR_APP/token" &>/dev/null
      }
    }
    _DependancyCheck
    _workdirs
  }
  _job_printer() {
    # Config Files
    local SOURCE_DIRS
    local SOURCE_FILES
    local JOBS
    local ACCOUNTS
    SOURCE_DIRS="$(mktemp -q "$SCRATCH"/dirs.XXXX)" || {
      echo "filelist: Can't create temp file, exiting..."
      exit 1
    }

    SOURCE_FILES="$(mktemp -q "$SCRATCH"/filelist.XXXX)" || {
      echo "filelist: Can't create temp file, exiting..."
      exit 1
    }

    JOBS="$(mktemp -q "$SCRATCH"/joblist.XXXX)" || {
      echo "joblist: Can't create temp file, exiting..."
      exit 1
    }

    ACCOUNTS="$(mktemp -q "$SCRATCH"/accounts.XXXX)" || {
      echo "accounts: Can't create temp file, exiting..."
      exit 1
    }

    #  Rclone Variables
    local SOURCE="stubbs-TDmattpalm-movies"
    local SOURCE_SUBDIR=""
    local SOURCE_PATH="${SOURCE}:${SOURCE_SUBDIR}"

    local GD_DEST_SUBDIR="mattpalm"
    #local GD_DEST_PATH="${GD_DEST}:${GD_DEST_SUBDIR}/"

    _TmpRcloneConf() {
      local TmpRcloneConf
      local Rclone_Config
      local DIR_JSON
      DIR_JSON="$DIR_APP/token/"
      Rclone_Config="$(rclone config file | grep rclone.conf)"
      TmpRcloneConf="$(mktemp -q "$SCRATCH"/rclone.XXXX || $(echo "rclone: Can't create temp file, exiting..." && exit 1) | tee -a "$LOG_SCRIPT")"
      # copy Users rclone.config to tmp location
      cp "$Rclone_Config" "$TmpRcloneConf"

      _Json_Email() {
        SA_EMAILS="$DIR_APP/emails.txt"
        cat "$DIR_JSON"** | jq '.client_email' | tee "$SA_EMAILS"
        echo
        echo 'NOTE: you can copy and paste the whole chunk at once'
        echo "If you need to see them again, they are in $SA_EMAILS"
        read -p 'Press Any Key To Continue.'
        return 0
      }
/home6/omg/.config/jacktheripper/token/Owncloud-e60bd7db1d6f.json
      _Json_Config_SA() {
        VALUES=(
          'client_id ""'
          'client_secret ""'
          'scope drive'
          'root_folder_id ""'
          'service_account_file {}'
          "team_drive $teamDrive"
        )
        # Add Service accounts from $DIR_JSON
        find "$DIR_JSON" -type f -name *.json
        find "$DIR_JSON" -type f -name *.json | parallel -X --link "rclone config create gdsa01 drive ${VALUES[*]} --config $TmpRcloneConf"
      }

      _Json_Validate() {
        # validate new keys
        local THREADS
        Rclone_SA_List="$(rclone listremotes --config "${TmpRcloneConf}" | grep gdsa | sed "s/://")"
        THREADS="$(wc -l <"$Rclone_SA_List")"
        local pARGS=(
          '-X'
          '--link'
          -"j${THREADS}"
        )
        parallel "${pARGS[@]}" "rclone touch {}:test.tmp --config $TmpRcloneConf" :::: "$Rclone_SA_List" | tee -a "$LOG_SCRIPT"
      }

      _Local_Remote() {
        # Add new remote for the user's home directory
        rclone config create local local_home 'nounc ""' --config "$TmpRcloneConf"
      }

      _Generate_Accounts() {
        # generate new accounts file every time for portability.
        "${Rclone_SA_List}" >"${ACCOUNTS}"
      }

      _Json_Email
      _Json_Config_SA
      _Json_Validate
      _Local_Remote
      _Generate_Accounts

    }

    _rclone_list_files() {
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
      rclone lsf "${SOURCE_PATH}" "${rcloneARGS[@]}" | tee "$SOURCE_FILES"
    }
    _jacktheripper() {
      local driveChunkSize
      local AvailableRam
      local COUNT_SA
      # count configured Rclone Remotes to limit Parallel threads.
      COUNT_SA=$(wc -l <"$Rclone_SA_List")

      # Calculate best chunksize for trasnfer speed.
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

      local parallelARGS=(
        "-j$COUNT_SA"
        '--tmux'
        "--joblog=$LOG_PARALLEL"
        "--progress"
        '--load 50%'
        '--retries=3'
        '--noswap'
        '--memfree 128M'
        '--resume-failed'
        '--delay'
        '--link'
        '-X'
      )
      # parallel "rclone copy <Source Path>/<Source Files> <Accounts>:<Destination Subdirectory>/<Source File's Paths with filename cut>"
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
