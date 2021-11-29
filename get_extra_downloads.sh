#!/bin/sh

# Ensure the extra downloads directory exists and switch into it.
mkdir -p extra/downloads
cd extra/downloads || exit 1

# Ensure the Mullvad VPN app package is present.
wget --timestamping https://mullvad.net/media/app/MullvadVPN-2021.4_amd64.deb

# Ensure the fd package is present.
wget --timestamping "https://github.com/sharkdp/fd/releases/download/v8.2.1/\
fd_8.2.1_amd64.deb"

# Ensure the ripgrep package is present.
wget --timestamping "https://github.com/BurntSushi/ripgrep/releases/download/\
13.0.0/ripgrep_13.0.0_amd64.deb"

# Ensure the exa package is present.
wget --timestamping "https://github.com/ogham/exa/releases/download/v0.10.1/\
exa-linux-x86_64-v0.10.1.zip"

# Ensure the bat package is present.
wget --timestamping "https://github.com/sharkdp/bat/releases/download/v0.18.3/\
bat_0.18.3_amd64.deb"
