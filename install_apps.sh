#!/bin/bash

run() {
    output=$(cat /var_output)

    log INFO "FETCH VARS FROM FILES" "$output"
    name=$(cat /tmp/var_user_name)
    url_installer=$(cat /var_url_installer)
    dry_run=$(cat /var_dry_run)

    log INFO "DOWNLOAD APPS CSV" "$output"
    apps_path="$(download-app-csv "$url_installer")"
    log INFO "APPS CSV DOWNLOADED AT: $apps_path" "$output"
    add-multilib-repo
    log INFO "MULTILIB ADDED" "$output"
    dialog-welcome
    dialog-choose-apps ch
    choices=$(cat ch) && rm ch
    log INFO "APP CHOOSEN: $choices" "$output"
    lines="$(extract-choosed-apps "$choices" "$apps_path")"
    log INFO "GENERATED LINES: $lines" "$output"
    apps="$(extract-app-names "$lines")"
    log INFO "APPS: $apps" "$output"
    update-system
    log INFO "UPDATED SYSTEM" "$output"
    delete-previous-aur-queue
    log INFO "DELETED PREVIOUS AUR QUEUE" "$output"
    dialog-install-apps "$apps" "$dry_run" "$output"
    log INFO "APPS INSTALLED" "$output"
    disable-horrible-beep
    log INFO "HORRIBLE BEEP DISABLED" "$output"
    set-user-permissions
    log INFO "USER PERMISSIONS SET" "$output"
    add-pacman-configuration-file
    log INFO "PACMAN CONF FILE ADDED" "$output"
    set-keyboard-colemak
    log INFO "KEYBOARD SET TO COLEMAK" "$output"
    set-touchpad-on
    log INFO "TOUCHPAD SET TO TOUCH ON" "$output"

    continue-install "$url_installer" "$name"
}

log() {
    local -r level=${1:?}
    local -r message=${2:?}
    local -r output=${3:?}
    local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo -e "${timestamp} [${level}] ${message}" >>"$output"
}

download-app-csv() {
    local -r url_installer=${1:?}

    apps_path="/tmp/apps.csv"
    curl "$url_installer/apps.csv" > "$apps_path"

    echo $apps_path
}

# Add multilib repo for steam
add-multilib-repo() {
    echo "[multilib]" >> /etc/pacman.conf && echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
}

dialog-welcome() {
    dialog --title "Welcome!" --msgbox "Welcome to ForgottenScream's dotfiles and software installation script for Arch linux.\n" 10 60
}

dialog-choose-apps() {
    local file=${1:?}

    apps=("essential" "Essentials" on
        "network" "Network Configuration" on
        "audio" "Audio tools" on
        "tools" "Very nice tools to have (highly recommended)" on
        "tmux" "Tmux" on
        "git" "Git & git tools" on
        "i3" "i3 Tile manager & Desktop" on
        "notify" "Notifications with dunst & libnotify" on
        "programming" "Programming environments" on
        "zsh" "Unix Z-Shell (zsh)" on
        "neovim" "Neovim" on
	"multimedia" "Packages for watching or streaming media" on
        "keepass" "Keepass" on
        "office" "Office tools (Libreoffice...)" off
        "pandoc" "Pandoc and usefull dependencies" off
        "firefox" "Firefox (browser)" on
        "keepass" "Keepass" off
	"qbittorrent" "Torrenting Client" off
	"phone" "Phone utilities" on
        "signal" "Signal Desktop Client" on
	"mullvad" "Mullvad VPN CLI" on)

    dialog --checklist "You can now choose the groups of applications you want to install, according to your own CSV file.\n\n Press SPACE to select and ENTER to validate your choices." 0 0 0 "${apps[@]}" 2> "$file"
}

extract-choosed-apps() {
    local -r choices=${1:?}
    local -r apps_path=${2:?}

    selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
    lines=$(grep -E "$selection" "$apps_path")

    echo "$lines"
}

extract-app-names() {
    local -r lines=${1:?}
    echo "$lines" | awk -F, '{print $2}'
}

update-system() {
    pacman -Syu --noconfirm
}

delete-previous-aur-queue() {
    rm -f /tmp/aur_queue
}

dialog-install-apps() {
    dialog --title "Let's go!" --msgbox \
    "The system will now install everything you need.\n\n\
    It will take some time.\n\n " 13 60
}

dialog-install-apps() {
    local -r final_apps=${1:?}
    local -r dry_run=${2:?}
    local -r output=${3:?}

    count=$(echo "$final_apps" | wc -l)

    c=0
    echo "$final_apps" | while read -r line; do
        c=$(( "$c" + 1 ))

        dialog --title "Arch Linux Installation" --infobox \
        "Downloading and installing program $c out of $count: $line..." 8 70

        if [ "$dry_run" = false ]; then
            pacman-install "$line" "$output"

            if [ "$line" = "networkmanager" ]; then
                # Enable the systemd service NetworkManager.
                systemctl enable NetworkManager.service
            fi

            if [ "$line" = "zsh" ]; then
                # zsh as default terminal for user
                chsh -s "$(which zsh)" "$name"
            fi

            if [ "$line" = "mariadb" ]; then
                mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            fi
        else
            fake_install "$line"
        fi
    done
}

fake-install() {
    echo "$1 fakely installed!" >> "$output"
}

pacman-install() {
    local -r app=${1:?}
    local -r output=${2:?}

    ((pacman --noconfirm --needed -S "$app" &>> "$output") || echo "$app" &>> /tmp/aur_queue)
}

continue-install() {
    local -r url_installer=${1:?}
    local -r name=${2:?}

    curl "$url_installer/install_user.sh" > /tmp/install_user.sh;

    if [ "$dry_run" = false ]; then
        # Change user and begin the install use script
        sudo -u "$name" bash /tmp/install_user.sh
    fi
}

set-user-permissions() {
    dialog --infobox "Copy user permissions configuration (sudoers)..." 4 40
    curl "$url_installer/sudoers" > /etc/sudoers
}

add-pacman-configuration-file() {
    dialog --infobox "Copy pacman configuration file (pacman.conf)..." 4 40
    curl "$url_installer/pacman.conf" > /etc/pacman.conf
}

set-keyboard-colemak() {
    dialog --infobox "Copy X11 Keyboard Configuration file (00-keyboard.conf)..." 4 40
    curl "$url_installer/00-keyboard.conf" > /etc/X11/xorg.conf.d/00-keyboard.conf
}

set-touchpad-on(){
    dialog --infobox "Copy X11 Touchpad Configuration file (40-libinput.conf)..." 4 40
    curl "$url_installer/40-libinput.conf" > /etc/X11/xorg.conf.d/40-libinput.conf
}

disable-horrible-beep() {
    rmmod pcspkr
    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
}

run "$@"
