#!/usr/bin/env bash

_JsonToken() {
  local jsonPath=/opt/appdata/plexguide/supertransfer

  _configure_teamdrive_share() {
    [[ ! $(ls "$jsonPath" | grep -E .json$) ]] && log "configure_teamdrive_share : no jsons found" FAIL && exit 1
    [[ -z "$teamDrive" ]] && log "configure_teamdrive_share : no teamdrive found in config" FAIL && exit 1
    printf "$(grep \"client_email\" "${jsonPath}"/*.json | cut -f4 -d'"')\t" >/tmp/clientemails
    count=$(grep -c "@" /tmp/clientemails) # accurate count by @
    read -p 'Press Any Key To See The Emails'
    cat /tmp/clientemails
    echo
    echo 'NOTE: you can copy and paste the whole chunk at once'
    echo 'If you need to see them again, they are in /tmp/clientemails'
    read -p 'Press Any Key To Continue.'
    return 0
  }

  _CONFIG_Print_SA() {
    #rclonePath=$(rclone -h | grep 'Config file. (default' | cut -f2 -d'"')
    rclonePath='/root/.config/rclone/rclone.conf'
    [[ -e ${rclonePath} ]] || mkdir -p ${rclonePath}
    [[ ! $(ls $jsonPath | egrep .json$) ]] && log "No Service Accounts Json Found." FAIL && exit 1
    # add rclone config for new keys if not already existing
    for json in ${jsonPath}/*.json; do
      if [[ ! $(egrep '^\[GDSA[0-9]+\]$' -A7 $rclonePath | grep $json) ]]; then
        oldMaxGdsa=$(egrep '^\[GDSA[0-9]+\]$' $rclonePath | sed 's/\[GDSA//g;s/\]//' | sort -g | tail -1)
        newMaxGdsa=$((++oldMaxGdsa))
        cat <<-CFG >>$rclonePath
  [GDSA${newMaxGdsa}]
  type = drive
  client_id =
  client_secret =
  scope = drive
  root_folder_id = $rootFolderId
  service_account_file = $json
  team_drive = $teamDrive

CFG
        ((++newGdsaCount))
      fi
    done
    [[ -n $newGdsaCount ]] && log "$newGdsaCount New Gdrive Service Account Added." INFO
    return 0
  }

}
