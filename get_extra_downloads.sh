#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Ensure the extra downloads directory exists and switch into it.
mkdir -p extra/downloads
cd extra/downloads || exit 1

# Ensure the Mullvad VPN app package is present.
wget --timestamping https://mullvad.net/media/app/MullvadVPN-2023.4_amd64.deb

# Ensure the fd package is present.
wget --timestamping "https://github.com/sharkdp/fd/releases/download/v8.4.0/\
fd_8.4.0_amd64.deb"

# Ensure the ripgrep package is present.
wget --timestamping "https://github.com/BurntSushi/ripgrep/releases/download/\
13.0.0/ripgrep_13.0.0_amd64.deb"

# Ensure the exa package is present.
wget --timestamping "https://github.com/ogham/exa/releases/download/v0.10.1/\
exa-linux-x86_64-v0.10.1.zip"

# Ensure the bat package is present.
wget --timestamping "https://github.com/sharkdp/bat/releases/download/v0.22.1/\
bat_0.22.1_amd64.deb"

# Ensure the fzf package is present.
wget --timestamping "https://github.com/junegunn/fzf/releases/download/0.33.0/\
fzf-0.33.0-linux_amd64.tar.gz"
wget --timestamping "https://github.com/junegunn/fzf/archive/refs/tags/\
0.33.0.tar.gz"
# As the fzf archive doesn't include fzf in its name, make a copy with fzf in
# its name. Simply saving with this different filename will stop wget's
# --timestamping option working.
cp 0.33.0.tar.gz fzf-0.33.0-source.tar.gz

# Ensure the zoxide package is present.
wget --timestamping "https://github.com/ajeetdsouza/zoxide/releases/download/\
v0.8.3/zoxide_0.8.3_amd64.deb"

# Ensure the delta package is present.
# The delta .deb package doesn't contain completions as of version 0.11.3, so
# manual installation is necessary.
wget --timestamping "https://github.com/dandavison/delta/releases/download/\
0.14.0/delta-0.14.0-x86_64-unknown-linux-gnu.tar.gz"
wget --timestamping "https://github.com/dandavison/delta/archive/refs/tags/\
0.14.0.tar.gz"
# As the delta archive doesn't include delta in its name, make a copy with
# delta in its name. Simply saving with this different filename will stop
# wget's --timestamping option working.
cp 0.14.0.tar.gz delta-0.14.0-source.tar.gz

# Ensure the keyd package is present.
wget --timestamping "https://github.com/rvaiya/keyd/archive/refs/tags/\
v2.4.2.tar.gz"
# As the keyd archive doesn't include keyd in its name, make a copy with keyd
# in its name. Simply saving with this different filename will stop wget's
# --timestamping option working.
cp v2.4.2.tar.gz keyd-v2.4.2-source.tar.gz

# Ensure the direnv package is present.
wget --timestamping "https://github.com/direnv/direnv/releases/download/\
v2.32.1/direnv.linux-amd64"
wget --timestamping "https://github.com/direnv/direnv/archive/refs/tags/\
v2.32.1.tar.gz"
# As the direnv archive doesn't include direnv in its name, make a copy with
# direnv in its name. Simply saving with this different filename will stop
# wget's --timestamping option working.
cp v2.32.1.tar.gz direnv-v2.32.1-source.tar.gz

# Ensure the Fira Code font is present.
wget --timestamping "https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/\
patched-fonts/FiraCode/Regular/complete/\
Fira%20Code%20Regular%20Nerd%20Font%20Complete.ttf"
# As the file name includes spaces, make a copy replacing them with
# underscores. Simply saving with this different filename will stop wget's
# --timestamping option working.
cp \
    'Fira Code Regular Nerd Font Complete.ttf' \
    Fira_Code_Regular_Nerd_Font_Complete.ttf

# Ensure the Starship binary is present.
wget --timestamping "https://github.com/starship/starship/releases/download/\
v1.10.3/starship-x86_64-unknown-linux-gnu.tar.gz"

# Ensure the HTTPie completion file is present.
wget --timestamping "https://github.com/httpie/httpie/raw/3.2.1/extras/\
httpie-completion.bash"

# Ensure the trash-cli package is present.
wget --timestamping "https://github.com/andreafrancia/trash-cli/archive/refs/\
tags/0.22.8.27.tar.gz"
# As the trash-cli archive doesn't include trash-cli in its name, make a copy
# with trash-cli in its name. Simply saving with this different filename will
# stop wget's --timestamping option working.
cp 0.22.8.27.tar.gz trash-cli-0.22.8.27-source.tar.gz

# Ensure the Neovim package is present.
wget --timestamping "https://github.com/neovim/neovim/releases/download/\
v0.7.2/nvim-linux64.deb"

# Ensure the StyLua package is present.
wget --timestamping "https://github.com/JohnnyMorganz/StyLua/releases/\
download/v0.15.1/stylua-linux-x86_64.zip"

# Ensure the yt-dlp package is present.
wget --timestamping "https://github.com/yt-dlp/yt-dlp/releases/download/\
2022.09.01/yt-dlp.tar.gz"

# Ensure the bandwhich package is present.
wget --timestamping "https://github.com/imsnif/bandwhich/releases/download/\
0.20.0/bandwhich-v0.20.0-x86_64-unknown-linux-musl.tar.gz"
wget --timestamping "https://github.com/imsnif/bandwhich/archive/refs/tags/\
0.20.0.tar.gz"
# As the bandwhich archive doesn't include bandwhich in its name, make a copy
# with bandwhich in its name. Simply saving with this different filename will
# stop wget's --timestamping option working.
cp 0.20.0.tar.gz bandwhich-0.20.0-source.tar.gz

# Ensure the pyenv package is present.
wget --timestamping "https://github.com/pyenv/pyenv/archive/refs/tags/\
v2.3.5.tar.gz"
# As the pyenv archive doesn't include pyenv in its name, make a copy with
# pyenv in its name. Simply saving with this different filename will stop
# wget's --timestamping option working.
cp v2.3.5.tar.gz pyenv-v2.3.5-source.tar.gz

# Ensure the geckodriver package is present.
wget --timestamping "https://github.com/mozilla/geckodriver/releases/download/\
v0.32.0/geckodriver-v0.32.0-linux64.tar.gz"
