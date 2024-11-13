#!/bin/bash
#Set variables from install script
uefi=$(cat /var_uefi)
hd=$(cat /var_hd)
#set hostname
cat /comp > /etc/hostname && rm /comp
#install dialog
pacman --noconfirm -S dialog
#install grub
pacman -S --noconfirm grub
#if else statement to install based on whether the system has UEFI or not
if [ "$uefi" = 1 ]; then
    pacman -S --noconfirm efibootmgr
    grub-install --target=x86_64-efi \
        --bootloader-id=GRUB \
        --efi-directory=/boot/efi
else
    grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

#Clock and Timezone
#Set hardware clock from system clock
hwclock --systohc
timedatectl set-timezone Europe/London

#Configuring Locales
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
#Configuring keyboard layout
echo "KEYMAP=colemak" > /etc/vconsole.conf
mkdir -p /etc/X11/xorg.conf.d/
cat > /etc/X11/xorg.conf.d/00-keyboard.conf << EOF
Section "InputClass"
    Identifier "keyboard defaults"
    MatchIsKeyboard "yes"
    Option "XkbLayout" "gb"
    Option "XkbVariant" "colemak"
EndSection
EOF
#Making the touchpad work
cat > /etc/X11/xorg.conf.d/40-libinput.conf << EOF
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"                 # Enable tap-to-click
    Option "NaturalScrolling" "true"      # Enable natural scrolling
    Option "DisableWhileTyping" "true"    # Disable touchpad while typing
    Option "VertEdgeScroll" "true"        # Enable vertical edge scrolling
    Option "HorizEdgeScroll" "true"       # Enable horizontal edge scrolling
    Option "ClickMethod" "clickfinger"    # Enable click with one or more fingers
    Option "AccelSpeed" "0.5"             # Adjust touchpad sensitivity (between -1 and 1)
EndSection
EOF
