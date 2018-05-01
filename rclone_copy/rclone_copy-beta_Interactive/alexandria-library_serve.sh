#!/bin/bash

################################################################################
#### Start multiple instannces of rclone http serve for use with a reverse #####
#### proxy webserver.                                                      #####
################################################################################
#							      ___           ___           ___                            #
#							     /  /\         /__/\         /  /\                           #
#							    /  /::\       |  |::\       /  /:/_                          #
#							   /  /:/\:\      |  |:|:\     /  /:/ /\                         #
#							  /  /:/  \:\   __|__|:|\:\   /  /:/_/::\                        #
#							 /__/:/ \__\:\ /__/::::| \:\ /__/:/__\/\:\                       #
#							 \  \:\ /  /:/ \  \:\~~\__\/ \  \:\ /~~/:/                       #
#							  \  \:\  /:/   \  \:\        \  \:\  /:/                        #
#							   \  \:\/:/     \  \:\        \  \:\/:/                         #
#							    \  \::/       \  \:\        \  \::/                          #
#							     \__\/         \__\/         \__\/                           #
#                                                                              #
################################################################################
#### rclone credit        : https://github.com/ncw/rclone
###  Install rclone       : https://rclone.org/install/
###  Install rclone       : "brew install rclone"

#### GNU parallel credit  : https://www.gnu.org/software/parallel/
###  Install GNU parallel : "sudo apt-get install parallel"
###  Install GNU parallel : "brew install parallel"
################################################################################

# path to your file containing the acounts you want to use.
ACCOUNTS="$HOME/scripts/pegasus.txt"

# path to your file containing the ports you want to use.
PORTS="$HOME/scripts/ports.txt"

# arguments for the rclone package.
#  "--stats"      : "interval between printing stats, e.g 500ms, 60s, 5m. (0 to disable) (default 1m0s)"
#  "--read-only"  : "Mount read-only."
#  "--fast-list"  : "Use recursive list if available. Uses more memory but fewer transactions."
#  "-vv"          : "Print lots more stuff (repeat for more)"
#  "--log-file="  : "Log everything to this file"
# "--addr"        : "IP or host to bind to.
rcloneARGS="--stats 30s --read-only --fast-list -vv --log-file=""${HOME}"/logs/alexandria.log""

# Arguments for the GNU parallel package.
# "--link"        : "link the input sources and get one argument from each input source."
# "--jobs=n"      : "Run n jobs in parallel."
# "--delay=n"     : "Delay the start of new jobs n amount of seconds."
# "--shuf"        : "Shuffle order that jobs are ran."
# "--joblog="     : "Path to logfile of the jobs completed so far."
# "--link"        : "If multiple input sources are given, one argument will be read from each of the input sources."
# " :::: "        : "argfiles. Unlike other options for GNU parallel :::: is placed after the command and before the arguments."
parallelARGS="--link --jobs=12 --delay=3 --joblog=alexandria-parallel.log -X"

# Remove existing accounts file.
rm -rf "$ACCOUNTS"

# Remove existing ports file.
rm -rf "$PORTS"

# My rclone remotes are named so that I can grep the Teamdrive name from
# multiple accounts and pipe them to the accounts file. You may need to create
# your own accounts.txt file manually if your remotes are not setup in this way.
rclone listremotes | grep TDpegasus >>"$ACCOUNTS"

# generating ports file. Since I have 12 remotes to start, this ports file will
# create 12 ports in sequence. If you have a different amout of remotes to use,
# modify "10033".
seq 10022 +1 10033 >>"$PORTS"

# create initial logfile.
touch "${HOME}/logs/alexandria.log"

# start rclone serve http remotes in a staggered fashion.
parallel $parallelARGS rclone serve http {1}alexandria-library.space --addr localhost:{2} "$rcloneARGS" :::: $ACCOUNTS $PORTS
echo "Alexandria started"
