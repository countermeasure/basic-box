#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Ensure the extra downloads directory exists and switch into it.
mkdir -p extra/downloads
cd extra/downloads || exit 1

# Ensure the Mullvad VPN app package is present.
wget --timestamping https://mullvad.net/media/app/MullvadVPN-2021.6_amd64.deb

# Ensure the fd package is present.
wget --timestamping "https://github.com/sharkdp/fd/releases/download/v8.3.2/\
fd_8.3.2_amd64.deb"

# Ensure the ripgrep package is present.
wget --timestamping "https://github.com/BurntSushi/ripgrep/releases/download/\
13.0.0/ripgrep_13.0.0_amd64.deb"

# Ensure the exa package is present.
wget --timestamping "https://github.com/ogham/exa/releases/download/v0.10.1/\
exa-linux-x86_64-v0.10.1.zip"

# Ensure the bat package is present.
wget --timestamping "https://github.com/sharkdp/bat/releases/download/v0.19.0/\
bat_0.19.0_amd64.deb"

# Ensure the fzf package is present.
wget --timestamping "https://github.com/junegunn/fzf/releases/download/0.29.0/\
fzf-0.29.0-linux_amd64.tar.gz"
wget --timestamping "https://github.com/junegunn/fzf/archive/refs/tags/\
0.29.0.tar.gz"
# As the fzf archive doesn't include fzf in its name, make a copy with fzf in
# its name. Simply saving with this different filename will stop wget's
# --timestamping option working.
cp 0.29.0.tar.gz fzf-0.29.0-source.tar.gz

# Ensure the zoxide package is present.
wget --timestamping "https://github.com/ajeetdsouza/zoxide/releases/download/\
v0.8.0/zoxide-v0.8.0-x86_64-unknown-linux-musl.tar.gz"

# Ensure the delta package is present.
# The delta .deb package doesn't contain completions as of version 0.11.3, so
# manual installation is necessary.
wget --timestamping "https://github.com/dandavison/delta/releases/download/\
0.11.3/delta-0.11.3-x86_64-unknown-linux-gnu.tar.gz"
wget --timestamping "https://github.com/dandavison/delta/archive/refs/tags/\
0.11.3.tar.gz"
# As the delta archive doesn't include delta in its name, make a copy with
# delta in its name. Simply saving with this different filename will stop
# wget's --timestamping option working.
cp 0.11.3.tar.gz delta-0.11.3-source.tar.gz

# Ensure the keyd package is present.
wget --timestamping "https://github.com/rvaiya/keyd/archive/refs/tags/\
v1.3.0.tar.gz"
# As the keyd archive doesn't include keyd in its name, make a copy with keyd
# in its name. Simply saving with this different filename will stop wget's
# --timestamping option working.
cp v1.3.0.tar.gz keyd-v1.3.0-source.tar.gz

# Ensure the direnv package is present.
wget --timestamping "https://github.com/direnv/direnv/releases/download/\
v2.30.3/direnv.linux-amd64"
wget --timestamping "https://github.com/direnv/direnv/archive/refs/tags/\
v2.30.3.tar.gz"
# As the direnv archive doesn't include direnv in its name, make a copy with
# direnv in its name. Simply saving with this different filename will stop
# wget's --timestamping option working.
cp v2.30.3.tar.gz direnv-v2.30.3-source.tar.gz

# Ensure the Fira Code font is present.
wget --timestamping "https://github.com/ryanoasis/nerd-fonts/raw/v2.1.0/\
patched-fonts/FiraCode/Regular/complete/\
Fira%20Code%20Regular%20Nerd%20Font%20Complete.otf"
# As the file name includes spaces, make a copy replacing them with
# underscores. Simply saving with this different filename will stop wget's
# --timestamping option working.
cp \
    'Fira Code Regular Nerd Font Complete.otf' \
    Fira_Code_Regular_Nerd_Font_Complete.otf

# Ensure the Starship binary is present.
wget --timestamping "https://github.com/starship/starship/releases/download/\
v1.3.0/starship-x86_64-unknown-linux-gnu.tar.gz"

# Ensure the HTTPie completion file is present.
wget --timestamping "https://github.com/httpie/httpie/raw/3.1.0/extras/\
httpie-completion.bash"

# Ensure the trash-cli package is present.
wget --timestamping "https://github.com/andreafrancia/trash-cli/archive/refs/\
tags/0.21.10.24.tar.gz"
# As the trash-cli archive doesn't include trash-cli in its name, make a copy
# with trash-cli in its name. Simply saving with this different filename will
# stop wget's --timestamping option working.
cp 0.21.10.24.tar.gz trash-cli-0.21.10.24-source.tar.gz

# Ensure the Neovim package is present.
wget --timestamping "https://github.com/neovim/neovim/releases/download/\
v0.7.0/nvim-linux64.deb"

# Ensure the StyLua package is present.
wget --timestamping "https://github.com/JohnnyMorganz/StyLua/releases/\
download/v0.13.1/stylua-linux.zip"
