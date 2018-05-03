#!/bin/bash
# NEEDED FOR SCRIPT: RCLONE, PARALLEL

# WARNING
#	USE AT YOUR OWN RISK.
#	I would not recommend adding an "&" to the script. you'll be in for a bad time.
	
# PURPOSE
#	The purpose of this script is to distribute load of API usage across multiple accounts.
	
# OPERATION
#	chmod u+x *.sh
#	./jacktheripper.sh

# INPUT
#	"accounts.txt" is your input file full of your google accounts that are already setup.
#	each account/remote must point to the same folder/teamdrive.
#	txt file needs to have 1 account/remote per line minus the ":".
#	See file for example.

# LOGS
#	Watch your per-remote log files in your (" $NEW") log folder.
#	tail -f ~/logs/.....

# VARIABLES
#	SOURCE and DEST need to be formatted like a normal rclone command.
#	I.E. SOURCE="gdrive:movie_folder"
#	I.E. DEST="teamdrive:movie_folder"
#	the "S1" variable represents the google drive accounts in accounts.txt

#	modify the --checkers/--transfers values for your needs.
#	this script will run (X rclone threads) multiplied by Y input accounts.

SOURCE="$1:movies"
DEST=""

rclone sync $SOURCE $DEST \
--ignore-checksum \
--ignore-existing \
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
--log-file=$HOME/logs/rclone-$1.log \
--fast-list \
-vvv

echo all processes complete
