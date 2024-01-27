#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Initialise the last alert tracker.
epoch_time_of_last_alert=0

while true; do

  # Wait for 5 seconds before beginning and between checks.
  sleep 5

  # Skip the remaining commands if there has been an alert in the last minute.
  current_epoch_time=$(date +%s)
  time_since_last_alert=$((current_epoch_time - epoch_time_of_last_alert))
  if [[ time_since_last_alert -lt 60 ]]; then
    continue
  fi

  # Skip the remaining commands if a VPN is managing traffic.
  if [[ -n $(nmcli connection show --active | rg 'vpn|wireguard') ]]; then
    continue
  fi

  # Skip the remaining commands if the Mullvad VPN is blocking traffic.
  mullvad_blocking_message='Block traffic when the VPN is disconnected: on'
  if [[ $(mullvad lockdown-mode get) == "${mullvad_blocking_message}" ]]; then
    continue
  fi

  # No VPN is managing traffic so show an alert.
  notify-send \
    'There is no VPN managing traffic' \
    'Activate a VPN as soon as possible.' \
    --icon /usr/share/icons/Adwaita/scalable/status/dialog-warning-symbolic.svg

  # Update the last alert tracker.
  epoch_time_of_last_alert=${current_epoch_time}

done
