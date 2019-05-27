#!/bin/bash
systemctl start dhcpcd
systemctl enable dhcpcd
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
sleep 2
timedatectl set-ntp true

read -p "Username: " username
home_dir="/home/$username"
read -p "Set up a user? (y/n): " opt_user
read -p "Set up yay (y/n): " opt_yay
read -p "Install sway and a bunch of other stuff? (y/n): " opt_install
read -p "Set up dotfiles? (y/n): " opt_dot

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
  rm yay.tar.gz
  cd /
fi

if [ "$opt_install" = "y" ]
then

  echo '[archzfs]' >> /etc/pacman.conf
  echo 'Server = http://archzfs.com/$repo/$arch' >> /etc/pacman.conf
  pacman-key -r F75D9D76
  pacman-key --lsign-key F75D9D76

  pacman -Syyu

  yay -S sway swaylock-blur-bin waybar xorg-server-xwayland 
  yay -S ttf-inconsolata ttf-liberation ttf-dejavu otf-font-awesome system-san-francisco-font-git ttf-vlgothic
  yay -S zsh tmux gvim keychain openssh xdg-user-dirs
  yay -S rofi w3m feh thunar ranger
  yay -S acpi sysstat alsa-utils ntfs-3g gotop
  yay -S pavucontrol pulseaudio pulseaudio-bluetooth pasystray pulseaudio-ctl
  yay -S networkmanager networkmanager-openconnect network-manager-applet-indicator
  yay -S vlc arc-gtk-theme viewnior tumbler ffmpegthumbnailer
  yay -S gvfs gvfs-smb xarchiver reflector
  yay -S git maven nodejs jdk8-openjdk
  yay -S iw dialog wpa_supplicant
  yay -S grim slurp enpass-bin rxvt-unicode-pixbuf
  yay -S google-chrome

  chsh -s /bin/zsh "$username"

  echo "#!/bin/bash" > /usr/local/bin/google-chrome-stable-incognito
  echo "google-chrome-stable --incognito" >> /usr/local/bin/google-chrome-stable-incognito
  chmod +x /usr/local/bin/google-chrome-stable-incognito

  echo 'DESKTOP=$home_dir' > /etc/xdg/user-dirs.defaults
  echo 'DOWNLOAD=down' >> /etc/xdg/user-dirs.defaults
  echo 'DOCUMENTS=doc' >> /etc/xdg/user-dirs.defaults
  echo 'MUSIC=music' >> /etc/xdg/user-dirs.defaults
  echo 'PICTURES=pic' >> /etc/xdg/user-dirs.defaults
  echo 'VIDEOS=vid' >> /etc/xdg/user-dirs.defaults
  cd "$home_dir"
  sudo -u "$username" xdg-user-dirs-update
  cd /

  sudo -u "$username" git clone https://github.com/cinocode/dvorak_ger_io "$home_dir/.dvorak_ger_io"
  chown -R $username:users "$home_dir/.dvorak_ger_io"
  cd "$home_dir/.dvorak_ger_io"
  sudo -u "$username" git checkout gk64
  sh "$home_dir/.dvorak_ger_io/install_xkb.sh"
  cd /

fi

if [ "$opt_dot" = "y" ]
then
  sudo -u "$username" git clone https://github.com/cinocode/dotfiles "$home_dir/.dotfiles"
  chown -R $username:users "$home_dir/.dotfiles"
  cd "$home_dir/.dotfiles/"
  sudo -u "$username" git checkout sway
  cd /
  sudo -u "$username" sh "$home_dir/.dotfiles/init_configs.sh"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_wallpaper.sh"
  sudo -u "$username" sh "$home_dir/.dotfiles/init_vim.sh"
fi

systemctl start NetworkManager
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

mv /rice "$home_dir/.rice"
chown -R $username:users "$home_dir/.rice"

echo This is a good time to take care of graphic card drivers or microcode
