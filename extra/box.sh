#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail


destroy () {
    # get list of block devices by type and name, then `awk` that to extract the name of the first type=crypt device by exiting after a match
    crypt_device_name=$(
        lsblk --noheadings --raw --output type,name |
        awk '/^crypt/ {print $2; exit}'
    )
    # now determine the path of the crypt device's parent (which is the partition we want to destroy)
    # -v for `awk` to use the dynamic contents of $pattern to match against `lsblk` list of devices
    # prepend 'part' to the pattern to match type=partition, then use parameter expansion to strip the tailing text '_crypt' from $crypt_device_name
    target_device=$(
        lsblk --noheadings --raw --output type,name,path |
        awk -v pattern="^part ${crypt_device_name%%_crypt*}" '$0 ~ pattern {print $3; exit}'
    )
    # if resulting $target_device is not empty, we have something sensible to destroy
    if [ -n "${target_device}" ]; then
        echo 'This will PERMANENTLY DESTROY ALL DATA on this machine.'
        echo
        sudo cryptsetup --verbose erase "${target_device}"
        echo
        echo 'Done.'
        sleep 1
        echo
        echo 'Powering off...'
        sleep 1
        systemctl poweroff
    else
        echo 'Device to destroy could not be determined.'
        echo 'Operation cancelled.'
        exit 1
    fi
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
    echo '  reboot     Reboot.'
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
    reboot)
        reboot
        ;;
    *)
        main_catchall "${1-}"
        ;;
esac
