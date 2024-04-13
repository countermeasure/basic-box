Basic Box
=========

Builds a basic Debian 12 (Bookworm) installer which asks very few questions.

When more than one drive is present, the installer targets the smallest drive.

Runs on Debian 12.


What it does
------------

The **Basic Box** installer creates a Debian 12 system with:

- full disk encryption (FDE)
- no ``root`` user
- an ordinary user called ``user`` with password ``basic``
- locale and timezone set to Melbourne, Australia
- the GNOME desktop environment
- the UFW firewall installed and enabled
- the Mullvad VPN app installed and enabled with an interactive script which
  runs automatically on the first boot
- Tor Browser Launcher installed
- these Firefox extensions installed:

  - Dark Reader
  - Firefox Multi-Account Containers
  - KeePassXC-Browser
  - OneTab
  - Privacy Badger
  - uBlock Origin

- certain Firefox preferences set for better privacy and a simpler interface
- pipx installed
- yt-dlp installed
- ranger installed
- these GNOME changes:

  - Enable dark theme
  - Display date and battery percentage in top bar
  - Never blank screen, dim screen or suspend when inactive
  - Enable night light (makes display colour warmer at night)
  - Enable natural scrolling for mouse
  - Speed up trackpad and enable trackpad tap-to-click

- these GNOME extensions installed, enabled and configured:

  - Bluetooth Quick Connect
  - Dash to Dock
  - Disable Workspace Switcher
  - Hide Activities Button
  - NoAnnoyance v2
  - Quick Close in Overview
  - system-monitor
  - Ubuntu AppIndicator

- automatic login enabled
- fd-find (fd) installed
- ripgrep installed
- exa installed
- bat installed
- fzf installed
- zoxide installed
- htop installed
- ncdu installed
- aliases which add certain defaults to commonly-used utilities
- delta installed
- Git installed
- gitk installed
- keyd installed
- key remapping, which can be deactivated, which:

  - modifies the Backslash key to produce Meta when held and Backslash when
    tapped
  - modifies the CapsLock key to produce Control when held and Escape when
    tapped
  - modifies the Escape key to produce CapsLock
  - modifies the Tab key to produce Meta when held and Tab when tapped

- direnv installed
- Fira Code Nerd Font installed and set as the system-wide monospace font
- Starship installed
- HTTPie installed
- Nmap installed
- KeePassXC installed
- IPython installed
- Entomb installed
- MTR installed
- tree installed
- tldr-pages installed
- OfflineIMAP installed
- a global Git ignore file
- trash-cli installed and integrated with ranger
- Neovim installed and configured with LazyVim
- curl installed
- Bluetooth turned off when the system boots
- atool installed
- bandwhich installed
- whois installed
- smartmontools installed
- python-is-python3 installed
- zathura installed
- acpi installed
- Syncthing installed
- Lynis installed
- ClamAV installed
- Rootkit Hunter installed
- pyenv installed
- geckodriver installed
- JupyterLab installed
- TLP installed and configured so that batteries start charging at 75% capacity
  and stop charging at 80% capacity
- Libnotify installed
- Thunderbird installed
- wl-clipboard installed
- Podman installed
- fish installed and set as the interactive shell
- MAC address randomised
- a systemd service which warns when no VPN is managing traffic
- build-essential installed
- dbus-x11 installed
- Signal installed
- duf installed
- Mullvad Browser installed
- dict, dictd and dict-wn installed


Set up
------

Install the dependencies::

  $ sudo apt install jq libnotify-bin make simple-cdd wget


Usage
-----

Insert a flash drive and then::

  $ make usb

Or to just create the installer image::

  $ make image
