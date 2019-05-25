#!/bin/bash
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
systemctl start dhcpcd
systemctl enable dhcpcd

read -p "Username: " username
home_dir="/home/$username"
read -p "Set up a user? (y/n): " opt_user
read -p "Set up yay (y/n): " opt_yay
read -p "Install sway and a bunch of other stuff? (y/n): " opt_install
read -p "Set up dotfiles? (y/n): " opt_dot
read -p "Install Intel microcode? (y/n)" opt_intel
read -p "Install Amd microcode? (y/n)" opt_amd

if [ "$opt_user" = "y" ]
then
  echo "Setting up $username - please provide your password"
  useradd -m "$username"
  usermod -g users -aG wheel "$username"
  passwd "$username"

  echo "%wheel      ALL=(ALL) ALL" >> /etc/sudoers
  echo "Defaults !tty_tickets" >> /etc/sudoers
  echo "Defaults env_reset, timestamp_timeout=30" >> /etc/sudoers

  mkdir -p /etc/systemd/system/getty@tty1.service.d/
  echo [Service] > /etc/systemd/system/getty@tty1.service.d/override.conf
  echo ExecStart= >> /etc/systemd/system/getty@tty1.service.d/override.conf
  echo ExecStart=-/usr/bin/agetty --autologin $username --noclear %I $TERM >> /etc/systemd/system/getty@tty1.service.d/override.conf

  pacman -S git

  sudo -u "$username" mkdir "$home_dir/code"
  sudo -u "$username" git clone https://github.com/cinocode/dvorak_ger_io "$home_dir/code/dvorak_ger_io"
  cd "$home_dir/code/dvorak_ger_io"
  sudo -u "$username" git checkout gk64
  sh "$home_dir/code/dvorak_ger_io/install_xkb.sh"
  cd /
fi

if [ "$opt_yay" = "y" ]
then
  echo Setting up yay

  cd "$home_dir"
  curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
  sudo -u "$username" tar -xvf yay.tar.gz
  cd yay
  sudo -u "$username" makepkg --noconfirm -si
  cd ..
  rm -rf yay
fi

if [ "$opt_install" = "y" ]
then
  pacman -Syy

  pacman -Su sway waybar ttf-inconsolata ttf-liberation ttf-dejavu terminus-fonts zsh tmux gvim keychain openssh rofi w3m feh acpi sysstat alsa-utils ntfs-3g pavucontrol pulseaudio pulseaudio-bluetooth networkmanager networkmanager-openconnect vlc thunar ranger arc-gtk-theme viewnior tumbler ffmpegthumbnailer gvfs gvfs-smb xarchiver redshift xdg-user-dirs maven nodejs jdk8-openjdk

  chsh -s /bin/zsh "$username"

  sudo -u "$username" yay -Sy swaylock-blur-bin google-chrome enpass-bin network-manager-applet-indicator rxvt-unicode-pixbuf otf-font-awesome system-san-francisco-font-git ttf-vlgothic screengrab pasystray pulseaudio-ctl gotop

  echo "#!/bin/bash" > /usr/local/bin/google-chrome-stable-incognito
  echo "google-chrome-stable --incognito" >> /usr/local/bin/google-chrome-stable-incognito
  chmod +x /usr/local/bin/google-chrome-stable-incognito

  echo DESKTOP=$home_dir > /etc/xdg/user-dirs.defaults
  echo DOWNLOAD=down >> /etc/xdg/user-dirs.defaults
  echo DOCUMENTS=doc >> /etc/xdg/user-dirs.defaults
  echo MUSIC=music >> /etc/xdg/user-dirs.defaults
  echo PICTURES=pic >> /etc/xdg/user-dirs.defaults
  echo VIDEOS=vid >> /etc/xdg/user-dirs.defaults
  sudo -u "$username" xdg-user-dirs-update
fi

if [ "$opt_dot" = "y" ]
then
  sudo -u "$username" git clone https://github.com/cinocode/dotfiles "$home_dir/.dotfiles"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_configs.sh"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_wallpaper.sh"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_vim.sh"

  mkdir -p "$home_dir/.config/sway"
  cp "$home_dir/.config/i3/config" "$home_dir/.config/sway/"
fi


if [ "$opt_intel" = "y" ]
then
  pacman -S intel_ucode
  grub-mkconfig -o /boot/grub/grub.cfg
fi

if [ "$opt_amd" = "y" ]
then
  pacman -S amd_ucode
  grub-mkconfig -o /boot/grub/grub.cfg
fi

systemctl start NetworkManager
systemctl enable NetworkManager

echo If everything looks clean, you probably want to rm -rf /rice
echo Also this is a good time to take care of drivers
