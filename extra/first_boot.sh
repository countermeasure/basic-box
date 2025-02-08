#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

user=$(ls /home)

run_as_ordinary_user() {
  # Run a command as the ordinary user with dbus-launch.
  runuser --login "${user}" --command "dbus-launch $1"
}

# Configure the Mullvad VPN. This task has to wait until the first boot because
# it doesn't seem to work in the postinst script.
run_as_ordinary_user 'mullvad auto-connect set on'
run_as_ordinary_user "mullvad dns set default \
--block-ads \
--block-adult-content \
--block-gambling \
--block-malware \
--block-trackers"
run_as_ordinary_user 'mullvad lockdown-mode set on'

# Enable the UFW firewall.
ufw enable

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
rm /home/"${user}"/.local/bin/first_boot
