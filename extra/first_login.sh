#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# TODO: Explain why extensions have to be enabled here.
gnome-extensions enable paperwm@paperwm.github.com
cp \
  "${HOME}/.local/share/gnome-shell/extensions/paperwm@paperwm.github.com/config/user.js" \
  "${HOME}/.config/paperwm/user.js"
paperwm_keybindings_setting='org.gnome.shell.extensions.paperwm.keybindings'
paperwm_schemadir="${HOME}/.local/share/gnome-shell/extensions/\
paperwm@paperwm.github.com/schemas"
# Remove the <Super>Return keybinding from new-window so that it doesn't
# conflict with the Terminal launch keybinding.
gsettings --schemadir "${paperwm_schemadir}" set \
  ${paperwm_keybindings_setting} new-window "['<Super>n']"
gnome_terminal_winprops="['{\"wm_class\":\"gnome-terminal-server\",\
\"preferredWidth\":\"50%\",\
\"title\":\"Terminal\"}']"
gsettings --schemadir "${paperwm_schemadir}" set \
  org.gnome.shell.extensions.paperwm winprops "${gnome_terminal_winprops}"
gsettings --schemadir "${paperwm_schemadir}" set \
  ${paperwm_keybindings_setting} switch-left "['<Super>Left', '<Super>h']"
gsettings --schemadir "${paperwm_schemadir}" set \
  ${paperwm_keybindings_setting} switch-right "['<Super>Right', '<Super>l']"

# Print a welcome.
echo
echo 'Welcome to your new Basic Box'
echo '-----------------------------'
echo
echo 'The final configuration steps have to be done interactively.'
echo
echo 'Step 1: Set up an additional encrypted disk'
echo 'Step 2: Enable the Mullvad VPN'
echo 'Step 3: Change some KeePassXC settings'
echo 'Step 4: Run the Basic Box tests'
echo
read -n 1 -p 'Press any key to continue...' -r -s

# Set up an additional encrypted disk.
clear
echo
echo 'Step 1 of 4: Set up an additional encrypted disk'
echo '------------------------------------------------'
echo
boot_device_partition_table_uuid=$(
  lsblk --output mountpoint,ptuuid \
    | awk '$1 == "/boot" { print $2 }' \
    | head --lines 1
)
boot_disk=$(
  lsblk --output ptuuid,type,path \
    | grep "^${boot_device_partition_table_uuid}" \
    | awk '$2 == "disk" { print $3 }'
)
non_boot_disks=$(
  lsblk --output path,type \
    | grep --invert-match "^${boot_disk}" \
    | awk '$2 == "disk" { print $1 }'
)
non_boot_encrypted_disks=$(
  for disk in ${non_boot_disks}; do
    if sudo cryptsetup isLuks "${disk}"; then
      echo "${disk}"
    fi
  done
)
non_boot_encrypted_disks_count=$(
  if [[ -z ${non_boot_encrypted_disks} ]]; then
    echo 0
  else
    echo "${non_boot_encrypted_disks}" | wc --lines
  fi
)
if [[ ${non_boot_encrypted_disks_count} = 0 ]]; then
  echo 'No additional encrypted disk was found.'
  echo
  echo 'There is nothing to do at this step.'
elif [[ ${non_boot_encrypted_disks_count} = 1 ]]; then
  disk="${non_boot_encrypted_disks}"
  disk_description=$(
    lsblk --output path,size,model \
      | grep "^${disk} " \
      | awk '{$1=""; print substr($0,2)}'
  )
  echo "The additional encrypted ${disk_description} disk was found."
  echo
  echo 'A new keyfile will be created and added to keyslot 31 for this disk.'
  echo
  echo 'If there is an existing key at keyslot 31, it will be removed first.'
  echo
  sudo -v
  echo
  keyfile="/root/luks_keyfile"
  head --bytes 256 /dev/random | sudo tee "${keyfile}" >/dev/null
  sudo chmod 400 "${keyfile}"
  echo 'Removing the old key at keyslot 31, if one exists...'
  echo
  sudo cryptsetup luksKillSlot "${disk}" 31 || true
  echo
  echo 'Adding a new keyfile to keyslot 31...'
  echo
  sudo cryptsetup luksAddKey --new-key-slot 31 "${disk}" "${keyfile}"
  device_name='data'
  disk_uuid=$(sudo cryptsetup luksUUID "${disk}")
  crypttab_entry="${device_name} UUID=${disk_uuid} ${keyfile} luks"
  entry_label='# Additional encrypted disk.'
  echo "${entry_label}" | sudo tee --append /etc/crypttab >/dev/null
  echo "${crypttab_entry}" | sudo tee --append /etc/crypttab >/dev/null
  mount_point="/mnt/${device_name}"
  sudo mkdir "${mount_point}"
  home_data_directory="${HOME}/Data"
  ln --symbolic "${mount_point}" "${home_data_directory}"
  device_path="/dev/mapper/${device_name}"
  fstab_entry="${device_path} ${mount_point} ext4 defaults 0 2"
  echo "${entry_label}" | sudo tee --append /etc/fstab >/dev/null
  echo "${fstab_entry}" | sudo tee --append /etc/fstab >/dev/null
  # Reload the systemd manager configuration after fstab is modified to stop a
  # warning being shown when the mount operation is run.
  sudo systemctl daemon-reload
  sudo cryptsetup open --key-file="${keyfile}" "${disk}" "${device_name}"
  sudo mount "${device_path}" "${mount_point}"
  # The chown operation must come after the mount operation, because if it
  # comes before, the mount operation will return ownership of the mount
  # point to root.
  sudo chown "${USER}":"${USER}" "${mount_point}"
  echo
  echo "The ${disk} disk is now available at ${home_data_directory}."
elif [[ ${non_boot_encrypted_disks_count} -gt 1 ]]; then
  echo 'More than one encrypted disk was found.'
  echo
  echo "This step can't automatically configure more than one encrypted"
  echo 'disk, so you will need to manage them manually.'
  echo
  echo "There is nothing to do at this step."
fi
echo
read -n 1 -p 'Press any key to continue...' -r -s

# Enable and configure the Mullvad VPN.
clear
echo
echo 'Step 2 of 4: Enable the Mullvad VPN'
echo '-----------------------------------'
echo
exit_code=''
while [[ ${exit_code} != 0 ]]; do
  printf 'Enter your Mullvad account number to enable the VPN: '
  read -r account_number
  echo
  echo "${account_number}" | mullvad account login
  echo
  mullvad account get && exit_code=$? || exit_code=$?
  echo
  if [[ ${exit_code} != 0 ]]; then
    echo "That account number didn't work."
    echo 'Try again.'
    echo
  fi
done
mullvad connect
echo
read -n 1 -p 'Press any key to continue...' -r -s

# Change KeePassXC settings.
clear
echo
echo 'Step 3 of 4: Change some KeePassXC settings'
echo '-------------------------------------------'
echo
echo "Some of KeePassXC's settings can't be set with its configuration file,"
echo 'so they must be set manually.'
echo
echo 'This step involves 2 small operations.'
echo
echo 'Operation 1: Enable Firefox integration'
echo 'Operation 2: Set clipboard clearing timeout'
echo
read -n 1 -p 'Press any key to continue...' -r -s
clear
echo
echo 'Step 3 of 4: Change some KeePassXC settings'
echo '-------------------------------------------'
echo
echo 'Operation 1 of 2: Enable Firefox integration'
echo
echo 'This will open KeePassXC.'
echo
echo 'Click Tools, click Settings, click the Browser Integration button, check'
echo 'the Firefox checkbox in the "Enable integration for these browsers" box,'
echo 'click the OK button, then close KeePassXC.'
echo
read -n 1 -p 'Press any key to continue...' -r -s
keepassxc 2>/dev/null
clear
echo
echo 'Step 3 of 4: Change some KeePassXC settings'
echo '-------------------------------------------'
echo
echo 'Operation 2 of 2: Set clipboard clearing timeout'
echo
echo 'This will open KeePassXC.'
echo
echo 'Click Tools, click Settings, click the Security button, set "Clear'
echo 'clipboard after" to 30 seconds, click the OK button, then close'
echo 'KeePassXC.'
echo
read -n 1 -p 'Press any key to continue...' -r -s
keepassxc 2>/dev/null

# Run tests.
clear
echo
echo 'Step 4 of 4: Run the Basic Box tests'
echo '------------------------------------'
echo
echo 'Now the test suite needs to run to verify the installation.'
echo
echo 'This is the last configuration step you need to carry out.'
echo
read -n 1 -p 'Press any key to run the test suite...' -r -s
echo
box test
echo
read -n 1 -p 'Press any key to continue...' -r -s

# Print a farewell.
clear
echo
echo 'Configuration complete'
echo '----------------------'
echo
echo "Basic Box configuration is all done, and now it's ready for use."
echo
echo "If you'd like to set it up with your personal data, the steps you need"
echo 'to take are in the ~/setup.rst file.'
echo

read -n 1 -p 'Press any key to close this terminal...' -r -s

# Remove the first_login infrastructure now that its work is done.
rm "${HOME}"/.config/autostart/first_login.desktop
rm "${HOME}"/.local/bin/first_login
