#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Enable the UFW firewall.
ufw enable

# Install the Mullvad VPN. This task has to wait until first boot because
# TODO:...
apt install --yes /usr/local/simple-cdd/mullvad.deb
mullvad lockdown-mode set on
mullvad dns set default \
  --block-ads \
  --block-adult-content \
  --block-gambling \
  --block-malware \
  --block-trackers
rm /usr/local/simple-cdd/mullvad.deb

# Enable the check_vpn systemd service.
# TODO: Explain that this goes here so that it doesn't run before the VPN is
# installed and annoy the user with a spurious warning right when things start
# up for the very first time.
username=$(ls /home)
runuser \
  --login \
  "${username}" \
  --command \
  'XDG_RUNTIME_DIR=/run/user/1000 dbus-launch systemctl --user enable check_vpn.service'

# Run Rootkit Hunter to create a baseline for future scans.
# This task has to wait until the first boot because if it is run any sooner,
# the systemd-coredump user and group are not yet present, then when Rootkit
# Hunter is first run by the user there will be unnecessary warnings about
# them.
# Also, Rootkit Hunter will exit with a non-zero code if it identifies anything
# it regards as suspicious, and false positives are common, so add "|| true" to
# ensure that this script doesn't exit here if that happens.
rkhunter --cronjob --report-warnings-only --summary || true

# Remove the first_boot infrastructure now that its work is done.
systemctl disable first_boot.service
rm /etc/systemd/system/first_boot.service
user=$(ls /home)
rm /home/"${user}"/.local/bin/first_boot
