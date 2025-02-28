These scripts install my setup and all its config files in one command.
Requires understanding a lot of different concepts as it focuses on being a keyboard first desktop,
but it still works if you were planning to use it with a mouse as well.

to install on arch live iso:
curl -LO https://raw.githubusercontent.com/ForgottenScream/arch_installer/main/install_sys.sh
bash install_sys.sh

You can watch the applications being installed from pacman by changing to TTY2 like so:
  CTRL + ALT + F2 (F1 to go back to the installation)

  and while it is downloading, type in:
    tail -f /tmp/arch_install

  this way you can watch it happen.
