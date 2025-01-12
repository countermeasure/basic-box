#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Install the Mullvad VPN. This task has to wait until the first boot because
# it installs into the /opt directory, which doesn't seem to be allowed in the
# postinst script.
apt install --yes /usr/local/simple-cdd/mullvad_vpn.deb
mullvad auto-connect set on
mullvad dns set default \
  --block-ads \
  --block-adult-content \
  --block-gambling \
  --block-malware \
  --block-trackers
mullvad lockdown-mode set on

# Enable the check_vpn systemd service. This task needs to occur after the
# Mullvad VPN is installed and set up, or the user will see a spurious warning
# when the machine boots for the very first time.
user=$(ls /home)
runuser \
  --login \
  "${user}" \
  --command \
  'XDG_RUNTIME_DIR=/run/user/1000 dbus-launch systemctl --user enable check_vpn.service'
runuser \
  --login \
  "${user}" \
  --command \
  'XDG_RUNTIME_DIR=/run/user/1000 dbus-launch systemctl --user start check_vpn.service'

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

# Enable PaperWM. TODO: Explain why that needs to happen here.
runuser \
  --login \
  "${user}" \
  --command \
  'XDG_RUNTIME_DIR=/run/user/1000 dbus-launch gnome-extensions enable paperwm@paperwm.github.com'

# TODO: Shorten the next lines.
# gnome_terminal_winprops="['{\"wm_class\":\"gnome-terminal-server\",\"preferredWidth\":\"50%\",\"title\":\"Terminal\"}']"
# runuser \
#   --login \
#   "${user}" \
#   --command \
#   "XDG_RUNTIME_DIR=/run/user/1000 dbus-launch gsettings set org.gnome.shell.extensions.paperwm winprops \"${gnome_terminal_winprops}\""

# Remove the first_boot infrastructure now that its work is done.
systemctl disable first_boot.service
rm /etc/systemd/system/first_boot.service
rm /home/"${user}"/.local/bin/first_boot
rm /usr/local/simple-cdd/mullvad_vpn.deb
