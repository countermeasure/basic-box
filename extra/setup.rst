Basic Box setup
===============

Once Basic Box is installed, you can take some or all of these steps to set it
up with your personal data.

Feel free to delete this file once you're done with it.


Security first
--------------

You should change the password of your user with::

    $ passwd


Bash
----

You can place any Bash aliases or functions you have into files with names
which start with ``.bashrc_`` and save those files into the ``$HOME``
directory.

Files which start with ``.bashrc_`` in ``$HOME`` are sourced by Bash.


Git
---

You can replace the placeholder identity details for Git with::

   $ git config --global user.name "Your Name"
   $ git config --global user.email your@email.address


KeePassXC
---------

1. Create a ``$HOME/.data/keepassxc`` directory.

2. Save your KeePassXC ``.kdbx`` data files into ``$HOME/.data/keepassxc``.

3. Open Firefox.

4. Open one of your ``.kdbx`` files in KeePassXC.

5. Click the **KeePassXC** icon in the Firefox toolbar.

6. Click the **Connect** button.

7. In the **New key association request** dialog box that appears, enter a name
   that represents the file you just opened. The name of the file minus the
   ``.kdbx`` extension is a good choice.

8. Click the **Save and allow access** button.

9. If you see an **Overwrite existing key?** dialog, click the **Overwrite**
   button in it.

10. Repeat steps 4 to 9 for each ``.kdbx`` file in ``$HOME/.data/keepassxc``.


OfflineIMAP
-----------

Copy your ``.offlineimaprc`` file into the ``$HOME`` directory.


PowerTOP
--------

Do an initial callibration of PowerTOP (which will make the machine unusable
for a few minutes) with::

   $ ptop --calibrate

After this, the longer you let PowerTOP run on battery power, the more accurate
it should become.


SSH
---

Replace the ``$HOME/.ssh`` directory with your own ``.ssh`` directory.
