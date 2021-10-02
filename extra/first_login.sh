#!/bin/bash

# Print a welcome.
echo
echo "Welcome to your new Basic Box"
echo "-----------------------------"
echo
echo "The final setup steps have to be done interactively."
echo
echo "Step 1: Enable the Mullvad VPN"
echo "Step 2: Install the Firefox browser extensions"
echo
read -n 1 -p "Press any key to continue..." -r -s

# Enable and configure the Mullvad VPN.
clear
echo
echo "Step 1 of 2: Enable the Mullvad VPN"
echo "-----------------------------------"
echo
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
read -n 1 -p "Press any key to continue..." -r -s

# Open Firefox extension installation tabs.
clear
echo
echo "Step 2 of 2: Install the Firefox browser extensions"
echo "---------------------------------------------------"
echo
echo "Installing browser extensions requires user interactions in Firefox."
echo
echo "This step will open these installer pages in tabs in Firefox:"
echo "- Dark Reader"
echo "- Decentraleyes"
echo "- Firefox Multi-Account Containers"
echo "- HTTPS Everywhere"
echo "- NoScript Security Suite"
echo "- Privacy Badger"
echo "- uBlock Origin"
echo
echo "In each tab, you need to click to install the extension."
echo
echo "This is the last configuration step you need to carry out."
echo
echo "When you've finished, close Firefox."
echo
read -n 1 -p "Press any key to continue..." -r -s
firefox \
    https://addons.mozilla.org/en-US/firefox/addon/darkreader/ \
    https://addons.mozilla.org/en-US/firefox/addon/decentraleyes/ \
    https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/ \
    https://addons.mozilla.org/en-US/firefox/addon/https-everywhere/ \
    https://addons.mozilla.org/en-US/firefox/addon/noscript/ \
    https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/ \
    https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/

# Print a farewell.
clear
echo
echo "Setup complete"
echo "--------------"
echo
echo "Basic Box setup is all done."
echo
read -n 1 -p "Press any key to close this terminal..." -r -s

# This script should only run at the first login, so remove the desktop entry
# which calls it now that it has done its work.
rm "$HOME"/.config/autostart/first_login.desktop
