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
