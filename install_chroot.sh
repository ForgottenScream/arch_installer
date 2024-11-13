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
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

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
#Root Password and User Creation
function config_user() {
    if [ -z "$1" ]; then
        dialog --no-cancel --inputbox "Please enter your username." \
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
            "Passwords do not match.\n\nEnter password again." \
            10 60 2> pass1
        dialog --no-cancel --passwordbox \
            "Retype your password." \
            10 60 2> pass2
    done

    name=$(cat name) && rm name
    pass1=$(cat pass1) && rm pass1 pass2

    # Create user if doesn't exist
    if [[ ! "$(id -u "$name" 2> /dev/null)" ]]; then
        dialog --infobox "Adding user $name..." 4 50
        useradd -m -g wheel -s /bin/bash "$name"
    fi

    # Add password to user
    echo "$name:$pass1" | chpasswd
}

dialog --title "root password" \
    --msgbox "It's time to add a password for the root user" \
    10 60
config_user root

dialog --title "Add User" \
    --msgbox "Let's create another user." \
    10 60
config_user

# Save your username for the next script.
echo "$name" > /tmp/user_name

# Ask to install all your apps / dotfiles.
dialog --title "Continue installation" --yesno \
"Do you want to install all your apps and your dotfiles?" \
10 60 \
&& curl https://raw.githubusercontent.com/ForgottenScream\
/arch_installer/master/install_apps.sh > /tmp/install_apps.sh \
&& bash /tmp/install_apps.sh
    
