#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Utility functions.

readonly ansi_clear='\033[0m'
readonly ansi_green='\033[1;32m'
readonly ansi_red='\033[1;31m'

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

_test_alternative() {
  if update-alternatives --display "$1" | grep --extended-regexp --quiet "$2 - priority $3"; then
    echo -e "${ansi_green}🗸 ${ansi_clear}Alternative ${1} is $2 priority $3"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}Alternative ${1} is not $2 priority $3"
  fi
}

_test_command_output() {
  output=$($1)
  if [[ ${output} == "$2" ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}The result of '${1}' was as expected"
  else
    echo -e \
      "${ansi_red}✗ ${ansi_clear}The result of '${1}' was not as expected"
  fi
}

_test_directory_exists() {
  if [[ -d $1 ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}Directory ${1} exists"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}Directory ${1} does not exist"
  fi
}

_test_executable_exists() {
  if [[ $(echo "$1" | rev | cut -d / -f 1 | rev | xargs which) == "$1" ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}${1} is an executable"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}${1} is not an executable"
  fi
}

_test_file_exists() {
  if [[ -f $1 ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}File ${1} exists"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}File ${1} does not exist"
  fi
}

_test_git_config() {
  if [[ $(git config --get "$1") == "$2" ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}Git setting ${1} is ${2}"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}Git setting ${1} is not ${2}"
  fi
}

_test_gsettings() {
  if [[ $(gsettings get org."$1" "$2") == "$3" ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}GNOME setting org.${1} ${2} is ${3}"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}GNOME setting org.${1} ${2} is not ${3}"
  fi
}

_test_gsettings_with_schemadir() {
  if [[ $(gsettings --schemadir "$1" get org."$2" "$3") == "$4" ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}GNOME setting org.${2} ${3} is ${4}"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}GNOME setting org.${2} ${3} is not ${4}"
  fi
}

_test_line_in_file() {
  if grep --fixed-strings --quiet "$1" "$2"; then
    echo -e "${ansi_green}🗸 ${ansi_clear}${2} contains '${1}'"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}${2} does not contain '${1}'"
  fi
}

_test_man_page_exists() {
  if man "$1" &>/dev/null; then
    echo -e "${ansi_green}🗸 ${ansi_clear}The man page for ${1} exists"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}The man page for ${1} does not exist"
  fi
}

_test_package_is_installed() {
  if [[ -n $(apt list --installed --quiet --quiet "$1" 2>/dev/null) ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}${1} package is installed"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}${1} package is not installed"
  fi
}

_test_package_is_not_installed() {
  if [[ -z $(apt list --installed --quiet --quiet "$1" 2>/dev/null) ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}${1} package is not installed"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}${1} package is installed"
  fi
}

_test_python_package_is_installed() {
  if pipx list | grep --extended-regexp --quiet "package $1 .+ installed"; then
    echo -e "${ansi_green}🗸 ${ansi_clear}${1} Python package is installed"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}${1} Python package is not installed"
  fi
}

_test_symlink_exists() {
  if [[ -L $1 ]]; then
    echo -e "${ansi_green}🗸 ${ansi_clear}${1} symlink exists"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}${1} symlink does not exist"
  fi
}

_test_systemd_service_is_active() {
  if systemctl status "$1" | grep --quiet 'Active: active (running)'; then
    echo -e "${ansi_green}🗸 ${ansi_clear}Systemd ${1} service is active"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}Systemd ${1} service is not active"
  fi
}

_test_systemd_user_service_is_active() {
  if systemctl status --user "$1" | grep --quiet 'Active: active (running)'; then
    echo -e "${ansi_green}🗸 ${ansi_clear}Systemd ${1} user service is active"
  else
    echo -e "${ansi_red}✗ ${ansi_clear}Systemd ${1} user service is not active"
  fi
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
  if [[ -n "$1" ]]; then
    case "$1" in
      -h | --help)
        battery_help
        ;;
      fill)
        for battery in {0..1}; do
          directory="/sys/class/power_supply/BAT${battery}"
          if [[ -d ${directory} ]]; then
            sudo tlp fullcharge "BAT${battery}"
          fi
        done
        ;;
      reset)
        for battery in {0..1}; do
          directory="/sys/class/power_supply/BAT${battery}"
          if [[ -d ${directory} ]]; then
            sudo tlp setcharge "BAT${battery}"
          fi
        done
        ;;
      *)
        battery_catchall "$1"
        ;;
    esac
  else
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
  fi
}

battery_catchall() {
  echo "\"$1\" is not a recognised argument."
  echo
  echo 'Here is the relevant help...'
  echo
  echo
  battery_help
  exit 1
}

battery_help() {
  echo 'usage: box battery'
  echo
  echo 'Show battery information.'
  echo
  echo 'usage: box battery <arg>'
  echo
  echo 'Control batteries.'
  echo
  echo 'Arguments:'
  echo
  echo '  -h|--help  Show this help.'
  echo '  fill       Charge batteries to full capacity.'
  echo '  reset      Reset charge thresholds to usual values.'
}

destroy() {
  _wipe
  echo
  _off
}

firewall() {
  sudo ufw status verbose
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
      echo '* holding the Backslash key produces Meta,'
      echo '* holding the CapsLock key produces Control,'
      echo '* tapping the CapsLock key produces Escape,'
      echo '* the Escape key produces CapsLock, and'
      echo '* holding the Tab key produces Meta.'
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
  echo '  battery    Show battery information and control batteries.'
  echo '  destroy    Destroy all data on this machine.'
  echo '  firewall   Show firewall information.'
  echo '  ip         Show public IP address.'
  echo '  keyboard   Control key mapping.'
  echo '  mac        Show MAC address of active network device.'
  echo '  off        Power off.'
  echo '  reboot     Reboot.'
  echo '  reinstall  Destroy all data on this machine then reboot.'
  echo '  scan       Scan for malware or rootkits.'
  echo '  sync       Start Syncthing.'
  echo '  test       Test the installation is functioning correctly.'
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

test() {
  # Tests arising from basic.postinst.
  _test_package_is_installed build-essential
  _test_package_is_installed dbus-x11
  _test_file_exists /etc/apt/trusted.gpg.d/shells_fish.gpg
  _test_file_exists /etc/apt/sources.list.d/fish.list
  _test_package_is_installed fish
  username=$(ls /home)
  user_dir=/home/${username}
  user_config_dir=${user_dir}/.config
  fish_config_dir="${user_config_dir}"/fish
  _test_file_exists "${fish_config_dir}"/config.fish
  _test_file_exists "${fish_config_dir}"/fish_aliases
  _test_file_exists "${fish_config_dir}"/themes/box.theme
  _test_file_exists "${fish_config_dir}"/fish_functions
  _test_directory_exists "${fish_config_dir}"/conf.d
  _test_directory_exists "${fish_config_dir}"/functions
  _test_package_is_installed ufw
  _test_file_exists /usr/share/keyrings/mullvad-keyring.asc
  _test_file_exists /etc/apt/sources.list.d/mullvad.list
  _test_package_is_installed mullvad-vpn
  _test_package_is_installed torbrowser-launcher
  _test_package_is_installed pipx
  _test_package_is_installed python3-pip
  fish_completions_dir=${fish_config_dir}/completions
  _test_file_exists "${fish_completions_dir}"/pipx.fish
  _test_line_in_file \
    '# If the parent process is not fish, launch the fish shell.' \
    "${user_dir}"/.bashrc
  # shellcheck disable=2016
  _test_line_in_file \
    "if [[ \$(ps --no-header --pid=\${PPID} --format=comm) != 'fish' ]]; then" \
    "${user_dir}"/.bashrc
  _test_line_in_file 'exec fish' "${user_dir}"/.bashrc
  _test_file_exists "${user_dir}"/.profile_modifications
  _test_line_in_file '# Enable .profile modifications.' "${user_dir}"/.profile
  # shellcheck disable=2016
  _test_line_in_file \
    '. "${HOME}/.profile_modifications"' "${user_dir}"/.profile
  _test_python_package_is_installed yt-dlp
  _test_man_page_exists yt-dlp
  _test_file_exists "${fish_completions_dir}"/yt-dlp.fish
  _test_package_is_installed ffmpeg
  _test_package_is_installed ranger
  _test_gsettings gnome.desktop.interface color-scheme "'prefer-dark'"
  _test_gsettings gnome.desktop.interface gtk-theme "'Adwaita-dark'"
  _test_gsettings gnome.desktop.interface clock-show-weekday true
  _test_gsettings gnome.desktop.interface show-battery-percentage true
  _test_gsettings gnome.desktop.session idle-delay 'uint32 0'
  _test_gsettings gnome.settings-daemon.plugins.power idle-dim false
  _test_gsettings \
    gnome.settings-daemon.plugins.power sleep-inactive-ac-type "'nothing'"
  _test_gsettings gnome.settings-daemon.plugins.color night-light-enabled true
  _test_gsettings gnome.desktop.peripherals.mouse natural-scroll true
  _test_gsettings gnome.desktop.peripherals.touchpad speed 0.25
  _test_gsettings gnome.desktop.peripherals.touchpad tap-to-click true
  _test_line_in_file 'AutomaticLoginEnable = true' /etc/gdm3/daemon.conf
  _test_line_in_file "AutomaticLogin = ${username}" /etc/gdm3/daemon.conf
  _test_package_is_installed fd-find
  _test_symlink_exists /usr/bin/fd
  _test_package_is_installed ripgrep
  _test_package_is_installed exa
  _test_package_is_installed bat
  _test_symlink_exists /usr/bin/bat
  _test_package_is_installed fzf
  _test_package_is_installed zoxide
  _test_package_is_installed htop
  _test_file_exists "${user_config_dir}"/htop/htoprc
  _test_gsettings gnome.Terminal.Legacy.Settings menu-accelerator-enabled false
  _test_package_is_installed ncdu
  _test_executable_exists /usr/local/bin/delta
  _test_file_exists "${fish_completions_dir}"/delta.fish
  _test_package_is_installed git
  _test_git_config user.name Basic
  _test_git_config user.email basic@basic.box
  _test_git_config branch.sort -committerdate
  _test_git_config log.date 'format:%b %d %Y'
  git_commit_format="%C(yellow)%h %C(white)%<(31)%s %C(dim white)Commit by \
%Creset%C(magenta)%an %C(cyan)%ar %C(dim white)on %ad %C(auto)%d"
  _test_git_config format.pretty "${git_commit_format}"
  _test_git_config pull.rebase true
  _test_git_config push.default current
  _test_git_config rerere.autoupdate true
  _test_git_config rerere.enabled true
  _test_git_config core.pager delta
  _test_git_config delta.navigate true
  _test_git_config diff.colorMoved default
  _test_git_config interactive.diffFilter 'delta --color-only'
  _test_git_config merge.conflictstyle diff3
  _test_git_config delta.line-numbers true
  _test_git_config init.defaultBranch main
  _test_package_is_installed gitk
  _test_file_exists "${user_config_dir}"/git/gitk
  _test_executable_exists /usr/local/bin/keyd
  keyd_dir="${user_config_dir}"/keyd
  _test_file_exists "${keyd_dir}"/default.conf
  _test_symlink_exists /etc/keyd/default.conf
  _test_systemd_service_is_active keyd
  user_bin_dir=${user_dir}/.local/bin
  _test_executable_exists "${user_bin_dir}"/box
  _test_package_is_installed direnv
  _test_file_exists /usr/local/share/fonts/fira_code.ttf
  _test_gsettings \
    gnome.desktop.interface monospace-font-name "'FiraCode Nerd Font 11'"
  _test_executable_exists /usr/local/bin/starship
  _test_file_exists "${fish_completions_dir}"/starship.fish
  _test_file_exists "${user_config_dir}"/starship.toml
  _test_python_package_is_installed httpie
  _test_file_exists "${fish_completions_dir}"/http.fish
  _test_file_exists "${fish_completions_dir}"/https.fish
  _test_line_in_file 'complete -c https' "${fish_completions_dir}"/https.fish
  _test_package_is_installed nmap
  _test_package_is_installed keepassxc
  _test_file_exists "${user_config_dir}"/keepassxc/keepassxc.ini
  _test_file_exists "${user_dir}"/setup.rst
  _test_python_package_is_installed ipython
  _test_python_package_is_installed entomb
  _test_package_is_installed mtr-tiny
  _test_package_is_installed tree
  _test_python_package_is_installed tldr
  _test_package_is_installed offlineimap
  _test_file_exists "${user_config_dir}"/git/ignore
  _test_python_package_is_installed trash-cli
  _test_man_page_exists trash
  _test_man_page_exists trash-empty
  _test_man_page_exists trash-list
  _test_man_page_exists trash-put
  _test_man_page_exists trash-restore
  _test_man_page_exists trash-rm
  _test_file_exists "${user_config_dir}"/ranger/rc.conf
  _test_package_is_not_installed vim-tiny
  nvim_path=/usr/local/bin/nvim
  _test_executable_exists ${nvim_path}
  _test_man_page_exists nvim
  _test_alternative editor ${nvim_path} 50
  _test_alternative ex ${nvim_path} 50
  _test_alternative rview ${nvim_path} 50
  _test_alternative rvim ${nvim_path} 50
  _test_alternative vi ${nvim_path} 50
  _test_alternative view ${nvim_path} 50
  _test_alternative vim ${nvim_path} 50
  _test_alternative vimdiff ${nvim_path} 50
  nvim_config_dir=${user_config_dir}/nvim
  _test_file_exists "${nvim_config_dir}"/init.lua
  _test_file_exists "${nvim_config_dir}"/lazy-lock.json
  _test_file_exists "${nvim_config_dir}"/lua/config/autocmds.lua
  _test_file_exists "${nvim_config_dir}"/lua/config/keymaps.lua
  _test_file_exists "${nvim_config_dir}"/lua/config/lazy.lua
  _test_file_exists "${nvim_config_dir}"/lua/config/options.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/blink.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/colourscheme.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/fzf_lua.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/conform.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/lualine.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/mason.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/neotree.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/nvim_lint.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/ranger.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/treesitter.lua
  _test_file_exists "${nvim_config_dir}"/lua/plugins/which_key.lua
  _test_python_package_is_installed python-lsp-server
  _test_package_is_installed curl
  _test_package_is_installed rfkill
  _test_file_exists "${user_config_dir}"/yt-dlp/config
  _test_package_is_installed atool
  _test_executable_exists /usr/local/bin/bandwhich
  _test_man_page_exists bandwhich
  _test_file_exists "${fish_completions_dir}"/bandwhich.fish
  _test_executable_exists /usr/local/bin/bandwhich
  _test_package_is_installed whois
  _test_file_exists "${user_config_dir}"/ranger/colorschemes/box.py
  _test_package_is_installed smartmontools
  _test_package_is_installed python-is-python3
  _test_package_is_installed zathura
  _test_file_exists "${user_config_dir}"/zathura/zathurarc
  _test_file_exists "${user_config_dir}"/ranger/rifle.conf
  _test_file_exists "${user_config_dir}"/ranger/scope.sh
  _test_package_is_installed acpi
  _test_file_exists /usr/share/keyrings/syncthing-archive-keyring.gpg
  _test_file_exists /etc/apt/sources.list.d/syncthing.list
  _test_package_is_installed syncthing
  sudoers_dir=/etc/sudoers.d
  _test_file_exists ${sudoers_dir}/ufw
  _test_file_exists "${user_dir}"/.ipython/profile_default/ipython_config.py
  _test_file_exists ${sudoers_dir}/apt
  _test_package_is_installed lynis
  _test_file_exists ${sudoers_dir}/lynis
  _test_package_is_installed clamav
  _test_package_is_installed rkhunter
  _test_file_exists ${sudoers_dir}/rkhunter
  _test_executable_exists "${user_dir}"/.pyenv/bin/pyenv
  _test_package_is_installed build-essential
  _test_package_is_installed curl
  _test_package_is_installed libbz2-dev
  _test_package_is_installed libffi-dev
  _test_package_is_installed liblzma-dev
  _test_package_is_installed libncursesw5-dev
  _test_package_is_installed libreadline-dev
  _test_package_is_installed libsqlite3-dev
  _test_package_is_installed libssl-dev
  _test_package_is_installed libxml2-dev
  _test_package_is_installed libxmlsec1-dev
  _test_package_is_installed llvm
  _test_package_is_installed make
  _test_package_is_installed tk-dev
  _test_package_is_installed wget
  _test_package_is_installed xz-utils
  _test_package_is_installed zlib1g-dev
  _test_executable_exists /usr/local/bin/geckodriver
  _test_python_package_is_installed jupyterlab
  jupyterlab_apputils_extension_dir="${user_dir}/.jupyter/lab/user-settings/\
@jupyterlab/apputils-extension"
  _test_file_exists \
    "${jupyterlab_apputils_extension_dir}"/themes.jupyterlab-settings
  jupyterlab_codemiror_extension_dir="${user_dir}/.jupyter/lab/user-settings/\
@jupyterlab/codemirror-extension"
  _test_file_exists \
    "${jupyterlab_codemiror_extension_dir}"/commands.jupyterlab-settings
  _test_file_exists ${sudoers_dir}/powertop
  _test_package_is_installed tlp
  _test_file_exists ${sudoers_dir}/tlp
  _test_file_exists /etc/tlp.d/10-charging-thresholds.conf
  _test_package_is_installed libnotify-bin
  _test_file_exists ${sudoers_dir}/lecture
  _test_file_exists ${sudoers_dir}/cryptsetup
  _test_package_is_installed thunderbird
  _test_file_exists "${user_bin_dir}"/git_wrapper
  _test_package_is_installed wl-clipboard
  _test_package_is_installed podman
  _test_gsettings gnome.desktop.wm.preferences audible-bell false
  _test_gsettings gnome.desktop.wm.preferences visual-bell true
  _test_gsettings gnome.desktop.wm.preferences visual-bell-type "'frame-flash'"
  _test_file_exists /usr/share/firefox-esr/distribution/policies.json
  _test_file_exists /etc/NetworkManager/conf.d/mac_randomisation.conf
  _test_file_exists "${user_bin_dir}"/check_vpn
  _test_file_exists "${user_config_dir}"/systemd/user/check_vpn.service
  _test_systemd_user_service_is_active check_vpn.service
  _test_file_exists "${user_config_dir}"/gnome-initial-setup-done
  _test_gsettings \
    gnome.nautilus.preferences default-folder-viewer "'list-view'"
  _test_gsettings gtk.gtk4.Settings.FileChooser sort-directories-first true
  _test_gsettings gtk.Settings.FileChooser sort-directories-first true
  _test_file_exists /usr/share/keyrings/signal-desktop-keyring.gpg
  _test_file_exists /etc/apt/sources.list.d/signal.list
  _test_package_is_installed signal-desktop
  _test_package_is_installed duf
  _test_package_is_installed mullvad-browser
  _test_package_is_installed dict
  _test_package_is_installed dictd
  _test_package_is_installed dict-wn
  _test_gsettings gnome.shell favorite-apps "[\
'firefox-esr.desktop', \
'mullvad-browser.desktop', \
'torbrowser.desktop', \
'signal-desktop.desktop', \
'thunderbird.desktop', \
'mullvad-vpn.desktop', \
'org.keepassxc.KeePassXC.desktop', \
'org.gnome.clocks.desktop', \
'org.gnome.Maps.desktop', \
'org.gnome.Nautilus.desktop', \
'org.gnome.Terminal.desktop']"
  media_keys_setting='gnome.settings-daemon.plugins.media-keys'
  custom_keybinding_setting="${media_keys_setting}.custom-keybinding"
  custom_keybindings_key_path="/org/gnome/settings-daemon/plugins/media-keys/\
custom-keybindings"
  _test_gsettings ${media_keys_setting} email "['<Super>m']"
  _test_gsettings gnome.shell.keybindings toggle-message-tray '@as []'
  _test_gsettings ${media_keys_setting} www "['<Super>b']"
  custom_keybinding_0="${custom_keybinding_setting}:\
${custom_keybindings_key_path}/custom0/"
  _test_gsettings ${custom_keybinding_0} binding "'<Ctrl><Super>b'"
  _test_gsettings ${custom_keybinding_0} command "'mullvad-browser'"
  _test_gsettings ${custom_keybinding_0} name "'Mullvad Browser'"
  custom_keybinding_1="${custom_keybinding_setting}:\
${custom_keybindings_key_path}/custom1/"
  _test_gsettings ${custom_keybinding_1} binding "'<Super>s'"
  _test_gsettings ${custom_keybinding_1} command "'signal-desktop'"
  _test_gsettings ${custom_keybinding_1} name "'Signal'"
  custom_keybinding_2="${custom_keybinding_setting}:\
${custom_keybindings_key_path}/custom2/"
  _test_gsettings ${custom_keybinding_2} binding "'<Super>Return'"
  _test_gsettings ${custom_keybinding_2} command "'gnome-terminal'"
  _test_gsettings ${custom_keybinding_2} name "'Terminal'"
  custom_keybinding_3="${custom_keybinding_setting}:\
${custom_keybindings_key_path}/custom3/"
  _test_gsettings ${custom_keybinding_3} binding "'<Super>v'"
  _test_gsettings \
    ${custom_keybinding_3} command "'/opt/Mullvad\\\ VPN/mullvad-vpn'"
  _test_gsettings ${custom_keybinding_3} name "'VPN'"
  _test_gsettings gnome.shell enabled-extensions "[\
'bluetooth-quick-connect@bjarosze.gmail.com', \
'dash-to-dock@micxgx.gmail.com', \
'Hide_Activities@shay.shayel.org', \
'noannoyance@daase.net', \
'middleclickclose@paolo.tranquilli.gmail.com', \
'disable-workspace-switcher@jbradaric.me', \
'system-monitor@paradoxxx.zero.gmail.com', \
'ubuntu-appindicators@ubuntu.com', \
'paperwm@paperwm.github.com', \
'space-bar@luchrioh']"
  bluetooth_quick_connect_schemadir="/usr/share/gnome-shell/extensions/\
bluetooth-quick-connect@bjarosze.gmail.com/schemas"
  _test_gsettings_with_schemadir \
    ${bluetooth_quick_connect_schemadir} \
    gnome.shell.extensions.bluetooth-quick-connect \
    bluetooth-auto-power-off true
  _test_gsettings_with_schemadir \
    ${bluetooth_quick_connect_schemadir} \
    gnome.shell.extensions.bluetooth-quick-connect \
    bluetooth-auto-power-on true
  _test_gsettings \
    gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
  _test_gsettings gnome.shell.extensions.dash-to-dock hot-keys false
  _test_gsettings gnome.shell.extensions.dash-to-dock multi-monitor true
  _test_gsettings gnome.shell.extensions.dash-to-dock show-trash false
  _test_gsettings gnome.shell.extensions.system-monitor cpu-style "'digit'"
  _test_gsettings \
    gnome.shell.extensions.system-monitor disk-usage-style "'none'"
  _test_gsettings gnome.shell.extensions.system-monitor icon-display false
  _test_gsettings gnome.shell.extensions.system-monitor memory-style "'digit'"
  _test_gsettings gnome.shell.extensions.system-monitor net-style "'digit'"
  _test_directory_exists "${user_dir}"/.cache/fish/generated_completions
  _test_package_is_not_installed gnome-shell-extension-prefs
  _test_package_is_installed gnome-shell-extension-manager
  _test_gsettings gnome.shell.overrides dynamic-workspaces false
  _test_gsettings gnome.mutter dynamic-workspaces false
  _test_gsettings gnome.desktop.wm.preferences num-workspaces 9
  wm_keybindings_setting='gnome.desktop.wm.keybindings'
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-1 "['<Super>1']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-2 "['<Super>2']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-3 "['<Super>3']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-4 "['<Super>4']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-5 "['<Super>5']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-6 "['<Super>6']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-7 "['<Super>7']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-8 "['<Super>8']"
  _test_gsettings \
    ${wm_keybindings_setting} switch-to-workspace-9 "['<Super>9']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-1 "['<Ctrl><Super>1']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-2 "['<Ctrl><Super>2']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-3 "['<Ctrl><Super>3']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-4 "['<Ctrl><Super>4']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-5 "['<Ctrl><Super>5']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-6 "['<Ctrl><Super>6']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-7 "['<Ctrl><Super>7']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-8 "['<Ctrl><Super>8']"
  _test_gsettings \
    ${wm_keybindings_setting} move-to-workspace-9 "['<Ctrl><Super>9']"
  keybindings_setting='gnome.shell.keybindings'
  _test_gsettings ${keybindings_setting} switch-to-application-1 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-2 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-3 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-4 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-5 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-6 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-7 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-8 '@as []'
  _test_gsettings ${keybindings_setting} switch-to-application-9 '@as []'
  # Tests arising from first_boot.sh
  _test_command_output 'sudo ufw status' 'Status: active'
  _test_command_output 'mullvad auto-connect get' 'Autoconnect: on'
  _test_command_output \
    'mullvad dns get' \
    "Custom DNS: no
Block ads: true
Block trackers: true
Block malware: true
Block adult content: true
Block gambling: true
Block social media: false"
  _test_command_output \
    'mullvad lockdown-mode get' \
    'Block traffic when the VPN is disconnected: on'
  _test_systemd_user_service_is_active check_vpn.service
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
    battery "${2-}"
    ;;
  destroy)
    destroy
    ;;
  firewall)
    firewall
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
  test)
    test
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
