#!/bin/bash

REPORT_FILE="~/dorian_watchdog/logs/dorian_watchdog_reboot_reason.txt"
CURRENT_TIME=$(date --utc +%s)

FILES=(
  "/tmp/dorian_watchdog_openvpn_dmp.txt"
  "/tmp/dorian_watchdog_devconn_connector.txt"
)

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
    if is_timestamp_old "$TIMESTAMP"; then
      echo "Reboot triggered by $file with timestamp $TIMESTAMP; current UTC time: $(date --utc +%Y-%m-%dT%H:%M:%S%z)" > "$REPORT_FILE"
      echo "Rebooting system due to file $file with old timestamp."
      #sudo reboot
    else
      REMAINING_TIME=$(time_until_timeout "$TIMESTAMP")
      echo "$file $REMAINING_TIME till timeout"
    fi
  fi
}

UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)
if [ "$UPTIME_HOURS" -ge 2 ]; then
  for FILE in "${FILES[@]}"; do
    check_file "$FILE"
  done
else
  echo "System uptime is less than 2 hours. No need to check files."
fi

