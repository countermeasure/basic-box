Basic Box
=========

Builds a basic Debian 10 (Buster) installer which asks very few questions.

Includes non-free wifi firmware for Thinkpad T-series laptops.

Runs on Debian 10.


What it does
------------

The **Basic Box** installer creates a Debian 10 system with:

- full disk encryption (FDE)
- no ``root`` user
- an ordinary user called ``basic`` with password ``basic``
- locale and timezone set to Melbourne, Australia
- the GNOME desktop environment
- the UFW firewall installed and enabled
- the Mullvad VPN app installed and enabled with an interactive script which
  runs automatically on the first boot
- Tor Browser Launcher installed
- these Firefox extensions installed interactively on the first login:

  - Dark Reader
  - Decentraleyes
  - Firefox Multi-Account Containers
  - HTTPS Everywhere
  - NoScript Security Suite
  - Privacy Badger
  - uBlock Origin

- these Firefox preferences set interactively on the first login:

  - Enhanced Tracking Protection to Strict
  - Default Search Engine to DuckDuckGo
  - Theme to Dark

- pipx installed
- youtube-dl installed
- ranger installed
- these GNOME changes:

  - Enable dark theme
  - Display date and battery percentage in top bar
  - Never blank screen, dim screen or suspend when inactive
  - Enable night light (makes display colour warmer at night)
  - Enable natural scrolling for mouse
  - Speed up trackpad and enable trackpad tap-to-click

- automatic login enabled
- fd installed
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
- optional key remapping which:

  - modifies the CapsLock key to produce Control when held and Escape when
    tapped
  - modifies the Escape key to produce CapsLock

- direnv installed


Set up
------

Install the dependencies::

  $ sudo apt install make simple-cdd wget


Usage
-----

Insert a flash drive and then::

  $ make usb

Or to just create the installer image::

  $ make image
