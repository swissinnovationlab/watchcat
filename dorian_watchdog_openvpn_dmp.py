import sys
import re
from datetime import datetime
from dataclasses import dataclass
from enum import Enum

# 2024-11-14T14:14:21.501306+00:00
timestamp_pattern = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}\+00:00")

class State(str, Enum):
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"

STATE_PATTERNS = {
    State.CONNECTED: re.compile(rf".*openvpn.*Peer Connection Initiated with \[AF_INET\].*"),
    State.DISCONNECTED: re.compile(rf".*openvpn.*TCP: connect to \[AF_INET\].*failed: Connection refused.*")
}

@dataclass
class Status:
    state: State
    state_timestamp: datetime
    last_timestamp: datetime

STATUS = Status(State.DISCONNECTED, datetime.now(), datetime.now())

def parse_log(log_line):
    match = timestamp_pattern.search(log_line)
    if match:
        timestamp_str = match.group(0)
        timestamp = datetime.fromisoformat(timestamp_str)
        for state, pattern in STATE_PATTERNS.items():
            match = pattern.search(log_line)
            if match:
                return state, timestamp
        return None, timestamp
    return None, None

if __name__ == "__main__":
    while True:
        log_line = sys.stdin.readline()
        if log_line is None:
            break
        log_line = log_line.strip()
        if len(log_line) == 0:
            continue
        state, timestamp = parse_log(log_line)
        if timestamp is not None:
            if state is not None:
                print(timestamp, state.name)
                STATUS.state = state
                STATUS.state_timestamp = timestamp
            STATUS.last_timestamp = timestamp

            if STATUS.state == State.CONNECTED:
                pass # write current timestamp to tmp

        else:
            pass
            print("ERROR: invalid log:", log_line)
