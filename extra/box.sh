#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Utility functions.

_off() {
  echo 'Powering off...'
  sleep 1
  systemctl poweroff
}

_reboot() {
  echo 'Rebooting...'
  sleep 1
  systemctl reboot
}

_wipe() {
  echo 'Wiping...'
  boot_device_partition_table_uuid=$(
    lsblk --output mountpoint,ptuuid \
      | awk '$1 == "/boot" { print $2 }' \
      | head --lines 1
  )
  target_device=$(
    lsblk --output ptuuid,fstype,path \
      | grep "^${boot_device_partition_table_uuid}" \
      | awk '$2 == "crypto_LUKS" { print $3 }' \
      | head --lines 1
  )
  if [ -z "${target_device}" ]; then
    echo "Couldn't determine which device to destroy."
    echo 'Operation cancelled.'
    exit 1
  fi
  echo
  echo 'This will PERMANENTLY DESTROY ALL DATA on this machine.'
  echo
  sudo cryptsetup --verbose erase "${target_device}"
  echo
  echo 'Done.'
  sleep 1
}

# Command functions.

audit() {
  echo 'Auditing the system with Lynis...'
  sudo lynis audit system
}

battery() {
  discharging_power=0
  for battery in {0..1}; do
    battery_power_file="/sys/class/power_supply/BAT${battery}/power_now"
    if [[ -f ${battery_power_file} ]]; then
      battery_status_file="/sys/class/power_supply/BAT${battery}/status"
      battery_status=$(<"${battery_status_file}")
      if [[ ${battery_status} = 'Discharging' ]]; then
        discharging_power_in_microwatts=$(<"${battery_power_file}")
        discharging_power=$(
          echo "scale=1; ${discharging_power_in_microwatts} / 10^6" \
            | bc
        )
        echo "Battery ${battery}: Discharging at ${discharging_power}W"
        break
      fi
    fi
  done
  if [[ ${discharging_power} = 0 ]]; then
    echo 'Currently on mains power.'
  fi
  echo
  acpi
  echo
  for battery in {0..1}; do
    directory="/sys/class/power_supply/BAT${battery}"
    if [[ -d ${directory} ]]; then
      start_threshold=$(<"${directory}"/charge_start_threshold)
      stop_threshold=$(<"${directory}"/charge_stop_threshold)
      charging_output="Battery ${battery}: "
      charging_output+="Charging starts below ${start_threshold}%, "
      charging_output+="stops at ${stop_threshold}%"
      echo "${charging_output}"
    fi
  done
}

destroy() {
  _wipe
  echo
  _off
}

ip() {
  curl \
    --silent \
    'https://duckduckgo.com/?q=my%20ip&format=json&pretty=true' \
    | grep '"Answer" :' \
    | sed -e 's/<[^>]*>//g' \
    | sed -e 's/^\s*"Answer" : "Your IP address is //' \
    | sed -e 's/\sin\s/\n/' \
    | sed -e 's/\",$//'
}

keyboard() {
  case "$1" in
    -h | --help)
      keyboard_help
      ;;
    custom)
      sudo systemctl enable keyd
      sudo systemctl start keyd
      echo
      echo 'Keys are mapped so that:'
      echo '* holding the CapsLock key produces Control,'
      echo '* tapping the CapsLock key produces Escape, and'
      echo '* the Escape key produces CapsLock.'
      ;;
    default)
      sudo systemctl stop keyd
      sudo systemctl disable keyd
      echo
      echo 'All keys have their default behaviour.'
      ;;
    *)
      keyboard_catchall "$1"
      ;;
  esac
}

keyboard_catchall() {
  if [ "$1" = '' ]; then
    echo 'An argument is required.'
  else
    echo "\"$1\" is not a recognised argument."
  fi
  echo
  echo 'Here is the relevant help...'
  echo
  echo
  keyboard_help
  exit 1
}

keyboard_help() {
  echo 'usage: box keyboard <arg>'
  echo
  echo 'Control key mapping.'
  echo
  echo 'Arguments:'
  echo
  echo '  -h|--help  Show this help.'
  echo '  custom     Map keys so that:'
  echo '             * holding the CapsLock key produces Control,'
  echo '             * tapping the CapsLock key produces Escape, and'
  echo '             * the Escape key produces CapsLock.'
  echo '  default    Ensure all keys have their default behaviour.'
}

mac() {
  active_network_device=$(command ip route show default | awk '{ print $5 }')
  if [[ -z ${active_network_device} ]]; then
    echo 'No connection.'
    exit 1
  fi
  active_network_name=$(
    nmcli --get-values device,name connection show --active \
      | grep "${active_network_device}:" \
      | cut --delimiter ':' --fields 2
  )
  active_network_device_details=$(
    command ip link show "${active_network_device}" | tail --lines 1
  )
  mac_address=$(echo "${active_network_device_details}" | awk '{ print $2 }')
  permanent_mac_address=$(
    echo "${active_network_device_details}" \
      | awk '$5 == "permaddr" { print $6 }'
  )
  if [[ -n ${permanent_mac_address} ]]; then
    echo "${mac_address} (spoofed)"
    echo "${permanent_mac_address} (permanent)"
  else
    echo "${mac_address} (permanent)"
  fi
  echo
  echo "${active_network_name} (device: ${active_network_device})"
}

main_catchall() {
  if [ "$1" = '' ]; then
    echo 'A command is required.'
  else
    echo "\"$1\" is not a recognised command."
  fi
  echo
  echo 'Here is the relevant help...'
  echo
  echo
  main_help
  exit 1
}

main_help() {
  echo 'usage: box <command> <arg>'
  echo
  echo 'Manage a basic-box machine.'
  echo
  echo 'Commands:'
  echo
  echo '  -h|--help  Show this help.'
  echo '  audit      Audit system with Lynis.'
  echo '  battery    Show battery information.'
  echo '  destroy    Destroy all data on this machine.'
  echo '  ip         Show public IP address.'
  echo '  keyboard   Control key mapping.'
  echo '  mac        Show MAC address of active network device.'
  echo '  off        Power off.'
  echo '  reboot     Reboot.'
  echo '  reinstall  Destroy all data on this machine then reboot.'
  echo '  scan       Scan for malware or rootkits.'
  echo '  sync       Start Syncthing.'
  echo '  upgrade    Upgrade firmware and software packages.'
  echo '  wifi       Show wifi access points.'
}

off() {
  _off
}

reboot() {
  _reboot
}

reinstall() {
  echo 'Logging out of Mullvad VPN...'
  echo
  mullvad account logout
  echo
  _wipe
  echo
  echo 'Preparing to reboot...'
  echo
  echo 'Insert the USB installer.'
  echo
  echo 'Once the installer is inserted the machine is ready to reboot.'
  echo
  echo 'When it reboots, enter the boot menu by pressing F12 and then select'
  echo 'the installer.'
  echo
  read -n 1 -p 'Press any key to reboot.' -r -s
  echo
  echo
  _reboot
}

scan() {
  scan_for_malware() {
    echo "Scanning ${1} with ClamAV..."
    clamscan \
      --alert-exceeds-max=yes \
      --infected \
      --max-filesize=4000M \
      --max-scansize=4000M \
      --max-scantime=0 \
      --recursive=yes \
      "${1}"
  }
  case "${1-}" in
    -h | --help)
      scan_help
      ;;
    malware)
      case "${2-}" in
        -h | --help)
          scan_for_malware_help
          ;;
        downloads)
          scan_for_malware "${HOME}/Downloads"
          ;;
        home)
          scan_for_malware "${HOME}"
          ;;
        root)
          scan_for_malware /
          ;;
        '')
          echo 'An argument is required.'
          echo
          echo 'Here is the relevant help...'
          echo
          echo
          scan_for_malware_help
          exit 1
          ;;
        *)
          if [[ ${2} == /* ]]; then
            scan_for_malware "${2}"
          else
            scan_for_malware "${PWD}/${2}"
          fi
          ;;
      esac
      ;;
    rootkits)
      echo 'Scanning the system with Rootkit Hunter...'
      echo
      sudo rkhunter \
        --check \
        --quiet \
        --report-warnings-only \
        --skip-keypress \
        --summary
      ;;
    *)
      scan_catchall "${1-}"
      ;;
  esac
}

scan_catchall() {
  if [[ ${1} = '' ]]; then
    echo 'An argument is required.'
  else
    echo "\"${1}\" is not a recognised argument."
  fi
  echo
  echo 'Here is the relevant help...'
  echo
  echo
  scan_help
  exit 1
}

scan_for_malware_help() {
  echo 'usage: box scan malware <arg>'
  echo
  echo 'Scan for malware with ClamAV.'
  echo
  echo 'Arguments:'
  echo
  echo '  -h|--help  Show this help.'
  # shellcheck disable=2016
  echo '  downloads  Scan the $HOME/Downloads directory'
  # shellcheck disable=2016
  echo '  home       Scan the $HOME directory'
  echo '  root       Scan the / directory'
  echo '  <path>     Scan <path>, which can be an absolute or relative path'
}

scan_help() {
  echo 'usage: box scan <arg>'
  echo
  echo 'Scan for malware or rootkits.'
  echo
  echo 'Arguments:'
  echo
  echo '  -h|--help  Show this help.'
  echo '  malware    Scan for Malware with ClamAV'
  echo '  rootkits   Scan for rootkits with Rootkit Hunter'
}

sync() {
  manage_syncthing() {
    sudo ufw allow syncthing
    mullvad-exclude syncthing
    # Execution will block here while Syncthing is running, then the
    # following command will run after Syncthing is shut down.
    sudo ufw delete allow syncthing
  }
  # Ensure the user is authenticated for sudo before the manage_syncthing
  # function is backgrounded.
  sudo -v
  echo 'Starting Syncthing...'
  manage_syncthing &>/dev/null &
}

upgrade() {
  echo 'Upgrading Debian packages...'
  echo
  sudo apt --quiet --quiet update
  echo
  apt --upgradable list
  echo
  sudo apt --quiet --quiet --yes upgrade
  echo
  echo 'Upgrading Python packages...'
  echo
  pipx upgrade-all
  echo
  echo 'Upgrading firmware...'
  echo
  fwupdmgr --force refresh
  fwupdmgr upgrade
}

wifi() {
  nmcli dev wifi rescan
  nmcli dev wifi list
}

# Command selector.

echo
case "${1-}" in
  -h | --help)
    main_help
    ;;
  audit)
    audit
    ;;
  battery)
    battery
    ;;
  destroy)
    destroy
    ;;
  ip)
    ip
    ;;
  keyboard)
    keyboard "${2-}"
    ;;
  mac)
    mac
    ;;
  off)
    off
    ;;
  reboot)
    reboot
    ;;
  reinstall)
    reinstall
    ;;
  scan)
    scan "${@:2}"
    ;;
  sync)
    sync
    ;;
  upgrade)
    upgrade
    ;;
  wifi)
    wifi
    ;;
  *)
    main_catchall "${1-}"
    ;;
esac
