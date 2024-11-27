#!/bin/bash

pattern_timestamp="^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}\+00:00"
pattern_connected=".*openvpn.*Peer Connection Initiated with \[AF_INET\].*"
pattern_disconnected=".*openvpn.*TCP: connect to \[AF_INET\].*failed: Connection refused.*"
pattern_connected=${pattern_connected//[$'\t\r\n ']}
pattern_disconnected=${pattern_disconnected//[$'\t\r\n ']}

state="DISCONNECTED"
state_timestamp=""

parse_log() {
    local log_line="$1"
    if [[ $log_line =~ $pattern_timestamp ]]; then
        local timestamp="${BASH_REMATCH[0]}"
        if [[ $log_line =~ $pattern_connected ]]; then
            echo "$timestamp CONNECTED"
            state="CONNECTED"
            state_timestamp="$timestamp"
        elif [[ $log_line =~ $pattern_disconnected ]]; then
            echo "$timestamp DISCONNECTED"
            state="DISCONNECTED"
            state_timestamp="$timestamp"
        fi
        state_timestamp="$timestamp"
    else
        echo "ERROR: invalid log: $log_line"
    fi
}

main() {
    while IFS= read -r log_line || [[ -n "$log_line" ]]; do
        log_line="${log_line//[$'\t\r\n ']}" # trim whitespace
        if [[ -n "$log_line" ]]; then
            parse_log "$log_line"
            if [[ "$state" == "CONNECTED" ]]; then
                echo $state_timestamp > /tmp/watchcat_openvpn_dmp.txt
            fi
        fi
    done
}

echo Starting script
main
echo Ending script
