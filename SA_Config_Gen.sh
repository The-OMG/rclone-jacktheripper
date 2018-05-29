#!/usr/bin/env bash

_Main() {
  clear
  local TITLE="OMG's Service Account Config Generator"
  local DIR_JSON="$HOME/.config/rclone/tokens"
  # local THREADS
  # local Rclone_SA_List
  local RCLONE_BETA="$HOME/.config/rclone/rclone-v1.41-070-g67e9ef45β-linux-amd64/rclone"

  _polly() {
    whiptail --title "YOU SHALL NOT PASS" --msgbox Exiting 10 60
    clear
    curl -s parrot.live
  }

  _Token_Folder() {
    mkdir -p "$DIR_JSON"
    whiptail --title "$TITLE" --msgbox "Place your JSON files in $DIR_JSON" 10 60
  }

  _TD_Name() {
    local PROMPT="What is your Teamdrive name?"
    TD_NAME=$(whiptail --title "$TITLE" --inputbox "$PROMPT" 10 60 3>&1 1>&2 2>&3)
    local RCLONE_CONFIG="$HOME/.config/rclone/$TD_NAME/rclone.conf"

    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      mkdir -p "$HOME/.config/rclone/$TD_NAME"
      echo "" >$RCLONE_CONFIG
    else
      _polly
    fi

    local PROMPT="What is your Teamdrive Folder ID?"
    TD_FOLDER_ID=$(whiptail --title "$TITLE" --inputbox "$PROMPT" 10 60 3>&1 1>&2 2>&3 || _polly)
    VALUES=(
      'scope drive'
      'service_account_file {2}'
      "team_drive $TD_FOLDER_ID"
      "--config $RCLONE_CONFIG"
    )

    local START=01
    local END
    local SA_NUMBERS
    END=("$(find "$DIR_JSON" -type f -name '*.json' | wc -l)")

    SA_NUMBERS=("$(
      for ((i = START; i <= END; i++)); do
        printf "%02d\n" $i
      done
    )"
    )

    local TOKENS
    TOKENS=("$(find "$DIR_JSON" -type f -name '*.json')")

    parallel -J1 -X "$RCLONE_BETA config create gdsa{1}-$TD_NAME drive ${VALUES[*]}" ::: "${SA_NUMBERS[@]}" :::+ "${TOKENS[@]}" >/dev/null

    #   local Rclone_SA_List
    #
    #   Rclone_SA_List=("$(for account in $($RCLONE_BETA listremotes --config "$RCLONE_CONFIG"); do
    #     echo $account | sed "s/://"
    #   done)")
    #
    #   # validate new keys
    #   THREADS="$($RCLONE_BETA listremotes --config "$RCLONE_CONFIG" | sed "s/://" | grep -c gdsa)"
    #   local pARGS=(
    #     '-X'
    #     -"j${THREADS}"
    #     '--delay'
    #   )
    #   parallel "${pARGS[@]}" "$RCLONE_BETA touch {}:{}-test.GDSAtmp --config $RCLONE_CONFIG" ::: "${Rclone_SA_List[@]}"

    for entry in "$DIR_JSON"/*; do
      cat "$entry" | jq '.client_email'
    done

    echo
    echo 'Make sure to share access to your service accounts.'
    echo 'NOTE: you can copy and paste the whole chunk at once.'
    echo
    echo "Your config file can be found here:"
    echo "$HOME/.config/rclone/$TD_NAME/rclone.conf"
    echo
    echo 'See your new remotes with:'
    echo "rclone listremotes --config $HOME/.config/rclone/$TD_NAME/rclone.conf"
  }
  _Token_Folder
  _TD_Name
}

_Main
