#!/bin/bash

#Never run pacman on your system!!
pacman -Sy dialog

#Ensuring the time is correct
timedatectl set-ntp true

#Confirmation box
dialog --defaultno --title "Are you sure?" --yesno \
"This is a personal arch linux install. \n\n\
It will DESTROY everything on one of your hard disks. \n\n\
Do not say YES if you are not sure what you are doing. \n\n\
Do you want to continue?" 15 60 || exit

#Ask user's name
dialog --no-cancel --inputbox "Enter a name for your computer." \
10 60 2> comp

#Verify boot (UEFI or BIOS)
uefi=0
ls /sys/firmware/efi/efivars 2> /dev/null && uefi=1

#Choosing the Hard Disk
devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' \
    | grep -E 'sd/hd/vd/nvme/mmcblk'))

dialog --title "Choose your hard drive" --no-cancel --radiolist \
"Where do you want to install your new system? \n\n\
Select with SPACE, validate with ENTER. \n\n\
WARNING: Everything will be DESTROYED on the hard disk!" \
15 60 4 "${devices_list[@]}" 2> hd

hd-$(cat hd) rm hd
