#!/usr/bin/env bash

############################################################################
# Supertransfer User Settings
############################################################################
# enter to use team drives. run with --purge-rclone
# Teamdrive ID
teamDrive=
# leave empty for root
remoteDir=

#######################################
# Supertransfer Application Settings
#######################################
gdsaDB=/tmp/gdsaDB
localDir=/mnt/move/
modTime=0.5
uploadHistory=/tmp/superTransferUploadHistory.txt
jsonPath=/opt/appdata/plexguide/supertransfer
userSettings=/opt/appdata/plexguide/supertransfer/usersettings.conf
logDir=/opt/appdata/plexguide/supertransfer/logs
fileLock=/tmp/filelock
maxConcurrentUploads=8
staleFileTime=5
sleepTime=20
# _JsonToken() {

#   upload_Json() {
#     [[ ! -e "$jsonPath" ]] && mkdir" $jsonPath" && log 'Json Path Not Found. Creating.' INFO && sleep 0.5
#     [[ ! -e "$jsonPath" ]] && log 'Json Path Could Not Be Created.' FAIL && sleep 0.5
#
#     localIP=$(curl -s icanhazip.com)
#     [[ -z $localIP ]] && localIP=$(
#       wget -qO- http://ipecho.net/plain
#       echo
#     )
#     # mini upload server usage: start it in directory that will be used for upload.
#     # Note to self: see if you can curl the python file from github instead of running it local.
#     cd "$jsonPath" || exit
#     python3 /opt/plexguide/scripts/supertransfer/jsonUpload.py &>/dev/null &
#     jobpid=$!
#     trap 'kill $jobpid && exit 1' SIGTERM
#
#     cat <<MSG
#
#   ############ CONFIGURATION ################################
#
#   1. Go to [32mhttp://${localIP}:7998[0m
#   2. Login: plex / guide
#   3. Drag & Drop your keys in the PG CloudCMD ST Edition
#   4. Follow the instructions to generate the json keys
#   5. Upload 20-99 Gsuite service account json keys
#             - domain wide delegation not needed.
#
#   TIP: Port 8000 is alternative port (slower process)
#
#   If port 7998/8000 is closed or wish to upload keys securely,
#   Transfer json keys directly into:
#   $jsonPath
#
#   ###########################################################
#
# MSG
#     read -rep $'\e[032m   -- Press any key when you are done uploading --\e[0m'
#     trap "exit 1" SIGTERM
#     echo
#     start_spinner "Terminating Web Server."
#     sleep 2
#     { kill $jobpid && wait $jobpid; } &>/dev/null
#     stop_spinner $((!$?))
#
#     if [[ $(ps -ef | grep "jsonUpload.py" | grep -v grep) ]]; then
#       start_spinner "Web Server Still Running. Attempting to kill again."
#       jobpid=$(ps -ef | grep "jsonUpload.py" | grep -v grep | awk '{print $2}')
#       sleep 5
#       { kill "$jobpid" && wait "$jobpid"; } &>/dev/null
#       stop_spinner $((!$?))
#     fi
#
#     numKeys=$(find "$jsonPath" -type f -name .json$ | wc -1)
#     if [[ $numKeys -gt 0 ]]; then
#       log "Found $numKeys Service Account Keys" INFO
#     else
#       log "No Service Keys Found. Try Again." FAIL
#       exit 1
#     fi
#     return 0
#   }


# cat_Troubleshoot() {
#   read -p "View Troubleshooting Tips? y/n>" answer
#   if [[ $answer =~ [y|Y|yes|Yes] ]]; then
#     cat <<EOF
# ####### Troubleshooting steps: ###########################
#
# 1. Make sure you have enabled gdrive api access in
#    both the dev console and admin security settings.
#
# 2. Check if the json keys have "domain wide delegation"
#
# 3. Check if the this email is correct:
#    [1;35m$gdsaImpersonate[0m
#       - if it is incorrect, configure it again with:
#         supertransfer --config
#
# 4. Remove the offending keys and run:
#         supertransfer --purge-rclone
#
# 5. Check these logs for detailed debugging:
#       - /tmp/SA_error.log
#
# ##########################################################
# EOF
#   fi
#
#   read -p "View Error Log? y/n>" answer
#   [[ $answer =~ [y|Y|yes|Yes] ]] && less /tmp/SA_error.log
# }
#
#
# _validate_json_Troubleshoot() {
#   # help user troubleshoot
#   if [[ -n $gdsaFail ]]; then
#     log "$gdsaFail Validation Failure(s). " WARN
#     cat_Troubleshoot
#   read -r -p "Continue anyway? y/n>" answer
#   [[ ! $answer =~ [y|Y|Yes|yes] || ! $answer == '' ]] && exit 1
#   fi
# }
#     }
#
# }
local jsonPath=/opt/appdata/plexguide/supertransfer

local JSON_FILES="$(cat $JSON_PATH/**)"
_Json_Email() {
  # Verify Json Token Folder is made and Create if not found.
  [[ $(ls -A $jsonPath | grep -E .json$) ]] || log "configure_teamdrive_share : no jsons found" FAIL && exit 1
  # Verify that a Teamdrive has been specified and exit if not found.
  [[ "$teamDrive" ]] || log "configure_teamdrive_share : no teamdrive found in config" FAIL && exit 1

  cat "$JSON_PATH/**" | jq '.client_email' | tee "$SA_EMAILS"
  echo
  echo 'NOTE: you can copy and paste the whole chunk at once'
  echo "If you need to see them again, they are in $SA_EMAILS"
  read -p 'Press Any Key To Continue.'
  return 0
}

_CONFIG_Print_SA() {
  Rclone_Config="$(rclone config file | grep rclone.conf)"
  #[[ -e ${Rclone_Config} ]] || mkdir -p ${Rclone_Config}
  #[[ ! $(ls $jsonPath | egrep .json$) ]] && log "No Service Accounts Json Found." FAIL && exit 1
  # add rclone config for new keys if not already existing

  VALUES=(
    client_id ""
    client_secret ""
    scope drive ""
    root_folder_id ""
    service_account_file {}
    team_drive $teamDrive
  )

  parallel -X --link "rclone config create gdsa01 drive ${VALUES[*]} --config $SA_Rclone_Config" ::::

  for json in ${jsonPath}/*.json; do
    if [[ ! $(grep -e '^\[GDSA[0-9]+\]$' -A7 $Rclone_Config | grep "$json") ]]; then
      oldMaxGdsa=$(egrep '^\[GDSA[0-9]+\]$' $Rclone_Config | sed 's/\[GDSA//g;s/\]//' | sort -g | tail -1)
      newMaxGdsa=$((++oldMaxGdsa))

      ((++newGdsaCount))
    fi
  done
  [[ -n $newGdsaCount ]] && log "$newGdsaCount New Gdrive Service Account Added." INFO
  return 0
}

# configure json's for rclone
_CONFIG_Print_SA
gdsaList=$(rclone listremotes --config /root/.config/rclone/rclone.conf | sed 's/://' | grep -E '^GDSA[0-9]+$')
[[ -z $gdsaList ]] && log "Rclone Configuration Failure." FAIL && exit 1
# validate new keys

_validate_json() {
  echo '' >/tmp/SA_error.log
  for gdsa in $gdsaList; do
    s=0
    start_spinner "Validating: ${gdsa}"
    rclone touch "${gdsa}":"${rootDir}"/SA_validate &>/tmp/.SA_error.log.tmp && s=1
    if [[ $s == 1 ]]; then
      stop_spinner 0
    else
      cat /tmp/.SA_error.log.tmp >>/tmp/SA_error.log
      stop_spinner 1
      ((gdsaFail++))
    fi
  done
}
