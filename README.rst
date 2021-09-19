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


Set up
------

Install the dependencies::

  $ sudo apt install make simple-cdd


Usage
-----

Insert a flash drive and then::

  $ make usb

Or to just create the installer image::

  $ make image
