#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail


audit () {
    echo "Auditing the system with Lynis..."
    sudo lynis audit system
}


battery () {
    acpi
}


destroy () {
    boot_device=$(
        lsblk --list --paths |
        awk '$7 == "/boot" { print $1 }' |
        head --lines 1
    )
    target_device=$(
        lsblk --fs --list --paths |
        grep "${boot_device%?}" |
        awk '$2 == "crypto_LUKS" { print $1 }' |
        head --lines 1
    )
    if [ -z "${target_device}" ]; then
        echo "Couldn't determine which device to destroy."
        echo 'Operation cancelled.'
        exit 1
    fi
    echo 'This will PERMANENTLY DESTROY ALL DATA on this machine.'
    echo
    sudo cryptsetup --verbose erase $target_device
    echo
    echo 'Done.'
    sleep 1
    echo
    echo 'Powering off...'
    sleep 1
    systemctl poweroff
}


ip () {
    curl \
        --silent \
        'https://duckduckgo.com/?q=my%20ip&format=json&pretty=true' \
        | grep '"Answer" :' \
        | sed -e 's/<[^>]*>//g' \
        | sed -e 's/^\s*"Answer" : "Your IP address is //' \
        | sed -e 's/\sin\s/\n/' \
        | sed -e 's/\",$//'
}


keyboard () {
    case "$1" in
        -h|--help)
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


keyboard_catchall () {
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


keyboard_help () {
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


main_catchall () {
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


main_help () {
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
    echo '  off        Power off.'
    echo '  reboot     Reboot.'
    echo '  sync       Start Syncthing.'
    echo '  upgrade    Upgrade firmware and software packages.'
}


off () {
    echo 'Powering off...'
    sleep 1
    systemctl poweroff
}


reboot () {
    echo 'Rebooting...'
    sleep 1
    systemctl reboot
}


sync () {
    manage_syncthing () {
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
    manage_syncthing &> /dev/null &
}


upgrade () {
    echo "Upgrading Debian packages..."
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


echo
case "${1-}" in
    -h|--help)
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
    off)
        off
        ;;
    reboot)
        reboot
        ;;
    sync)
        sync
        ;;
    upgrade)
        upgrade
        ;;
    *)
        main_catchall "${1-}"
        ;;
esac
