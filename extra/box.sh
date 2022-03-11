#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail


destroy () {
    boot_device_name=$(
        lsblk --list | grep /boot$ | awk '{print $1}' | head --lines 1
    )
    if [ "$boot_device_name" = 'nvme0n1p2' ]; then
        target_device='/dev/nvme0n1p3'
    elif [ "$boot_device_name" = 'sda1' ]; then
        target_device='/dev/sda5'
    else
        echo 'Boot device could not be determined.'
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
    echo '  destroy    Destroy all data on this machine.'
    echo '  keyboard   Control key mapping.'
    echo '  off        Power off.'
}


off () {
    echo 'Powering off...'
    sleep 1
    systemctl poweroff
}

echo
case "${1-}" in
    -h|--help)
        main_help
        ;;
    destroy)
        destroy
        ;;
    keyboard)
        keyboard "${2-}"
        ;;
    off)
        off
        ;;
    *)
        main_catchall "${1-}"
        ;;
esac
