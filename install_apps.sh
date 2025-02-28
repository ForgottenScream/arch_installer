#!/bin/bash

name=$(cat /tmp/user_name)

apps_path="/tmp/apps.csv"
curl https://raw.githubusercontent.com/ForgottenScream\
    /arch_installer/main/apps.csv > $apps_path

dialog --title "Welcome!"\
    --msgbox "Welcome to the installation script for your apps and dotfiles!" \
    10 60

apps=("essential" "Essentials" on
      "network" "Network" on
      "tools" "Recommend these tools" on
      "tmux" "Tmux" on
      "notifier" "Notification Tools" on
      "git" "Git & Git tools" on
      "i3" "i3 wm" on
      "zsh" "The Z-Shell (zsh)" on
      "neovim" "Neovim" on
      "urxvt" "URxvt" on
      "firefox" "Firefox (Browser)" off
      "js" "JavaScript Tooling" off
      "qutebrowser" "Qutebrowser (Browser)" off
      "lynx" "Lynx (browser)" off
      "zathura" "Zathura - PDF Reader" on
      "signal" "Signal Desktop" on
      "games" "Selection of games" off
      "audio" "Audio stuff - recommended" on
      "video" "Video stuff - recommended" on
      "extra" "Extra stuff, can use" off)

dialog --checklist \
    "You can now choose the groups of applications you want to install. \n\n\
    You can select an option with SPACE and validate your choices with ENTER." \
    0 0 0 \
    "${apps[@]}" 2> app_choices

    choices=$(cat app_choices) && rm app_choices
