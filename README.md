# dorian_watchdog

## concept idea:

```bash
dorain_watchdog.sh:
  dorian_watchdog_uptime.txt
  dorian_watchdog_devconn_connector.txt
  dorian_watchdog_openvpn_dmp.txt

ako uptime > 2h:
  ako bilo koji > 2h:
    restart
      >> dorain_watchdog_reboot_reason.txt
```
## devconn_connector

### Examples
- connected:

...`2024-11-12T14:24:08.354113485Z 13:24:08.351 [info] [c_backend:#PID<0.976.0>] Connected! Status: 101; Headers: [{"cache-control", "max-age=0, private, must-revalidate"}, {"connection", "Upgrade"}, {"date", "Tue, 12 Nov 2024 13:24:07 GMT"}, {"sec-websocket-accept", "dkJnsqHN6dykICIAsHowcK7l3TY="}, {"server", "Cowboy"}, {"upgrade", "websocket"}]`
- error:

...`2024-11-12T14:23:57.476638108Z 13:23:57.474 [info] [c_backend:#PID<0.976.0>] Error! Error: {:connecting_failed, %Mint.TransportError{reason: :econnrefused}}`
- disconnected:
...`2024-11-12T14:23:49.315446432Z 13:23:49.313 [info] [c_backend:#PID<0.976.0>] Disconnected! Code: 1000; Reason: ""`

### Testing
- disable connection:
  `sudo iptables -A OUTPUT -p tcp -d 20.203.166.66 -j REJECT`
- enable connection
  `sudo iptables -D OUTPUT -p tcp -d 20.203.166.66 -j REJECT`
- viewing logs:
  `docker logs -t -f devconn_connector`
- parsing logs:
  `docker logs -t -f devconn_connector | sh dorian_watchdog_devconn_connector.sh`

## openvpn_dmp

## uptime

cat /proc/uptime | awk '{print $1}'
uptime -s

