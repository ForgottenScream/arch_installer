#!/bin/bash

# get variables from last script
uefi=$(cat /var_uefi; hd=$(cat /var_hd);

# set hostname defined in last script
cat /comp > /etc/hostname && rm /comp

# install dialog
pacman --noconfirm -S dialog

# install grub and configure it for UEFI or BIOS
pacman -S --noconfirm grub

if [ "$uefi" = 1 ]; then
    pacman -S --noconfirm efibootmgr
    grub-install --target=x86_64-efi \
        --bootloader-id=GRUB \
        --efi-directory=/boot/efi
else
    grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Set hardware clock from system clock
hwclock --systohc

# setting timezones and locales, putting PT there incase there is a need to switch
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
echo "pt_PT.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.gonf

# Set keymap layout, mine is colemak so
loadkeys colemak
echo "KEYMAP=colemak" >> /etc/vconsole.conf

function config_user() {
    if [ -z "$1" ]; then
        dialog --no-cancel --inputbox "Please enter your user name." \
            10 60 2> name
        else
            echo "$1" > name
        fi
        dialog --no-cancel --passwordbox "Enter your password." \
            10 60 2> pass1
        dialog --no-cancel --passwordbox "Confirm your password." \
            10 60 2> pass2

        while [ "$(cat pass1)" != "$(cat pass2)" ]
        do
            dialog --no-cancel --passwordbox \
                "The passwords do not match.\n\n\ Enter your password again." \
                10 60 2> pass1
            dialog --no-cancel --passwordbox \
                "Retype your password." \
                10 60 2> pass2
        done

        name=$(cat name) && rm name
        pass1=$(cat pass1) && rm pass1 pass2

        # Create user if does not exist
        if [[ ! "$(id -u "$name" 2> /dev/null)" ]]; then
            dialog --infobox "Adding user $name..." 4 50
            useradd -m -g wheel -s /bin/bash "$name"
        fi

        # Add password to user
        echo "$name:$pass1" | chpasswd
}

dialog --title "Root password" \
    --msgbox "It is time to add a password for the root user." \
    10 60
config_user root

dialog --title "Add user" \
    --msgbox "Let's create another user." \
    10 60
config_user

# at this point arch is fully configured, functionally speaking- moving on to applications

echo "$name" > /tmp/user_name

dialog --title "Continue installation?" --yesno\
    "Do you want to install all applications and dotfiles?" \
    10 60 \
    && curl https://raw.githubusercontent.com/ForgottenScream\
    /arch_installer/main/install_apps.sh > /tmp/install_apps.sh \
    && bash /tmp/install_apps.sh
