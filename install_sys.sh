#!/bin/bash

#Never run pacman -Sy on your system!
pacman -Sy dialog

# set date and time
timedatectl set-ntp true

# first prompt, giving the last hail mary before using the script
dialog --defaultno --title "Are you Sure?" --yesno \
    "This is my personal arch linux install. \n\n\
    It will destroy everything on one of your hard disks. \n\n\
    Do not say YES if you are not sure what you are doing. \n\n\
    Do you want to continue?" 15 60 || exit

# enter hostname
dialog --no-cancel --inputbox "Enter a name for your computer." \
    10 60 2> comp

# verify the boot (UEFI or BIOS)
uefi=0
ls /sys/firmware/efi/efivars 2> /dev/null && uefi=1

# giving the user the choice of which hard disk to gormat
devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' \
    | grep -E 'sd|hd|vd|nvme|mmcblk'))

dialog --title "Choose your hard drive" --no-cancel --radiolist \
    "Where do you want to install your new system? \n\n\
    Select with SPACE, validate with ENTER. \n\n\
    WARNING: Everything will be DESTROYED on the hard disk!" \
    15 60 4 "${devices_list[@]}" 2>
    hd=$(cat hd) && rm hd

# Partitioning and installing Arch Linux
default_size="8"
dialog --no-cancel --inputbox \
    "You need three partitions: Boot, Root and Swap \n\
    The boot partition will be 512M \n\
    The root partition will be the rmeaining of the hard disk \n\n\
    Enter below the partition size (in Gb) for the Swap. \n\n\
    If you do not enter anything, it will default to ${default_size}G. \n" \
    20 60 2> swap_size
size=$(cat swap_size) && rm swap_size

[[ $size =~ ^[0-9]+$ ]] || size=$default_size

# ERASING the hard disk :)
dialog --no-cancel \
    --title "!!! DELETING EVERYTHING TIME !!!"\
    --menu "Choose your weapon to wipe the hard disk ($hd)" \
    15 60 4 \
    1 "Use dd (wipe all disk)" \
    2 "Use shred (slow & secure)" \
    3 "No need - my hard disk is empty" 2> eraser

hderaser=$(cat eraser); rm eraser

#This function is for erasing the disk either with dd or shred
function eraseDisk() {
    case $1 in
        1) dd if=/dev/zero of="$hd" status=progress 2>&1 \
            | dialog \
            --title "Formatting $hd..." \
            --progressbox --stdout 20 60;;
        2) shred -v "$hd" \
            | dialog \
            --title "Formatting $hd.." \
            --progressbox --stdout 20 60;;
        3) ;;
    esac
}

eraseDisk "$hderaser"

# Creating Partitions - to clear confusions, fdisk uses numbers for boot type
# 4 is for BIOS and UEFI is 1, could define variable uefi as 4 then change to 1 but idk
boot_partition_type=1
[[ "$uefi" == 0 ]] && boot_partition_type=4

# Create the partitions
#Be careful with this bit, the spaces are there for a reason..
#g - create non empty GPT partition table
#n - create new partition
#p - primary partition
#e - extended partition
#w - write the table to disk and exit

partprobe "$hd"

fdisk "$hd" << EOF
g
n


+512M
t
$boot_partition_type
n


+${size}G
n



w
EOF

partprobe "$hd"

# Add a suffix "p" in case we have a NVMe controller chip
echo "$hd" | grep -E 'nvme' &> /dev/null && hd="${hd}p"

# Format the partitions
mkswap "${hd}2"
swapon "${hd}2"
mkfs.ext4 "${hd}3"
mount "${hd}3" /mnt

if [ "$uefi" = 1 ]; then
    mkfs.fat -F32 "${hd}1"
    mkdir -p /mnt/boot/efi
    mount "${hd}1" /mnt/boot/efi
fi

# Install Arch Linux!
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Persist important values for the next script
echo "$uefi" > /mnt/var_uefi
echo "$hd" > /mnt/var_hd
mv comp /mnt/comp

curl https://raw.githubusercontent.com/ForgottenScream\
/arch_installer/main/install_chroot.sh > /mnt/install_chroot.sh

arch-chroot /mnt bash install_chroot.sh

rm /mnt/var_uefi
rm /mnt/var_hd
rm /mnt/install_chroot.sh
rm /mnt/comp

dialog --title "To reboot or not to reboot?" --yesno \
"The install is completed. \n\n\
Do you want to reboot your computer?" 20 60

response=$?

case $response in
    0) reboot;;
    1) clear;;
esac
