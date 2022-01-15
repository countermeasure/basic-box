#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Enable the UFW firewall.
ufw enable

# Remove the first_boot infrastructure now that its work is done.
systemctl disable first_boot.service
rm /etc/systemd/system/first_boot.service
