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

wget_to_directory() {
  # Get a file and place it in a directory.
  wget --directory-prefix "$1" --timestamping "$2"
}

# Ensure the firmware is present.
wget_to_directory 'firmware' "https://cdimage.debian.org/cdimage/unofficial/\
non-free/firmware/bookworm/current/firmware.tar.gz"

# Ensure the extra packages directory exists and switch into it.
mkdir -p extra/packages
cd extra/packages || exit 1

# Ensure the zoxide package is present.
zoxide_version=$(get_version zoxide)
wget_to_directory 'zoxide' "https://github.com/ajeetdsouza/zoxide/releases/\
download/v${zoxide_version}/zoxide_${zoxide_version}-1_amd64.deb"
link "zoxide/zoxide_${zoxide_version}-1_amd64.deb" 'zoxide.deb'

# Ensure the delta package is present.
# The delta .deb package doesn't contain completions as of version 0.11.3, so
# manual installation is necessary.
delta_version=$(get_version delta)
wget_to_directory 'delta' "https://github.com/dandavison/delta/releases/\
download/${delta_version}/\
delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz"
link \
  "delta/delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz" \
  'delta.tar.gz'
wget_to_directory 'delta' "https://github.com/dandavison/delta/archive/refs/\
tags/${delta_version}.tar.gz"
link "delta/${delta_version}.tar.gz" 'delta_source.tar.gz'

# Ensure the keyd package is present.
keyd_version=$(get_version keyd)
wget_to_directory 'keyd' "https://github.com/rvaiya/keyd/archive/refs/tags/\
v${keyd_version}.tar.gz"
link "keyd/v${keyd_version}.tar.gz" 'keyd_source.tar.gz'

# Ensure the Fira Code font is present.
nerd_fonts_version=$(get_version nerd-fonts)
wget_to_directory 'nerd_fonts' "https://github.com/ryanoasis/nerd-fonts/raw/\
v${nerd_fonts_version}/patched-fonts/FiraCode/Regular/\
FiraCodeNerdFont-Regular.ttf"
link 'nerd_fonts/FiraCodeNerdFont-Regular.ttf' 'fira_code.ttf'

# Ensure the Starship binary is present.
starship_version=$(get_version starship)
wget_to_directory 'starship' "https://github.com/starship/starship/releases/\
download/v${starship_version}/starship-x86_64-unknown-linux-gnu.tar.gz"
link 'starship/starship-x86_64-unknown-linux-gnu.tar.gz' 'starship.tar.gz'

# Ensure the HTTPie completion files are present.
httpie_version=$(get_version httpie)
wget_to_directory 'httpie' "https://github.com/httpie/httpie/raw/\
${httpie_version}/extras/httpie-completion.bash"
link 'httpie/httpie-completion.bash' 'httpie-completion.bash'
wget_to_directory 'httpie' "https://github.com/httpie/httpie/raw/\
${httpie_version}/extras/httpie-completion.fish"
link 'httpie/httpie-completion.fish' 'httpie-completion.fish'

# Ensure the trash-cli package is present.
trash_cli_version=$(get_version trash-cli)
wget_to_directory 'trash_cli' "https://github.com/andreafrancia/trash-cli/\
archive/refs/tags/${trash_cli_version}.tar.gz"
link "trash_cli/${trash_cli_version}.tar.gz" 'trash_cli_source.tar.gz'

# Ensure the Neovim package is present.
neovim_version=$(get_version neovim)
wget_to_directory 'neovim' "https://github.com/neovim/neovim/releases/\
download/v${neovim_version}/nvim-linux-x86_64.appimage"
link 'neovim/nvim-linux-x86_64.appimage' 'nvim.appimage'
wget_to_directory 'neovim' "https://github.com/neovim/neovim/archive/refs/\
tags/v${neovim_version}.tar.gz"
link "neovim/v${neovim_version}.tar.gz" 'nvim_source.tar.gz'

# Ensure the yt-dlp package is present.
yt_dlp_version=$(get_version yt-dlp)
wget_to_directory 'yt_dlp' "https://github.com/yt-dlp/yt-dlp/releases/\
download/${yt_dlp_version}/yt-dlp.tar.gz"
link 'yt_dlp/yt-dlp.tar.gz' 'yt_dlp.tar.gz'

# Ensure the bandwhich package is present.
bandwhich_version=$(get_version bandwhich)
wget_to_directory 'bandwhich' "https://github.com/imsnif/bandwhich/releases/\
download/v${bandwhich_version}/\
bandwhich-v${bandwhich_version}-x86_64-unknown-linux-musl.tar.gz"
link \
  "bandwhich/bandwhich-v${bandwhich_version}-x86_64-unknown-linux-musl.tar.gz" \
  'bandwhich.tar.gz'

# Ensure the pyenv package is present.
pyenv_version=$(get_version pyenv)
wget_to_directory 'pyenv' "https://github.com/pyenv/pyenv/archive/refs/tags/\
v${pyenv_version}.tar.gz"
link "pyenv/v${pyenv_version}.tar.gz" 'pyenv_source.tar.gz'

# Ensure the geckodriver package is present.
geckodriver_version=$(get_version geckodriver)
wget_to_directory 'geckodriver' "https://github.com/mozilla/geckodriver/\
releases/download/v${geckodriver_version}/\
geckodriver-v${geckodriver_version}-linux64.tar.gz"
link \
  "geckodriver/geckodriver-v${geckodriver_version}-linux64.tar.gz" \
  'geckodriver.tar.gz'

# Ensure the paperwm package is present.
paperwm_version=$(get_version paperwm)
wget_to_directory 'paperwm' "https://github.com/paperwm/PaperWM/archive/refs/\
tags/v${paperwm_version}.zip"
link "paperwm/v${paperwm_version}.zip" 'paperwm.zip'

# Ensure the Space Bar package is present.
spacebar_version=$(get_version spacebar)
wget_to_directory 'spacebar' "https://extensions.gnome.org/extension-data/\
space-barluchrioh.v${spacebar_version}.shell-extension.zip"
link \
  "spacebar/space-barluchrioh.v${spacebar_version}.shell-extension.zip" \
  'spacebar.zip'
