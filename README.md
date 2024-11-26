# watchcat

## concept idea:

The script is based on log lines which trigger the update of timestamps based on the state. If the log line is less often than restart timeout the device will reboot every min timeout.

```bash
dorain_watchdog.sh:
  watchcat_uptime.txt
  watchcat_devconn_connector.txt
  watchcat_openvpn_dmp.txt

ako uptime > 2h:
  ako bilo koji > 2h:
    restart
      >> dorain_watchdog_reboot_reason.txt
```
## devconn_connector

log lines are based on telemetry timeout which is by default set to 15m
```
2024-11-14T14:05:59.218519692Z 14:05:59.217 [info] [telemetry_collector:#PID<0.979.0>] Reading telemetry...
2024-11-14T14:05:59.231019504Z 14:05:59.230 [info] [telemetry_collector:#PID<0.979.0>] Next tick in 900000
2024-11-14T14:05:59.231191961Z 14:05:59.230 [info] [message_router:#PID<0.975.0>] Sending telemetry: ["service_ctrl", "system"]
```

### Examples
- connected:

   `2024-11-12T14:24:08.354113485Z 13:24:08.351 [info] [c_backend:#PID<0.976.0>] Connected! Status: 101; Headers: [{"cache-control", "max-age=0, private, must-revalidate"}, {"connection", "Upgrade"}, {"date", "Tue, 12 Nov 2024 13:24:07 GMT"}, {"sec-websocket-accept", "dkJnsqHN6dykICIAsHowcK7l3TY="}, {"server", "Cowboy"}, {"upgrade", "websocket"}]`
- error:

   `2024-11-12T14:23:57.476638108Z 13:23:57.474 [info] [c_backend:#PID<0.976.0>] Error! Error: {:connecting_failed, %Mint.TransportError{reason: :econnrefused}}`
- disconnected:

   `2024-11-12T14:23:49.315446432Z 13:23:49.313 [info] [c_backend:#PID<0.976.0>] Disconnected! Code: 1000; Reason: ""`

### Testing
- start container using dorian_builder:

   `docker compose --env-file dorian_builder.env --profile devconn_connector up`
- disable connection:

   `sudo iptables -A OUTPUT -p tcp -d 20.203.166.66 -j REJECT`
- enable connection:

   `sudo iptables -D OUTPUT -p tcp -d 20.203.166.66 -j REJECT`
- viewing logs:

   `docker logs -t -f devconn_connector`
- parsing logs:

   `docker logs -t -f devconn_connector | sh watchcat_devconn_connector.sh`

## openvpn_dmp

log lines are based on control channel which is every 1h
```
2024-11-14T05:39:20.000000+00:00 neotux openvpn[741]: Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, peer certificate: 2048 bits RSA, signature: RSA-SHA256, peer temporary key: 253 bits X25519
2024-11-14T06:35:16.000000+00:00 neotux openvpn[741]: VERIFY OK: depth=1, CN=Easy-RSA CA
2024-11-14T06:35:16.000000+00:00 neotux openvpn[741]: VERIFY OK: depth=0, CN=dmp
```

### Examples
- connected:

   `2024-11-14T14:12:37.000000+00:00 neotux openvpn[372571]: [dmp] Peer Connection Initiated with [AF_INET]20.203.166.66:9897`
- disconnected:

   `2024-11-14T14:04:02.000000+00:00 neotux openvpn[372571]: TCP: connect to [AF_INET]20.203.166.66:9897 failed: Connection refused`

### Testing
- disable connection:

   `sudo iptables -A OUTPUT -p tcp -d 20.203.166.66 -j REJECT`
- enable connection:

   `sudo iptables -D OUTPUT -p tcp -d 20.203.166.66 -j REJECT`
- viewing logs:

   `journalctl --unit=openvpn-client@dmp.service -f --no-pager -o short-iso-precise --utc --since "$(date -d "$(systemctl show -p ActiveEnterTimestamp openvpn-client@dmp.service | cut -d'=' -f2)" +'%Y-%m-%d %H:%M:%S')"`

- parsing logs:

   `docker logs -t -f devconn_connector | sh watchcat_devconn_connector.sh`

## Install
- clone this repo to ~/watchcat
- put all files inside `services` folder to `~/.config/systemd/user/`

```
systemctl --user daemon-reload
systemctl --user enable watchcat_devconn_connector.service
systemctl --user enable watchcat_openvpn_dmp.service
systemctl --user enable watchcat.timer
```
