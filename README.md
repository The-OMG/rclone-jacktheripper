# rclone-hydra

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
