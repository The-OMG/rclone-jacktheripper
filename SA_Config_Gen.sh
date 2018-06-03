#!/usr/bin/env sh

_Main() {
    clear
    TITLE="OMG's Service Account Config Generator"
    DIR_JSON="$HOME/.config/rclone/tokens"
    RCLONE_BETA="$HOME/.config/rclone/rclone"

    _Polly() {
        whiptail --title "YOU SHALL NOT PASS" --msgbox Exiting 10 60
        clear
        curl -s parrot.live
        sleep 5
        exit 1
    }

    _Token_Folder() {
        # Make tokens folder
        mkdir -p "$DIR_JSON"
        whiptail --title "$TITLE" --msgbox "Place your JSON files in $DIR_JSON" 10 60
    }

    _TD_Name() {
        PROMPT="What is your Teamdrive name?"
        TD_NAME=$(whiptail --title "$TITLE" --inputbox "$PROMPT" 10 60 3>&1 1>&2 2>&3 &&
            exit 0 || exit 1)
        DIR_CONFIG="$HOME/.config/rclone/$TD_NAME"

        mkdir -p "$DIR_CONFIG" || _Polly

        RCLONE_CONFIG="$DIR_CONFIG/rclone.conf"
        # Generate initial rclone.conf
        touch $RCLONE_CONFIG

        # copy .json files from /tokens/ to new TD folder.
        for entry in "$DIR_JSON"/*.json; do
            cp -n "$entry" "$DIR_CONFIG" ||
                echo "There weren't any .json files found in $DIR_JSON"
        done

        #cp --no-clobber "$DIR_JSON"/*.json "$DIR_CONFIG/" || echo "There weren't any .json files found in $DIR_JSON" && exit 1

        DIR_CONFIG="$HOME/.config/rclone/$TD_NAME"
        PROMPT="What is your Teamdrive Folder ID?"
        TD_FOLDER_ID=$(whiptail --title "$TITLE" --inputbox "$PROMPT" 10 60 3>&1 1>&2 2>&3 || _Polly)
        VALUES="scope drive \
        service_account_file {2} \
        team_drive $TD_FOLDER_ID \
        --config $RCLONE_CONFIG"

        START=01

        END=("$(find "$DIR_CONFIG" -type f -name '*.json' | wc -l)")

        # Lets count.
        SA_NUMBERS=("$(
            for ((i = START; i <= END; i++)); do
                printf "%02d\n" $i
            done
        )"
        )

        # Found your .json files.
        TOKENS=("$(find "$DIR_CONFIG" -type f -name '*.json')")

        # Lets make a rclone.conf.
        parallel -J1 -X "$RCLONE_BETA config create gdsa{1}-$TD_NAME drive ${VALUES[*]}" ::: "${SA_NUMBERS[@]}" :::+ "${TOKENS[@]}" >/dev/null

        # Here's your Service Account emails.
        for entry in "$DIR_CONFIG"/*; do
            cat "$entry" | jq '.client_email'
        done
        RCLONE_CONFIG=$(rclone config file)
        cat "$OLD_RCLONE_CONFIG" >>"$RCLONE_CONFIG"
        rm -rf $DIR_JSON/*.json

        echo
        echo 'Make sure to share access to your service accounts.'
        echo 'NOTE: you can copy and paste the whole chunk at once.'
        echo
        echo "Your config file can be found here:"
        echo "$HOME/.config/rclone/$TD_NAME/rclone.conf"
        echo
        echo "Your .json files were moved from $DIR_TOKEN to $DIR_CONFIG"
        echo
        echo
        echo 'See your new remotes with:'
        echo "rclone listremotes --config $DIR_CONFIG/rclone.conf"
    }
    _Token_Folder
    _TD_Name
}

_Main
