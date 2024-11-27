#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
REPORT_FILE="$SCRIPT_DIR"/../logs/watchcat_reboot_reason.txt
CURRENT_TIME=$(date --utc +%s)

FILES=(
  "/tmp/watchcat_openvpn_dmp.txt"
  "/tmp/watchcat_devconn_connector.txt"
)

DRYRUN=0

is_timestamp_old() {
  local timestamp="$1"
  local timestamp_sec=$(date --utc --date="$timestamp" +%s)
  local time_diff=$((CURRENT_TIME - timestamp_sec))
  
  if [ $time_diff -gt 7200 ]; then
    return 0
  else
    return 1
  fi
}

time_until_timeout() {
  local timestamp="$1"
  local timestamp_sec=$(date --utc --date="$timestamp" +%s)
  local time_diff=$((7200 - (CURRENT_TIME - timestamp_sec)))

  if [ $time_diff -le 0 ]; then
    echo "0h0m0s"
  else
    local hours=$((time_diff / 3600))
    local minutes=$(( (time_diff % 3600) / 60 ))
    local seconds=$((time_diff % 60))
    echo "${hours}h${minutes}m${seconds}s"
  fi
}

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    TIMESTAMP=$(cat "$file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|\+00:00)?')
    if [ -z "$TIMESTAMP" ]; then
        echo "TIMESTAMP could not be parsed"
        TIMESTAMP=NONPARSE
    else
        echo "TIMESTAMP is $TIMESTAMP"
    fi

    if is_timestamp_old "$TIMESTAMP"; then
      echo "Reboot triggered by $file with timestamp $TIMESTAMP; current UTC time: $(date --utc +%Y-%m-%dT%H:%M:%S%z) DRYRUN=$DRYRUN" >> "$REPORT_FILE"
      echo "Rebooting system due to file $file with old timestamp."
      [ $DRYRUN -eq 0 ] && sudo reboot || echo "Reboot skipped due to --dryrun FLAG or failed"
    else
      REMAINING_TIME=$(time_until_timeout "$TIMESTAMP")
      echo "$file $REMAINING_TIME till timeout"
    fi
  else
    echo "$file does not exist"
  fi
}

echo "Starting script"

check_args() {
  for arg in "$@"
  do
      if [ "$arg" == "--dryrun" ]; then
          DRYRUN=1
          echo "--dryrun FLAG is called"
      fi
  done
}

main() {
  UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)
  if [ "$UPTIME_HOURS" -ge 2 ]; then
    for FILE in "${FILES[@]}"; do
      check_file "$FILE"
    done
  else
    echo "System uptime is less than 2 hours. No need to check files."
  fi
}

check_args "$@"
main
