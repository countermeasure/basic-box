#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

nvim_config_dir="${HOME}"/.config/nvim/lua/config
nvim_plugins_dir="${HOME}"/.config/nvim/lua/plugins

link() {
  # Create a symbolic link, overwriting an existing link or file. If the link
  # is not created in the $HOME directory, make root its owner.
  if [[ $2 = ${HOME}* ]]; then
    ln --force --symbolic "${PWD}"/extra/"$1" "$2"
  else
    sudo ln --force --symbolic "${PWD}"/extra/"$1" "$2"
    sudo chown root:root "$2"
  fi
}

link box.sh "${HOME}"/.local/bin/box
link check_vpn.service "${HOME}"/.config/systemd/user/check_vpn.service
link check_vpn.sh "${HOME}"/.local/bin/check_vpn
link git_wrapper.sh "${HOME}"/.local/bin/git_wrapper
link setup.rst "${HOME}"/setup.rst
link dotfiles/config.fish "${HOME}"/.config/fish/config.fish
link dotfiles/dot_bash_aliases "${HOME}"/.bash_aliases
link dotfiles/dot_bash_functions "${HOME}"/.bash_functions
link dotfiles/dot_bashrc_modifications "${HOME}"/.bashrc_modifications
link dotfiles/dot_profile_modifications "${HOME}"/.profile_modifications
link \
  dotfiles/firefox_policies.json \
  /usr/share/firefox-esr/distribution/policies.json
link dotfiles/fish.theme "${HOME}"/.config/fish/themes/box.theme
link dotfiles/fish_aliases "${HOME}"/.config/fish/fish_aliases
link dotfiles/fish_functions "${HOME}"/.config/fish/fish_functions
link dotfiles/git_global_ignore "${HOME}"/.config/git/ignore
link dotfiles/gitk "${HOME}"/.config/git/gitk
link \
  dotfiles/gnome_initial_setup_done "${HOME}"/.config/gnome-initial-setup-done
link dotfiles/htoprc "${HOME}"/.config/htop/htoprc
link \
  dotfiles/ipython_config.py \
  "${HOME}"/.ipython/profile_default/ipython_config.py
link \
  dotfiles/jupyterlab_apputils_settings \
  "${HOME}"/.jupyter/lab/user-settings/themes.jupyterlab-settings
link \
  dotfiles/jupyterlab_codemirror_settings \
  "${HOME}"/.jupyter/lab/user-settings/commands.jupyterlab-settings
link dotfiles/keepassxc.ini "${HOME}"/.config/keepassxc/keepassxc.ini
link dotfiles/keyd_default.conf "${HOME}"/.config/keyd/default.conf
link \
  dotfiles/nm_mac_randomisation.conf \
  /etc/NetworkManager/conf.d/mac_randomisation.conf
link dotfiles/nvim_config_autocmds.lua "${nvim_config_dir}"/autocmds.lua
link dotfiles/nvim_config_keymaps.lua "${nvim_config_dir}"/keymaps.lua
link dotfiles/nvim_config_lazy.lua "${nvim_config_dir}"/lazy.lua
link dotfiles/nvim_config_options.lua "${nvim_config_dir}"/options.lua
link dotfiles/nvim_init.lua "${HOME}"/.config/nvim/init.lua
link dotfiles/nvim_lazy_lock.json "${HOME}"/.config/nvim/lazy-lock.json
link \
  dotfiles/nvim_plugins_colourscheme.lua "${nvim_plugins_dir}"/colourscheme.lua
link dotfiles/nvim_plugins_conform.lua "${nvim_plugins_dir}"/conform.lua
link dotfiles/nvim_plugins_lualine.lua "${nvim_plugins_dir}"/lualine.lua
link dotfiles/nvim_plugins_luasnip.lua "${nvim_plugins_dir}"/luasnip.lua
link dotfiles/nvim_plugins_mason.lua "${nvim_plugins_dir}"/mason.lua
link dotfiles/nvim_plugins_neotree.lua "${nvim_plugins_dir}"/neotree.lua
link dotfiles/nvim_plugins_nvim_cmp.lua "${nvim_plugins_dir}"/nvim_cmp.lua
link dotfiles/nvim_plugins_nvim_lint.lua "${nvim_plugins_dir}"/nvim_lint.lua
link \
  dotfiles/nvim_plugins_nvim_lspconfig.lua \
  "${nvim_plugins_dir}"/nvim_lspconfig.lua
link dotfiles/nvim_plugins_ranger.lua "${nvim_plugins_dir}"/ranger.lua
link dotfiles/nvim_plugins_telescope.lua "${nvim_plugins_dir}"/telescope.lua
link dotfiles/nvim_plugins_treesitter.lua "${nvim_plugins_dir}"/treesitter.lua
link dotfiles/nvim_plugins_which_key.lua "${nvim_plugins_dir}"/which_key.lua
link \
  dotfiles/ranger_colourscheme.py "${HOME}"/.config/ranger/colorschemes/box.py
link dotfiles/ranger_rc.conf "${HOME}"/.config/ranger/rc.conf
link dotfiles/ranger_rifle.conf "${HOME}"/.config/ranger/rifle.conf
link dotfiles/ranger_scope.sh "${HOME}"/.config/ranger/scope.sh
link dotfiles/sources_fish.list /etc/apt/sources.list.d/fish.list
link dotfiles/sources_signal.list /etc/apt/sources.list.d/signal.list
link dotfiles/sources_syncthing.list /etc/apt/sources.list.d/syncthing.list
link dotfiles/starship.toml "${HOME}"/.config/starship.toml
link dotfiles/sudoers_apt /etc/sudoers.d/apt
link dotfiles/sudoers_cryptsetup /etc/sudoers.d/cryptsetup
link dotfiles/sudoers_lecture /etc/sudoers.d/lecture
link dotfiles/sudoers_lynis /etc/sudoers.d/lynis
link dotfiles/sudoers_powertop /etc/sudoers.d/powertop
link dotfiles/sudoers_rkhunter /etc/sudoers.d/rkhunter
link dotfiles/sudoers_tlp /etc/sudoers.d/tlp
link dotfiles/sudoers_ufw /etc/sudoers.d/ufw
link \
  dotfiles/tlp_charging_thresholds.conf /etc/tlp.d/10-charging-thresholds.conf
link dotfiles/yt_dlp_config "${HOME}"/.config/yt-dlp/config
link dotfiles/zathurarc "${HOME}"/.config/zathura/zathurarc
