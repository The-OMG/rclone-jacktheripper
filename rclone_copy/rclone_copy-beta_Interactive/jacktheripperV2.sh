#!/bin/bash
#####################################################################
# Benchmark Script 2.1 by SavageWS6 from FreeVPS                    #
#####################################################################

# PERMISSIONS

# Gloabal Variables
	SOURCE_PATH="$SOURCE:$SOURCE_SUBDIR/"
	DEST_path="$DEST:$DEST_SUBDIR/"
	ECHO="echo -e"
	LOGDATE="date +%Y%m%d%H%M%S"
	LOG="tee -a $OUTPUT/jacktheripper$LOGDATE.log" # Path to logfile

# Global Functions
function ask_yes_or_no () {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}
# Rclone functions
function rclone_list_files () {
	rclone lsf \
	SOURCE_PATH \
	--files-only \
	-R \
	--fast-list
}
function merged_listed_input_files () {
	echo ""${SOURCE_PATH}""${rclone_list_files}""
}
function rclone_copy () {
	rclone copy {1} {2}:$DEST_SUBDIR \
		--checksum \
		--transfers=8 \
		--checkers=8 \
		--low-level-retries=20 \
		--stats=10s \
		--retries=20 \
		--ignore-existing \
		--min-size=0 \
		--contimeout=60s \
		--timeout=300s \
		--retries=3 \
		--low-level-retries=10 \
		--log-file=$HOME/logs/rclone-$SOURCE-rclone.log \
		--fast-list \
		-vvv
	echo "thread complete"
}
## GNU PARALLEL Functions

## GNU Parallel flags:
	# --delay
		# Some jobs do heavy I/O when they start. To avoid a thundering herd GNU parallel can delay starting new jobs. --delay X will make sure there is at least X seconds between each start.
	# --progress
		# GNU parallel can give progress information with --progress.
	# --joblog 
		# A logfile of the jobs completed so far can be generated with --joblog
	# --retries
		# GNU parallel can retry the command with --retries. This is useful if a command fails for unknown reasons now and then.
	# --resume-failed
		# With --resume-failed GNU parallel will re-run the jobs that failed
function parallelize () {
	parallel \
		-j4 \
		--delay \
		--xapply \
		--progress \
		--load 50% \
		--retries 3 \
		--noswap \
		--memfree 128M \
		--resume-failed \
		--joblog=$HOME/logs/jacktheripper-parallel.log
}
# User input
function source_interactive_input () {
	rclone listremotes
	echo "Name of the rclone remote above that you want to download from."
	echo "Example: "mygsuite" or "this-cool-http-site" etc"
	read -p 'Source Remote: ' SOURCE
	echo "Subdirectory of $SOURCE, if any you want to download from"
	echo "Leave blank if you want to mirror $SOURCE"
	echo "Example: "Public/uploads/year""
	read -p 'Source Subdirectory: ' SOURCE_SUBDIR
	sleep 2
	echo "$SOURCE_PATH"
	if [[ "no" == $(ask_yes_or_no "Are you sure you want to download from here?")
	then
		echo "Exiting."
		exit 0
fi
}
function destination_interactive_input () {
	rclone listremotes
	echo "Name of the rclone remote above that you want to save to."
	echo "Example: "mygsuite" or "$HOME/files" etc"
	read -p 'Destination Remote: ' DEST
	echo "Subdirectory of $DEST, if any you want to download from"
	echo "Leave blank if you want to mirror $DEST"
	echo "Example: "Public/uploads/year""
	read -p 'Source Subdirectory: ' DEST_SUBDIR
	sleep 2
	echo "$DEST_PATH"
	if [[ "no" == $(ask_yes_or_no "Are you sure you want to download from here?")
	then
		echo "Exiting."
		exit 0
fi
}

## final script
source_interactive_input
destination_interactive_input
merged_listed_input_files | parallelize -a accounts.txt rclone_copy