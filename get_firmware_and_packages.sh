#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

get_version() {
  # Get the version of a package.
  jq ".[\"$1\"]" ../../versions.json | tr --delete '"'
}

link() {
  # Create a symbolic link, overwriting an existing link or file.
  ln --force --symbolic "$1" "$2"
}

# Ensure the firmware directory exists and switch into it.
mkdir -p firmware
cd firmware || exit 1

# Ensure the firmware is present.
wget --timestamping "https://cdimage.debian.org/cdimage/unofficial/non-free/\
firmware/bookworm/current/firmware.tar.gz"

# Ensure the extra packages directory exists and switch into it.
mkdir -p ../extra/packages
cd ../extra/packages || exit 1

# Ensure the Mullvad VPN app package is present.
mullvad_version=$(get_version mullvad)
wget --timestamping "https://mullvad.net/media/app/\
MullvadVPN-${mullvad_version}_amd64.deb"
link "MullvadVPN-${mullvad_version}_amd64.deb" 'mullvad.deb'

# Ensure the zoxide package is present.
zoxide_version=$(get_version zoxide)
wget --timestamping "https://github.com/ajeetdsouza/zoxide/releases/download/\
v${zoxide_version}/zoxide_${zoxide_version}-1_amd64.deb"
link "zoxide_${zoxide_version}-1_amd64.deb" 'zoxide.deb'

# Ensure the delta package is present.
# The delta .deb package doesn't contain completions as of version 0.11.3, so
# manual installation is necessary.
delta_version=$(get_version delta)
wget --timestamping "https://github.com/dandavison/delta/releases/download/\
${delta_version}/delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz"
link "delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz" 'delta.tar.gz'
wget --timestamping "https://github.com/dandavison/delta/archive/refs/tags/\
${delta_version}.tar.gz"
link "${delta_version}.tar.gz" 'delta_source.tar.gz'

# Ensure the keyd package is present.
keyd_version=$(get_version keyd)
wget --timestamping "https://github.com/rvaiya/keyd/archive/refs/tags/\
v${keyd_version}.tar.gz"
link "v${keyd_version}.tar.gz" 'keyd_source.tar.gz'

# Ensure the Fira Code font is present.
nerd_fonts_version=$(get_version nerd-fonts)
wget --timestamping "https://github.com/ryanoasis/nerd-fonts/raw/\
v${nerd_fonts_version}/patched-fonts/FiraCode/Regular/\
FiraCodeNerdFont-Regular.ttf"
link 'FiraCodeNerdFont-Regular.ttf' 'fira_code.ttf'

# Ensure the Starship binary is present.
starship_version=$(get_version starship)
wget --timestamping "https://github.com/starship/starship/releases/download/\
v${starship_version}/starship-x86_64-unknown-linux-gnu.tar.gz"
link 'starship-x86_64-unknown-linux-gnu.tar.gz' 'starship.tar.gz'

# Ensure the HTTPie completion files are present.
httpie_version=$(get_version httpie)
wget --timestamping "https://github.com/httpie/httpie/raw/${httpie_version}/\
extras/httpie-completion.bash"
wget --timestamping "https://github.com/httpie/httpie/raw/${httpie_version}/\
extras/httpie-completion.fish"

# Ensure the trash-cli package is present.
trash_cli_version=$(get_version trash-cli)
wget --timestamping "https://github.com/andreafrancia/trash-cli/archive/refs/\
tags/${trash_cli_version}.tar.gz"
link "${trash_cli_version}.tar.gz" 'trash_cli_source.tar.gz'

# Ensure the Neovim package is present.
neovim_version=$(get_version neovim)
wget --timestamping "https://github.com/neovim/neovim/releases/download/\
v${neovim_version}/nvim.appimage"
wget --timestamping "https://github.com/neovim/neovim/archive/refs/tags/\
v${neovim_version}.tar.gz"
link "v${neovim_version}.tar.gz" 'nvim_source.tar.gz'

# Ensure the yt-dlp package is present.
yt_dlp_version=$(get_version yt-dlp)
wget --timestamping "https://github.com/yt-dlp/yt-dlp/releases/download/\
${yt_dlp_version}/yt-dlp.tar.gz"
link 'yt-dlp.tar.gz' 'yt_dlp.tar.gz'

# Ensure the bandwhich package is present.
bandwhich_version=$(get_version bandwhich)
wget --timestamping "https://github.com/imsnif/bandwhich/releases/download/\
v${bandwhich_version}/\
bandwhich-v${bandwhich_version}-x86_64-unknown-linux-musl.tar.gz"
link \
  "bandwhich-v${bandwhich_version}-x86_64-unknown-linux-musl.tar.gz" \
  'bandwhich.tar.gz'
wget --timestamping "https://github.com/imsnif/bandwhich/archive/refs/tags/\
v${bandwhich_version}.tar.gz"
link "v${bandwhich_version}.tar.gz" 'bandwhich_source.tar.gz'

# Ensure the pyenv package is present.
pyenv_version=$(get_version pyenv)
wget --timestamping "https://github.com/pyenv/pyenv/archive/refs/tags/\
v${pyenv_version}.tar.gz"
link "v${pyenv_version}.tar.gz" 'pyenv_source.tar.gz'

# Ensure the geckodriver package is present.
geckodriver_version=$(get_version geckodriver)
wget --timestamping "https://github.com/mozilla/geckodriver/releases/download/\
v${geckodriver_version}/geckodriver-v${geckodriver_version}-linux64.tar.gz"
link "geckodriver-v${geckodriver_version}-linux64.tar.gz" 'geckodriver.tar.gz'

# Ensure the fish package is present.
fish_version=$(get_version fish)
wget --timestamping "https://download.opensuse.org/repositories/shells:/fish:/\
release:/3/Debian_12/amd64/fish_${fish_version}-1_amd64.deb"
link "fish_${fish_version}-1_amd64.deb" "fish.deb"
