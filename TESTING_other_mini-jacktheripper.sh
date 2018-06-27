#!/usr/bin/env sh

###############################################################################
#  Wrapper script for rclone to distribute transfers over multiple accounts.  #
###############################################################################
eval "$(curl https://raw.githubusercontent.com/The-OMG/rclone-jacktheripper/master/sub/jacktheripper.sauce)"

_Main() {

    _Finish() {
        rm -rf "$SCRATCH"
    }

    _setup() {
        PACKAGES="rclone parallel mktemp cat jq"
        for i in $PACKAGES; do
            curl -s x | sh $i
        done

        DIRS="$DIR_LOG $TMPDIR $DIR_APP"
        for i in $DIRS; do
            curl -s x | sh $i
        done
    }

    _job_printer() {
        _TmpRcloneConf() {
            # copy Users rclone.config to tmp location
            cp "$Rclone_Config" "$TmpRcloneConf"

            _Json_Email() {
                cat "$DIR_JSON"** |
                    jq '.client_email' |
                    tee "$SA_EMAILS"
                echo
                echo 'NOTE: you can copy and paste the whole chunk at once'
                echo "If you need to see them again, they are in $SA_EMAILS"
                read 'Press Any Key To Continue.'
                return 0
            }
            _Json_Config_SA() {
                VALUES="scope drive \
                service_account_file {} \
                team_drive $teamDrive"

                # Add Service accounts from $DIR_JSON
                find "$DIR_JSON" -type f -"name *.json"
                find "$DIR_JSON" -type f -"name *.json" |
                    parallel -X --link "rclone config create gdsa01 drive $VALUES --config $TmpRcloneConf"
            }

            _Json_Validate() {
                # validate new keys
                THREADS
                Rclone_SA_List="$(rclone listremotes --config "${TmpRcloneConf}" |
                    grep gdsa |
                    sed "s/://")"
                THREADS="$(wc -l <"$Rclone_SA_List")"
                pARGS="-X \
                    --link \
                    j${THREADS}"

                parallel "$pARGS" "rclone touch {}:test.tmp --config $TmpRcloneConf" :::: "$Rclone_SA_List" |
                    tee -a "$LOG_SCRIPT"
            }

            _Local_Remote() {
                # Add new remote for the user's home directory
                rclone config create local_home 'nounc ""' --config "$TmpRcloneConf"
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
            rcloneARGS="--files-only \
                --recursive \
                --checkers=40 \
                --fast-list \
                --exclude=\**partial~\" \
                --exclude=\**_HIDDEN~\""

            echo "Creating input filelist" |
                tee -a "$LOG_SCRIPT"
            #sleep 2
            echo "This process may take a long time."
            # Prints rclone Source file with path to a file. Overwrites file every time.
            rclone lsf "${SOURCE_PATH}" "$rcloneARGS" |
                tee "$SOURCE_FILES"
        }
        _jacktheripper() {
            RCLONE_SUBPROCESS="$(curl -s x | sh)"

            # parallel "rclone copy <Source Path>/<Source Files> <Accounts>:<Destination Subdirectory>/<Source File's Paths with filename cut>"
            parallel "$parallelARGS" $RCLONE_SUBPROCESS :::: ${SOURCE_FILES} :::: ${ACCOUNTS} |
                tee "$JOBS"
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
