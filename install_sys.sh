#!/bin/bash

#Never run pacman -Sy on your system!
pacman -Sy dialog

timedatectl set-ntp true

dialog --defaultno --title "Are you Sure?" --yesno \
    "This is my personal arch linux install. \n\n\
    It will destroy everything on one of your hard disks. \n\n\
    Do not say YES if you are not sure what you are doing. \n\n\
    Do you want to continue?" 15 60 || exit

