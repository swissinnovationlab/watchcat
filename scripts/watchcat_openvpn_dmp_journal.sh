#/bin/bash
START_TIMESTAMP="$(date -d "$(systemctl show -p ActiveEnterTimestamp openvpn-client@dmp.service | cut -d'=' -f2)" +'%Y-%m-%d %H:%M:%S')"
journalctl --unit=openvpn-client@dmp.service -f --no-pager -o short-iso-precise --utc --since "$START_TIMESTAMP"
