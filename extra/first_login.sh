#!/bin/bash

# Print a welcome.
echo
echo "Welcome to your new Basic Box"
echo "-----------------------------"
echo

# Enable and configure the Mullvad VPN.
EXIT_CODE=""
while [[ $EXIT_CODE != 0 ]] ; do
    printf "Enter your Mullvad account number to enable the VPN: "
    read -r ACCOUNT_NUMBER
    echo
    echo "$ACCOUNT_NUMBER" | mullvad account set
    echo
    mullvad account get
    EXIT_CODE=$?
    echo
    if [[ $EXIT_CODE != 0 ]] ; then
        echo "That account number didn't work."
        echo "Try again."
        echo
    fi
done
mullvad connect
mullvad auto-connect set on
echo
mullvad always-require-vpn set on
echo

# This script should only run at the first login, so remove the desktop entry
# which calls it now that it has done its work.
rm "$HOME"/.config/autostart/first_login.desktop

# Hold the terminal open so that the user can read the output.
read -n 1 -p "Press any key to close this terminal..." -r -s
