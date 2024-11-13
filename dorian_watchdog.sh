#!/bin/bash

timestamp_pattern="^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{9}Z"
state_connected=".*\[info\].*Connected!"
state_disconnected=".*\[info\].*Disconnected!"
state_error=".*\[info\].*Error!"

state="DISCONNECTED"
state_timestamp=""

parse_log() {
    local log_line="$1"
    if [[ $log_line =~ $timestamp_pattern ]]; then
        local timestamp="${BASH_REMATCH[0]}"
        if [[ $log_line == *"c_backend"* ]]; then
            if [[ $log_line =~ $state_connected ]]; then
                echo "$timestamp CONNECTED"
                state="CONNECTED"
                state_timestamp="$timestamp"
            elif [[ $log_line =~ $state_error ]]; then
                echo "$timestamp ERROR"
                state="ERROR"
                state_timestamp="$timestamp"
            elif [[ $log_line =~ $state_disconnected ]]; then
                echo "$timestamp DISCONNECTED"
                state="DISCONNECTED"
                state_timestamp="$timestamp"
            fi
        fi
        state_timestamp="$timestamp"
    else
        echo "ERROR: invalid log: $log_line"
    fi
}

while IFS= read -r log_line || [[ -n "$log_line" ]]; do
    log_line="${log_line//[$'\t\r\n ']}" # trim whitespace
    if [[ -n "$log_line" ]]; then
        parse_log "$log_line"
        if [[ "$state" == "CONNECTED" ]]; then
            echo $state_timestamp > /tmp/dorian_watchdog_devconn_connector.txt
        fi
    fi
done

