#!/bin/bash
function ensureInstalled() {
    PACKAGE=$1
    if [[ -z $(pacman -Qs "^${PACKAGE}$") ]]; then
        echo "Installing ${PACKAGE}"
        yay -S ${PACKAGE}
    fi
}

ensureInstalled bat
ensureInstalled git
ensureInstalled yadm
ensureInstalled maven
ensureInstalled nodejs
ensureInstalled npm
ensureInstalled jdk8-openjdk
ensureInstalled jdk11-openjdk
ensureInstalled mpv
ensureInstalled vlc
ensureInstalled arc-gtk-theme
ensureInstalled viewnior
ensureInstalled tumbler
ensureInstalled ffmpegthumbnailer
ensureInstalled gvfs
ensureInstalled gvfs-smb
ensureInstalled xarchiver
ensureInstalled reflector
ensureInstalled redshift-wayland-git
ensureInstalled clipman
ensureInstalled kanshi-git
ensureInstalled wdisplays-git
ensureInstalled pass
ensureInstalled tree
ensureInstalled browserpass-chrome
ensureInstalled diceware
ensureInstalled pass-extension-tail
ensureInstalled pass-git-helper
ensureInstalled grim
ensureInstalled slurp
ensureInstalled rxvt-unicode-pixbuf
ensureInstalled flashfocus-git
ensureInstalled networkmanager
ensureInstalled networkmanager-openconnect
ensureInstalled network-manager-applet-indicator
ensureInstalled acpi
ensureInstalled sysstat
ensureInstalled alsa-utils
ensureInstalled ntfs-3g
ensureInstalled gotop
ensureInstalled i3
ensureInstalled i3blocks
ensureInstalled xorg-server
ensureInstalled xorg-xinit
ensureInstalled compton
ensureInstalled autorandr
ensureInstalled arandr
ensureInstalled sway
ensureInstalled swaybg
ensureInstalled swayidle
ensureInstalled swaylock-blur-bin
ensureInstalled waybar
ensureInstalled xorg-server-xwayland
ensureInstalled ttf-inconsolata
ensureInstalled ttf-liberation
ensureInstalled ttf-dejavu
ensureInstalled otf-font-awesome
ensureInstalled system-san-francisco-font-git
ensureInstalled ttf-vlgothic
ensureInstalled zsh
ensureInstalled tmux
ensureInstalled gvim
ensureInstalled keychain
ensureInstalled openssh
ensureInstalled xdg-user-dirs
ensureInstalled rsync
ensureInstalled rofi
ensureInstalled w3m
ensureInstalled feh
ensureInstalled pacman-contrib
ensureInstalled thunar
ensureInstalled ranger
ensureInstalled trash-cli
ensureInstalled pavucontrol
ensureInstalled pulseaudio
ensureInstalled pulseaudio-bluetooth
ensureInstalled pasystray
ensureInstalled pulseaudio-ctl
ensureInstalled iw
ensureInstalled dialog
ensureInstalled wpa_supplicant
ensureInstalled google-chrome
ensureInstalled docker
